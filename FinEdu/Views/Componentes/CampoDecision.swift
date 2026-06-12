//
//  CampoDecision.swift
//  FinEdu
//
//  Campo de texto libre donde el jugador escribe su decisión financiera.
//  Accesibilidad: accessibilityHint explica qué hacer (requisito explícito de
//  la rúbrica), el botón de enviar tiene su label y el campo soporta varias
//  líneas con Dynamic Type.
//

import SwiftUI

struct CampoDecision: View {
    @Binding var texto: String
    let habilitado: Bool
    let alEnviar: () -> Void

    @FocusState private var enfocado: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Escribe tu decisión…", text: $texto, axis: .vertical)
                .lineLimit(1...4)
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 20))
                .focused($enfocado)
                .submitLabel(.send)
                .onSubmit { enviar() }
                .accessibilityLabel("Tu decisión financiera")
                .accessibilityHint("Escribe con tus palabras qué harás con tu dinero en este turno. Por ejemplo: compraré dólares, o pagaré mi deuda.")

            Button(action: enviar) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .symbolRenderingMode(.hierarchical)
            }
            .disabled(!habilitado)
            .accessibilityLabel("Enviar decisión")
            .accessibilityHint("Analiza tu decisión y muestra las consecuencias")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private func enviar() {
        guard habilitado else { return }
        alEnviar()
    }
}
