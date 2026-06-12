//
//  EnrutadorApp.swift
//  FinEdu
//
//  Enrutador compartido para navegación dirigida desde fuera de las vistas
//  (App Intents / Siri / Spotlight). Un App Intent corre fuera del árbol de
//  SwiftUI, así que deja aquí el escenario solicitado y la vista raíz observa
//  este objeto para hacer el push correspondiente.
//

import Foundation
import Observation

/// Destino navegable hacia una partida concreta. Tipo dedicado (en vez de
/// String suelto) para que `navigationDestination(for:)` no colisione con
/// otros valores de tipo String que se empujen a la pila.
struct RutaEscenario: Hashable {
    let escenarioID: String
}

@MainActor
@Observable
final class EnrutadorApp {
    /// Singleton: los App Intents no reciben dependencias inyectadas.
    static let shared = EnrutadorApp()

    /// Escenario que un App Intent pidió abrir; la vista raíz lo consume,
    /// navega y lo vuelve a poner en nil.
    var escenarioPendienteID: String?

    private init() {}
}
