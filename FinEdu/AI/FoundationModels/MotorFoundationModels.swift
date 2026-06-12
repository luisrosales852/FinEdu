//
//  MotorFoundationModels.swift
//  FinEdu
//
//  CAPA 1 de la arquitectura de IA: Foundation Models (Apple Intelligence).
//  Un LLM de ~3B parámetros corriendo EN el dispositivo: sin red, sin nube,
//  sin enviar ni un byte de los textos del usuario fuera del iPhone.
//
//  Decisiones técnicas clave:
//  · UNA LanguageModelSession por partida: la sesión conserva el transcript,
//    así el modelo recuerda los turnos anteriores y la narrativa es continua.
//  · Salida estructurada con @Generable (EsquemasGenerable.swift): el modelo
//    no devuelve texto libre, devuelve un struct tipado.
//  · El número que propone el LLM se ACOTA al rango histórico definido en el
//    escenario (human-centered: la IA narra y enseña; los límites de la
//    simulación los fijan datos reales auditables, no el modelo).
//

#if canImport(FoundationModels)
import Foundation
import FoundationModels

@available(iOS 26.0, *)
final class MotorFoundationModels: MotorDeDecision {

    let tipo: MotorIA = .foundationModels

    private let session: LanguageModelSession
    /// Reutilizamos el extractor de la capa 2 para desbloquear el glosario:
    /// detectar QUÉ mencionó el usuario es tarea de NLP clásico, no del LLM.
    private let extractor = ExtractorConceptos()

    init(escenario: Escenario) {
        let instrucciones = """
        Eres el motor educativo de FinEdu, un simulador de resiliencia financiera \
        para jóvenes basado en crisis económicas históricas reales. El jugador \
        está en este escenario:

        ESCENARIO: \(escenario.titulo) (\(escenario.periodo)).
        CONTEXTO: \(escenario.contextoHistorico)
        PERFIL DEL JUGADOR: \(escenario.perfil.rol). \(escenario.perfil.descripcion) \
        Su moneda es \(escenario.perfil.nombreMoneda).

        En cada turno recibirás el evento económico (con su dato histórico real) \
        y la decisión escrita por el jugador. Tu trabajo:
        1. Clasificar el riesgo de la decisión EN ese contexto histórico.
        2. Estimar el impacto porcentual en su patrimonio, fiel a los datos reales.
        3. Narrar las consecuencias en segunda persona, tono cercano, español de México.
        4. Dar una lección educativa que conecte la decisión con el concepto económico.

        Sé empático y nunca regañes: el objetivo es que el jugador aprenda. No \
        inventes cifras históricas distintas a las del evento.
        """
        session = LanguageModelSession(instructions: instrucciones)
        // Precalienta el modelo para reducir la latencia del primer turno.
        session.prewarm()
    }

    func evaluarDecision(texto: String,
                         turno: Turno,
                         escenario: Escenario,
                         estado: EstadoJuego) async throws -> ResultadoTurno {

        let prompt = """
        TURNO \(turno.id) DE \(escenario.turnos.count): \(turno.titulo)
        EVENTO: \(turno.evento)
        DATO HISTÓRICO REAL: \(turno.datoHistorico)
        ESTADO DEL JUGADOR: patrimonio \(escenario.perfil.simboloMoneda)\(Int(estado.patrimonio)), \
        liquidez \(Int(estado.liquidez))/100, resiliencia \(estado.scoreResiliencia)/100.

        DECISIÓN ESCRITA POR EL JUGADOR: "\(texto)"

        Evalúa la decisión y genera el resultado del turno.
        """

        // Guided generation: la respuesta ES un EvaluacionFM tipado.
        let respuesta = try await session.respond(to: prompt, generating: EvaluacionFM.self)
        let evaluacion = respuesta.content
        let nivel = evaluacion.nivelRiesgo.aNivelRiesgo

        // ── Acotamiento human-centered ───────────────────────────────────
        // El LLM propone el impacto, pero la app lo limita al rango definido
        // con datos históricos para ese nivel de riesgo en ese turno.
        let rango = turno.efectos[nivel]?.rangoCambioPatrimonio ?? -20.0...20.0
        let cambio = min(max(Double(evaluacion.cambioPatrimonioPorcentaje),
                             rango.lowerBound),
                         rango.upperBound)

        return ResultadoTurno(nivelRiesgo: nivel,
                              cambioPatrimonioPorcentaje: cambio,
                              narrativa: evaluacion.narrativa,
                              concepto: evaluacion.concepto.aConcepto,
                              leccion: evaluacion.leccion,
                              conceptosDetectados: extractor.extraer(de: texto),
                              motor: .foundationModels)
    }

    func validarInput(texto: String,
                      turno: Turno,
                      escenario: Escenario) async throws -> ValidacionInput {
        // Railguard determinista ANTES del LLM: instrumentos que el escenario no
        // simula (acciones concretas, cripto…) se desvían a las opciones válidas.
        if let termino = GuardiaEscenario.instrumentoFueraDeContexto(en: texto) {
            return GuardiaEscenario.validacion(termino: termino, escenario: escenario)
        }

        // Sesión ligera y sin contexto narrativo: solo detecta si el texto
        // tiene sentido como decisión financiera. No contamina el transcript
        // de la sesión principal que mantiene la continuidad del juego.
        let sessionVal = LanguageModelSession(instructions: """
            Eres un validador para FinEdu, simulador de crisis financieras históricas. \
            Determina si el texto del jugador expresa alguna intención financiera.
            """)

        let prompt = """
            TURNO: \(turno.titulo)
            EVENTO: \(turno.evento)
            TEXTO DEL JUGADOR: "\(texto)"

            ¿El texto usa palabras reales del español o inglés Y expresa qué \
            haría el jugador con su dinero?

            Ejemplos SENSATOS: "compro dólares", "ahorro todo", "pago mi deuda"
            Ejemplos NO SENSATOS: "passosss doofars" (palabras inventadas), \
            "asdf qwerty" (letras al azar), "123 !!!" (sin palabras reales), \
            cualquier texto con letras repetidas de más o sin relación financiera.

            Sé estricto: si el texto no forma oraciones reconocibles en español \
            o inglés, marca esSensato como false.
            """

        let respuesta = try await sessionVal.respond(to: prompt, generating: ValidacionInputFM.self)
        return ValidacionInput(esSensato: respuesta.content.esSensato,
                               mensajeReformulacion: respuesta.content.mensajeReformulacion)
    }

    func generarOpciones(turno: Turno,
                         escenario: Escenario,
                         estado: EstadoJuego) async throws -> [String] {
        let sessionOpc = LanguageModelSession(instructions: """
            Eres un asistente educativo de FinEdu. Generas opciones de decisión \
            financiera históricamente plausibles para ayudar al jugador.
            """)

        let prompt = """
            ESCENARIO: \(escenario.titulo) (\(escenario.periodo))
            TURNO \(turno.id): \(turno.titulo)
            EVENTO: \(turno.evento)
            PERFIL: \(escenario.perfil.rol). \
            Patrimonio: \(escenario.perfil.simboloMoneda)\(Int(estado.patrimonio)).
            Genera 3 opciones breves en primera persona, de menor a mayor riesgo, \
            coherentes con el momento histórico.
            """

        let respuesta = try await sessionOpc.respond(to: prompt, generating: OpcionesDecisionFM.self)
        let c = respuesta.content
        return [c.opcion1, c.opcion2, c.opcion3]
    }
}
#endif
