//
//  FinEduApp.swift
//  FinEdu — Simulador de resiliencia financiera
//
//  Punto de entrada de la app. Decisión técnica: usamos SwiftData como capa de
//  persistencia 100% local (sin red, requisito del hackathon) para guardar
//  partidas, historial de decisiones y conceptos del glosario desbloqueados.
//

import SwiftUI
import SwiftData

@main
struct FinEduApp: App {
    /// Bandera persistente para mostrar el onboarding solo la primera vez.
    /// @AppStorage es suficiente para un booleano simple; SwiftData se reserva
    /// para datos estructurados (partidas, decisiones, glosario).
    @AppStorage("onboardingCompletado") private var onboardingCompletado = false

    var body: some Scene {
        WindowGroup {
            if onboardingCompletado {
                ContenedorPrincipalView()
            } else {
                OnboardingView()
            }
        }
        // El contenedor de SwiftData se inyecta en todo el árbol de vistas.
        // Incluye los modelos del modo de crisis y los del Simulador de Bolsa.
        .modelContainer(for: [Partida.self, DecisionGuardada.self, ConceptoDesbloqueado.self,
                              CarteraBolsa.self, Holding.self, Transaccion.self, SnapshotMensual.self])
    }
}

/// Vista raíz después del onboarding: el menú principal con los dos modos
/// (selección de crisis y simulación de bolsa). Además escucha al enrutador
/// para abrir una crisis directamente cuando un App Intent / Siri lo pide.
struct ContenedorPrincipalView: View {
    @State private var ruta = NavigationPath()
    private let enrutador = EnrutadorApp.shared

    var body: some View {
        NavigationStack(path: $ruta) {
            MenuPrincipalView()
                .navigationDestination(for: RutaEscenario.self) { destino in
                    if let escenario = CatalogoEscenarios.porID(destino.escenarioID) {
                        JuegoView(escenario: escenario)
                    }
                }
        }
        // Deep link desde Siri / Spotlight: empuja la partida solicitada.
        .onChange(of: enrutador.escenarioPendienteID) { _, nuevo in
            if let id = nuevo {
                ruta.append(RutaEscenario(escenarioID: id))
                enrutador.escenarioPendienteID = nil
            }
        }
    }
}
