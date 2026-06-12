//
//  BudgetSimulatorView.swift
//  FinEdu
//
//  Contenedor principal del "Simulador de Presupuesto Personal Mensual".
//  Flujo: 1) capturar salario, 2) repartirlo entre las 6 categorías, 3) la IA
//  on-device clasifica la distribución (SOSTENIBLE / RIESGOSO / CRÍTICO) y
//  4) muestra retroalimentación contextual. Guarda las últimas 3 simulaciones.
//
//  Todo es 100% en el dispositivo: no hay llamadas de red ni APIs externas.
//
//  Layout adaptable iPhone/iPad: las categorías usan un LazyVGrid con columnas
//  adaptativas (1 columna en iPhone, 2 en iPad) y el resultado se reordena con
//  ViewThatFits (ver BudgetResultView).
//

import SwiftUI

struct BudgetSimulatorView: View {
    // MARK: - Estado

    /// Flujo en dos pasos (como el Simulador de Bolsa): primero el salario,
    /// luego el reparto entre categorías con el salario fijado arriba.
    private enum Paso { case salario, reparto }
    @State private var paso: Paso = .salario

    @State private var salarioTexto = ""
    @State private var salario: Double = 0
    /// Monto asignado a cada categoría (MXN).
    @State private var montos: [CategoriaPresupuesto: Double] = [:]
    /// Resultado del último análisis; nil mientras el usuario edita.
    @State private var resultado: ResultadoPresupuesto?

    /// Historial persistente (UserDefaults) de las últimas 3 simulaciones.
    @State private var historial = BudgetHistoryStore()

    /// Clasificador on-device (reglas + Core ML opcional). Sin estado mutable.
    private let clasificador = BudgetClassifier()

    // MARK: - Derivados

    private var totalAsignado: Double {
        montos.values.reduce(0, +)
    }

    private var totalPorcentaje: Double {
        salario > 0 ? totalAsignado / salario * 100 : 0
    }

    /// Diferencia respecto al 100% del salario (positiva = falta por asignar).
    private var restante: Double {
        salario - totalAsignado
    }

    private var puedeAnalizar: Bool {
        salario > 0 && totalAsignado > 0
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                switch paso {
                case .salario:
                    intro

                    SalaryInputView(salarioTexto: $salarioTexto, salario: $salario)
                        .onChange(of: salario) { _, _ in resultado = nil }

                    botonContinuar

                case .reparto:
                    resumenSalario

                    seccionCategorias
                    bannerValidacion
                    botonAnalizar

                    if let resultado {
                        BudgetResultView(resultado: resultado, salario: salario, montos: montos)
                            // Aparición animada: escala + opacidad.
                            .transition(.scale(scale: 0.9).combined(with: .opacity))
                    }
                }

                if !historial.entradas.isEmpty {
                    seccionHistorial
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Presupuesto mensual")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Paso 1 → Paso 2

    /// Avanza al reparto. Se habilita solo cuando ya hay un salario válido.
    private var botonContinuar: some View {
        Button {
            withAnimation(.snappy) { paso = .reparto }
        } label: {
            Text("Continuar")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(salario <= 0)
        .accessibilityHint("Continúa para repartir tu salario entre las categorías")
    }

    /// Resumen del salario elegido, fijado arriba durante el reparto, con un
    /// botón para volver a editarlo (regresa al paso 1).
    private var resumenSalario: some View {
        HStack(spacing: 12) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.title2)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Salario mensual")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(salario.comoMoneda(simbolo: "$")) MXN")
                    .font(.title3.bold().monospacedDigit())
                    .contentTransition(.numericText())
            }
            Spacer()
            Button {
                withAnimation(.snappy) { paso = .salario }
            } label: {
                Label("Cambiar", systemImage: "pencil")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.bordered)
            .accessibilityHint("Vuelve a editar tu salario mensual")
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Salario mensual: \(Int(salario)) pesos. Toca Cambiar para editarlo.")
    }

    // MARK: - Intro

