//
//  AtajosApp.swift
//  FinEdu
//
//  Integración con App Intents: expone las crisis como entidades buscables
//  para que el usuario abra una simulación directamente desde Siri, Spotlight,
//  el botón de acción o la app Atajos — sin abrir antes la app.
//

import AppIntents

/// Una crisis jugable, expuesta al sistema (Siri / Spotlight / Atajos).
struct EscenarioEntity: AppEntity {
    let id: String
    let titulo: String
    let subtitulo: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Crisis"

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(titulo)", subtitle: "\(subtitulo)")
    }

    static var defaultQuery = EscenarioQuery()
}

/// Provee las entidades al sistema desde el catálogo estático.
struct EscenarioQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [EscenarioEntity] {
        identifiers.compactMap { id in
            CatalogoEscenarios.porID(id).map(EscenarioEntity.init(escenario:))
        }
    }

    func suggestedEntities() async throws -> [EscenarioEntity] {
        CatalogoEscenarios.todos.map(EscenarioEntity.init(escenario:))
    }
}

private extension EscenarioEntity {
    init(escenario: Escenario) {
        self.init(id: escenario.id, titulo: escenario.titulo, subtitulo: escenario.subtitulo)
    }
}

/// Abre la app y navega directamente a la crisis elegida.
struct AbrirCrisisIntent: AppIntent {
    static var title: LocalizedStringResource = "Abrir una crisis"
    static var description = IntentDescription("Empieza a jugar una crisis económica en FinEdu.")
    static var openAppWhenRun = true

    @Parameter(title: "Crisis")
    var crisis: EscenarioEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        EnrutadorApp.shared.escenarioPendienteID = crisis.id
        return .result()
    }
}

/// Frases para invocar la acción por voz, y su presencia en Spotlight.
struct AtajosFinEdu: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AbrirCrisisIntent(),
            phrases: [
                "Jugar una crisis en \(.applicationName)",
                "Abrir una crisis en \(.applicationName)",
                "Empezar una simulación en \(.applicationName)"
            ],
            shortTitle: "Abrir crisis",
            systemImageName: "chart.line.downtrend.xyaxis"
        )
    }
}
