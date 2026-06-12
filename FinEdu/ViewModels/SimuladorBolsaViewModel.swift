//
//  SimuladorBolsaViewModel.swift
//  FinEdu
//
//  ViewModel del Simulador de Bolsa (MVVM con Observation). Mismo patrón que
//  JuegoViewModel: @Observable @MainActor y los métodos que mutan SwiftData
//  reciben el ModelContext como parámetro (la vista lo inyecta desde el
//  entorno). Toda la aritmética del portafolio vive aquí, es determinista y
//  auditable. Moneda: USD.
//
//  El tiempo avanza mes a mes sobre MarketData.months; el usuario solo ve
//  precios HASTA el mes actual de la simulación, nunca el futuro.
//

import Foundation
import SwiftData
import Observation

/// Vista de la gráfica central seleccionable por el usuario.
enum VistaGrafica: String, CaseIterable, Identifiable {
    case portafolio = "Portafolio"
    case vsCash = "vs. efectivo"
    case porEmpresa = "Por empresa"

    var id: String { rawValue }
}

@Observable
@MainActor
final class SimuladorBolsaViewModel {

    /// Cartera persistida (SwiftData @Model, ya es Observable: la vista se
    /// redibuja cuando cambian sus propiedades o relaciones).
    let cartera: CarteraBolsa

    /// Dataset estático del mercado, validado al cargar.
    let market: MarketData = MarketDataLoader.shared

    /// Evento educativo del mes recién alcanzado, para mostrar una tarjeta.
    /// Se consume (pone en nil) cuando la vista lo descarta.
    var eventoPendiente: MarketEvent?

    init(cartera: CarteraBolsa) {
        self.cartera = cartera
    }

    // MARK: - Tiempo

    /// Índice del mes actual, acotado al rango válido del dataset.
    var indiceMes: Int { min(max(cartera.mesActual, 0), market.months.count - 1) }

    /// Mes actual en formato "YYYY-MM".
    var mesActualID: String { market.months[indiceMes] }

    /// Mes actual legible ("jun 2023").
    var mesActualLegible: String { MarketDataLoader.nombreMes(mesActualID) }

    var esUltimoMes: Bool { indiceMes >= market.months.count - 1 }

    /// Meses transcurridos desde el inicio (para mostrar progreso).
    var mesesTranscurridos: Int { indiceMes + 1 }
    var totalMeses: Int { market.months.count }

    // MARK: - Precios

    func empresa(_ ticker: String) -> Company? {
        market.companies.first { $0.ticker == ticker }
    }

    /// Precio de una empresa en el mes actual.
    func precioActual(_ ticker: String) -> Double {
        empresa(ticker)?.close(enIndice: indiceMes) ?? 0
    }

    /// Cambio porcentual del precio respecto al mes anterior (0 en el primer mes).
    func cambioMensual(_ ticker: String) -> Double {
        guard indiceMes > 0,
              let empresa = empresa(ticker),
              let actual = empresa.close(enIndice: indiceMes),
              let previo = empresa.close(enIndice: indiceMes - 1),
              previo > 0 else { return 0 }
        return (actual / previo - 1) * 100
    }

    /// Serie de precios visible (solo hasta el mes actual; nunca el futuro).
    func serieVisible(_ ticker: String) -> [Double] {
        guard let empresa = empresa(ticker) else { return [] }
        return (0...indiceMes).compactMap { empresa.close(enIndice: $0) }
    }

    // MARK: - Posiciones

    func holding(_ ticker: String) -> Holding? {
        cartera.holdings.first { $0.ticker == ticker }
    }

    /// Holdings con cantidad significativa, ordenadas por valor de mercado.
    var posiciones: [Holding] {
        cartera.holdings
            .filter { $0.cantidad > 0.0000001 }
            .sorted { valorPosicion($0) > valorPosicion($1) }
    }

    /// Valor de mercado actual de una posición.
    func valorPosicion(_ holding: Holding) -> Double {
        holding.cantidad * precioActual(holding.ticker)
    }

    /// Valor de mercado de TODAS las posiciones en el mes actual.
    var valorMercadoActual: Double {
        cartera.holdings.reduce(0) { $0 + valorPosicion($1) }
    }

    /// Valor total del portafolio = efectivo + valor de mercado.
    var valorTotal: Double { cartera.cashActual + valorMercadoActual }

    /// Valor si se hubiera dejado TODO en efectivo (no crece): el monto asignado.
    var valorSiCash: Double { cartera.montoAsignado }

    // MARK: - Métricas

    /// Rendimiento total % respecto al capital asignado.
    var rendimientoTotalPct: Double {
        guard cartera.montoAsignado > 0 else { return 0 }
        return (valorTotal / cartera.montoAsignado - 1) * 100
    }

    /// Dinero ganado o perdido en USD respecto al capital asignado inicial.
    var gananciaTotal: Double { valorTotal - cartera.montoAsignado }

    /// Diferencia frente a haber dejado todo en efectivo (USD).
    var diferenciaVsCash: Double { valorTotal - valorSiCash }

    /// Número de empresas distintas en cartera.
    var numeroEmpresas: Int { posiciones.count }

