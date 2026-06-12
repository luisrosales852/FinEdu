//
//  BarraMetricas.swift
//  FinEdu
//
//  Métricas vivas de la partida: patrimonio, liquidez y resiliencia.
//  Los números usan .contentTransition(.numericText()) para animarse de
//  forma sutil (y la animación se desactiva con Reduce Motion).
//

import SwiftUI

struct BarraMetricas: View {
    let estado: EstadoJuego
    let simboloMoneda: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 12) {
            Metrica(titulo: "Patrimonio",
                    valor: estado.patrimonio.comoMoneda(simbolo: simboloMoneda),
                    icono: "wallet.bifold.fill",
                    color: estado.patrimonio >= estado.patrimonioInicial ? .green : .orange)

            Metrica(titulo: "Liquidez",
                    valor: "\(Int(estado.liquidez))%",
                    icono: "drop.fill",
                    color: .blue)

            Metrica(titulo: "Resiliencia",
                    valor: "\(estado.scoreResiliencia)",
                    icono: "shield.lefthalf.filled",
                    color: .purple)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
        // Reduce Motion: sin transición numérica animada.
        .animation(reduceMotion ? nil : .snappy, value: estado.patrimonio)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Patrimonio: \(estado.patrimonio.comoMoneda(simbolo: simboloMoneda)). Liquidez: \(Int(estado.liquidez)) por ciento. Resiliencia financiera: \(estado.scoreResiliencia) de 100.")
    }
}

private struct Metrica: View {
    let titulo: String
    let valor: String
    let icono: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Label(titulo, systemImage: icono)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .labelStyle(.titleAndIcon)
                .imageScale(.small)
            Text(valor)
                .font(.subheadline.bold().monospacedDigit())
                .foregroundStyle(color)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
    }
}
