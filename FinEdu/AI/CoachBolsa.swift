//
//  CoachBolsa.swift
//  FinEdu
//
//  Coach financiero on-device del Simulador de Bolsa. Mismo patrón de dos
//  capas que el resto de FinEdu:
//  Capa 1 — Foundation Models: consejo breve generado por el LLM (@Generable).
//  Capa 2 — Reglas deterministas: alertas de concentración (>50% en una sola
//           empresa), diversificación y comprar caro / vender en pánico.
//
//  Es la conexión natural con el resto de la app (educación financiera) y
//  suma al criterio de IA. Todo corre en el dispositivo, sin red.
//

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Datos de una operación recién hecha, para que el coach la comente.
struct ContextoCoach {
    let operacion: TipoTransaccion
    let ticker: String
    let nombreEmpresa: String
    /// Cambio % del precio este mes.
    let cambioMensual: Double
    let numeroEmpresas: Int
    /// Fracción 0...1 del portafolio en la mayor posición tras la operación.
    let concentracionMayor: Double
    let tickerMayor: String?
}

/// Consejo del coach con el motor que lo produjo (para el chip de UI).
struct ConsejoCoach: Identifiable {
    let id = UUID()
    let texto: String
    let motor: MotorIA
}

enum CoachBolsa {

    /// Umbral de concentración a partir del cual avisamos del riesgo.
    static let umbralConcentracion = 0.5

    // MARK: - Consejo tras una operación

    static func consejo(_ ctx: ContextoCoach) async -> ConsejoCoach {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), case .available = SystemLanguageModel.default.availability {
            if let texto = try? await consejoConFM(ctx) {
                return ConsejoCoach(texto: texto, motor: .foundationModels)
            }
        }
        #endif
        return ConsejoCoach(texto: consejoDeterminista(ctx), motor: .reglasConLexico)
    }

    /// Capa 2: reglas claras y defendibles.
    static func consejoDeterminista(_ ctx: ContextoCoach) -> String {
        if ctx.concentracionMayor > umbralConcentracion, let t = ctx.tickerMayor {
            return "Ojo: alrededor del \(Int(ctx.concentracionMayor * 100))% de tu portafolio está en \(t). Concentrar tanto en una sola empresa aumenta el riesgo; repartir entre varias lo reduce."
        }
        switch ctx.operacion {
        case .compra:
            if ctx.numeroEmpresas <= 1 {
                return "Sumaste \(ctx.ticker). Tener una sola empresa es arriesgado: piensa en repartir tu dinero entre varias para no depender de una."
            }
            if ctx.cambioMensual > 8 {
                return "Compraste \(ctx.ticker) justo tras subir \(ctx.cambioMensual.comoPorcentajeConSigno) en el mes. Comprar caro pasa; lo que importa es tu horizonte de largo plazo, no un mes."
            }
            return "Buena, ahora tienes \(ctx.numeroEmpresas) empresas. Mantén la calma con los altibajos y revisa que sigas diversificado."
        case .venta:
            if ctx.cambioMensual < -8 {
                return "Vendiste \(ctx.ticker) después de caer \(ctx.cambioMensual.comoPorcentajeConSigno). Vender en pánico suele costar caro: a veces conviene esperar a que se recupere."
            }
            return "Vendiste \(ctx.ticker). Recuerda que vender vuelve definitiva la ganancia o la pérdida de esa posición."
        }
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private static func consejoConFM(_ ctx: ContextoCoach) async throws -> String {
        let instrucciones = """
        Eres un coach financiero educativo para jóvenes en un simulador de bolsa. \
        Hablas español de México, en tono cercano y motivador, y NUNCA regañas. \
        Das consejos breves (1-2 oraciones) sobre diversificación, concentración \
        de riesgo y el momento de comprar o vender. Es educación, no asesoría.
        """
        let session = LanguageModelSession(instructions: instrucciones)
        let accion = ctx.operacion == .compra ? "compró" : "vendió"
        let concentracion = "\(Int(ctx.concentracionMayor * 100))% en \(ctx.tickerMayor ?? "ninguna")"
        let prompt = """
        El usuario \(accion) acciones de \(ctx.nombreEmpresa) (\(ctx.ticker)), que este \
        mes cambió \(ctx.cambioMensual.comoPorcentajeConSigno). Ahora tiene \
        \(ctx.numeroEmpresas) empresas y su mayor posición es \(concentracion). \
        Dale un consejo educativo breve sobre su decisión.
        """
        let respuesta = try await session.respond(to: prompt, generating: ConsejoCoachFM.self)
        return respuesta.content.consejo
    }
    #endif

    // MARK: - Retroalimentación final

    static func feedbackFinal(rendimientoPct: Double,
                              diferenciaVsCash: Double,
                              numeroEmpresas: Int) async -> String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), case .available = SystemLanguageModel.default.availability {
            if let texto = try? await feedbackFinalConFM(rendimientoPct: rendimientoPct,
                                                         diferenciaVsCash: diferenciaVsCash,
                                                         numeroEmpresas: numeroEmpresas) {
                return texto
            }
        }
        #endif
        return feedbackFinalDeterminista(rendimientoPct: rendimientoPct,
                                         diferenciaVsCash: diferenciaVsCash,
                                         numeroEmpresas: numeroEmpresas)
    }

    static func feedbackFinalDeterminista(rendimientoPct: Double,
                                          diferenciaVsCash: Double,
                                          numeroEmpresas: Int) -> String {
        let diversif = numeroEmpresas >= 3
            ? "Diversificaste en \(numeroEmpresas) empresas, lo que reduce el riesgo."
            : "Tuviste pocas empresas: diversificar más suaviza los altibajos."
        let resultado = diferenciaVsCash >= 0
            ? "Invertir te dio más que dejar el dinero quieto."
            : "Esta vez el efectivo habría rendido más; pasa, el mercado sube y baja."
        return "\(resultado) \(diversif) Lo importante no es acertar siempre, sino entender por qué pasó cada cosa y pensar a largo plazo."
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private static func feedbackFinalConFM(rendimientoPct: Double,
                                           diferenciaVsCash: Double,
                                           numeroEmpresas: Int) async throws -> String {
        let instrucciones = """
        Eres un coach financiero educativo para jóvenes. Hablas español de México, \
        en tono motivador, y nunca regañas. Resumes el desempeño en un simulador \
        de bolsa destacando diversificación y pensamiento de largo plazo. Es \
        educación, no asesoría de inversión.
        """
        let session = LanguageModelSession(instructions: instrucciones)
        let vsCash = diferenciaVsCash >= 0 ? "mejor que dejar todo en efectivo" : "peor que dejar todo en efectivo"
        let prompt = """
        El usuario terminó la simulación con un rendimiento total de \
        \(rendimientoPct.comoPorcentajeConSigno), \(vsCash), con \(numeroEmpresas) \
        empresas en cartera. Dale una retroalimentación final educativa y motivadora.
        """
        let respuesta = try await session.respond(to: prompt, generating: FeedbackFinalFM.self)
        return respuesta.content.resumen
    }
    #endif
}
