//
//  SimulacionBolsaView.swift
//  FinEdu
//
//  Punto de entrada del Simulador de Bolsa. Decide entre el onboarding (la
//  primera vez) y el simulador propiamente dicho, según si ya existe una
//  CarteraBolsa con el onboarding completado en SwiftData.
//

import SwiftUI
import SwiftData

struct SimulacionBolsaView: View {
    // Cartera activa = la más reciente con onboarding completado. @Query se
    // actualiza solo cuando el onboarding inserta la cartera.
    @Query(sort: \CarteraBolsa.fechaCreacion, order: .reverse) private var carteras: [CarteraBolsa]

    private var carteraActiva: CarteraBolsa? {
        carteras.first { $0.onboardingCompletado }
    }

    var body: some View {
        if let cartera = carteraActiva {
            SimuladorBolsaView(cartera: cartera)
        } else {
            OnboardingBolsaView(alCompletar: {})
        }
    }
}

#Preview {
    NavigationStack { SimulacionBolsaView() }
        .modelContainer(for: [CarteraBolsa.self, Holding.self, Transaccion.self, SnapshotMensual.self],
                        inMemory: true)
}
