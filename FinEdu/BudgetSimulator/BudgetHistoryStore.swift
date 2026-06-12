//
//  BudgetHistoryStore.swift
//  FinEdu
//
//  Persistencia de las últimas 3 simulaciones de presupuesto. Decisión técnica:
//  UserDefaults + Codable (JSON) en vez de SwiftData. Son pocos registros, sin
//  relaciones, y así no hay que tocar el modelContainer de FinEduApp. Todo
//  queda en el dispositivo; la app no tiene ninguna conexión de red.
//

import Foundation
import Observation

/// Almacén observable del historial de presupuestos. La UI lo observa con
/// @State / @Bindable y se actualiza al guardar.
@MainActor
@Observable
final class BudgetHistoryStore {

    /// Máximo de simulaciones que se conservan (las más recientes).
    static let maximo = 3

    private static let clave = "historialPresupuestos"

    /// Historial actual, de la más reciente a la más antigua.
    private(set) var entradas: [BudgetEntry] = []

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        cargar()
    }

    /// Guarda una nueva simulación, conservando solo las últimas 3.
    func guardar(_ entrada: BudgetEntry) {
        entradas.insert(entrada, at: 0)
        if entradas.count > Self.maximo {
            entradas = Array(entradas.prefix(Self.maximo))
        }
        persistir()
    }

    /// Borra todo el historial (útil para pruebas o reinicio).
    func borrarTodo() {
        entradas = []
        persistir()
    }

    // MARK: - Lectura/escritura en UserDefaults

    private func cargar() {
        guard let datos = defaults.data(forKey: Self.clave),
              let decodificado = try? JSONDecoder().decode([BudgetEntry].self, from: datos) else {
            entradas = []
            return
        }
        entradas = decodificado
    }

    private func persistir() {
        if let datos = try? JSONEncoder().encode(entradas) {
            defaults.set(datos, forKey: Self.clave)
        }
    }
}
