//
//  SalaryInputView.swift
//  FinEdu
//
//  Captura del salario mensual simulado (en pesos MXN). Muestra el monto
//  formateado en tiempo real bajo el campo. Componente reutilizable que expone
//  el salario como Double mediante un Binding.
//

import SwiftUI

struct SalaryInputView: View {
    /// Texto crudo que escribe el usuario (fuente de verdad del campo).
    @Binding var salarioTexto: String
    /// Salario numérico derivado (0 si el texto no es válido).
    @Binding var salario: Double

    @FocusState private var enfocado: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Salario mensual", systemImage: "dollarsign.circle.fill")
                .font(.headline)
                .foregroundStyle(.tint)

            Text("Ingresa un salario mensual simulado en pesos mexicanos (MXN).")
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Text("$")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                TextField("Ej. 12000", text: $salarioTexto)
                    .keyboardType(.numberPad)
                    .font(.title2)
                    .textFieldStyle(.roundedBorder)
                    .focused($enfocado)
                    // Cada cambio de texto recalcula el salario numérico.
                    .onChange(of: salarioTexto) { _, nuevo in
                        salario = Self.parsear(nuevo)
                    }
                    // El teclado numérico no trae tecla de retorno: este botón
                    // permite confirmar el salario y cerrar el teclado.
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Listo") { enfocado = false }
                                .fontWeight(.semibold)
                                .accessibilityHint("Confirma el salario y cierra el teclado")
                        }
                    }
                    .accessibilityLabel("Salario mensual en pesos")
                Text("MXN")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }

            // Eco del monto formateado para confirmar lo que entendió la app.
            if salario > 0 {
                Text("Salario: \(salario.comoMoneda(simbolo: "$")) MXN")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
                    .accessibilityLabel("Salario capturado: \(Int(salario)) pesos")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
    }

    /// Convierte el texto del usuario a Double, tolerando comas y espacios.
    static func parsear(_ texto: String) -> Double {
        let limpio = texto
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "$", with: "")
            .trimmingCharacters(in: .whitespaces)
        return Double(limpio) ?? 0
    }
}
