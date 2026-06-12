//
//  BudgetResultView.swift
//  FinEdu
//
//  Tarjeta de resultado del análisis: clasificación (con tema de color), gráfica
//  de dona (Swift Charts) con el desglose por categoría, leyenda con porcentajes
//  y la tarjeta de retroalimentación. La aparición se anima (escala + opacidad).
//
//  Layout adaptable iPhone/iPad: en pantallas anchas la dona y la leyenda van
//  lado a lado (ViewThatFits elige el arreglo que quepa); en iPhone se apilan.
//

import SwiftUI
import Charts

struct BudgetResultView: View {
    let resultado: ResultadoPresupuesto
    let salario: Double
    let montos: [CategoriaPresupuesto: Double]

    /// Categorías con monto > 0, ordenadas de mayor a menor (para la dona/leyenda).
    private var segmentos: [(categoria: CategoriaPresupuesto, monto: Double)] {
        CategoriaPresupuesto.allCases
            .compactMap { cat in
                let monto = montos[cat] ?? 0
                return monto > 0 ? (cat, monto) : nil
            }
            .sorted { $0.monto > $1.monto }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            encabezadoClasificacion

            // Dona + leyenda, adaptativo según ancho disponible.
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 24) {
                    dona
                        .frame(width: 200, height: 200)
                    leyenda
                }
                VStack(spacing: 20) {
                    dona
                        .frame(height: 220)
                    leyenda
                }
            }

            BudgetFeedbackCard(resultado: resultado)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(resultado.clasificacion.color.opacity(0.08),
                    in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(resultado.clasificacion.color.opacity(0.4), lineWidth: 1.5)
        )
    }

    // MARK: - Encabezado con la clasificación

    private var encabezadoClasificacion: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: resultado.clasificacion.icono)
                    .font(.largeTitle)
                    .foregroundStyle(resultado.clasificacion.color)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(resultado.clasificacion.titulo)
                        .font(.title2.bold())
                        .foregroundStyle(resultado.clasificacion.color)
                    Text(resultado.clasificacion.resumen)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                IndicadorMotorIA(motor: resultado.motor)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Clasificación: \(resultado.clasificacion.titulo). \(resultado.clasificacion.resumen)")
    }

    // MARK: - Gráfica de dona (Swift Charts)

    private var dona: some View {
        Chart(segmentos, id: \.categoria) { segmento in
            SectorMark(
                angle: .value("Monto", segmento.monto),
                innerRadius: .ratio(0.6),
                angularInset: 1.5
            )
            .cornerRadius(4)
            .foregroundStyle(segmento.categoria.color)
        }
        .chartLegend(.hidden) // usamos nuestra propia leyenda con porcentajes
        .accessibilityLabel("Distribución del presupuesto por categoría")
        .accessibilityValue(resumenAccesible)
    }

    /// Leyenda textual: icono + nombre + porcentaje por categoría.
    private var leyenda: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(segmentos, id: \.categoria) { segmento in
                let pct = salario > 0 ? segmento.monto / salario * 100 : 0
                HStack(spacing: 10) {
                    Image(systemName: segmento.categoria.icono)
                        .font(.footnote)
                        .foregroundStyle(segmento.categoria.color)
                        .frame(width: 20)
                        .accessibilityHidden(true)
                    Text(segmento.categoria.nombre)
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(pct.rounded()))%")
                        .font(.subheadline.bold().monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(segmento.categoria.nombre): \(Int(pct.rounded())) por ciento, \(segmento.monto.comoMoneda(simbolo: "$")) pesos")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Resumen para VoiceOver del contenido de la dona.
    private var resumenAccesible: String {
        segmentos.map { seg in
            let pct = salario > 0 ? seg.monto / salario * 100 : 0
            return "\(seg.categoria.nombre) \(Int(pct.rounded()))%"
        }.joined(separator: ", ")
    }
}
