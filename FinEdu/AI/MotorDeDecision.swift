//
//  MotorDeDecision.swift
//  FinEdu
//
//  ═══════════════════════════════════════════════════════════════════════
//  ARQUITECTURA DE IA EN DOS CAPAS CON FALLBACK AUTOMÁTICO (100% on-device)
//  ═══════════════════════════════════════════════════════════════════════
//
//  Capa 1 — Foundation Models (Apple Intelligence, iOS 26+):
//      LLM on-device de ~3B parámetros. Interpreta la decisión en texto
//      libre, genera la narrativa de consecuencias y la lección educativa
//      con salida estructurada (@Generable). Cero red, cero nube.
//
//  Capa 2 — NaturalLanguage + Create ML (siempre disponible, iOS 17+):
//      Clasificador de riesgo entrenado con MLTextClassifier (y léxico de
//      respaldo), extracción de conceptos con NLTagger/NLEmbedding y un
//      motor determinista de consecuencias con plantillas por escenario.
//
//  Ambas capas producen el MISMO struct (ResultadoTurno): el resto de la
//  app es agnóstico al motor. La elección ocurre AQUÍ, una sola vez por
//  partida, según SystemLanguageModel.default.availability.
//

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Resultado de validar el input del usuario ANTES de evaluarlo.
/// Ambos motores producen este mismo struct para que el ViewModel sea agnóstico.
struct ValidacionInput {
    let esSensato: Bool
    /// Mensaje que se muestra al usuario cuando su input no tiene sentido.
    let mensajeReformulacion: String
    /// true cuando el input SÍ es una intención financiera reconocible pero
    /// menciona un instrumento/activo que ESTE escenario no simula (p. ej.
    /// acciones de una empresa concreta o criptomonedas). En ese caso el juego
    /// ofrece directamente las opciones válidas en vez de pedir reformular.
    var fueraDeContexto: Bool = false
}

/// Guardia determinista que rechaza instrumentos financieros que las crisis
/// macroeconómicas de FinEdu NO simulan (acciones de una empresa concreta,
/// criptomonedas, índices…). Esas decisiones pertenecen al Simulador de Bolsa,
/// no a estos escenarios. Se aplica ANTES de cualquier motor de IA para que el
/// comportamiento sea idéntico con o sin Apple Intelligence.
enum GuardiaEscenario {

    /// Frases de varias palabras (normalizadas, sin acentos) fuera de alcance.
    private static let frasesFueraDeContexto: [String] = [
        "acciones de", "s&p 500", "s&p500", "wall street",
    ]

    /// Instrumentos/activos concretos (palabras sueltas) fuera de alcance.
    /// Se buscan como token completo para evitar falsos positivos (p. ej.
    /// "meta" dentro de "metas").
    private static let palabrasFueraDeContexto: Set<String> = [
        "pemex", "cemex", "bimbo", "televisa", "naftrac", "bitcoin", "btc",
        "ethereum", "cripto", "crypto", "criptomoneda", "criptomonedas",
        "dogecoin", "nft", "nfts", "tesla", "nvidia", "netflix", "robinhood",
        "memecoin", "memecoins", "forex", "nasdaq", "ipo",
    ]

    /// Si el texto menciona un instrumento fuera de contexto, devuelve ese
    /// término (legible) para explicárselo al jugador; si no, nil.
    static func instrumentoFueraDeContexto(en texto: String) -> String? {
        let normalizado = texto
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        for frase in frasesFueraDeContexto where normalizado.contains(frase) {
            return frase
        }
        let palabras = Set(normalizado
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty })
        return palabras.first { palabrasFueraDeContexto.contains($0) }
    }

    /// Mensaje que se muestra cuando el jugador propone un instrumento que el
    /// escenario no simula, antes de ofrecerle las opciones válidas.
    static func mensaje(termino: String, escenario: Escenario) -> String {
        """
        En “\(escenario.titulo)” no puedes apostar por “\(termino)”: esa opción no \
        está disponible en esta simulación, que cubre decisiones macroeconómicas \
        como guardar efectivo, cambiar de moneda, comprar activos que protejan de \
        la inflación o pagar deudas. Para invertir en empresas concretas usa el \
        Simulador de Bolsa. Por ahora, elige una de estas opciones:
        """
    }

    /// Construye la validación "fuera de contexto" lista para el ViewModel.
    static func validacion(termino: String, escenario: Escenario) -> ValidacionInput {
        ValidacionInput(esSensato: false,
                        mensajeReformulacion: mensaje(termino: termino, escenario: escenario),
                        fueraDeContexto: true)
    }
}

