//
//  ConceptoEconomico.swift
//  FinEdu
//
//  Conceptos económicos que la app enseña. Son el puente entre las tres capas:
//  - El extractor de NaturalLanguage mapea palabras del usuario a estos casos.
//  - El motor de Foundation Models los genera como enum @Generable espejo.
//  - El glosario los muestra y se van desbloqueando al jugar.
//

import Foundation

enum ConceptoEconomico: String, Codable, CaseIterable, Identifiable {
    case inflacion
    case devaluacion
    case diversificacion
    case liquidez
    case tasaDeInteres = "tasa_de_interes"
    case deuda
    case ahorro
    case inversion
    case dolarizacion
    case activosReales = "activos_reales"
    case panicoFinanciero = "panico_financiero"
    case fondoDeEmergencia = "fondo_de_emergencia"

    var id: String { rawValue }

    var nombre: String {
        switch self {
        case .inflacion: return "Inflación"
        case .devaluacion: return "Devaluación"
        case .diversificacion: return "Diversificación"
        case .liquidez: return "Liquidez"
        case .tasaDeInteres: return "Tasa de interés"
        case .deuda: return "Deuda"
        case .ahorro: return "Ahorro"
        case .inversion: return "Inversión"
        case .dolarizacion: return "Dolarización"
        case .activosReales: return "Activos reales"
        case .panicoFinanciero: return "Pánico financiero"
        case .fondoDeEmergencia: return "Fondo de emergencia"
        }
    }

    var icono: String {
        switch self {
        case .inflacion: return "chart.line.uptrend.xyaxis"
        case .devaluacion: return "arrow.down.right.circle.fill"
        case .diversificacion: return "square.grid.2x2.fill"
        case .liquidez: return "drop.fill"
        case .tasaDeInteres: return "percent"
        case .deuda: return "creditcard.fill"
        case .ahorro: return "banknote.fill"
        case .inversion: return "chart.bar.fill"
        case .dolarizacion: return "dollarsign.circle.fill"
        case .activosReales: return "house.fill"
        case .panicoFinanciero: return "person.3.fill"
        case .fondoDeEmergencia: return "cross.case.fill"
        }
    }
}
