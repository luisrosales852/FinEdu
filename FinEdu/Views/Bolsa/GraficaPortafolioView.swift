//
//  GraficaPortafolioView.swift
//  FinEdu
//
//  Gráfica central del simulador (Swift Charts). Selector de tres vistas:
//  · Portafolio: evolución del valor total (cash + posiciones) mes a mes.
//  · vs. efectivo: lo anterior comparado con dejar todo en efectivo.
//  · Por empresa: composición actual del portafolio por empresa + efectivo.
//
//  Accesibilidad: resumen textual en accessibilityLabel/Value y, en las
//  series temporales, audio graph automático de Swift Charts.
//

import SwiftUI
import Charts

struct GraficaPortafolioView: View {
    let vm: SimuladorBolsaViewModel
    @Binding var vista: VistaGrafica

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Vista de la gráfica", selection: $vista) {
                ForEach(VistaGrafica.allCases) { v in
                    Text(v.rawValue).tag(v)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityHint("Cambia lo que muestra la gráfica")

            grafica
                .frame(minHeight: 220)
        }
    }

    @ViewBuilder
    private var grafica: some View {
        switch vista {
        case .portafolio: graficaTemporal(incluirCash: false)
        case .vsCash:     graficaTemporal(incluirCash: true)
        case .porEmpresa: graficaPorEmpresa
        }
    }

    // MARK: - Series temporales

    private let serieValor = "Valor del portafolio"
    private let serieCash = "Todo en efectivo"

    private func graficaTemporal(incluirCash: Bool) -> some View {
        let snapshots = vm.snapshotsOrdenados
        return Chart {
            ForEach(snapshots) { snap in
                LineMark(x: .value("Mes", snap.indiceMes),
                         y: .value("Valor", snap.valorPortafolio),
                         series: .value("Serie", serieValor))
                    .foregroundStyle(by: .value("Serie", serieValor))
                    .interpolationMethod(.monotone)
                PointMark(x: .value("Mes", snap.indiceMes),
                          y: .value("Valor", snap.valorPortafolio))
                    .foregroundStyle(Color.accentColor)
                    .symbolSize(snapshots.count == 1 ? 60 : 20)

                if incluirCash {
                    LineMark(x: .value("Mes", snap.indiceMes),
                             y: .value("Valor", snap.valorSiCash),
                             series: .value("Serie", serieCash))
                        .foregroundStyle(by: .value("Serie", serieCash))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 4]))
                }
            }
        }
        .chartForegroundStyleScale([
            serieValor: Color.accentColor,
            serieCash: Color.secondary,
        ])
        .chartXScale(domain: 0...max(vm.indiceMes, 1))
        // Anima toda la gráfica como una unidad cuando cambia la serie (nuevo
        // mes o revaluación tras una operación): así la línea y los puntos se
        // mueven con la misma curva y no aparecen los puntos antes que la línea.
        .animation(.easeInOut(duration: 0.35), value: snapshots.map(\.valorPortafolio))
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { valor in
                AxisGridLine()
                AxisValueLabel {
                    if let indice = valor.as(Int.self),
                       vm.market.months.indices.contains(indice) {
                        Text(MarketDataLoader.nombreMes(vm.market.months[indice]))
                    }
                }
            }
        }
        .chartYAxisLabel("Valor (USD)")
        .chartLegend(position: .bottom)
        .accessibilityLabel(incluirCash
            ? "Gráfica del valor de tu portafolio comparado con dejar todo en efectivo"
            : "Gráfica del valor total de tu portafolio mes a mes")
        .accessibilityValue(resumenTemporal(incluirCash: incluirCash))
    }

    private func resumenTemporal(incluirCash: Bool) -> String {
        let valor = vm.valorTotal.comoMoneda(simbolo: "$")
        let base = "Valor actual \(valor) en \(vm.mesActualLegible), rendimiento \(vm.rendimientoTotalPct.comoPorcentajeConSigno)."
        guard incluirCash else { return base }
        let dif = vm.diferenciaVsCash
        let comparativo = dif >= 0
            ? "Vas \(dif.comoMoneda(simbolo: "$")) por encima de haber dejado todo en efectivo."
            : "Vas \((-dif).comoMoneda(simbolo: "$")) por debajo de haber dejado todo en efectivo."
        return base + " " + comparativo
    }

    // MARK: - Composición por empresa

    private var graficaPorEmpresa: some View {
        // Una barra por posición + una barra de efectivo, ordenadas por valor.
        struct Segmento: Identifiable {
            let id: String
            let etiqueta: String
            let valor: Double
        }
        var segmentos = vm.posiciones.map {
            Segmento(id: $0.ticker, etiqueta: $0.ticker, valor: vm.valorPosicion($0))
        }
        segmentos.append(Segmento(id: "__cash", etiqueta: "Efectivo", valor: vm.cartera.cashActual))

        return Chart(segmentos) { segmento in
            BarMark(x: .value("Valor", segmento.valor),
                    y: .value("Empresa", segmento.etiqueta))
                .foregroundStyle(segmento.id == "__cash" ? Color.secondary : Color.accentColor)
                .annotation(position: .trailing) {
                    Text(segmento.valor.comoMoneda(simbolo: "$"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
        }
        .chartXAxisLabel("Valor (USD)")
        .accessibilityLabel("Composición de tu portafolio por empresa")
        .accessibilityValue(resumenComposicion)
    }

    private var resumenComposicion: String {
        guard !vm.posiciones.isEmpty else {
            return "Aún no tienes posiciones; todo tu dinero está en efectivo."
        }
        let detalle = vm.posiciones.map {
            "\($0.ticker): \(vm.valorPosicion($0).comoMoneda(simbolo: "$"))"
        }.joined(separator: ", ")
        return "Tienes \(vm.numeroEmpresas) empresas. \(detalle). Efectivo: \(vm.cartera.cashActual.comoMoneda(simbolo: "$"))."
    }
}