    /// Fracción (0...1) del portafolio concentrada en la mayor posición.
    var concentracionMayorPosicion: Double {
        guard valorTotal > 0, let mayor = posiciones.first else { return 0 }
        return valorPosicion(mayor) / valorTotal
    }

    var tickerMayorPosicion: String? { posiciones.first?.ticker }

    // MARK: - Gráfica (snapshots)

    /// Snapshots ordenados cronológicamente (para reconstruir la gráfica).
    var snapshotsOrdenados: [SnapshotMensual] {
        cartera.snapshots.sorted { $0.indiceMes < $1.indiceMes }
    }

    // MARK: - Operaciones

    /// Cantidad máxima de acciones comprables de un ticker con el cash actual.
    func maximoComprable(_ ticker: String) -> Double {
        let precio = precioActual(ticker)
        guard precio > 0 else { return 0 }
        return cartera.cashActual / precio
    }

    func puedeComprar(_ ticker: String, cantidad: Double) -> Bool {
        cantidad > 0 && cantidad * precioActual(ticker) <= cartera.cashActual + 0.001
    }

    /// Compra `cantidad` (fraccionaria) acciones de `ticker` al precio del mes.
    @discardableResult
    func comprar(_ ticker: String, cantidad: Double, contexto: ModelContext) -> Bool {
        let precio = precioActual(ticker)
        let costo = cantidad * precio
        guard cantidad > 0, precio > 0, costo <= cartera.cashActual + 0.001 else { return false }

        cartera.cashActual -= costo

        if let holding = holding(ticker) {
            // Precio promedio ponderado de compra.
            let cantidadTotal = holding.cantidad + cantidad
            let costoTotal = holding.cantidad * holding.precioPromedioCompra + costo
            holding.precioPromedioCompra = costoTotal / cantidadTotal
            holding.cantidad = cantidadTotal
        } else {
            let holding = Holding(ticker: ticker, cantidad: cantidad, precioPromedioCompra: precio)
            holding.cartera = cartera
            cartera.holdings.append(holding)
        }

        registrarTransaccion(.compra, ticker: ticker, cantidad: cantidad, precio: precio, contexto: contexto)
        actualizarSnapshotActual(contexto: contexto)
        try? contexto.save()
        return true
    }

    /// Vende `cantidad` (fraccionaria) acciones de `ticker` al precio del mes.
    @discardableResult
    func vender(_ ticker: String, cantidad: Double, contexto: ModelContext) -> Bool {
        guard let holding = holding(ticker),
              cantidad > 0,
              cantidad <= holding.cantidad + 0.0000001 else { return false }

        let precio = precioActual(ticker)
        let ingreso = cantidad * precio
        cartera.cashActual += ingreso
        holding.cantidad -= cantidad

        // Si la posición queda en cero (con tolerancia de redondeo), se elimina.
        if holding.cantidad <= 0.0000001 {
            cartera.holdings.removeAll { $0 === holding }
            contexto.delete(holding)
        }

        registrarTransaccion(.venta, ticker: ticker, cantidad: cantidad, precio: precio, contexto: contexto)
        actualizarSnapshotActual(contexto: contexto)
        try? contexto.save()
        return true
    }

    private func registrarTransaccion(_ tipo: TipoTransaccion,
                                      ticker: String,
                                      cantidad: Double,
                                      precio: Double,
                                      contexto: ModelContext) {
        let tx = Transaccion(tipo: tipo,
                             ticker: ticker,
                             cantidad: cantidad,
                             precio: precio,
                             mesSimulado: mesActualID,
                             indiceMes: indiceMes)
        tx.cartera = cartera
        cartera.transacciones.append(tx)
    }

    // MARK: - Avance del tiempo

    /// Avanza un mes: registra el snapshot del nuevo mes y, si hay evento
    /// educativo, lo deja pendiente para que la vista lo muestre.
    func avanzarMes(contexto: ModelContext) {
        guard !esUltimoMes else { return }
        cartera.mesActual = indiceMes + 1
        actualizarSnapshotActual(contexto: contexto)
        eventoPendiente = MarketDataLoader.evento(mes: mesActualID)
        try? contexto.save()
    }

    /// Garantiza que exista un snapshot del mes actual y lo deja con el valor
    /// vigente (upsert). Se llama al iniciar y tras cada operación o avance.
    func actualizarSnapshotActual(contexto: ModelContext) {
        let valor = valorTotal
        if let existente = cartera.snapshots.first(where: { $0.indiceMes == indiceMes }) {
            existente.valorPortafolio = valor
            existente.valorSiCash = valorSiCash
        } else {
            let snap = SnapshotMensual(indiceMes: indiceMes,
                                       mesSimulado: mesActualID,
                                       valorPortafolio: valor,
                                       valorSiCash: valorSiCash)
            snap.cartera = cartera
            cartera.snapshots.append(snap)
        }
    }

    // MARK: - Reinicio

    /// Borra SOLO los datos del simulador (la cartera y, en cascada, holdings,
    /// transacciones y snapshots). No toca las partidas del modo de crisis.
    func reiniciar(contexto: ModelContext) {
        contexto.delete(cartera)
        try? contexto.save()
    }
}
