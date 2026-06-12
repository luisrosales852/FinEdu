//
//  MenuPrincipalView.swift
//  FinEdu
//
//  Menú principal: divide la app en sus dos modos de aprendizaje —
//  simulación de crisis históricas y simulación del mercado de valores.
//  Es la pantalla de inicio después del onboarding.
//

import SwiftUI

struct MenuPrincipalView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("¿Qué quieres practicar hoy?")
                    .font(.title2.bold())
                    .padding(.top, 4)

                NavigationLink {
                    SimulacionBolsaView()
                } label: {
                    BotonModo(titulo: "Simulación de bolsa",
                              subtitulo: "Practica invertir en el mercado de valores.",
                              icono: "chart.bar.xaxis")
                }
                .buttonStyle(.plain)
                .cursorFlecha()
                .accessibilityHint("Abre el simulador del mercado de valores")

                NavigationLink {
                    BudgetSimulatorView()
                } label: {
                    BotonModo(titulo: "Simulador de presupuesto",
                              subtitulo: "Reparte tu salario del mes y descubre si tus hábitos son sostenibles.",
                              icono: "chart.pie.fill")
                }
                .buttonStyle(.plain)
                .cursorFlecha()
                .accessibilityHint("Abre el simulador de presupuesto personal mensual")

                NavigationLink {
                    SeleccionEscenarioView()
                } label: {
                    BotonModo(titulo: "Selección de crisis",
                              subtitulo: "Vive crisis económicas reales y decide con tus propias palabras.",
                              icono: "chart.line.downtrend.xyaxis")
                }
                .buttonStyle(.plain)
                .cursorFlecha()
                .accessibilityHint("Abre la lista de crisis históricas jugables")
            }
            .padding()
        }
        .navigationTitle("FinEdu")
    }
}

/// Tarjeta-botón de un modo de la app.
private struct BotonModo: View {
    let titulo: String
    let subtitulo: String
    let icono: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icono)
                .font(.title)
                .foregroundStyle(.tint)
                .frame(width: 52, height: 52)
                .background(.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 4) {
                Text(titulo)
                    .font(.headline)
                Text(subtitulo)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(titulo). \(subtitulo)")
    }
}

#Preview {
    NavigationStack { MenuPrincipalView() }
        .modelContainer(for: [Partida.self, DecisionGuardada.self, ConceptoDesbloqueado.self],
                        inMemory: true)
}
