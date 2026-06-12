//
//  Persistencia.swift
//  FinEdu
//
//  Modelos de SwiftData (@Model). Decisión técnica: SwiftData (iOS 17+) en
//  lugar de Core Data por su integración directa con SwiftUI (@Query) y cero
//  boilerplate — ideal para las 20 horas del hackathon. Todo se guarda en el
//  dispositivo; la app no tiene ninguna conexión de red.
//

import Foundation
import SwiftData

/// Una partida jugada (completa o abandonada).
@Model
final class Partida {
    var escenarioID: String
    var fecha: Date
    var completada: Bool
    var scoreFinal: Int
    var patrimonioFinal: Double
    var patrimonioInicial: Double
    var inflacionAcumulada: Double
    /// Nombre del motor de IA usado (interesante para comparar partidas).
    var motorUtilizado: String

    /// Historial de decisiones; cascade: al borrar la partida se borran.
    @Relationship(deleteRule: .cascade, inverse: \DecisionGuardada.partida)
    var decisiones: [DecisionGuardada] = []

    init(escenarioID: String,
         fecha: Date = .now,
         completada: Bool = false,
         scoreFinal: Int = 0,
         patrimonioFinal: Double = 0,
         patrimonioInicial: Double = 0,
         inflacionAcumulada: Double = 0,
         motorUtilizado: String = "") {
        self.escenarioID = escenarioID
        self.fecha = fecha
        self.completada = completada
        self.scoreFinal = scoreFinal
        self.patrimonioFinal = patrimonioFinal
        self.patrimonioInicial = patrimonioInicial
        self.inflacionAcumulada = inflacionAcumulada
        self.motorUtilizado = motorUtilizado
    }

    var escenario: Escenario? { CatalogoEscenarios.porID(escenarioID) }
}

/// Una decisión de texto libre del usuario y cómo fue evaluada.
@Model
final class DecisionGuardada {
    var numeroTurno: Int
    var textoUsuario: String
    /// rawValue de NivelRiesgo.
    var nivelRiesgo: String
    var cambioPatrimonio: Double
    var leccion: String
    var partida: Partida?

    init(numeroTurno: Int,
         textoUsuario: String,
         nivelRiesgo: String,
         cambioPatrimonio: Double,
         leccion: String) {
        self.numeroTurno = numeroTurno
        self.textoUsuario = textoUsuario
        self.nivelRiesgo = nivelRiesgo
        self.cambioPatrimonio = cambioPatrimonio
        self.leccion = leccion
    }
}

/// Concepto del glosario desbloqueado al encontrarlo jugando.
@Model
final class ConceptoDesbloqueado {
    /// rawValue de ConceptoEconomico. @Attribute(.unique) evita duplicados.
    @Attribute(.unique) var conceptoID: String
    var fecha: Date

    init(conceptoID: String, fecha: Date = .now) {
        self.conceptoID = conceptoID
        self.fecha = fecha
    }

    var concepto: ConceptoEconomico? { ConceptoEconomico(rawValue: conceptoID) }
}