    private var intro: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "chart.pie.fill")
                .font(.largeTitle)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            Text("Arma tu presupuesto del mes")
                .font(.title2.bold())
            Text("Reparte tu salario entre las 6 categorías. Una IA en tu dispositivo analizará tus hábitos y te dirá qué tan sostenible es tu plan.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Categorías

    private var seccionCategorias: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("¿Cómo repartes tu salario?")
                .font(.headline)
            Text("Escribe un monto (\"4000\") o un porcentaje (\"40%\"), o usa el deslizador.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            // 1 columna en iPhone, 2 en iPad (columnas adaptativas).
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 16)], spacing: 16) {
                ForEach(CategoriaPresupuesto.allCases) { categoria in
                    CategorySliderView(categoria: categoria,
                                       salario: salario,
                                       monto: binding(para: categoria))
                }
            }
        }
    }

    /// Binding al monto de una categoría que, al cambiar, invalida el resultado
    /// previo (para no mostrar una clasificación que ya no corresponde).
    private func binding(para categoria: CategoriaPresupuesto) -> Binding<Double> {
        Binding(
            get: { montos[categoria] ?? 0 },
            set: { nuevo in
                montos[categoria] = nuevo
                if resultado != nil { resultado = nil }
            }
        )
    }

    // MARK: - Validación en tiempo real

    @ViewBuilder
    private var bannerValidacion: some View {
        // Aviso cuando la suma no llega o se pasa del 100% del salario.
        if abs(restante) >= 1 {
            let falta = restante > 0
            Label {
                Text(falta
                     ? "Te faltan \(restante.comoMoneda(simbolo: "$")) por asignar (\(Int(totalPorcentaje.rounded()))% del salario)."
                     : "Te pasaste \((-restante).comoMoneda(simbolo: "$")) del salario (\(Int(totalPorcentaje.rounded()))%).")
            } icon: {
                Image(systemName: falta ? "exclamationmark.circle.fill" : "exclamationmark.triangle.fill")
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(falta ? .orange : .red)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background((falta ? Color.orange : Color.red).opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 12))
            .accessibilityLabel(falta
                ? "Te faltan \(Int(restante)) pesos por asignar"
                : "Te pasaste \(Int(-restante)) pesos del salario")
        } else {
            Label("Tu reparto suma el 100% del salario.", systemImage: "checkmark.circle.fill")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.green)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Botón analizar

    private var botonAnalizar: some View {
        Button {
            analizar()
        } label: {
            Label("Analizar mi presupuesto", systemImage: "sparkles")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(!puedeAnalizar)
        .accessibilityHint("La IA del dispositivo clasifica tu presupuesto y te da retroalimentación")
    }

    private func analizar() {
        guard puedeAnalizar else { return }
        // El clasificador es síncrono y ligero (reglas + modelo opcional).
        let nuevo = clasificador.clasificar(salario: salario, montos: montos)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            resultado = nuevo
        }
        guardarEnHistorial(nuevo)
    }

    private func guardarEnHistorial(_ resultado: ResultadoPresupuesto) {
        let categorias = Dictionary(uniqueKeysWithValues:
            montos.map { ($0.key.rawValue, $0.value) })
        let entrada = BudgetEntry(salario: salario,
                                  categorias: categorias,
                                  clasificacion: resultado.clasificacion.rawValue)
        historial.guardar(entrada)
    }

    // MARK: - Historial (últimas 3)

    private var seccionHistorial: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tus últimas simulaciones")
                .font(.headline)
            ForEach(historial.entradas) { entrada in
                FilaHistorialPresupuesto(entrada: entrada)
            }
        }
        .padding(.top, 4)
    }
}

/// Fila compacta de una simulación guardada en el historial.
private struct FilaHistorialPresupuesto: View {
    let entrada: BudgetEntry

    private var clasificacion: ClasificacionPresupuesto { entrada.clasificacionEnum }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: clasificacion.icono)
                .foregroundStyle(clasificacion.color)
                .frame(width: 32)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(clasificacion.titulo)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(clasificacion.color)
                Text("Salario \(entrada.salario.comoMoneda(simbolo: "$")) · \(entrada.fecha.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Simulación \(clasificacion.titulo), salario \(Int(entrada.salario)) pesos, \(entrada.fecha.formatted(date: .abbreviated, time: .shortened))")
    }
}

#Preview {
    NavigationStack {
        BudgetSimulatorView()
    }
}
