//
//  IndicadorMotorIA.swift
//  FinEdu
//
//  Chip discreto que indica qué motor de IA está activo (capa 1: Foundation
//  Models, o capa 2: Create ML/NaturalLanguage). Al tocarlo muestra el
//  diagnóstico de disponibilidad — pensado para explicar la arquitectura a
//  los jueces en plena demo sin abrir el código.
//

import SwiftUI

struct IndicadorMotorIA: View {
    let motor: MotorIA
    @State private var mostrarDetalle = false

    var body: some View {
        Button {
            mostrarDetalle = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: motor.esGenerativo ? "sparkles" : "cpu")
                Text(motor.esGenerativo ? "IA generativa" : "IA clásica")
            }
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.tint.opacity(0.12), in: Capsule())
        }
        .accessibilityLabel("Motor de inteligencia artificial activo: \(motor.rawValue)")
        .accessibilityHint("Muestra detalles de la arquitectura de IA en el dispositivo")
        .popover(isPresented: $mostrarDetalle) {
            VStack(alignment: .leading, spacing: 12) {
                Label("IA 100% en tu dispositivo", systemImage: "lock.shield.fill")
                    .font(.headline)
                Text("Motor activo: \(motor.rawValue).")
                    .font(.subheadline.weight(.semibold))
                Text(FabricaMotorIA.diagnostico)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Ninguna decisión que escribas sale de tu iPhone: no hay servidores, ni nube, ni conexión de red.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(idealWidth: 320)
            .presentationCompactAdaptation(.popover)
        }
    }
}
