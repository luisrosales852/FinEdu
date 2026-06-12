//
//  CategorySliderView.swift
//  FinEdu
//
//  Componente reutilizable para una categoría del presupuesto. Ofrece DOS
//  formas de capturar el monto, sincronizadas entre sí:
//   · un campo de texto donde el usuario escribe un monto ("4000") o un
//     porcentaje del salario ("40%") — "lenguaje natural" de cantidades, y
//   · un slider para ajustar el monto de forma continua.
//  Muestra en tiempo real el porcentaje que representa del salario.
//

import SwiftUI

struct CategorySliderView: View {
    let categoria: CategoriaPresupuesto
    /// Salario total, para calcular porcentajes y acotar el slider.
    let salario: Double
    /// Monto asignado a esta categoría (fuente de verdad, en MXN).
    @Binding var monto: Double

    /// Texto editable del campo. Se mantiene en sync con `monto`.
    @State private var texto: String = ""
    @FocusState private var enfocado: Bool

    /// Porcentaje del salario que representa el monto actual.
    private var porcentaje: Double {
        salario > 0 ? monto / salario * 100 : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            encabezado

            HStack(spacing: 10) {
                Text("$")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                TextField("0", text: $texto)
                    // numbersAndPunctuation permite escribir el símbolo "%".
                    .keyboardType(.numbersAndPunctuation)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 140)
                    .focused($enfocado)
                    .onChange(of: texto) { _, nuevo in
                        // Solo el campo manda mientras está enfocado, para no
                        // pelear con las actualizaciones que provoca el slider.
                        if enfocado { monto = interpretar(nuevo) }
                    }
                    // Botón para confirmar el monto y cerrar el teclado numérico
                    // (que no tiene tecla de retorno), para una captura fluida.
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Listo") { enfocado = false }
                                .fontWeight(.semibold)
                                .accessibilityHint("Confirma el monto y cierra el teclado")
                        }
                    }
                    .accessibilityLabel("Monto para \(categoria.nombre)")
                    .accessibilityHint("Escribe una cantidad en pesos o un porcentaje terminado en %")

                Spacer()

                // Insignia con el porcentaje en vivo.
                Text("\(Int(porcentaje.rounded()))%")
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(categoria.color)
                    .contentTransition(.numericText())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(categoria.color.opacity(0.15), in: Capsule())
                    .accessibilityLabel("\(Int(porcentaje.rounded())) por ciento del salario")
            }

            Slider(value: $monto, in: 0...max(salario, 1), step: 1)
                .tint(categoria.color)
                // Cuando el slider mueve el monto, reflejamos el valor en el
                // texto (salvo que el usuario esté escribiendo en el campo).
                .onChange(of: monto) { _, nuevo in
                    if !enfocado { texto = nuevo > 0 ? String(Int(nuevo)) : "" }
                }
                .accessibilityLabel("Ajustar \(categoria.nombre)")
                .accessibilityValue("\(Int(monto)) pesos, \(Int(porcentaje.rounded())) por ciento")
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
        // Inicializa el texto si la categoría ya trae un monto (p. ej. al volver).
        .onAppear {
            if monto > 0 { texto = String(Int(monto)) }
        }
    }

    // MARK: - Subvistas

    private var encabezado: some View {
        HStack(spacing: 12) {
            Image(systemName: categoria.icono)
                .font(.title3)
                .foregroundStyle(categoria.color)
                .frame(width: 38, height: 38)
                .background(categoria.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(categoria.nombre)
                    .font(.headline)
                Text(categoria.pista)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(categoria.nombre). \(categoria.pista)")
    }

    // MARK: - Interpretación del texto

    /// Interpreta el texto como monto en pesos o como porcentaje del salario.
    /// "40%" -> 40% del salario; "4000" -> 4000 pesos. El resultado se acota
    /// al rango 0...salario para mantener coherencia con el slider.
    private func interpretar(_ entrada: String) -> Double {
        let limpio = entrada
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: "$", with: "")
            .trimmingCharacters(in: .whitespaces)

        let valor: Double
        if limpio.hasSuffix("%") {
            let numero = Double(limpio.dropLast()) ?? 0
            valor = salario * numero / 100
        } else {
            valor = Double(limpio) ?? 0
        }
        return min(max(valor, 0), max(salario, 0))
    }
}
