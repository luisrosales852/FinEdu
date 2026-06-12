//
//  GlosarioView.swift
//  FinEdu
//
//  Glosario de conceptos económicos que se desbloquea jugando.
//  Los desbloqueos vienen de SwiftData (@Query); los bloqueados se muestran
//  difuminados como invitación a seguir jugando.
//

import SwiftUI
import SwiftData

struct GlosarioView: View {
    @Query private var desbloqueados: [ConceptoDesbloqueado]
    @State private var viewModel = GlosarioViewModel()

    private var conjuntoDesbloqueado: Set<ConceptoEconomico> {
        Set(desbloqueados.compactMap(\.concepto))
    }

    var body: some View {
        List {
            Section {
                ProgressView(value: viewModel.progreso(desbloqueados: conjuntoDesbloqueado)) {
                    Text("\(conjuntoDesbloqueado.count) de \(ConceptoEconomico.allCases.count) conceptos desbloqueados")
                        .font(.subheadline)
                }
                .accessibilityLabel("Progreso del glosario: \(conjuntoDesbloqueado.count) de \(ConceptoEconomico.allCases.count) conceptos desbloqueados")
            }

            Section {
                ForEach(viewModel.conceptosOrdenados(desbloqueados: conjuntoDesbloqueado)) { concepto in
                    FilaConcepto(concepto: concepto,
                                 desbloqueado: conjuntoDesbloqueado.contains(concepto))
                }
            } footer: {
                Text("Desbloquea conceptos jugando: cada decisión y cada lección revela nuevas entradas.")
            }
        }
        .searchable(text: $viewModel.textoBusqueda, prompt: "Buscar concepto")
        .navigationTitle("Glosario")
    }
}

private struct FilaConcepto: View {
    let concepto: ConceptoEconomico
    let desbloqueado: Bool

    var body: some View {
        if desbloqueado {
            DisclosureGroup {
                VStack(alignment: .leading, spacing: 8) {
                    Text(concepto.definicion)
                        .font(.callout)
                    Label {
                        Text(concepto.ejemploHistorico)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: "clock.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            } label: {
                Label(concepto.nombre, systemImage: concepto.icono)
                    .font(.body.weight(.medium))
            }
            .accessibilityHint("Toca para leer la definición y un ejemplo histórico")
        } else {
            HStack {
                Label(concepto.nombre, systemImage: "lock.fill")
                    .font(.body)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Bloqueado")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(concepto.nombre): bloqueado. Juega para desbloquearlo.")
        }
    }
}

#Preview {
    NavigationStack { GlosarioView() }
        .modelContainer(for: [ConceptoDesbloqueado.self], inMemory: true)
}
