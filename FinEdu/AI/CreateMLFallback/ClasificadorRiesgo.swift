//
//  ClasificadorRiesgo.swift
//  FinEdu
//
//  Clasificador de riesgo de la CAPA 2, con su propia degradación interna:
//
//  2a) Si el bundle contiene el modelo entrenado con Create ML
//      (ClasificadorRiesgo.mlmodel → compilado a .mlmodelc), se usa vía
//      NLModel. El dataset y el script de entrenamiento están en /Training.
//
//  2b) Si el modelo no está (p. ej. clonaste el repo y aún no lo entrenas),
//      se usa un clasificador léxico: diccionario ponderado de expresiones
//      financieras en español + NLEmbedding para palabras fuera del léxico.
//
//  Así la app SIEMPRE clasifica, y la UI reporta honestamente qué vía se usó.
//

import Foundation
import CoreML
import NaturalLanguage

struct ClasificadorRiesgo {

    enum Fuente {
        case coreML   // modelo entrenado con Create ML
        case lexico   // diccionario + NLEmbedding
    }

    /// Modelo de Create ML cargado desde el bundle (si existe).
    private let modeloNL: NLModel?

    /// Embedding de palabras en español del sistema (para texto fuera del
    /// léxico). Puede ser nil en dispositivos sin el recurso descargado.
    private let embedding: NLEmbedding?

    init() {
        // Xcode compila ModeloRiesgoFinanciero.mlmodel → .mlmodelc en el bundle.
        // (El modelo NO se llama "ClasificadorRiesgo" para que la clase que
        // genera Xcode no choque con este struct.)
        if let url = Bundle.main.url(forResource: "ModeloRiesgoFinanciero", withExtension: "mlmodelc"),
           let modelo = try? MLModel(contentsOf: url),
           let nl = try? NLModel(mlModel: modelo) {
            modeloNL = nl
        } else {
            modeloNL = nil
        }
        embedding = NLEmbedding.wordEmbedding(for: .spanish)
    }

    /// Clasifica una decisión financiera en texto libre.
    func clasificar(_ texto: String) -> (nivel: NivelRiesgo, fuente: Fuente) {
        // Vía 2a: modelo de Create ML.
        if let modeloNL,
           let etiqueta = modeloNL.predictedLabel(for: texto),
           let nivel = NivelRiesgo(rawValue: etiqueta) {
            return (nivel, .coreML)
        }
        // Vía 2b: léxico ponderado.
        return (clasificarPorLexico(texto), .lexico)
    }

    // MARK: - Clasificador léxico

    /// Expresiones (normalizadas, sin acentos) con su peso de riesgo 0–3.
    /// Los prefijos cubren conjugaciones: "invert" → invertir/invertiré/inversión.
    private static let lexico: [(prefijos: [String], peso: Double)] = [
        // 0 = conservadora
        (["guardar", "guardo", "guardare", "ahorr", "esperar", "espero", "mantener", "mantengo",
          "colchon", "conservar", "no hago nada", "no hacer nada", "alcancia", "recort",
          "pagar", "pagare", "pago", "liquidar", "liquido", "abonar", "abono"], 0),
        // 1 = moderada
        (["diversific", "repartir", "reparto", "balance", "una parte", "la mitad", "poco a poco",
          "mensualmente", "renegoci", "reestructur", "plazo fijo", "cetes", "udis", "gradual"], 1),
        // 2 = arriesgada
        (["invert", "inversion", "bolsa", "acciones", "negocio", "emprend", "comprar dolares",
          "compro dolares", "comprare dolares", "mercancia", "inventario", "especul", "arriesg",
          "criptomoneda", "bitcoin", "oro"], 2),
        // 3 = muy arriesgada
        (["todo mi dinero", "todos mis ahorros", "todo lo que tengo", "apostar", "apuesto",
          "apueste", "apalanc", "prestamo para invertir", "credito para invertir",
          "endeudarme para", "me endeudo para", "hipotecar", "casino", "loteria",
          "pedir prestado para", "doble o nada"], 3),
    ]

