//
//  RecomendadorPresupuesto.swift
//  FinEdu
//
//  IA on-device del onboarding del Simulador de Bolsa. Mismo patrón que
//  FabricaMotorIA: dos capas con fallback automático y transparente.
//
//  Capa 1 — Foundation Models: pide al LLM una recomendación ESTRUCTURADA
//           (@Generable) de cuánto del capital destinar a bolsa.
//  Capa 2 — Regla determinista y defendible (15% tras señalar el fondo de
//           emergencia). Funciona siempre, sin Apple Intelligence ni red.
//
//  Ambas capas devuelven el mismo struct RecomendacionPresupuesto: la vista
//  no sabe qué capa respondió.
//

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Recomendación de asignación a bolsa (salida común de las dos capas).
struct RecomendacionPresupuesto {
    /// Fracción del capital total sugerida para bolsa (0...1).
    let porcentaje: Double
    /// Monto sugerido en USD.
    let monto: Double
    /// Explicación educativa en español.
    let explicacion: String
    /// Motor que produjo la recomendación.
    let motor: MotorIA
}

enum RecomendadorPresupuesto {

    /// Porcentaje base de la regla determinista (extremo conservador del
    /// rango 15–20% recomendado).
    static let porcentajeDeterminista = 0.15

    /// Genera la mejor recomendación disponible para el capital declarado.
    static func recomendar(presupuestoTotal: Double) async -> RecomendacionPresupuesto {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), case .available = SystemLanguageModel.default.availability {
            if let recomendacion = try? await recomendarConFM(presupuestoTotal: presupuestoTotal) {
                return recomendacion
            }
            // Si la capa 1 falla (guardrails, modelo no listo), degradamos.
        }
        #endif
        return recomendarDeterminista(presupuestoTotal: presupuestoTotal)
    }

    /// Capa 2: regla simple, fija y explicable. Recomienda 15% del capital
    /// tras recordar el fondo de emergencia de 3–6 meses de gastos.
    static func recomendarDeterminista(presupuestoTotal: Double) -> RecomendacionPresupuesto {
        let monto = (presupuestoTotal * porcentajeDeterminista).rounded()
        let explicacion = """
        Antes de invertir, lo ideal es tener un fondo de emergencia de 3 a 6 \
        meses de gastos y no usar dinero que necesites a corto plazo. Como guía \
        educativa para alguien joven con horizonte largo, sugerimos destinar \
        alrededor del 15% de tu capital a la bolsa. Puedes ajustar el monto \
        libremente: tú decides.
        """
        return RecomendacionPresupuesto(porcentaje: porcentajeDeterminista,
                                        monto: monto,
                                        explicacion: explicacion,
                                        motor: .reglasConLexico)
    }

    #if canImport(FoundationModels)
    /// Capa 1: recomendación estructurada del LLM on-device.
    @available(iOS 26.0, *)
    private static func recomendarConFM(presupuestoTotal: Double) async throws -> RecomendacionPresupuesto {
        let instrucciones = """
        Eres un coach financiero educativo para jóvenes en FinEdu. Tu tono es \
        cercano, claro y nunca regañas. Sigues principios básicos y prudentes: \
        primero un fondo de emergencia de 3 a 6 meses de gastos, no invertir \
        dinero que se necesita a corto plazo, y que un perfil joven con mayor \
        horizonte de tiempo puede tolerar algo más de riesgo. Esto es educación, \
        no asesoría de inversión.
        """
        let session = LanguageModelSession(instructions: instrucciones)
        let prompt = """
        El usuario declara un capital total de \(Int(presupuestoTotal)) USD. \
        Recomienda qué porcentaje y qué monto en USD destinar a invertir en \
        bolsa dentro de un simulador educativo, con una explicación corta.
        """
        let respuesta = try await session.respond(to: prompt,
                                                   generating: RecomendacionPresupuestoFM.self)
        let contenido = respuesta.content

        // Acotamiento human-centered: el LLM propone, la app lo limita a un
        // rango sensato (5–40%) para que ninguna recomendación sea temeraria.
        let porcentaje = min(max(Double(contenido.recommendedPercent) / 100.0, 0.05), 0.40)
        // El monto se recalcula desde el porcentaje acotado para mantener
        // coherencia con el capital (evita que el modelo proponga más de lo
        // que el usuario tiene).
        let monto = min((presupuestoTotal * porcentaje).rounded(), presupuestoTotal)

        return RecomendacionPresupuesto(porcentaje: porcentaje,
                                        monto: monto,
                                        explicacion: contenido.reasoning,
                                        motor: .foundationModels)
    }
    #endif
}
