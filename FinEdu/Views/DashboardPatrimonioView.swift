//
//  DashboardPatrimonioView.swift
//  FinEdu
//
//  Gráfica con Swift Charts: evolución del patrimonio del jugador frente a
//  la "línea de la inflación" (cuánto necesitarías para conservar tu poder
//  de compra inicial). Si tu línea queda debajo de la de inflación, ganaste
//  pesos pero perdiste riqueza real — la lección central de la app.
//
//  Interacción: arrastra sobre la gráfica para inspeccionar turno por turno
//  los valores exactos (chartXSelection, iOS 17+).
//
//  Accesibilidad: Swift Charts genera audio graphs automáticamente para
//  VoiceOver; añadimos además un resumen textual accesible.
//

import SwiftUI
import Charts

struct DashboardPatrimonioView: View {
    let estado: EstadoJuego
    let escenario: Escenario

    @Environment(\.dismiss) private var dismiss

    /// Turno seleccionado al arrastrar sobre la gráfica.
    @State private var turnoSeleccionado: Int?

    private let seriePatrimonio = "Tu patrimonio"
    private let serieInflacion = "Necesario por inflación"

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(resumen)
                    .font(.callout)
                    .foregroundStyle(.secondary)

                grafica

                explicacion
            }
            .padding()
            .navigationTitle("Tu dinero vs. la inflación")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") { dismiss() }
                }
            }
        }
    }

    private var grafica: some View {
        Chart {
            ForEach(estado.historial) { registro in
                LineMark(x: .value("Turno", registro.numeroTurno),
                         y: .value("Monto", registro.patrimonio),
                         series: .value("Serie", seriePatrimonio))
                    .foregroundStyle(by: .value("Serie", seriePatrimonio))
                    .symbol(by: .value("Serie", seriePatrimonio))
                    .interpolationMethod(.catmullRom)

                LineMark(x: .value("Turno", registro.numeroTurno),
                         y: .value("Monto", registro.umbralInflacion),
                         series: .value("Serie", serieInflacion))
                    .foregroundStyle(by: .value("Serie", serieInflacion))
                    .symbol(by: .value("Serie", serieInflacion))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 4]))
                    .interpolationMethod(.catmullRom)
            }

            // Regla + anotación con los valores del turno que el usuario toca.
            if let seleccion = registroSeleccionado {
                RuleMark(x: .value("Turno", seleccion.numeroTurno))
                    .foregroundStyle(.secondary.opacity(0.4))
                    .annotation(position: .top, alignment: .center, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                        anotacionSeleccion(seleccion)
                    }
            }
        }
        .chartForegroundStyleScale([
            seriePatrimonio: Color.accentColor,
            serieInflacion: Color.red,
        ])
        .chartXAxisLabel("Turno")
        .chartYAxisLabel("Monto (\(escenario.perfil.nombreMoneda))")
        .chartXSelection(value: $turnoSeleccionado)
        .chartLegend(position: .bottom)
        .frame(minHeight: 240)
        .accessibilityLabel("Gráfica de tu patrimonio contra la inflación por turno")
        .accessibilityValue(resumen)
    }

    /// Tarjeta flotante con el detalle del turno seleccionado.
    private func anotacionSeleccion(_ registro: RegistroTurno) -> some View {
        let simbolo = escenario.perfil.simboloMoneda
        return VStack(alignment: .leading, spacing: 4) {
            Text("Turno \(registro.numeroTurno)")
                .font(.caption.bold())
            Label(registro.patrimonio.comoMoneda(simbolo: simbolo), systemImage: "person.fill")
                .foregroundStyle(Color.accentColor)
            Label(registro.umbralInflacion.comoMoneda(simbolo: simbolo), systemImage: "flame.fill")
                .foregroundStyle(.red)
        }
        .font(.caption.monospacedDigit())
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
    }

    private var registroSeleccionado: RegistroTurno? {
        guard let turnoSeleccionado else { return nil }
        return estado.historial.min {
            abs($0.numeroTurno - turnoSeleccionado) < abs($1.numeroTurno - turnoSeleccionado)
        }
    }

    private var resumen: String {
        let simbolo = escenario.perfil.simboloMoneda
        let umbral = estado.patrimonioInicial * estado.indiceInflacion / 100
        let estadoTexto = estado.conservoPoderAdquisitivo
            ? "Vas ARRIBA de la inflación: conservas tu poder de compra."
            : "Vas DEBAJO de la inflación: aunque tengas más billetes, compras menos que al inicio."
        return "Patrimonio: \(estado.patrimonio.comoMoneda(simbolo: simbolo)). Para igualar tu poder de compra inicial necesitas \(umbral.comoMoneda(simbolo: simbolo)). \(estadoTexto)"
    }

    private var explicacion: some View {
        Label {
            Text("Arrastra sobre la gráfica para ver cada turno. La línea roja punteada es la inflación acumulada del escenario (datos históricos reales). Vencer a esa línea —no solo \"tener más dinero\"— es conservar riqueza real.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        } icon: {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(.tint)
        }
    }
}
