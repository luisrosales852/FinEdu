//
//  ResultadosBolsaView.swift
//  FinEdu
//
//  Pantalla de resultados al llegar al último mes del dataset: rendimiento
//  total, comparación vs. efectivo, mejor y peor decisión y retroalimentación
//  educativa. La retroalimentación de IA se conecta en la Fase (d); por ahora
//  usa una plantilla determinista.
//

import SwiftUI

struct ResultadosBolsaView: View {
    let vm: SimuladorBolsaViewModel

    /// Retroalimentación generada por el coach de IA on-device (con fallback a
    /// plantilla mientras carga o si Apple Intelligence no está disponible).
    @State private var feedbackIA: String?

    private struct EvaluacionDecision: Identifiable {
        let id = UUID()
        let ticker: String
        let mes: String
        let retorno: Double
    }

    /// Evalúa cada COMPRA por su retorno desde el precio de compra hasta el
    /// precio del último mes.
    private var evaluaciones: [EvaluacionDecision] {
        vm.cartera.transacciones
            .filter { $0.tipoTransaccion == .compra }
            .compactMap { tx in
                guard let empresa = vm.empresa(tx.ticker),
                      let final = empresa.close(enIndice: vm.indiceMes),
                      tx.precio > 0 else { return nil }
                return EvaluacionDecision(ticker: tx.ticker,
                                          mes: tx.mesSimulado,
                                          retorno: (final / tx.precio - 1) * 100)
            }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                encabezado
                metricas
                mejorPeor
                retroalimentacion
                disclaimer
            }
            .padding()
        }
        .navigationTitle("Resultados")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Coach de IA on-device para la retroalimentación final.
            feedbackIA = await CoachBolsa.feedbackFinal(
                rendimientoPct: vm.rendimientoTotalPct,
                diferenciaVsCash: vm.diferenciaVsCash,
                numeroEmpresas: vm.numeroEmpresas)
        }
    }

    private var encabezado: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "flag.checkered")
                .font(.largeTitle)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            Text("Llegaste a \(vm.mesActualLegible)")
                .font(.title2.bold())
            Text("Recorriste \(vm.totalMeses) meses de mercado. Esto es lo que pasó con tu dinero.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var metricas: some View {
        VStack(spacing: 12) {
            tarjeta(titulo: "Valor final",
                    valor: vm.valorTotal.comoMoneda(simbolo: "$"),
                    detalle: "Partiste de \(vm.cartera.montoAsignado.comoMoneda(simbolo: "$"))")
            tarjeta(titulo: "Rendimiento total",
                    valor: vm.rendimientoTotalPct.comoPorcentajeConSigno,
                    detalle: vm.rendimientoTotalPct >= 0 ? "Ganaste valor" : "Perdiste valor",
                    color: vm.rendimientoTotalPct >= 0 ? .green : .red)
            tarjeta(titulo: "vs. dejar todo en efectivo",
                    valor: vm.diferenciaVsCash.comoMoneda(simbolo: "$"),
                    detalle: vm.diferenciaVsCash >= 0 ? "Invertir te convino" : "Habría sido mejor el efectivo",
                    color: vm.diferenciaVsCash >= 0 ? .green : .red)
        }
    }

    private func tarjeta(titulo: String, valor: String, detalle: String, color: Color = .primary) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(titulo).font(.caption).foregroundStyle(.secondary)
            Text(valor).font(.title2.bold().monospacedDigit()).foregroundStyle(color)
            Text(detalle).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(titulo): \(valor). \(detalle).")
    }

    @ViewBuilder
    private var mejorPeor: some View {
        if let mejor = evaluaciones.max(by: { $0.retorno < $1.retorno }),
           let peor = evaluaciones.min(by: { $0.retorno < $1.retorno }) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Tus decisiones").font(.headline)
                fila(icono: "trophy.fill", color: .green,
                     titulo: "Mejor compra",
                     texto: "\(mejor.ticker) en \(MarketDataLoader.nombreMes(mejor.mes)): \(mejor.retorno.comoPorcentajeConSigno) hasta hoy.")
                fila(icono: "exclamationmark.triangle.fill", color: .orange,
                     titulo: "Peor compra",
                     texto: "\(peor.ticker) en \(MarketDataLoader.nombreMes(peor.mes)): \(peor.retorno.comoPorcentajeConSigno) hasta hoy.")
            }
        } else {
            Label("No registraste compras durante la simulación.", systemImage: "info.circle")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func fila(icono: String, color: Color, titulo: String, texto: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icono).foregroundStyle(color).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(titulo).font(.subheadline.weight(.semibold))
                Text(texto).font(.footnote).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var retroalimentacion: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Lo que aprendiste", systemImage: "graduationcap.fill")
                .font(.headline)
            Text(feedbackIA ?? feedbackPorPlantilla)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
    }

    private var feedbackPorPlantilla: String {
        let diversif = vm.numeroEmpresas >= 3
            ? "Diversificaste en \(vm.numeroEmpresas) empresas, lo que reduce el riesgo."
            : "Tuviste pocas empresas: diversificar más suaviza los altibajos."
        let resultado = vm.diferenciaVsCash >= 0
            ? "Invertir te dio más que dejar el dinero quieto."
            : "Esta vez el efectivo habría rendido más; pasa, el mercado sube y baja."
        return "\(resultado) \(diversif) Lo importante no es acertar siempre, sino entender por qué pasó cada cosa."
    }

    private var disclaimer: some View {
        Text("Simulador educativo con datos históricos. No es asesoría de inversión.")
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}
