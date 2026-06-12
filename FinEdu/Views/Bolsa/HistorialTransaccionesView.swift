//
//  HistorialTransaccionesView.swift
//  FinEdu
//
//  Historial persistido de compras y ventas (fecha simulada, ticker, tipo,
//  cantidad y precio). Se lee directamente de la cartera de SwiftData.
//

import SwiftUI

struct HistorialTransaccionesView: View {
    let cartera: CarteraBolsa

    private var transacciones: [Transaccion] {
        cartera.transacciones.sorted { $0.indiceMes > $1.indiceMes }
    }

    var body: some View {
        Group {
            if transacciones.isEmpty {
                ContentUnavailableView("Sin movimientos",
                                       systemImage: "list.bullet.rectangle",
                                       description: Text("Aún no has comprado ni vendido nada."))
            } else {
                List(transacciones) { tx in
                    HStack(spacing: 12) {
                        Image(systemName: tx.tipoTransaccion.icono)
                            .foregroundStyle(tx.tipoTransaccion == .compra ? Color.green : Color.red)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(tx.tipoTransaccion.titulo) · \(tx.ticker)")
                                .font(.subheadline.weight(.semibold))
                            Text("\(formato(tx.cantidad)) acc a \(tx.precio.comoMoneda(simbolo: "$")) · \(MarketDataLoader.nombreMes(tx.mesSimulado))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(tx.monto.comoMoneda(simbolo: "$"))
                            .font(.subheadline.monospacedDigit())
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .navigationTitle("Historial")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formato(_ valor: Double) -> String {
        String(format: "%g", (valor * 10000).rounded() / 10000)
    }
}
