//
//  Escenario.swift
//  FinEdu
//
//  Modelos de dominio del simulador. Decisión técnica: los escenarios se
//  definen como structs de Swift (no JSON) porque son contenido estático,
//  type-safe y más rápido de iterar en un hackathon — el compilador valida
//  que cada turno tenga sus efectos completos.
//

import Foundation

/// Nivel de riesgo de una decisión financiera.
/// Los `rawValue` coinciden EXACTAMENTE con las etiquetas del dataset de
/// Create ML (`Training/dataset_decisiones.csv`) para que la salida del
/// clasificador `MLTextClassifier` se mapee directo a este enum.
enum NivelRiesgo: String, Codable, CaseIterable, Identifiable {
    case conservadora
    case moderada
    case arriesgada
    case muyArriesgada = "muy_arriesgada"

    var id: String { rawValue }

    /// Título legible para la UI y VoiceOver.
    var titulo: String {
        switch self {
        case .conservadora: return "Conservadora"
        case .moderada: return "Moderada"
        case .arriesgada: return "Arriesgada"
        case .muyArriesgada: return "Muy arriesgada"
        }
    }

    var icono: String {
        switch self {
        case .conservadora: return "shield.fill"
        case .moderada: return "scalemass.fill"
        case .arriesgada: return "flame.fill"
        case .muyArriesgada: return "exclamationmark.triangle.fill"
        }
    }

    /// Posición 0...3 para el medidor de riesgo de la UI.
    var indice: Int {
        switch self {
        case .conservadora: return 0
        case .moderada: return 1
        case .arriesgada: return 2
        case .muyArriesgada: return 3
        }
    }
}

/// Efecto que produce una decisión de cierto nivel de riesgo en un turno.
/// El AUTOR del escenario define qué nivel de riesgo conviene en cada turno:
/// en una hiperinflación, ser "conservador" guardando efectivo es lo peor,
/// y eso se modela aquí con datos históricos, no lo decide la IA.
struct EfectoDecision {
    /// Rango de cambio porcentual del patrimonio (ej. -30 ... -10).
    /// El motor de reglas usa el punto medio ajustado por conceptos detectados;
    /// el motor de Foundation Models propone un valor y la app lo ACOTA a un
    /// rango seguro (la IA narra, las matemáticas las controla la app).
    let rangoCambioPatrimonio: ClosedRange<Double>
    /// Cambio en puntos de liquidez (0–100). Ej.: invertir todo baja liquidez.
    let cambioLiquidez: Double
    /// Puntos que suma o resta al score de resiliencia financiera (0–100).
    let puntosResiliencia: Int
    /// Narrativa de consecuencias escrita por el autor del escenario,
    /// usada por el motor de reglas (capa 2 de IA).
    let narrativa: String
}

/// Un turno del juego: evento económico + efectos posibles.
struct Turno: Identifiable {
    let id: Int
    let titulo: String
    /// Narrativa del evento económico que se presenta al jugador.
    let evento: String
    /// Dato histórico real que justifica el evento (criterio de la rúbrica:
    /// "datos que justifican la propuesta"). Se muestra como nota en la tarjeta.
    let datoHistorico: String
    /// Inflación (%) del periodo que cubre este turno; alimenta la gráfica
    /// de patrimonio vs. inflación en Swift Charts.
    let inflacionDelTurno: Double
    /// Efectos para cada nivel de riesgo. Debe contener los 4 niveles.
    let efectos: [NivelRiesgo: EfectoDecision]
    /// Conceptos económicos que, si aparecen en la decisión del usuario,
    /// MEJORAN el resultado este turno (ej. "dolarización" antes de devaluar).
    let conceptosFavorables: [ConceptoEconomico]
    /// Conceptos que EMPEORAN el resultado este turno (ej. tomar "deuda"
    /// justo cuando las tasas se disparan).
    let conceptosDesfavorables: [ConceptoEconomico]
    /// Magnitud (en puntos %) del ajuste por cada concepto detectado.
    let ajustePorConcepto: Double
    /// Concepto educativo principal del turno (fallback para la lección).
    let conceptoPrincipal: ConceptoEconomico
}

/// Perfil inicial del jugador en un escenario.
struct PerfilJugador {
    let rol: String
    let descripcion: String
    let ingresoMensual: Double
    let ahorrosIniciales: Double
    let deudaInicial: Double
    let simboloMoneda: String
    let nombreMoneda: String

    /// Patrimonio neto inicial = ahorros − deuda.
    var patrimonioInicial: Double { ahorrosIniciales - deudaInicial }
}

/// Escenario completo: contexto histórico + perfil + turnos.
struct Escenario: Identifiable {
    let id: String
    let titulo: String
    let subtitulo: String
    let periodo: String
    let contextoHistorico: String
    /// Fuentes de los datos históricos (se muestran en la ficha del escenario
    /// y en el README; refuerzan el criterio de datos reales).
    let fuentesDatos: [String]
    let perfil: PerfilJugador
    let turnos: [Turno]
    let icono: String
}

/// Catálogo estático de escenarios jugables.
enum CatalogoEscenarios {
    static let todos: [Escenario] = [
        crisisTequila1994,
        crisisGlobal2008,
        hiperinflacion,
    ]

    static func porID(_ id: String) -> Escenario? {
        todos.first { $0.id == id }
    }
}
