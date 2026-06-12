//
//  JuegoView.swift
//  FinEdu
//
//  Pantalla principal del juego: conversación narrativa por turnos.
//  Haptics con .sensoryFeedback (iOS 17) y autodesplazamiento al último
//  mensaje, respetando Reduce Motion.
//

import SwiftUI
import SwiftData

struct JuegoView: View {
    @State private var viewModel: JuegoViewModel
    @State private var mostrarDashboard = false
    @State private var mostrarResultados = false

    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss

    init(escenario: Escenario) {
        _viewModel = State(initialValue: JuegoViewModel(escenario: escenario))
    }

    var body: some View {
        VStack(spacing: 0) {
            BarraMetricas(estado: viewModel.estado,
                          simboloMoneda: viewModel.escenario.perfil.simboloMoneda)

            conversacion

            if viewModel.partidaTerminada {
                Button {
                    mostrarResultados = true
                } label: {
                    Label("Ver mis resultados", systemImage: "trophy.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding()
                .accessibilityHint("Muestra tu score final y las lecciones aprendidas")
            } else if !viewModel.esperandoOpciones {
                CampoDecision(texto: $viewModel.textoDecision,
                              habilitado: viewModel.puedeEnviar) {
                    Task { await viewModel.enviarDecision(contexto: modelContext) }
                }
            }
        }
        .navigationTitle(viewModel.numeroTurnoLegible)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    mostrarDashboard = true
                } label: {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                }
                .accessibilityLabel("Gráfica de tu patrimonio contra la inflación")
            }
        }
        .sheet(isPresented: $mostrarDashboard) {
            DashboardPatrimonioView(estado: viewModel.estado,
                                    escenario: viewModel.escenario)
                .presentationDetents([.medium, .large])
        }
        .fullScreenCover(isPresented: $mostrarResultados) {
            ResultadosView(escenario: viewModel.escenario,
                           estado: viewModel.estado,
                           motor: viewModel.motorActivo) {
                mostrarResultados = false
                dismiss() // regresa a la selección de escenario
            }
        }
        // Haptics (iOS 17): un toque suave por cada mensaje nuevo y un
        // "success" cuando termina la partida.
        .sensoryFeedback(.impact(weight: .light), trigger: viewModel.mensajes.count)
        .sensoryFeedback(.success, trigger: viewModel.partidaTerminada)
    }

    private var conversacion: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.mensajes) { mensaje in
                        let esUltimoMensaje = mensaje.id == viewModel.mensajes.last?.id
                        MensajeView(
                            mensaje: mensaje,
                            simboloMoneda: viewModel.escenario.perfil.simboloMoneda,
                            onSeleccionarOpcion: (viewModel.esperandoOpciones && esUltimoMensaje)
                                ? { opcion in
                                    Task { await viewModel.seleccionarOpcion(opcion, contexto: modelContext) }
                                }
                                : nil
                        )
                        .id(mensaje.id)
                    }
                    if viewModel.procesando {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Analizando tu decisión…")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: viewModel.mensajes.count) {
                guard let ultimo = viewModel.mensajes.last else { return }
                // Reduce Motion: salto directo sin animación.
                if reduceMotion {
                    proxy.scrollTo(ultimo.id, anchor: .bottom)
                } else {
                    withAnimation(.easeOut(duration: 0.35)) {
                        proxy.scrollTo(ultimo.id, anchor: .bottom)
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        JuegoView(escenario: CatalogoEscenarios.crisisTequila1994)
    }
    .modelContainer(for: [Partida.self, DecisionGuardada.self, ConceptoDesbloqueado.self],
                    inMemory: true)
}
