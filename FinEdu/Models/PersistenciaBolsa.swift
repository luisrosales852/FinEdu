//
//  PersistenciaBolsa.swift
//  FinEdu
//
//  Modelos de SwiftData (@Model) del Simulador de Bolsa. Viven SEPARADOS de
//  Persistencia.swift (el modo de crisis) para que reiniciar el simulador
//  borre SOLO estos datos sin tocar las partidas del otro modo.
//
//  Toda la moneda es USD (se simplifica contra los precios reales de las
//  acciones). Todo se guarda en el dispositivo; la app no tiene red.
//

import Foundation
import SwiftData

/// Estado raíz del simulador. Hay una sola cartera activa (la simulación en
/// curso). `mesActual` es el índice 0-based dentro de `MarketData.months`.
@Model
final class CarteraBolsa {
    /// Capital/ahorros totales que el usuario declaró en el onboarding (USD).
    var presupuestoTotal: Double
    /// Monto que decidió asignar a la bolsa (cash inicial 100% líquido, USD).
    var montoAsignado: Double
    /// Cash disponible actual (USD), tras compras y ventas.
    var cashActual: Double
    /// Índice del mes actual de la simulación (0 = primer mes del dataset).
    var mesActual: Int
    /// Marca que el onboarding del simulador ya se completó.
    var onboardingCompletado: Bool
    /// Fecha real de creación (para ordenar / depurar; no es el tiempo simulado).
    var fechaCreacion: Date

    @Relationship(deleteRule: .cascade, inverse: \Holding.cartera)
    var holdings: [Holding] = []

    @Relationship(deleteRule: .cascade, inverse: \Transaccion.cartera)
    var transacciones: [Transaccion] = []

    @Relationship(deleteRule: .cascade, inverse: \SnapshotMensual.cartera)
    var snapshots: [SnapshotMensual] = []

    init(presupuestoTotal: Double = 0,
         montoAsignado: Double = 0,
         cashActual: Double = 0,
         mesActual: Int = 0,
         onboardingCompletado: Bool = false,
         fechaCreacion: Date = .now) {
        self.presupuestoTotal = presupuestoTotal
        self.montoAsignado = montoAsignado
        self.cashActual = cashActual
        self.mesActual = mesActual
        self.onboardingCompletado = onboardingCompletado
        self.fechaCreacion = fechaCreacion
    }
}

/// Posición del usuario en una empresa: acciones (fraccionarias) y su costo
/// promedio de compra (para calcular ganancia/pérdida y métricas).
@Model
final class Holding {
    var ticker: String
    /// Cantidad de acciones; admite fracciones (ej. 0.5).
    var cantidad: Double
    /// Precio promedio ponderado de compra (USD por acción).
    var precioPromedioCompra: Double
    var cartera: CarteraBolsa?

    init(ticker: String, cantidad: Double, precioPromedioCompra: Double) {
        self.ticker = ticker
        self.cantidad = cantidad
        self.precioPromedioCompra = precioPromedioCompra
    }
}

/// Una operación de compra o venta, persistida para el historial.
@Model
final class Transaccion {
    /// rawValue de TipoTransaccion.
    var tipo: String
    var ticker: String
    var cantidad: Double
    /// Precio por acción al que se ejecutó (USD).
    var precio: Double
    /// Mes simulado en que ocurrió, formato "YYYY-MM".
    var mesSimulado: String
    /// Orden cronológico dentro de la simulación (para ordenar de forma estable).
    var indiceMes: Int
    var cartera: CarteraBolsa?

    init(tipo: TipoTransaccion,
         ticker: String,
         cantidad: Double,
         precio: Double,
         mesSimulado: String,
         indiceMes: Int) {
        self.tipo = tipo.rawValue
        self.ticker = ticker
        self.cantidad = cantidad
        self.precio = precio
        self.mesSimulado = mesSimulado
        self.indiceMes = indiceMes
    }

    var tipoTransaccion: TipoTransaccion { TipoTransaccion(rawValue: tipo) ?? .compra }
    /// Monto total de la operación (USD).
    var monto: Double { cantidad * precio }
}

/// Tipo de operación. String para mapear directo desde SwiftData.
enum TipoTransaccion: String, Codable {
    case compra
    case venta

    var titulo: String { self == .compra ? "Compra" : "Venta" }
    var icono: String { self == .compra ? "arrow.down.circle.fill" : "arrow.up.circle.fill" }
}

/// Snapshot del valor del portafolio al cierre de un mes simulado. Permite
/// reconstruir la gráfica al reabrir la app sin recalcular toda la historia.
@Model
final class SnapshotMensual {
    var indiceMes: Int
    var mesSimulado: String
    /// Valor total = cash + valor de mercado de las posiciones (USD).
    var valorPortafolio: Double
    /// Valor que tendría el usuario si hubiera dejado TODO en cash (USD).
    var valorSiCash: Double
    var cartera: CarteraBolsa?

    init(indiceMes: Int,
         mesSimulado: String,
         valorPortafolio: Double,
         valorSiCash: Double) {
        self.indiceMes = indiceMes
        self.mesSimulado = mesSimulado
        self.valorPortafolio = valorPortafolio
        self.valorSiCash = valorSiCash
    }
}
