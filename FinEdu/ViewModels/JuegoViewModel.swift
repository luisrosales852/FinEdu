//
//  JuegoViewModel.swift
//  FinEdu
//
//  ViewModel del juego por turnos (MVVM con el framework Observation).
//  Decisión técnica: @Observable (iOS 17) en lugar de ObservableObject —
//  menos boilerplate y la vista solo se redibuja por las propiedades que lee.
//  Es @MainActor porque muta estado que dibuja SwiftUI; la inferencia del
//  motor (capa 1) ocurre con await sin bloquear la UI.
//

import Foundation
import SwiftData
import Observation

/// Un elemento de la "conversación" del juego (estilo interactive fiction).
struct MensajeJuego: Identifiable {
    enum Contenido {
        case sistema(String)            // contexto/cierres narrativos
        case contexto(String)           // contexto histórico, oculto tras botón
        case evento(Turno)              // tarjeta de evento económico
        case decisionUsuario(String)    // burbuja con el texto del jugador
        case resultado(ResultadoTurno)  // consecuencias + lección
        case pedirReintento(String)     // IA pide al jugador que reformule
        case opciones([String])         // 3 opciones para elegir cuando el jugador no sabe
    }
    let id = UUID()
    let contenido: Contenido
}

@Observable
@MainActor
final class JuegoViewModel {

    let escenario: Escenario
    private(set) var estado: EstadoJuego
    private(set) var mensajes: [MensajeJuego] = []
    private(set) var procesando = false
    private(set) var partidaTerminada = false
    private(set) var ultimoResultado: ResultadoTurno?
    /// true mientras se espera que el jugador elija una de las 3 opciones
    /// generadas por el motor (el campo de texto se oculta en este estado).
    private(set) var esperandoOpciones = false
    var textoDecision = ""

    /// Motor de IA elegido por la fábrica (capa 1 o capa 2).
    private let motor: MotorDeDecision
    /// Motor que realmente respondió el último turno (puede diferir si la
    /// capa 1 falló a media partida y degradamos a la 2).
    private(set) var motorActivo: MotorIA

    private var indiceTurno = 0
    /// Cuántas veces seguidas el jugador ha enviado un input sin sentido en
    /// el turno actual. Se resetea al avanzar de turno o al validar con éxito.
    private var intentosInvalidosActual = 0
    /// Acumulamos las decisiones en memoria y persistimos la Partida completa
    /// al final (una sola transacción de SwiftData).
    private var decisionesAcumuladas: [DecisionGuardada] = []

    var turnoActual: Turno? {
        indiceTurno < escenario.turnos.count ? escenario.turnos[indiceTurno] : nil
    }

    var numeroTurnoLegible: String {
        "Turno \(min(indiceTurno + 1, escenario.turnos.count)) de \(escenario.turnos.count)"
    }

    var puedeEnviar: Bool {
        !textoDecision.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !procesando && !partidaTerminada && !esperandoOpciones
    }

    init(escenario: Escenario) {
        self.escenario = escenario
        estado = EstadoJuego(perfil: escenario.perfil)
        motor = FabricaMotorIA.crearMotor(escenario: escenario)
        motorActivo = motor.tipo

        // El contexto histórico se ofrece tras un botón "Más información" para
        // no saturar de texto el inicio: el foco es aprender decidiendo.
        mensajes.append(MensajeJuego(contenido: .contexto(escenario.contextoHistorico)))
        if let primero = turnoActual {
            mensajes.append(MensajeJuego(contenido: .evento(primero)))
        }
    }

    /// Evalúa la decisión escrita por el usuario y avanza el turno.
    /// Antes de evaluar, valida con el motor de IA si el input tiene sentido:
    /// · 1er input sin sentido → pide reformulación libre.
    /// · 2º input sin sentido → genera 3 opciones para elegir.
    func enviarDecision(contexto: ModelContext) async {
        guard let turno = turnoActual, puedeEnviar else { return }

        let texto = textoDecision.trimmingCharacters(in: .whitespacesAndNewlines)
        textoDecision = ""
        procesando = true
        mensajes.append(MensajeJuego(contenido: .decisionUsuario(texto)))

        // Validación: ¿el texto expresa una intención financiera?
        // Si el motor principal falla (p.ej. FM no disponible o guardrail),
        // usamos el heurístico de la capa 2 en lugar de aceptar todo ciegamente.
        let validacion: ValidacionInput
        do {
            validacion = try await motor.validarInput(texto: texto, turno: turno, escenario: escenario)
        } catch {
            validacion = (try? await MotorReglas().validarInput(texto: texto, turno: turno, escenario: escenario))
                ?? ValidacionInput(esSensato: true, mensajeReformulacion: "")
        }

        // Railguard de escenario: el input es una intención financiera, pero
        // sobre un instrumento que esta crisis no simula (p. ej. "le entro todo
        // a Pemex"). En vez de pedir reformular, explicamos por qué no aplica y
        // ofrecemos directamente las opciones válidas del turno.
        if validacion.fueraDeContexto {
            let opciones = (try? await motor.generarOpciones(turno: turno,
                                                             escenario: escenario,
                                                             estado: estado))
                ?? ["Guardo todo en efectivo y espero.",
                    "Divido mis ahorros entre pesos y dólares.",
                    "Invierto en activos que me protejan de la inflación."]
            mensajes.append(MensajeJuego(contenido: .pedirReintento(validacion.mensajeReformulacion)))
            mensajes.append(MensajeJuego(contenido: .opciones(opciones)))
            esperandoOpciones = true
            procesando = false
            return
        }

        if !validacion.esSensato {
            intentosInvalidosActual += 1
            if intentosInvalidosActual < 2 {
                // Primera vez sin sentido: otra oportunidad con texto libre.
                mensajes.append(MensajeJuego(contenido: .pedirReintento(validacion.mensajeReformulacion)))
            } else {
                // Segunda vez sin sentido: ofrecer 3 opciones concretas.
                let opciones = (try? await motor.generarOpciones(turno: turno,
                                                                  escenario: escenario,
                                                                  estado: estado))
                    ?? ["Guardo todo en efectivo y espero.",
                        "Divido mis ahorros entre pesos y dólares.",
                        "Invierto en activos que me protejan de la inflación."]
                mensajes.append(MensajeJuego(contenido: .opciones(opciones)))
                esperandoOpciones = true
            }
            procesando = false
            return
        }

        intentosInvalidosActual = 0
        await procesarEvaluacion(texto: texto, turno: turno, contexto: contexto)
        procesando = false
    }

