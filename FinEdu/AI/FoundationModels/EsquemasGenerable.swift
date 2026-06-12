//
//  EsquemasGenerable.swift
//  FinEdu
//
//  Esquemas de SALIDA ESTRUCTURADA para Foundation Models (CAPA 1).
//  @Generable hace que el LLM on-device genere directamente instancias de
//  estos tipos (guided generation): nada de parsear JSON a mano ni de
//  respuestas con formato impredecible. @Guide restringe cada campo.
//
//  Todo el archivo está condicionado: compila solo con el SDK de iOS 26+ y
//  se usa solo si el dispositivo tiene Apple Intelligence disponible.
//

#if canImport(FoundationModels)
import Foundation
import FoundationModels

/// Espejo @Generable de NivelRiesgo (los tipos del dominio no pueden ser
/// @Generable directamente porque deben compilar también en iOS 17).
@available(iOS 26.0, *)
@Generable
enum NivelRiesgoFM {
    case conservadora
    case moderada
    case arriesgada
    case muyArriesgada

    var aNivelRiesgo: NivelRiesgo {
        switch self {
        case .conservadora: return .conservadora
        case .moderada: return .moderada
        case .arriesgada: return .arriesgada
        case .muyArriesgada: return .muyArriesgada
        }
    }
}

/// Espejo @Generable de ConceptoEconomico.
@available(iOS 26.0, *)
@Generable
enum ConceptoFM {
    case inflacion
    case devaluacion
    case diversificacion
    case liquidez
    case tasaDeInteres
    case deuda
    case ahorro
    case inversion
    case dolarizacion
    case activosReales
    case panicoFinanciero
    case fondoDeEmergencia

    var aConcepto: ConceptoEconomico {
        switch self {
        case .inflacion: return .inflacion
        case .devaluacion: return .devaluacion
        case .diversificacion: return .diversificacion
        case .liquidez: return .liquidez
        case .tasaDeInteres: return .tasaDeInteres
        case .deuda: return .deuda
        case .ahorro: return .ahorro
        case .inversion: return .inversion
        case .dolarizacion: return .dolarizacion
        case .activosReales: return .activosReales
        case .panicoFinanciero: return .panicoFinanciero
        case .fondoDeEmergencia: return .fondoDeEmergencia
        }
    }
}

/// Resultado estructurado que genera el LLM por cada turno.
/// Equivale al "TurnOutcome" del diseño: riesgo + impacto + narrativa +
/// concepto económico + lección.
@available(iOS 26.0, *)
@Generable(description: "Evaluación educativa de una decisión financiera dentro de una simulación histórica")
struct EvaluacionFM {

    @Guide(description: "Nivel de riesgo financiero de la decisión del jugador en su contexto")
    var nivelRiesgo: NivelRiesgoFM

    @Guide(description: "Cambio porcentual estimado del patrimonio del jugador este turno, coherente con los datos históricos del evento", .range(-60...40))
    var cambioPatrimonioPorcentaje: Int

    @Guide(description: "Narrativa en segunda persona y en español (máximo 3 oraciones) de qué pasó con el dinero, el empleo y la economía del jugador tras su decisión")
    var narrativa: String

    @Guide(description: "Concepto económico central que mejor explica esta situación")
    var concepto: ConceptoFM

    @Guide(description: "Lección educativa en español (máximo 2 oraciones): por qué la decisión fue prudente o arriesgada EN ese contexto histórico específico")
    var leccion: String
}

// ─────────────────────────────────────────────────────────────────────────
// MARK: - Esquemas del Simulador de Bolsa
// ─────────────────────────────────────────────────────────────────────────

/// Recomendación estructurada de cuánto del capital total destinar a bolsa,
/// generada en el onboarding del simulador.
@available(iOS 26.0, *)
@Generable(description: "Recomendación educativa de cuánto del capital total destinar a invertir en bolsa")
struct RecomendacionPresupuestoFM {

    @Guide(description: "Porcentaje del capital total que conviene destinar a la bolsa, como número entero de 0 a 100", .range(0...100))
    var recommendedPercent: Int

    @Guide(description: "Monto en dólares (USD) que conviene destinar a la bolsa, coherente con el porcentaje y el capital total declarado")
    var recommendedAmount: Double

    @Guide(description: "Explicación educativa en español (máximo 3 oraciones): por qué ese monto, mencionando el fondo de emergencia de 3 a 6 meses y no invertir dinero que se necesita a corto plazo")
    var reasoning: String
}

/// Consejo breve del coach de IA tras una operación de compra/venta.
@available(iOS 26.0, *)
@Generable(description: "Retroalimentación educativa breve sobre una decisión de inversión en un simulador")
struct ConsejoCoachFM {

    @Guide(description: "Consejo educativo en español, una o dos oraciones, tono cercano y sin regañar, sobre diversificación, concentración de riesgo o el momento de comprar/vender")
    var consejo: String
}

/// Retroalimentación final estructurada al terminar la simulación.
@available(iOS 26.0, *)
@Generable(description: "Retroalimentación educativa final sobre el desempeño en un simulador de bolsa")
struct FeedbackFinalFM {

    @Guide(description: "Resumen educativo en español (máximo 4 oraciones): qué hizo bien o mal el usuario, mencionando diversificación y horizonte de largo plazo, en tono motivador")
    var resumen: String
}

// ─────────────────────────────────────────────────────────────────────────
// MARK: - Esquemas de validación de input del jugador
// ─────────────────────────────────────────────────────────────────────────

/// Valida si el texto del jugador tiene sentido como decisión financiera.
/// Se usa ANTES de evaluar el turno para detectar inputs sin sentido.
@available(iOS 26.0, *)
@Generable(description: "Validación de si el texto del jugador expresa una intención financiera en el contexto de la crisis")
struct ValidacionInputFM {

    /// El modelo decide primero si tiene sentido, luego redacta el mensaje.
    @Guide(description: "true SOLO si el texto usa palabras reconocibles del español o inglés Y expresa alguna intención con el dinero (ahorrar, invertir, gastar, dolarizar, pagar deudas, etc.); false si contiene palabras inventadas, letras repetidas de más (ej: 'passosss', 'doofars'), caracteres al azar, o no guarda relación con finanzas")
    var esSensato: Bool

    @Guide(description: "Mensaje breve en español de México, cálido y sin regañar, invitando al jugador a contarle qué haría con su dinero en este momento de crisis (solo relevante cuando esSensato es false, máximo 2 oraciones)")
    var mensajeReformulacion: String
}

/// Tres opciones de decisión financiera generadas por el motor cuando el
/// jugador no sabe qué responder tras dos intentos sin sentido.
@available(iOS 26.0, *)
@Generable(description: "Tres opciones de decisión financiera realistas para el contexto de la crisis, de menor a mayor riesgo")
struct OpcionesDecisionFM {

    @Guide(description: "Opción conservadora: en primera persona informal, máximo 12 palabras, coherente con el evento histórico del turno")
    var opcion1: String

    @Guide(description: "Opción moderada (equilibrio riesgo/protección): en primera persona informal, máximo 12 palabras")
    var opcion2: String

    @Guide(description: "Opción arriesgada (mayor potencial de ganancia o pérdida): en primera persona informal, máximo 12 palabras")
    var opcion3: String
}
#endif
