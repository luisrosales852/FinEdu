//
//  ExtractorConceptos.swift
//  FinEdu
//
//  Extrae conceptos económicos de la decisión del usuario con el framework
//  NaturalLanguage: NLTokenizer separa palabras, se normalizan (sin acentos)
//  y se mapean a ConceptoEconomico mediante un diccionario de prefijos y
//  frases. Los prefijos cubren las conjugaciones del español sin necesidad
//  de un lematizador completo ("invert" → invertiré, inversión, invirtiendo).
//
//  Estos conceptos tienen doble uso:
//  1. El motor de reglas ajusta el resultado si el concepto era favorable o
//     desfavorable EN ese momento histórico (ej. "dólares" antes de la
//     devaluación de 1994 = favorable).
//  2. Desbloquean entradas del glosario educativo (SwiftData).
//

import Foundation
import NaturalLanguage

struct ExtractorConceptos {

    /// Frases completas (se buscan en el texto normalizado entero).
    private static let frases: [(frase: String, concepto: ConceptoEconomico)] = [
        ("fondo de emergencia", .fondoDeEmergencia),
        ("moneda extranjera", .dolarizacion),
        ("plazo fijo", .tasaDeInteres),
        ("bajo el colchon", .liquidez),
        ("vender todo", .panicoFinanciero),
        ("sacar todo", .panicoFinanciero),
        ("una parte", .diversificacion),
        ("la mitad", .diversificacion),
    ]

    /// Prefijos de palabra → concepto.
    private static let prefijos: [(prefijo: String, concepto: ConceptoEconomico)] = [
        ("dolar", .dolarizacion), ("divisa", .dolarizacion), ("usd", .dolarizacion),
        ("euro", .dolarizacion),
        ("invert", .inversion), ("inversion", .inversion), ("accion", .inversion),
        ("bolsa", .inversion), ("bono", .inversion), ("cetes", .inversion),
        ("negocio", .inversion), ("emprend", .inversion),
        ("mercancia", .activosReales), ("inventario", .activosReales),
        ("terreno", .activosReales), ("propiedad", .activosReales),
        ("casa", .activosReales), ("oro", .activosReales), ("herramient", .activosReales),
        ("ahorr", .ahorro), ("guardar", .ahorro), ("guardo", .ahorro), ("alcancia", .ahorro),
        ("efectivo", .liquidez), ("liquidez", .liquidez), ("liquido", .liquidez),
        ("colchon", .liquidez),
        ("deuda", .deuda), ("prestamo", .deuda), ("credito", .deuda),
        ("endeud", .deuda), ("tarjeta", .deuda), ("hipotec", .deuda),
        ("diversific", .diversificacion), ("repart", .diversificacion),
        ("balance", .diversificacion),
        ("tasa", .tasaDeInteres), ("interes", .tasaDeInteres), ("rendimiento", .tasaDeInteres),
        ("panico", .panicoFinanciero), ("miedo", .panicoFinanciero),
        ("rematar", .panicoFinanciero), ("huir", .panicoFinanciero),
        ("emergencia", .fondoDeEmergencia), ("reserva", .fondoDeEmergencia),
        ("imprevisto", .fondoDeEmergencia),
        ("inflacion", .inflacion), ("precios", .inflacion),
        ("devalu", .devaluacion),
    ]

    /// Devuelve los conceptos detectados, sin duplicados y en orden de aparición.
    func extraer(de texto: String) -> [ConceptoEconomico] {
        let normalizado = ClasificadorRiesgo.normalizar(texto)
        var encontrados: [ConceptoEconomico] = []

        func agregar(_ concepto: ConceptoEconomico) {
            if !encontrados.contains(concepto) { encontrados.append(concepto) }
        }

        // 1. Frases completas primero (más específicas).
        for (frase, concepto) in Self.frases where normalizado.contains(frase) {
            agregar(concepto)
        }

        // 2. Palabra por palabra con NLTokenizer (framework NaturalLanguage).
        let tokenizador = NLTokenizer(unit: .word)
        tokenizador.setLanguage(.spanish)
        tokenizador.string = normalizado
        tokenizador.enumerateTokens(in: normalizado.startIndex..<normalizado.endIndex) { rango, _ in
            let palabra = String(normalizado[rango])
            for (prefijo, concepto) in Self.prefijos where palabra.hasPrefix(prefijo) {
                agregar(concepto)
            }
            return true
        }
        return encontrados
    }
}
