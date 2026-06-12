//
//  ResultadosView.swift
//  FinEdu
//
//  Pantalla final: score de resiliencia, desempeño vs. inflación, lecciones
//  (conceptos aprendidos) y la gráfica completa de la partida.
//

import SwiftUI
import Charts

struct ResultadosView: View {
    let escenario: Escenario
    let estado: EstadoJuego
    let motor: MotorIA
    let alTerminar: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    medallaScore

                    tarjetasNumeros

                    DashboardPatrimonioEmbebido(estado: estado, escenario: escenario)

                    leccionesAprendidas

                    Label("Resultados generados con \(motor.rawValue), 100% en tu dispositivo.",
                          systemImage: motor.icono)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
            }
            .navigationTitle("Resultados")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Button(action: alTerminar) {
                    Text("Volver al inicio")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding()
                .background(.bar)
                .accessibilityHint("Guarda la partida y regresa a la selección de escenarios")
            }
        }
    }

    // MARK: - Secciones

    private var medallaScore: some View {
        VStack(spacing: 8) {
            Gauge(value: Double(estado.scoreFinal), in: 0...100) {
                Text("Score")
            } currentValueLabel: {
                Text("\(estado.scoreFinal)")
                    .font(.title.bold())
            }
            .gaugeStyle(.accessoryCircular)
            .tint(colorScore)
            .scaleEffect(1.6)
            .frame(height: 110)

            Text(tituloScore)
                .font(.title3.bold())
            Text(descripcionScore)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tu score de resiliencia financiera: \(estado.scoreFinal) de 100. \(tituloScore). \(descripcionScore)")
    }

    private var tarjetasNumeros: some View {
        let simbolo = escenario.perfil.simboloMoneda
        let inflacion = estado.indiceInflacion - 100
        return VStack(spacing: 10) {
            FilaResultado(titulo: "Patrimonio final",
                          valor: estado.patrimonio.comoMoneda(simbolo: simbolo),
                          icono: "wallet.bifold.fill")
            FilaResultado(titulo: "Patrimonio inicial",
                          valor: estado.patrimonioInicial.comoMoneda(simbolo: simbolo),
                          icono: "arrow.backward.circle")
            FilaResultado(titulo: "Inflación acumulada del escenario",
                          valor: String(format: "%.0f%%", inflacion),
                          icono: "flame.fill")
            FilaResultado(titulo: "¿Conservaste poder de compra?",
                          valor: estado.conservoPoderAdquisitivo ? "Sí ✓" : "No",
                          icono: estado.conservoPoderAdquisitivo ? "checkmark.seal.fill" : "xmark.seal.fill")
        }
    }

    private var leccionesAprendidas: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Conceptos que aprendiste", systemImage: "graduationcap.fill")
                .font(.headline)

            if estado.conceptosAprendidos.isEmpty {
                Text("Juega de nuevo y menciona estrategias concretas para desbloquear conceptos.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(estado.conceptosAprendidos.sorted { $0.nombre < $1.nombre }) { concepto in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: concepto.icono)
                            .foregroundStyle(.tint)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(concepto.nombre)
                                .font(.subheadline.weight(.semibold))
                            Text(concepto.definicion)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Derivados del score

    private var colorScore: Color {
        switch estado.scoreFinal {
        case ..<40: return .red
        case ..<70: return .orange
        default: return .green
        }
    }

    private var tituloScore: String {
        switch estado.scoreFinal {
        case ..<40: return "Sobreviviste… apenas"
        case ..<70: return "Resististe la crisis"
        default: return "Resiliencia financiera sólida"
        }
    }

    private var descripcionScore: String {
        switch estado.scoreFinal {
        case ..<40:
            return "La crisis te golpeó fuerte. Revisa las lecciones: la próxima vez, el fondo de emergencia y la diversificación son tus aliados."
        case ..<70:
            return "Tomaste decisiones razonables en un contexto brutal. Afina el manejo de deuda y liquidez para blindarte mejor."
        default:
            return "Leíste el contexto histórico y actuaste a tiempo. Este criterio es exactamente la educación financiera que cambia vidas."
        }
    }
}

/// Fila de resultado numérico.
private struct FilaResultado: View {
    let titulo: String
    let valor: String
    let icono: String

    var body: some View {
        HStack {
            Label(titulo, systemImage: icono)
                .font(.subheadline)
            Spacer()
            Text(valor)
                .font(.subheadline.bold().monospacedDigit())
        }
        .padding(12)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }
}

/// Versión compacta de la gráfica para incrustar en resultados.
private struct DashboardPatrimonioEmbebido: View {
    let estado: EstadoJuego
    let escenario: Escenario

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Tu dinero vs. la inflación", systemImage: "chart.line.uptrend.xyaxis")
                .font(.headline)
            Chart {
                ForEach(estado.historial) { registro in
                    LineMark(x: .value("Turno", registro.numeroTurno),
                             y: .value("Monto", registro.patrimonio),
                             series: .value("Serie", "Tu patrimonio"))
                        .foregroundStyle(by: .value("Serie", "Tu patrimonio"))
                    LineMark(x: .value("Turno", registro.numeroTurno),
                             y: .value("Monto", registro.umbralInflacion),
                             series: .value("Serie", "Necesario por inflación"))
                        .foregroundStyle(by: .value("Serie", "Necesario por inflación"))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 4]))
                }
            }
            .chartForegroundStyleScale([
                "Tu patrimonio": Color.accentColor,
                "Necesario por inflación": Color.red,
            ])
            .chartLegend(position: .bottom)
            .frame(height: 200)
            .accessibilityLabel("Gráfica final de patrimonio contra inflación")
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
    }
}