/// Contrato común de los dos motores de IA.
protocol MotorDeDecision {
    var tipo: MotorIA { get }

    /// Evalúa la decisión en texto libre del usuario para el turno actual.
    /// Recibe el estado como COPIA inmutable: el motor propone, la app dispone.
    func evaluarDecision(texto: String,
                         turno: Turno,
                         escenario: Escenario,
                         estado: EstadoJuego) async throws -> ResultadoTurno

    /// Valida si el texto del usuario tiene sentido como decisión financiera
    /// en el contexto del turno. Se llama ANTES de evaluarDecision.
    func validarInput(texto: String,
                      turno: Turno,
                      escenario: Escenario) async throws -> ValidacionInput

    /// Genera 3 opciones de decisión financiera para el turno actual.
    /// Se usa cuando el jugador no supo responder tras dos intentos.
    func generarOpciones(turno: Turno,
                         escenario: Escenario,
                         estado: EstadoJuego) async throws -> [String]
}

/// Fábrica que decide en runtime qué motor usar (patrón Strategy + Factory).
enum FabricaMotorIA {

    /// Crea el mejor motor disponible para una partida.
    /// Se crea UNO por partida porque el motor de Foundation Models mantiene
    /// una sesión con el contexto narrativo de los turnos anteriores.
    static func crearMotor(escenario: Escenario) -> MotorDeDecision {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            // Manejo explícito de TODOS los casos de disponibilidad:
            switch SystemLanguageModel.default.availability {
            case .available:
                return MotorFoundationModels(escenario: escenario)
            case .unavailable(let razon):
                // No interrumpimos al usuario: el fallback es transparente.
                print("ℹ️ FinEdu: Foundation Models no disponible (\(razon)). Usando capa 2.")
            @unknown default:
                break
            }
        }
        #endif
        // Capa 2: funciona en cualquier dispositivo iOS 17+, incluso sin
        // Apple Intelligence y sin el modelo de Create ML en el bundle.
        return MotorReglas()
    }

    /// Diagnóstico legible de la disponibilidad de Apple Intelligence.
    /// Se muestra en la UI (indicador de motor) para explicar la
    /// arquitectura a los jueces sin abrir el código.
    static var diagnostico: String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return "Apple Intelligence está disponible: la narrativa y las lecciones las genera el modelo de lenguaje on-device (Foundation Models)."
            case .unavailable(.deviceNotEligible):
                return "Este dispositivo no es elegible para Apple Intelligence. FinEdu usa su capa 2: clasificador de Create ML + NaturalLanguage, también 100% on-device."
            case .unavailable(.appleIntelligenceNotEnabled):
                return "Apple Intelligence está desactivado en Ajustes. Actívalo para usar el modelo generativo; mientras tanto, FinEdu funciona con su capa 2 (Create ML + NaturalLanguage)."
            case .unavailable(.modelNotReady):
                return "El modelo de Apple Intelligence aún se está descargando o preparando. FinEdu usa su capa 2 mientras tanto."
            case .unavailable(let otra):
                return "Apple Intelligence no disponible (\(otra)). FinEdu funciona con su capa 2 on-device."
            @unknown default:
                return "Estado de Apple Intelligence desconocido. FinEdu usa su capa 2 on-device."
            }
        } else {
            return "Este sistema es anterior a iOS 26, sin framework Foundation Models. FinEdu usa su capa 2: Create ML + NaturalLanguage, 100% on-device."
        }
        #else
        return "Compilado sin el SDK de Foundation Models. FinEdu usa su capa 2: Create ML + NaturalLanguage, 100% on-device."
        #endif
    }
}
