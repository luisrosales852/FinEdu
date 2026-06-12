//
//  MercadoBolsa.swift
//  FinEdu
//
//  Modelo de dominio del Simulador de Bolsa. A diferencia de los escenarios de
//  crisis (que son structs Swift), aquí los datos del mercado viven en un JSON
//  estático embebido en el bundle (Data/Market/market_data.json) — así el
//  equipo puede actualizar los precios a mano sin tocar código. La app no hace
//  NINGUNA llamada de red: todo el dataset viaja dentro de la app (offline 100%).
//
//  IMPORTANTE (educativo): los precios hasta `realDataCutoff` se basan en
//  cierres históricos reales aproximados; los meses posteriores son valores
//  plausibles proyectados. No es asesoría de inversión.
//

import Foundation

/// Precio de cierre de un mes concreto. `month` usa el formato "YYYY-MM".
struct MonthlyPrice: Codable, Hashable {
    let month: String
    let close: Double
}

/// Una de las 10 empresas del simulador, con su serie de precios mensuales.
struct Company: Codable, Identifiable, Hashable {
    let ticker: String
    let name: String
    let sector: String
    let description: String
    let prices: [MonthlyPrice]

    var id: String { ticker }

    /// Precio de cierre para un mes dado ("YYYY-MM"), o nil si no existe.
    func close(en month: String) -> Double? {
        prices.first { $0.month == month }?.close
    }

    /// Precio de cierre en el índice de mes (0 = primer mes del dataset).
    func close(enIndice indice: Int) -> Double? {
        guard prices.indices.contains(indice) else { return nil }
        return prices[indice].close
    }
}

/// Evento educativo de mercado asociado a un mes ("YYYY-MM").
struct MarketEvent: Codable, Hashable, Identifiable {
    let month: String
    let title: String
    let detail: String

    var id: String { month }
}

/// Raíz del JSON del mercado.
struct MarketData: Codable {
    let schemaVersion: Int
    let currency: String
    /// Último mes ("YYYY-MM") cuyos precios provienen de datos históricos reales.
    let realDataCutoff: String
    let note: String
    /// Lista ordenada de meses del dataset ("YYYY-MM"), del más antiguo al más reciente.
    let months: [String]
    let companies: [Company]
    let events: [MarketEvent]
}

/// Errores de carga/validación del dataset del mercado.
enum MarketDataError: LocalizedError {
    case archivoNoEncontrado
    case jsonInvalido(String)
    case validacion(String)

    var errorDescription: String? {
        switch self {
        case .archivoNoEncontrado:
            return "No se encontró market_data.json en el bundle de la app."
        case .jsonInvalido(let detalle):
            return "El JSON del mercado no se pudo decodificar: \(detalle)"
        case .validacion(let detalle):
            return "El dataset del mercado no pasó la validación: \(detalle)"
        }
    }
}

/// Carga y valida el dataset del mercado desde el bundle al inicio.
/// Es un singleton porque el dataset es estático y se comparte en toda la app.
enum MarketDataLoader {

    /// Dataset cargado una sola vez (lazy). Si algo falla, la app no debería
    /// arrancar el módulo: preferimos un fallo temprano y explícito a datos
    /// silenciosamente corruptos.
    static let shared: MarketData = {
        do {
            return try cargar()
        } catch {
            // En un módulo educativo preferimos un crash claro durante el
            // desarrollo a un simulador con datos inconsistentes en demo.
            fatalError("FinEdu · Simulador de Bolsa: \(error.localizedDescription)")
        }
    }()

    /// Número de meses del dataset (puntos de tiempo de la simulación).
    static var totalMeses: Int { shared.months.count }

    /// Carga y valida el JSON. Expuesto para pruebas y para reutilizar la
    /// lógica de validación.
    static func cargar(bundle: Bundle = .main) throws -> MarketData {
        guard let url = bundle.url(forResource: "market_data", withExtension: "json") else {
            throw MarketDataError.archivoNoEncontrado
        }
        let datos = try Data(contentsOf: url)
        let market: MarketData
        do {
            market = try JSONDecoder().decode(MarketData.self, from: datos)
        } catch {
            throw MarketDataError.jsonInvalido(String(describing: error))
        }
        try validar(market)
        return market
    }

    /// Validaciones de integridad: 10 empresas, y cada empresa con un precio
    /// por cada mes declarado y en el mismo orden.
    private static func validar(_ market: MarketData) throws {
        guard !market.months.isEmpty else {
            throw MarketDataError.validacion("La lista de meses está vacía.")
        }
        guard market.companies.count == 10 else {
            throw MarketDataError.validacion(
                "Se esperaban 10 empresas, hay \(market.companies.count).")
        }
        for empresa in market.companies {
            guard empresa.prices.count == market.months.count else {
                throw MarketDataError.validacion(
                    "\(empresa.ticker) tiene \(empresa.prices.count) precios; se esperaban \(market.months.count).")
            }
            for (indice, precio) in empresa.prices.enumerated() where precio.month != market.months[indice] {
                throw MarketDataError.validacion(
                    "\(empresa.ticker): el mes en la posición \(indice) es \(precio.month), se esperaba \(market.months[indice]).")
            }
            guard empresa.prices.allSatisfy({ $0.close > 0 }) else {
                throw MarketDataError.validacion("\(empresa.ticker) tiene precios no positivos.")
            }
        }
    }

    /// Evento educativo para un mes dado, si existe.
    static func evento(mes: String) -> MarketEvent? {
        shared.events.first { $0.month == mes }
    }

    /// Nombre legible de un mes "YYYY-MM" → "jun 2023".
    static func nombreMes(_ mes: String) -> String {
        let partes = mes.split(separator: "-")
        guard partes.count == 2, let mm = Int(partes[1]) else { return mes }
        let nombres = ["", "ene", "feb", "mar", "abr", "may", "jun",
                       "jul", "ago", "sep", "oct", "nov", "dic"]
        let nombre = nombres.indices.contains(mm) ? nombres[mm] : "\(mm)"
        return "\(nombre) \(partes[0])"
    }
}
