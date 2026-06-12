//
//  FilaEmpresaView.swift
//  FinEdu
//
//  Fila de una empresa en la lista del simulador: precio actual, cambio %
//  vs. el mes anterior, mini-sparkline de la serie visible y, si el usuario
//  tiene posición, su valor. El color del cambio nunca es el único canal:
//  va acompañado de una flecha y del signo del porcentaje (daltonismo).
//

import SwiftUI
import Charts

struct FilaEmpresaView: View {
    let vm: SimuladorBolsaViewModel
    let empresa: Company

    private var precio: Double { vm.precioActual(empresa.ticker) }
    private var cambio: Double { vm.cambioMensual(empresa.ticker) }
    private var holding: Holding? { vm.holding(empresa.ticker) }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(empresa.ticker)
                    .font(.subheadline.bold())
                Text(empresa.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if let holding {
                    Text("Tienes \(formatoCantidad(holding.cantidad)) · \(vm.valorPosicion(holding).comoMoneda(simbolo: "$"))")
                        .font(.caption2)
                        .foregroundStyle(.tint)
                }
            }

            Spacer(minLength: 8)

            sparkline
                .frame(width: 64, height: 28)
                .accessibilityHidden(true)

            VStack(alignment: .trailing, spacing: 2) {
                Text(precio.comoMoneda(simbolo: "$"))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                HStack(spacing: 2) {
                    Image(systemName: cambio >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2)
                    Text(cambio.comoPorcentajeConSigno)
                        .font(.caption.monospacedDigit())
                }
                .foregroundStyle(cambio >= 0 ? Color.green : Color.red)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(etiquetaAccesible)
        .accessibilityHint("Toca para comprar o vender")
    }

    private var sparkline: some View {
        let serie = Array(vm.serieVisible(empresa.ticker).enumerated())
        return Chart {
            ForEach(serie, id: \.offset) { punto in
                LineMark(x: .value("Mes", punto.offset),
                         y: .value("Precio", punto.element))
                    .interpolationMethod(.monotone)
                    .foregroundStyle(cambio >= 0 ? Color.green : Color.red)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
    }

    private var etiquetaAccesible: String {
        var texto = "\(empresa.name). Precio \(precio.comoMoneda(simbolo: "$")). "
        texto += cambio >= 0 ? "Sube \(cambio.comoPorcentajeConSigno) este mes. " : "Baja \(cambio.comoPorcentajeConSigno) este mes. "
        if let holding {
            texto += "Tienes \(formatoCantidad(holding.cantidad)) acciones, valor \(vm.valorPosicion(holding).comoMoneda(simbolo: "$"))."
        }
        return texto
    }

    private func formatoCantidad(_ cantidad: Double) -> String {
        // Hasta 4 decimales para acciones fraccionarias, sin ceros sobrantes.
        String(format: "%g", (cantidad * 10000).rounded() / 10000)
    }
}
