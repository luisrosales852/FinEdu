//
//  EstadoJuego.swift
//  FinEdu
//
//  Estado mutable de una partida en curso. Decisión técnica: es un struct
//  (valor) dentro del ViewModel @Observable — los cambios disparan la UI sin
//  necesidad de hacerlo clase, y el motor determinista lo recibe como copia
//  inmutable (no puede modificarlo, solo proponer un ResultadoTurno).
//

import Foundation

/// Punto del historial para la gráfica de Swift Charts:
/// patrimonio nominal vs. lo que necesitarías para conservar tu poder de
/// compra inicial (patrimonio inicial ajustado por inflación acumulada).
struct RegistroTurno: Identifiable {
    var id: Int { numeroTurno }
    let numeroTurno: Int
    let patrimonio: Double
    /// Índice de inflación acumulada, base 100 al inicio del escenario.
    let indiceInflacion: Double
    let patrimonioInicial: Double

    /// Valor del patrimonio inicial ajustado por inflación: la "línea de
    /// flotación" — si tu patrimonio está debajo, perdiste poder adquisitivo.
    var umbralInflacion: Double { patrimonioInicial * indiceInflacion / 100 }
}

struct EstadoJuego {
    /// Patrimonio neto actual (ahorros + inversiones − deudas).
    var patrimonio: Double
    /// Liquidez 0–100: qué tan rápido puedes convertir tu patrimonio en
    /// efectivo para emergencias.
    var liquidez: Double
    /// Score de resiliencia financiera 0–100 (inicia en 50).
    var scoreResiliencia: Int
    /// Índice de inflación acumulada (base 100).
    var indiceInflacion: Double
    var historial: [RegistroTurno]
    var conceptosAprendidos: Set<ConceptoEconomico>

    let patrimonioInicial: Double

    init(perfil: PerfilJugador) {
        let inicial = perfil.patrimonioInicial
        patrimonio = inicial
        liquidez = 80 // se asume que casi todo el ahorro inicial es líquido
        scoreResiliencia = 50
        indiceInflacion = 100
        patrimonioInicial = inicial
        historial = [RegistroTurno(numeroTurno: 0,
                                   patrimonio: inicial,
                                   indiceInflacion: 100,
                                   patrimonioInicial: inicial)]
        conceptosAprendidos = []
    }

    /// Aplica el resultado de un turno. Toda la aritmética del juego vive
    /// aquí, en código determinista y auditable — nunca en la IA.
    mutating func aplicar(resultado: ResultadoTurno, turno: Turno) {
        // 1. Patrimonio: cambio porcentual ya acotado por el motor.
        patrimonio *= (1 + resultado.cambioPatrimonioPorcentaje / 100)

        // 2. Liquidez y resiliencia según el efecto del nivel de riesgo elegido.
        if let efecto = turno.efectos[resultado.nivelRiesgo] {
            liquidez = min(100, max(0, liquidez + efecto.cambioLiquidez))
            scoreResiliencia = min(100, max(0, scoreResiliencia + efecto.puntosResiliencia))
        }

        // 3. Inflación acumulada del periodo (dato histórico del turno).
        indiceInflacion *= (1 + turno.inflacionDelTurno / 100)

        // 4. Conceptos aprendidos (alimentan el glosario).
        conceptosAprendidos.insert(resultado.concepto)
        conceptosAprendidos.formUnion(resultado.conceptosDetectados)

        // 5. Historial para la gráfica.
        historial.append(RegistroTurno(numeroTurno: turno.id,
                                       patrimonio: patrimonio,
                                       indiceInflacion: indiceInflacion,
                                       patrimonioInicial: patrimonioInicial))
    }

    /// ¿El jugador conservó su poder adquisitivo? (patrimonio real ≥ inicial)
    var conservoPoderAdquisitivo: Bool {
        patrimonio >= patrimonioInicial * indiceInflacion / 100
    }

    /// Score final 0–100: combina resiliencia (60%) y desempeño del
    /// patrimonio frente a la inflación (40%).
    var scoreFinal: Int {
        let umbral = patrimonioInicial * indiceInflacion / 100
        let desempeno: Double
        if umbral > 0 {
            // 1.0 = conservaste exactamente tu poder de compra.
            desempeno = min(2, max(0, patrimonio / umbral))
        } else {
            desempeno = patrimonio >= 0 ? 1 : 0
        }
        let puntosDesempeno = min(40, max(0, Int(desempeno * 20)))
        let puntosResiliencia = Int(Double(scoreResiliencia) * 0.6)
        return min(100, puntosResiliencia + puntosDesempeno)
    }
}
