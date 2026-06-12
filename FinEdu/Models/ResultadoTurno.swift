//
//  ResultadoTurno.swift
//  FinEdu
//
//  Estructura COMÚN de salida de los dos motores de IA. Decisión técnica:
//  ambas capas (Foundation Models y NaturalLanguage/Create ML) producen este
//  mismo struct, de modo que el ViewModel y las vistas no saben — ni les
//  importa — qué motor generó el resultado. Esto hace el fallback transparente.
//

import Foundation

/// Identifica qué motor de IA produjo un resultado. Se muestra discretamente
/// en la UI para poder explicar la arquitectura a los jueces.
enum MotorIA: String, Codable {
    case foundationModels = "Apple Intelligence · Foundation Models"
    case reglasConCoreML = "Core ML + NaturalLanguage"
    case reglasConLexico = "NaturalLanguage (léxico)"

    var esGenerativo: Bool { self == .foundationModels }

    var icono: String {
        switch self {
        case .foundationModels: return "apple.intelligence"
        case .reglasConCoreML, .reglasConLexico: return "cpu.fill"
        }
    }
}

/// Resultado de evaluar la decisión en texto libre del usuario en un turno.
struct ResultadoTurno {
    /// Clasificación de riesgo de la decisión.
    let nivelRiesgo: NivelRiesgo
    /// Cambio porcentual aplicado al patrimonio. SIEMPRE acotado por la app
    /// al rango definido en el escenario: la IA nunca inventa números fuera
    /// de los límites históricos plausibles (principio human-centered).
    let cambioPatrimonioPorcentaje: Double
    /// Narrativa de consecuencias (qué pasó con tu dinero, empleo, economía).
    let narrativa: String
    /// Concepto económico central de la retroalimentación.
    let concepto: ConceptoEconomico
    /// Lección educativa personalizada: por qué la decisión fue prudente o
    /// arriesgada EN ESE contexto histórico.
    let leccion: String
    /// Conceptos detectados en el texto del usuario (para desbloquear glosario).
    let conceptosDetectados: [ConceptoEconomico]
    /// Motor que produjo este resultado.
    let motor: MotorIA
}
