//
//  BudgetModels.swift
//  FinEdu
//
//  Modelos de datos del "Simulador de Presupuesto Personal Mensual".
//  Decisión técnica: structs/enums de valor, sin dependencias de red ni de
//  terceros. La clasificación reutiliza el enum MotorIA del resto de la app
//  (ResultadoTurno.swift) para que la UI muestre, igual que en los otros
//  modos, qué motor de IA on-device produjo el resultado.
//

import Foundation
import SwiftUI

// MARK: - Categorías del presupuesto

/// Las 6 categorías fijas entre las que el usuario reparte su salario.
/// El `rawValue` es la clave estable que se usa para persistir en disco.
enum CategoriaPresupuesto: String, CaseIterable, Identifiable, Codable {
    case renta
    case alimentacion
    case ahorro
    case entretenimiento
    case transporte
    case otros

    var id: String { rawValue }

    /// Nombre legible para la UI y VoiceOver.
    var nombre: String {
        switch self {
        case .renta: return "Renta / Vivienda"
        case .alimentacion: return "Alimentación"
        case .ahorro: return "Ahorro / Inversión"
        case .entretenimiento: return "Entretenimiento"
        case .transporte: return "Transporte"
        case .otros: return "Otros / Imprevistos"
        }
    }

    /// SF Symbol representativo de la categoría.
    var icono: String {
        switch self {
        case .renta: return "house.fill"
        case .alimentacion: return "cart.fill"
        case .ahorro: return "banknote.fill"
        case .entretenimiento: return "gamecontroller.fill"
        case .transporte: return "car.fill"
        case .otros: return "questionmark.circle.fill"
        }
    }

    /// Pista breve que se muestra bajo el nombre como ayuda al usuario.
    var pista: String {
        switch self {
        case .renta: return "Lo ideal es no rebasar ~30%"
        case .alimentacion: return "Despensa, comidas"
        case .ahorro: return "La meta 50/30/20 sugiere ~20%"
        case .entretenimiento: return "Salidas, suscripciones"
        case .transporte: return "Gasolina, transporte público"
        case .otros: return "Imprevistos, salud, varios"
        }
    }

    /// Color del segmento en la gráfica de dona. Cada categoría tiene un color
    /// distinto; nunca es el único canal de información (siempre va con texto).
    var color: Color {
        switch self {
        case .renta: return .blue
        case .alimentacion: return .green
        case .ahorro: return .teal
        case .entretenimiento: return .purple
        case .transporte: return .orange
        case .otros: return .gray
        }
    }

    /// Clave usada para construir la cadena estructurada que recibe el modelo
    /// de Core ML (p. ej. "renta:40 comida:10 ahorro:5 ..."). "alimentacion"
    /// se abrevia a "comida" para coincidir con el formato del dataset.
    var claveModelo: String {
        self == .alimentacion ? "comida" : rawValue
    }

    /// Grupo de la regla 50/30/20: necesidades (50%), deseos (30%), ahorro (20%).
    var grupo: GrupoGasto {
        switch self {
        case .renta, .alimentacion, .transporte: return .necesidad
        case .entretenimiento, .otros: return .deseo
        case .ahorro: return .ahorro
        }
    }
}

/// Los tres grupos de la regla 50/30/20.
enum GrupoGasto {
    case necesidad
    case deseo
    case ahorro
}

// MARK: - Clasificación del presupuesto

/// Estado en el que la IA on-device clasifica una distribución de presupuesto.
/// Los `rawValue` coinciden con las etiquetas del dataset de Create ML
/// (ver Training/dataset_presupuesto.csv) para mapear la salida del modelo.
enum ClasificacionPresupuesto: String, Codable, CaseIterable, Identifiable {
    case sostenible
    case riesgoso
    case critico

    var id: String { rawValue }

    var titulo: String {
        switch self {
        case .sostenible: return "SOSTENIBLE"
        case .riesgoso: return "RIESGOSO"
        case .critico: return "CRÍTICO"
        }
    }

