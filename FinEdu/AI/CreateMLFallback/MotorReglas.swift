//
//  MotorReglas.swift
//  FinEdu
//
//  CAPA 2 de la arquitectura de IA: motor determinista de consecuencias.
//  Pipeline: clasificar riesgo (Create ML o léxico) → extraer conceptos
//  (NaturalLanguage) → calcular impacto con las reglas del escenario →
//  componer narrativa y lección con plantillas.
//
//  Ventaja pedagógica de esta capa: es 100% explicable. Podemos mostrar a
//  los jueces exactamente POR QUÉ la app respondió lo que respondió.
//

import Foundation
import NaturalLanguage

struct MotorReglas: MotorDeDecision {

    private let clasificador = ClasificadorRiesgo()
    private let extractor = ExtractorConceptos()

    /// El tipo exacto (.reglasConCoreML / .reglasConLexico) se conoce hasta
    /// clasificar; aquí reportamos el mejor caso según el bundle.
    var tipo: MotorIA {
        clasificador.clasificar("invertir").fuente == .coreML ? .reglasConCoreML : .reglasConLexico
    }

    func evaluarDecision(texto: String,
                         turno: Turno,
                         escenario: Escenario,
                         estado: EstadoJuego) async throws -> ResultadoTurno {

        // 1. Clasificación de riesgo (Create ML si hay modelo; léxico si no).
        let (nivel, fuente) = clasificador.clasificar(texto)

        // 2. Conceptos económicos mencionados por el usuario.
        let conceptos = extractor.extraer(de: texto)

        // 3. Impacto determinista a partir de los datos del escenario.
        guard let efecto = turno.efectos[nivel] else {
            // Por construcción los 4 niveles existen; esto es solo defensa.
            throw NSError(domain: "FinEdu.MotorReglas", code: 1)
        }
        let rango = efecto.rangoCambioPatrimonio

        // Punto de partida dentro del rango: variación pseudoaleatoria ESTABLE
        // derivada del texto (misma decisión → mismo resultado, demostrable).
        let semilla = Self.semillaEstable(de: texto)
        var cambio = rango.lowerBound + (rango.upperBound - rango.lowerBound) * (0.35 + 0.3 * semilla)

        // Ajuste por conceptos correctos/incorrectos PARA ESTE momento histórico.
        for concepto in conceptos where turno.conceptosFavorables.contains(concepto) {
            cambio += turno.ajustePorConcepto
        }
        for concepto in conceptos where turno.conceptosDesfavorables.contains(concepto) {
            cambio -= turno.ajustePorConcepto
        }

        // El impacto NUNCA sale del rango histórico plausible del turno.
        cambio = min(max(cambio, rango.lowerBound), rango.upperBound)

        // 4. Concepto central de la lección: el primero que el usuario mencionó
        //    y que era relevante este turno; si no, el concepto del turno.
        let conceptoCentral = conceptos.first {
            turno.conceptosFavorables.contains($0) || turno.conceptosDesfavorables.contains($0)
        } ?? turno.conceptoPrincipal

        // 5. Narrativa y lección con plantillas.
        let narrativa = PlantillasNarrativa.narrativa(efecto: efecto,
                                                      cambio: cambio,
                                                      conceptosDetectados: conceptos,
                                                      turno: turno)
        let leccion = PlantillasNarrativa.leccion(nivel: nivel,
                                                  concepto: conceptoCentral,
                                                  turno: turno)

        return ResultadoTurno(nivelRiesgo: nivel,
                              cambioPatrimonioPorcentaje: cambio,
                              narrativa: narrativa,
                              concepto: conceptoCentral,
                              leccion: leccion,
                              conceptosDetectados: conceptos,
                              motor: fuente == .coreML ? .reglasConCoreML : .reglasConLexico)
    }

    func validarInput(texto: String,
                      turno: Turno,
                      escenario: Escenario) async throws -> ValidacionInput {
        // Railguard de escenario: si el jugador menciona un instrumento que esta
        // crisis no simula (acciones de una empresa, cripto…), lo desviamos a las
        // opciones válidas con una explicación, en vez de evaluarlo a ciegas.
        if let termino = GuardiaEscenario.instrumentoFueraDeContexto(en: texto) {
            return GuardiaEscenario.validacion(termino: termino, escenario: escenario)
        }

        let trimmed = texto.trimmingCharacters(in: .whitespacesAndNewlines)
        // Normalización: sin acentos, minúsculas — igual que ExtractorConceptos.
        let normalizado = trimmed.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let palabras = normalizado.components(separatedBy: .whitespaces)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty }

