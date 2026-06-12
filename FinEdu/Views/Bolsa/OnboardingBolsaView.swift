//
//  OnboardingBolsaView.swift
//  FinEdu
//
//  Onboarding del Simulador de Bolsa (primera vez). Dos pasos:
//  1. ¿Cuál es tu presupuesto total? (capital/ahorros, input numérico en USD).
//  2. La IA on-device recomienda cuánto destinar a bolsa; el usuario lo ve en
//     un slider/campo editable y puede aceptarlo o cambiarlo antes de empezar.
//
//  Al confirmar se crea la CarteraBolsa en SwiftData con el cash inicial.
//  Moneda: USD (se simplifica contra los precios reales de las acciones).
//

import SwiftUI
import SwiftData

struct OnboardingBolsaView: View {
    /// Se llama tras crear la cartera, para que el contenedor muestre el simulador.
    var alCompletar: () -> Void

    @Environment(\.modelContext) private var contexto

    private enum Paso { case presupuesto, recomendacion }
    @State private var paso: Paso = .presupuesto

    @State private var presupuestoTexto = ""
    @State private var presupuesto: Double = 0
    @State private var cargando = false
    @State private var recomendacion: RecomendacionPresupuesto?
    @State private var montoAsignado: Double = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                encabezado

                switch paso {
                case .presupuesto:
                    pasoPresupuesto
                case .recomendacion:
                    pasoRecomendacion
                }

                disclaimer
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Simulador de bolsa")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Encabezado

    private var encabezado: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.largeTitle)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            Text("Antes de empezar")
                .font(.title2.bold())
            Text("Vas a practicar invirtiendo en empresas reales con datos históricos, desde junio de 2023. Primero definamos con cuánto juegas.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Paso 1: presupuesto total

    private var pasoPresupuesto: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("¿Cuál es tu presupuesto total?")
                .font(.headline)
            Text("Tu capital o ahorros totales (en Pesos). No te preocupes: en el siguiente paso decidimos cuánto de eso conviene poner en bolsa.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack {
                Text("$")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
                TextField("Ej. 10000", text: $presupuestoTexto)
                    .keyboardType(.decimalPad)
                    .font(.title3)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Presupuesto total en dólares")
            }

            Button {
                continuarAPresupuesto()
            } label: {
                Text("Continuar")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(presupuestoValido == nil)
            .accessibilityHint("Genera una recomendación de cuánto invertir")
        }
    }

    private var presupuestoValido: Double? {
        let limpio = presupuestoTexto.replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)
        guard let valor = Double(limpio), valor > 0 else { return nil }
        return valor
    }

    private func continuarAPresupuesto() {
        guard let valor = presupuestoValido else { return }
        presupuesto = valor
        paso = .recomendacion
        Task { await generarRecomendacion() }
    }

    // MARK: - Paso 2: recomendación editable

    private var pasoRecomendacion: some View {
        VStack(alignment: .leading, spacing: 16) {
            if cargando {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Calculando una recomendación para ti…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if let recomendacion {
                tarjetaRecomendacion(recomendacion)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Monto a invertir en bolsa")
                    .font(.headline)
                Text(montoAsignado.comoMoneda(simbolo: "$"))
                    .font(.largeTitle.bold())
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .accessibilityLabel("Monto a invertir: \(Int(montoAsignado)) dólares")

                Slider(value: $montoAsignado, in: 0...max(presupuesto, 1), step: 1)
                    .disabled(cargando)
                    .accessibilityValue("\(Int(montoAsignado)) de \(Int(presupuesto)) dólares")

                HStack {
                    Text("$0")
                    Spacer()
                    Text("Total: \(presupuesto.comoMoneda(simbolo: "$"))")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                Text("Este monto será tu efectivo inicial, 100% líquido. Podrás comprar acciones cuando quieras.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Button {
                empezar()
            } label: {
                Text("Empezar a invertir")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(cargando || montoAsignado <= 0)
            .accessibilityHint("Crea tu cartera y abre el simulador en junio de 2023")
        }
    }

    private func tarjetaRecomendacion(_ rec: RecomendacionPresupuesto) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Recomendación", systemImage: "sparkles")
                    .font(.headline)
                Spacer()
                IndicadorMotorIA(motor: rec.motor)
            }
            Text("Sugerimos invertir \(rec.monto.comoMoneda(simbolo: "$")) (\(Int(rec.porcentaje * 100))% de tu capital).")
                .font(.subheadline.weight(.semibold))
            Text(rec.explicacion)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }

    private func generarRecomendacion() async {
        cargando = true
        let rec = await RecomendadorPresupuesto.recomendar(presupuestoTotal: presupuesto)
        recomendacion = rec
        montoAsignado = rec.monto
        cargando = false
    }

    private func empezar() {
        let cartera = CarteraBolsa(presupuestoTotal: presupuesto,
                                   montoAsignado: montoAsignado,
                                   cashActual: montoAsignado,
                                   mesActual: 0,
                                   onboardingCompletado: true)
        contexto.insert(cartera)
        try? contexto.save()
        alCompletar()
    }

    // MARK: - Disclaimer

    private var disclaimer: some View {
        Text("Simulador educativo con datos históricos. No es asesoría de inversión.")
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 8)
    }
}

#Preview {
    NavigationStack {
        OnboardingBolsaView(alCompletar: {})
    }
    .modelContainer(for: [CarteraBolsa.self, Holding.self, Transaccion.self, SnapshotMensual.self],
                    inMemory: true)
}
