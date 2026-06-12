//
//  PlantillasNarrativa.swift
//  FinEdu
//
//  Generación de narrativa y lección educativa para la CAPA 2 (sin LLM).
//  Combina: la narrativa escrita por el autor del escenario para el nivel de
//  riesgo clasificado + el impacto numérico + retroalimentación sobre los
//  conceptos detectados en el texto del usuario. El resultado se siente
//  personalizado aunque sea 100% determinista.
//

import Foundation

enum PlantillasNarrativa {

    /// Construye la narrativa de consecuencias del turno.
    static func narrativa(efecto: EfectoDecision,
                          cambio: Double,
                          conceptosDetectados: [ConceptoEconomico],
                          turno: Turno) -> String {
        var texto = efecto.narrativa

        let favorables = conceptosDetectados.filter { turno.conceptosFavorables.contains($0) }
        let desfavorables = conceptosDetectados.filter { turno.conceptosDesfavorables.contains($0) }

        if !favorables.isEmpty {
            texto += " Mencionar \(lista(favorables)) jugó a tu favor en este momento de la historia."
        }
        if !desfavorables.isEmpty {
            texto += " Apoyarte en \(lista(desfavorables)) te costó caro justo en esta coyuntura."
        }
        return texto
    }

    /// Construye la lección educativa: clasificación + por qué en ESTE
    /// contexto + definición del concepto económico central.
    static func leccion(nivel: NivelRiesgo,
                        concepto: ConceptoEconomico,
                        turno: Turno) -> String {
        let apertura: String
        switch nivel {
        case .conservadora:
            apertura = "Tu decisión fue conservadora: priorizaste proteger lo que tienes."
        case .moderada:
            apertura = "Tu decisión fue moderada: buscaste equilibrio entre proteger y crecer."
        case .arriesgada:
            apertura = "Tu decisión fue arriesgada: aceptaste exponerte a pérdidas a cambio de una posible ganancia."
        case .muyArriesgada:
            apertura = "Tu decisión fue muy arriesgada: comprometiste una parte grande de tu patrimonio en una sola apuesta."
        }

        // ¿Ese nivel de riesgo convenía en este turno? Lo dice el rango de
        // resultados definido con datos históricos.
        let contexto: String
        if let efecto = turno.efectos[nivel] {
            let centro = (efecto.rangoCambioPatrimonio.lowerBound + efecto.rangoCambioPatrimonio.upperBound) / 2
            if centro > 1 {
                contexto = "En este momento histórico, ese perfil de decisión solía dar buenos resultados."
            } else if centro < -1 {
                contexto = "En este momento histórico, ese perfil de decisión solía costar dinero — la historia no premia siempre la misma estrategia."
            } else {
                contexto = "En este momento histórico, ese perfil de decisión era defendible: ni la mejor ni la peor jugada."
            }
        } else {
            contexto = ""
        }

        return "\(apertura) \(contexto) Concepto clave — \(concepto.nombre): \(concepto.definicion)"
    }

    /// Lista legible en español: "deuda", "deuda y liquidez", "a, b y c".
    private static func lista(_ conceptos: [ConceptoEconomico]) -> String {
        let nombres = conceptos.map { $0.nombre.lowercased() }
        switch nombres.count {
        case 0: return ""
        case 1: return nombres[0]
        default: return nombres.dropLast().joined(separator: ", ") + " y " + nombres.last!
        }
    }
}