        guard trimmed.count >= 2, !palabras.isEmpty else {
            return ValidacionInput(esSensato: false, mensajeReformulacion: Self.mensajeReintento)
        }

        // ── 1. Anti-gibberish: 3+ caracteres idénticos consecutivos ──────────
        for palabra in palabras {
            var prev: Character? = nil; var racha = 0
            for c in palabra {
                if c == prev { racha += 1 } else { prev = c; racha = 1 }
                if racha >= 3 { return ValidacionInput(esSensato: false, mensajeReformulacion: Self.mensajeReintento) }
            }
        }

        // ── 2. Debe tener vocales ─────────────────────────────────────────────
        let vocales = CharacterSet(charactersIn: "aeiouAEIOU")
        guard normalizado.unicodeScalars.contains(where: { vocales.contains($0) }) else {
            return ValidacionInput(esSensato: false, mensajeReformulacion: Self.mensajeReintento)
        }

        // ── 3. ExtractorConceptos: si detecta algún concepto económico → válido
        // Es la validación semántica más fiable: ya sabe de "dolar", "ahorr",
        // "invert", "deuda", etc. gracias a sus prefijos y frases.
        if !extractor.extraer(de: trimmed).isEmpty {
            return ValidacionInput(esSensato: true, mensajeReformulacion: "")
        }

        // ── 4. Keywords financieras adicionales (prefijos normalizados) ────────
        if palabras.contains(where: { p in Self.prefijosFinancieros.contains(where: { p.hasPrefix($0) }) }) {
            return ValidacionInput(esSensato: true, mensajeReformulacion: "")
        }

        // ── 5. Oración larga: 4+ palabras con vocales → el usuario intenta algo
        let palabrasConVocal = palabras.filter { p in p.unicodeScalars.contains(where: { vocales.contains($0) }) }
        if palabrasConVocal.count >= 4 {
            return ValidacionInput(esSensato: true, mensajeReformulacion: "")
        }

        // ── 6. Cosine similarity con NLEmbedding como último recurso ──────────
        if similitudFinanciera(palabras: palabras) {
            return ValidacionInput(esSensato: true, mensajeReformulacion: "")
        }

        return ValidacionInput(esSensato: false, mensajeReformulacion: Self.mensajeReintento)
    }

    /// Compara cada palabra del input contra referencias financieras usando
    /// embeddings de palabras del framework NaturalLanguage (cosine distance).
    /// Retorna true si al menos una palabra está semánticamente cerca.
    private func similitudFinanciera(palabras: [String]) -> Bool {
        guard let embedding = NLEmbedding.wordEmbedding(for: .spanish) else { return false }
        let referencias = ["dinero", "ahorro", "invertir", "banco", "deuda",
                           "gastar", "guardar", "economia", "comprar", "vender"]
        for palabra in palabras {
            for ref in referencias where embedding.distance(between: palabra, and: ref, distanceType: .cosine) < 0.5 {
                return true
            }
        }
        return false
    }

    // Prefijos financieros que ExtractorConceptos no cubre (verbos de decisión
    // genéricos que igual expresan una intención económica válida).
    private static let prefijosFinancieros = [
        "dinero", "banco", "comprar", "compro", "vender", "vendo",
        "pagar", "pago", "cambiar", "cambio", "esperar", "espero",
        "retir", "deposit", "proteg", "mover", "muevo", "sacar", "saco",
        "capital", "fondo", "cuenta", "tarjet", "interés", "interes",
        "financ", "economic", "patrimoni", "plata", "lana",
    ]

    private static let mensajeReintento = "No entendí bien tu respuesta. ¿Qué harías con tu dinero en este momento? Cuéntame si lo guardarías, lo cambiarías de moneda, invertirías en algo o pagarías deudas."

    func generarOpciones(turno: Turno,
                         escenario: Escenario,
                         estado: EstadoJuego) async throws -> [String] {
        [
            "Guardo todo en efectivo y espero a que la situación se calme.",
            "Divido mis ahorros: una parte en dólares y el resto en el banco.",
            "Invierto en activos reales que puedan protegerme de la inflación."
        ]
    }

    /// Hash estable 0...1 (no usamos `hashValue` porque cambia entre
    /// ejecuciones; aquí queremos reproducibilidad para la demo).
    private static func semillaEstable(de texto: String) -> Double {
        var acumulador: UInt64 = 5381
        for escalar in texto.unicodeScalars {
            acumulador = (acumulador &* 33) &+ UInt64(escalar.value)
        }
        return Double(acumulador % 1000) / 1000
    }
}