    /// El jugador eligió una de las opciones generadas por el motor.
    /// Salta la validación (las opciones son válidas por construcción) y evalúa.
    func seleccionarOpcion(_ opcion: String, contexto: ModelContext) async {
        guard let turno = turnoActual, !procesando, !partidaTerminada else { return }
        esperandoOpciones = false
        intentosInvalidosActual = 0
        procesando = true
        mensajes.append(MensajeJuego(contenido: .decisionUsuario(opcion)))
        await procesarEvaluacion(texto: opcion, turno: turno, contexto: contexto)
        procesando = false
    }

    /// Lógica central de evaluación: llama al motor, aplica el resultado,
    /// registra la decisión y avanza al siguiente turno o termina la partida.
    private func procesarEvaluacion(texto: String, turno: Turno, contexto: ModelContext) async {
        var resultado: ResultadoTurno
        do {
            resultado = try await motor.evaluarDecision(texto: texto,
                                                        turno: turno,
                                                        escenario: escenario,
                                                        estado: estado)
        } catch {
            let respaldo = MotorReglas()
            resultado = (try? await respaldo.evaluarDecision(texto: texto,
                                                             turno: turno,
                                                             escenario: escenario,
                                                             estado: estado))
                ?? ResultadoTurno(nivelRiesgo: .moderada,
                                  cambioPatrimonioPorcentaje: 0,
                                  narrativa: "La economía sigue su curso mientras evalúas tus opciones.",
                                  concepto: turno.conceptoPrincipal,
                                  leccion: PlantillasNarrativa.leccion(nivel: .moderada,
                                                                       concepto: turno.conceptoPrincipal,
                                                                       turno: turno),
                                  conceptosDetectados: [],
                                  motor: .reglasConLexico)
        }
        motorActivo = resultado.motor

        estado.aplicar(resultado: resultado, turno: turno)
        ultimoResultado = resultado
        mensajes.append(MensajeJuego(contenido: .resultado(resultado)))

        desbloquearConceptos(de: resultado, contexto: contexto)
        decisionesAcumuladas.append(
            DecisionGuardada(numeroTurno: turno.id,
                             textoUsuario: texto,
                             nivelRiesgo: resultado.nivelRiesgo.rawValue,
                             cambioPatrimonio: resultado.cambioPatrimonioPorcentaje,
                             leccion: resultado.leccion))

        indiceTurno += 1
        intentosInvalidosActual = 0
        if let siguiente = turnoActual {
            mensajes.append(MensajeJuego(contenido: .evento(siguiente)))
        } else {
            partidaTerminada = true
            mensajes.append(MensajeJuego(contenido: .sistema(
                "Fin del escenario. Revisa tus resultados y las lecciones que te llevas.")))
            guardarPartida(contexto: contexto)
        }
    }

    /// Inserta conceptos en el glosario persistente. @Attribute(.unique)
    /// en ConceptoDesbloqueado convierte duplicados en upsert.
    private func desbloquearConceptos(de resultado: ResultadoTurno, contexto: ModelContext) {
        var conceptos = resultado.conceptosDetectados
        conceptos.append(resultado.concepto)
        for concepto in conceptos {
            contexto.insert(ConceptoDesbloqueado(conceptoID: concepto.rawValue))
        }
        try? contexto.save()
    }

    private func guardarPartida(contexto: ModelContext) {
        let partida = Partida(escenarioID: escenario.id,
                              completada: true,
                              scoreFinal: estado.scoreFinal,
                              patrimonioFinal: estado.patrimonio,
                              patrimonioInicial: estado.patrimonioInicial,
                              inflacionAcumulada: estado.indiceInflacion - 100,
                              motorUtilizado: motorActivo.rawValue)
        partida.decisiones = decisionesAcumuladas
        contexto.insert(partida)
        try? contexto.save()
    }
}
