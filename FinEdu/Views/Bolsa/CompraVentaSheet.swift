//
//  CompraVentaSheet.swift
//  FinEdu
//
//  Hoja para comprar o vender una empresa al precio del mes actual. Soporta
//  acciones FRACCIONARIAS y entrada por monto en dólares o por número de
//  acciones, para que cualquier presupuesto funcione (BRK.B o AVGO son caros).
//

import SwiftUI
import SwiftData

struct CompraVentaSheet: View {
    let vm: SimuladorBolsaViewModel
    let empresa: Company
    /// Se llama tras una operación exitosa (lo usa el coach de IA).
    var alOperar: (TipoTransaccion) -> Void = { _ in }

    @Environment(\.modelContext) private var contexto
    @Environment(\.dismiss) private var dismiss

    @State private var modo: TipoTransaccion = .compra
    /// true = el usuario ingresa dólares; false = número de acciones.
    @State private var porMonto = true
    @State private var texto = ""

    private var precio: Double { vm.precioActual(empresa.ticker) }
    private var holding: Holding? { vm.holding(empresa.ticker) }

    /// Número de acciones derivado de la entrada del usuario.
    private var cantidadAcciones: Double {
        let valor = Double(texto.replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)) ?? 0
        guard valor > 0 else { return 0 }
        return porMonto ? (precio > 0 ? valor / precio : 0) : valor
    }

    private var montoOperacion: Double { cantidadAcciones * precio }

    private var operacionValida: Bool {
        guard cantidadAcciones > 0 else { return false }
        switch modo {
        case .compra: return vm.puedeComprar(empresa.ticker, cantidad: cantidadAcciones)
        case .venta:  return cantidadAcciones <= (holding?.cantidad ?? 0) + 0.0000001
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                seccionEncabezado
                seccionModo
                seccionEntrada
                seccionResumen
                seccionDisclaimer
            }
            .navigationTitle(empresa.ticker)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var seccionEncabezado: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                Text(empresa.name).font(.headline)
                Text(empresa.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                LabeledContent("Precio (\(vm.mesActualLegible))",
                               value: precio.comoMoneda(simbolo: "$"))
                LabeledContent("Efectivo disponible",
                               value: vm.cartera.cashActual.comoMoneda(simbolo: "$"))
                if let holding {
                    LabeledContent("Tu posición",
                                   value: "\(formato(holding.cantidad)) acc · \(vm.valorPosicion(holding).comoMoneda(simbolo: "$"))")
                }
            }
        }
    }

    private var seccionModo: some View {
        Section {
            Picker("Operación", selection: $modo) {
                Text("Comprar").tag(TipoTransaccion.compra)
                Text("Vender").tag(TipoTransaccion.venta)
            }
            .pickerStyle(.segmented)
            .accessibilityHint("Elige si quieres comprar o vender")
            .onChange(of: modo) { _, _ in texto = "" }
        }
    }

    private var seccionEntrada: some View {
        Section {
            Picker("Ingresar por", selection: $porMonto) {
                Text("Monto ($)").tag(true)
                Text("Acciones").tag(false)
            }
            .pickerStyle(.segmented)

            HStack {
                Text(porMonto ? "$" : "#")
                    .foregroundStyle(.secondary)
                TextField(porMonto ? "Monto en dólares" : "Número de acciones", text: $texto)
                    .keyboardType(.decimalPad)
                    .accessibilityLabel(porMonto ? "Monto en dólares" : "Número de acciones")
            }

            HStack {
                ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { fraccion in
                    Button(fraccion == 1.0 ? "Máx" : "\(Int(fraccion * 100))%") {
                        aplicarFraccion(fraccion)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .frame(maxWidth: .infinity)
                }
            }
            .accessibilityHint("Rellena con una fracción del máximo disponible")
        } header: {
            Text(modo == .compra ? "¿Cuánto comprar?" : "¿Cuánto vender?")
        }
    }

    private var seccionResumen: some View {
        Section {
            LabeledContent("Acciones", value: formato(cantidadAcciones))
            LabeledContent(modo == .compra ? "Costo total" : "Recibirás",
                           value: montoOperacion.comoMoneda(simbolo: "$"))

            Button {
                ejecutar()
            } label: {
                Text(modo == .compra ? "Confirmar compra" : "Confirmar venta")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!operacionValida)
            .accessibilityHint(modo == .compra
                ? "Compra las acciones con tu efectivo"
                : "Vende las acciones y acredita el efectivo")
        }
    }

    private var seccionDisclaimer: some View {
        Section {
            Text("Simulador educativo con datos históricos. No es asesoría de inversión.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Acciones

    private func aplicarFraccion(_ fraccion: Double) {
        let maxAcciones: Double
        switch modo {
        case .compra: maxAcciones = vm.maximoComprable(empresa.ticker)
        case .venta:  maxAcciones = holding?.cantidad ?? 0
        }
        let acciones = maxAcciones * fraccion
        texto = porMonto ? formato(acciones * precio) : formato(acciones)
    }

    private func ejecutar() {
        let exito: Bool
        switch modo {
        case .compra: exito = vm.comprar(empresa.ticker, cantidad: cantidadAcciones, contexto: contexto)
        case .venta:  exito = vm.vender(empresa.ticker, cantidad: cantidadAcciones, contexto: contexto)
        }
        if exito {
            alOperar(modo)
            dismiss()
        }
    }

    private func formato(_ valor: Double) -> String {
        String(format: "%g", (valor * 10000).rounded() / 10000)
    }
}
