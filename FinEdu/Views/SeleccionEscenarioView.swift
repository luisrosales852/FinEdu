//
//  SeleccionEscenarioView.swift
//  FinEdu
//
//  Selección de escenario + historial de partidas (SwiftData @Query).
//

import SwiftUI
import SwiftData

struct SeleccionEscenarioView: View {
    /// Partidas guardadas, las más recientes primero.
    @Query(sort: \Partida.fecha, order: .reverse) private var partidas: [Partida]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                encabezado

                ForEach(CatalogoEscenarios.todos) { escenario in
                    NavigationLink {
                        JuegoView(escenario: escenario)
                    } label: {
                        TarjetaEscenario(escenario: escenario,
                                         mejorScore: mejorScore(de: escenario))
                    }
                    .buttonStyle(.plain)
                    .cursorFlecha()
                    .accessibilityHint("Inicia la simulación \(escenario.titulo), de \(escenario.turnos.count) turnos")
                }

                if !partidas.isEmpty {
                    historial
                }
            }
            .padding()
        }
        .navigationTitle("FinEdu")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    GlosarioView()
                } label: {
                    Image(systemName: "book.fill")
                }
                .accessibilityLabel("Glosario de conceptos económicos")
            }
        }
    }

    private var encabezado: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Elige tu crisis")
                .font(.title2.bold())
            Text("Vive una crisis económica real, decide con tus propias palabras y aprende de las consecuencias. Sin riesgo: aquí quebrar es gratis.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var historial: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Tus partidas", systemImage: "clock.arrow.circlepath")
                .font(.headline)
            ForEach(partidas.prefix(5)) { partida in
                HStack {
                    Image(systemName: partida.escenario?.icono ?? "questionmark.circle")
                        .foregroundStyle(.tint)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(partida.escenario?.titulo ?? partida.escenarioID)
                            .font(.subheadline.weight(.semibold))
                        Text(partida.fecha, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("Score \(partida.scoreFinal)")
                        .font(.subheadline.bold().monospacedDigit())
                        .foregroundStyle(partida.scoreFinal >= 70 ? .green : .orange)
                }
                .padding(12)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
                .accessibilityElement(children: .combine)
            }
        }
    }

    private func mejorScore(de escenario: Escenario) -> Int? {
        let scores = partidas.filter { $0.escenarioID == escenario.id }.map(\.scoreFinal)
        return scores.max()
    }
}

/// Tarjeta de presentación de un escenario.
private struct TarjetaEscenario: View {
    let escenario: Escenario
    let mejorScore: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: escenario.icono)
                    .font(.title2)
                    .foregroundStyle(.tint)
                    .frame(width: 40, height: 40)
                    .background(.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading) {
                    Text(escenario.titulo)
                        .font(.headline)
                    Text("\(escenario.subtitulo) · \(escenario.periodo)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let mejorScore {
                    VStack(spacing: 0) {
                        Text("\(mejorScore)")
                            .font(.subheadline.bold().monospacedDigit())
                        Text("mejor")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Text(escenario.perfil.rol + " · " + escenario.perfil.descripcion)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Escenario: \(escenario.titulo), \(escenario.subtitulo), periodo \(escenario.periodo). Tu rol: \(escenario.perfil.rol).\(mejorScore.map { " Tu mejor score: \($0)." } ?? "")")
    }
}

#Preview {
    NavigationStack { SeleccionEscenarioView() }
        .modelContainer(for: [Partida.self, DecisionGuardada.self, ConceptoDesbloqueado.self],
                        inMemory: true)
}
