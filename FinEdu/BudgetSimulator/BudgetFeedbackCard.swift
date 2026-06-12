//
//  BudgetFeedbackCard.swift
//  FinEdu
//
//  Tarjeta de retroalimentación contextual. Combina el mensaje principal "de
//  la IA" (ligado a una crisis histórica real) con consejos puntuales por cada
//  categoría problemática. Incluye un enlace para "vivir" la crisis relacionada
//  en el modo de Selección de crisis, conectando ambas funciones de la app.
//
//  Accesibilidad: el bloque principal se agrupa para VoiceOver; el color de la
//  clasificación nunca es el único canal (siempre va con icono + texto).
//

import SwiftUI

struct BudgetFeedbackCard: View {
    let resultado: ResultadoPresupuesto

    /// Enrutador compartido: al pulsar el enlace, el NavigationStack raíz
    /// empuja la crisis correspondiente (mismo mecanismo que Siri/Spotlight).
    private let enrutador = EnrutadorApp.shared

    private var clasificacion: ClasificacionPresupuesto { resultado.clasificacion }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Mensaje principal contextualizado.
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "text.bubble.fill")
                    .foregroundStyle(clasificacion.color)
                    .accessibilityHidden(true)
                Text(resultado.feedbackPrincipal)
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Análisis: \(resultado.feedbackPrincipal)")

            // Consejos por categoría problemática (si hay).
            if !resultado.consejos.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 10) {
                    Label("Qué puedes ajustar", systemImage: "wrench.and.screwdriver.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    ForEach(Array(resultado.categoriasProblematicas.enumerated()), id: \.offset) { indice, categoria in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: categoria.icono)
                                .font(.footnote)
                                .foregroundStyle(categoria.color)
                                .frame(width: 18)
                                .accessibilityHidden(true)
                            Text(resultado.consejos[indice])
                                .font(.footnote)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(categoria.nombre): \(resultado.consejos[indice])")
                    }
                }
            }

            Divider()

            // Enlace al simulador de crisis relacionado.
            Button {
                enrutador.escenarioPendienteID = clasificacion.escenarioRelacionadoID
            } label: {
                HStack {
                    Label("Vivir esta crisis: \(clasificacion.escenarioRelacionadoNombre)",
                          systemImage: "play.circle.fill")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.tint)
            .accessibilityHint("Abre la crisis histórica relacionada en el simulador")
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(clasificacion.color.opacity(0.35))
        )
    }
}