    /// Modificadores: palabras que intensifican o moderan el riesgo detectado.
    private static let intensificadores = ["todo", "toda", "todos", "todas", "completo", "integro"]
    private static let moderadores = ["parte", "mitad", "poco", "algo", "porcion", "porcentaje"]

    /// Palabras ancla por nivel para la vía de NLEmbedding (cuando ninguna
    /// expresión del léxico aparece en el texto).
    private static let anclas: [NivelRiesgo: [String]] = [
        .conservadora: ["guardar", "ahorrar", "esperar", "conservar"],
        .moderada: ["diversificar", "repartir", "equilibrar", "planear"],
        .arriesgada: ["invertir", "negociar", "comprar", "emprender"],
        .muyArriesgada: ["apostar", "arriesgar", "especular", "jugar"],
    ]

    private func clasificarPorLexico(_ texto: String) -> NivelRiesgo {
        let normalizado = Self.normalizar(texto)

        // 1. Suma ponderada de expresiones del léxico encontradas.
        var pesos: [Double] = []
        for grupo in Self.lexico {
            for prefijo in grupo.prefijos where normalizado.contains(prefijo) {
                pesos.append(grupo.peso)
            }
        }

        var puntaje: Double
        if !pesos.isEmpty {
            puntaje = pesos.reduce(0, +) / Double(pesos.count)
        } else if let estimado = puntajePorEmbedding(normalizado) {
            // 2. Sin coincidencias léxicas: similitud semántica con NLEmbedding.
            puntaje = estimado
        } else {
            // 3. Último recurso: asumir riesgo medio.
            puntaje = 1.5
        }

        // 4. Modificadores de magnitud ("todo" sube el riesgo, "una parte" lo baja).
        let palabras = Set(normalizado.split(separator: " ").map(String.init))
        if !palabras.isDisjoint(with: Self.intensificadores) { puntaje += 0.8 }
        if !palabras.isDisjoint(with: Self.moderadores) { puntaje -= 0.6 }

        switch puntaje {
        case ..<0.75: return .conservadora
        case ..<1.6: return .moderada
        case ..<2.5: return .arriesgada
        default: return .muyArriesgada
        }
    }

    /// Estima el riesgo comparando cada palabra del texto con las anclas de
    /// cada nivel usando distancia de NLEmbedding (menor distancia = más afín).
    private func puntajePorEmbedding(_ textoNormalizado: String) -> Double? {
        guard let embedding else { return nil }
        let tokenizador = NLTokenizer(unit: .word)
        tokenizador.string = textoNormalizado
        var palabras: [String] = []
        tokenizador.enumerateTokens(in: textoNormalizado.startIndex..<textoNormalizado.endIndex) { rango, _ in
            let palabra = String(textoNormalizado[rango])
            if palabra.count > 3 { palabras.append(palabra) }
            return true
        }
        guard !palabras.isEmpty else { return nil }

        var mejorNivel: NivelRiesgo?
        var mejorDistancia = Double.greatestFiniteMagnitude
        for (nivel, anclasNivel) in Self.anclas {
            for ancla in anclasNivel {
                for palabra in palabras {
                    let distancia = embedding.distance(between: palabra, and: ancla)
                    // distance devuelve 2.0 si alguna palabra no está en el vocabulario
                    if distancia < mejorDistancia, distancia < 1.2 {
                        mejorDistancia = distancia
                        mejorNivel = nivel
                    }
                }
            }
        }
        guard let mejorNivel else { return nil }
        return Double(mejorNivel.indice)
    }

    /// Minúsculas y sin acentos, para comparar contra el léxico.
    static func normalizar(_ texto: String) -> String {
        texto.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "es_MX"))
            .lowercased()
    }
}
