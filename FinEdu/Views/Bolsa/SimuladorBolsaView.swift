//
//  SimuladorBolsaView.swift
//  FinEdu
//
//  Pantalla principal del Simulador de Bolsa: resumen del portafolio, gráfica
//  central, botón prominente para avanzar el mes y lista de empresas para
//  comprar/vender. El tiempo arranca en junio de 2023 y avanza mes a mes; el
//  usuario solo ve precios hasta el mes actual. Moneda: USD.
//

import SwiftUI
import SwiftData

struct SimuladorBolsaView: View {
    @State private var vm: SimuladorBolsaViewModel

    @Environment(\.modelContext) private var contexto

    @State private var vista: VistaGrafica = .portafolio
    @State private var empresaSeleccionada: Company?
    @State private var mostrarReinicio = false
    /// Consejo del coach de IA tras la última operación (se descarta al tocar la X).
    @State private var consejo: ConsejoCoach?

    init(cartera: CarteraBolsa) {
        _vm = State(initialValue: SimuladorBolsaViewModel(cartera: cartera))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                resumenPortafolio
                if let consejo { coachBanner(consejo) }
                GraficaPortafolioView(vm: vm, vista: $vista)
                metricas
                controlTiempo
                listaEmpresas
                disclaimer
            }
            .padding()
        }
        .navigationTitle("Simulador")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    NavigationLink {
                        HistorialTransaccionesView(cartera: vm.cartera)
                    } label: {
                        Label("Historial", systemImage: "list.bullet.rectangle")
                    }
                    NavigationLink {
                        ResultadosBolsaView(vm: vm)
                    } label: {
                        Label("Ver resultados", systemImage: "flag.checkered")
                    }
                    Divider()
                    Button(role: .destructive) {
                        mostrarReinicio = true
                    } label: {
                        Label("Reiniciar simulador", systemImage: "arrow.counterclockwise")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .accessibilityLabel("Más opciones del simulador")
                }
            }
        }
        .sheet(item: $empresaSeleccionada) { empresa in
            CompraVentaSheet(vm: vm, empresa: empresa, alOperar: { modo in
                lanzarCoach(modo: modo, empresa: empresa)
            })
        }
        .sheet(item: $vm.eventoPendiente) { evento in
            EventoMercadoSheet(evento: evento)
        }
        .alert("¿Reiniciar el simulador?", isPresented: $mostrarReinicio) {
            Button("Cancelar", role: .cancel) {}
            Button("Reiniciar", role: .destructive) {
                vm.reiniciar(contexto: contexto)
                // Al borrar la cartera, el @Query de SimulacionBolsaView vuelve
                // a mostrar el onboarding automáticamente.
            }
        } message: {
            Text("Se borrarán tu efectivo, posiciones e historial de bolsa. Tus partidas de crisis no se tocan.")
        }
        .onAppear {
            // Asegura un snapshot del mes inicial para que la gráfica tenga un punto.
            if vm.cartera.snapshots.isEmpty {
                vm.actualizarSnapshotActual(contexto: contexto)
                try? contexto.save()
            }
        }
    }

    // MARK: - Resumen

    private var resumenPortafolio: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Valor del portafolio")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(vm.valorTotal.comoMoneda(simbolo: "$"))
                .font(.largeTitle.bold().monospacedDigit())
                .contentTransition(.numericText())
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Label(vm.rendimientoTotalPct.comoPorcentajeConSigno,
                          systemImage: vm.rendimientoTotalPct >= 0 ? "arrow.up.right" : "arrow.down.right")
                    Text(vm.gananciaTotal.comoMonedaConSigno(simbolo: "$"))
                        .font(.subheadline.monospacedDigit())
                }
                .foregroundStyle(vm.rendimientoTotalPct >= 0 ? Color.green : Color.red)
                Spacer(minLength: 4)
                Text("Efectivo: \(vm.cartera.cashActual.comoMoneda(simbolo: "$"))")
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Valor del portafolio \(Int(vm.valorTotal)) dólares, rendimiento \(vm.rendimientoTotalPct.comoPorcentajeConSigno), equivalente a \(vm.gananciaTotal.comoMonedaConSigno(simbolo: "$")). Efectivo \(Int(vm.cartera.cashActual)) dólares.")
    }

    // MARK: - Coach de IA

    private func coachBanner(_ consejo: ConsejoCoach) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: consejo.motor.esGenerativo ? "sparkles" : "cpu")
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Coach financiero").font(.caption.weight(.semibold))
                Text(consejo.texto).font(.footnote).foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)
            Button {
                withAnimation { self.consejo = nil }
            } label: {
                Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Cerrar consejo")
        }
        .padding()
        .background(.tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Consejo del coach: \(consejo.texto)")
    }

    private func lanzarCoach(modo: TipoTransaccion, empresa: Company) {
        let ctx = ContextoCoach(operacion: modo,
                                ticker: empresa.ticker,
                                nombreEmpresa: empresa.name,
                                cambioMensual: vm.cambioMensual(empresa.ticker),
                                numeroEmpresas: vm.numeroEmpresas,
                                concentracionMayor: vm.concentracionMayorPosicion,
                                tickerMayor: vm.tickerMayorPosicion)
        Task {
            let resultado = await CoachBolsa.consejo(ctx)
            withAnimation { consejo = resultado }
        }
    }

    // MARK: - Métricas

    private var metricas: some View {
        HStack(spacing: 12) {
            metrica(titulo: "Rendimiento",
                    valor: vm.rendimientoTotalPct.comoPorcentajeConSigno,
                    icono: "percent")
            metrica(titulo: "Empresas",
                    valor: "\(vm.numeroEmpresas)",
                    icono: "building.2")
            metrica(titulo: "Mayor pos.",
                    valor: vm.numeroEmpresas > 0 ? "\(Int(vm.concentracionMayorPosicion * 100))%" : "—",
                    icono: "chart.pie")
        }
    }

    private func metrica(titulo: String, valor: String, icono: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icono).font(.caption).foregroundStyle(.tint)
            Text(valor).font(.headline.monospacedDigit())
            Text(titulo).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(titulo): \(valor)")
    }

    // MARK: - Control del tiempo

    private var controlTiempo: some View {
        VStack(spacing: 8) {
            Text("\(vm.mesActualLegible) · mes \(vm.mesesTranscurridos) de \(vm.totalMeses)")
                .font(.subheadline.weight(.medium))
            if vm.esUltimoMes {
                NavigationLink {
                    ResultadosBolsaView(vm: vm)
                } label: {
                    Label("Ver resultados finales", systemImage: "flag.checkered")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else {
                Button {
                    withAnimation(.snappy) {
                        vm.avanzarMes(contexto: contexto)
                    }
                } label: {
                    Label("Avanzar mes", systemImage: "arrow.right.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityHint("Pasa al siguiente mes y actualiza los precios")
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Lista de empresas

    private var listaEmpresas: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Empresas")
                .font(.headline)
                .padding(.bottom, 4)
            ForEach(vm.market.companies) { empresa in
                Button {
                    empresaSeleccionada = empresa
                } label: {
                    FilaEmpresaView(vm: vm, empresa: empresa)
                }
                .buttonStyle(.plain)
                Divider()
            }
        }
    }

    private var disclaimer: some View {
        Text("Simulador educativo con datos históricos. No es asesoría de inversión.")
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

/// Tarjeta de evento educativo que aparece al avanzar a ciertos meses.
struct EventoMercadoSheet: View {
    let evento: MarketEvent
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(MarketDataLoader.nombreMes(evento.month), systemImage: "newspaper.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tint)
            Text(evento.title).font(.title3.bold())
            Text(evento.detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Entendido") { dismiss() }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
        }
        .padding()
        .presentationDetents([.medium])
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Evento de \(MarketDataLoader.nombreMes(evento.month)): \(evento.title). \(evento.detail)")
    }
}