    var resumen: String {
        switch self {
        case .sostenible: return "Buenos hábitos financieros"
        case .riesgoso: return "Algunas categorías están desbalanceadas"
        case .critico: return "Alto riesgo de inestabilidad financiera"
        }
    }

    var icono: String {
        switch self {
        case .sostenible: return "checkmark.seal.fill"
        case .riesgoso: return "exclamationmark.triangle.fill"
        case .critico: return "xmark.octagon.fill"
        }
    }

    /// Color temático. Usamos verde / amarillo / rojo, pero para el amarillo
    /// preferimos un tono más saturado (cumple contraste AA sobre fondos del
    /// sistema). Como en todo el proyecto, el color SIEMPRE va acompañado de
    /// icono + texto, pensando en usuarios con daltonismo.
    var color: Color {
        switch self {
        case .sostenible: return .green
        case .riesgoso: return .yellow
        case .critico: return .red
        }
    }

    /// Escenario de crisis de la app relacionado con la retroalimentación,
    /// para conectar este simulador con el modo de "Selección de crisis".
    var escenarioRelacionadoID: String {
        switch self {
        case .sostenible: return "global2008"     // Crisis global de 2008
        case .riesgoso: return "hiperinflacion"   // Inflación alta
        case .critico: return "tequila1994"       // "Error de diciembre" de 1994
        }
    }

    /// Nombre legible de la crisis relacionada (para el botón de enlace).
    var escenarioRelacionadoNombre: String {
        switch self {
        case .sostenible: return "Crisis global de 2008"
        case .riesgoso: return "Hiperinflación"
        case .critico: return "Error de diciembre (1994)"
        }
    }
}

// MARK: - Resultado del análisis (salida del clasificador)

/// Resultado completo de analizar un presupuesto. No se persiste tal cual;
/// para el historial se guarda el `BudgetEntry` (más compacto).
struct ResultadoPresupuesto {
    /// Estado en que se clasificó el presupuesto.
    let clasificacion: ClasificacionPresupuesto
    /// Motor de IA que produjo la clasificación (Core ML o léxico/reglas).
    let motor: MotorIA
    /// Porcentaje del salario que representa cada categoría.
    let porcentajes: [CategoriaPresupuesto: Double]
    /// Categorías señaladas como problemáticas por las reglas financieras.
    let categoriasProblematicas: [CategoriaPresupuesto]
    /// Meses de colchón estimados: si sostienes este ritmo de ahorro un año,
    /// cuántos meses de gastos esenciales podrías cubrir sin ingresos.
    let mesesDeColchon: Int
    /// Mensaje principal (texto "de la IA"), referido a un hecho histórico real.
    let feedbackPrincipal: String
    /// Consejos puntuales por cada categoría problemática.
    let consejos: [String]
}

// MARK: - Entrada persistida en el historial

/// Una simulación guardada. Codable + Identifiable para serializarla a JSON en
/// UserDefaults (ver BudgetHistoryStore) y listarla en la UI. Se conservan solo
/// las últimas 3 simulaciones.
struct BudgetEntry: Codable, Identifiable {
    let id: UUID
    let salario: Double
    /// rawValue de CategoriaPresupuesto -> monto asignado en MXN.
    let categorias: [String: Double]
    /// rawValue de ClasificacionPresupuesto.
    let clasificacion: String
    let fecha: Date

    init(id: UUID = UUID(),
         salario: Double,
         categorias: [String: Double],
         clasificacion: String,
         fecha: Date = .now) {
        self.id = id
        self.salario = salario
        self.categorias = categorias
        self.clasificacion = clasificacion
        self.fecha = fecha
    }

    /// Clasificación decodificada (con valor por defecto seguro).
    var clasificacionEnum: ClasificacionPresupuesto {
        ClasificacionPresupuesto(rawValue: clasificacion) ?? .riesgoso
    }

    /// Montos decodificados a su enum de categoría.
    var montos: [CategoriaPresupuesto: Double] {
        var resultado: [CategoriaPresupuesto: Double] = [:]
        for (clave, monto) in categorias {
            if let categoria = CategoriaPresupuesto(rawValue: clave) {
                resultado[categoria] = monto
            }
        }
        return resultado
    }
}
