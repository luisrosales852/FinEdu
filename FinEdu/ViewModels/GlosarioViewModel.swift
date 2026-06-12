//
//  GlosarioViewModel.swift
//  FinEdu
//
//  ViewModel del glosario. La vista obtiene los desbloqueos con @Query
//  (SwiftData); este ViewModel concentra la lógica de presentación:
//  filtrado por búsqueda y orden (desbloqueados primero).
//

import Foundation
import Observation

@Observable
final class GlosarioViewModel {

    var textoBusqueda = ""

    /// Conceptos ordenados: desbloqueados primero, luego alfabético.
    func conceptosOrdenados(desbloqueados: Set<ConceptoEconomico>) -> [ConceptoEconomico] {
        let filtrados = ConceptoEconomico.allCases.filter { concepto in
            guard !textoBusqueda.isEmpty else { return true }
            let consulta = ClasificadorRiesgo.normalizar(textoBusqueda)
            return ClasificadorRiesgo.normalizar(concepto.nombre).contains(consulta)
        }
        return filtrados.sorted { a, b in
            let aDesbloqueado = desbloqueados.contains(a)
            let bDesbloqueado = desbloqueados.contains(b)
            if aDesbloqueado != bDesbloqueado { return aDesbloqueado }
            return a.nombre < b.nombre
        }
    }

    func progreso(desbloqueados: Set<ConceptoEconomico>) -> Double {
        Double(desbloqueados.count) / Double(ConceptoEconomico.allCases.count)
    }
}
