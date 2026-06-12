//
//  EntrenarClasificador.swift
//  FinEdu — script de entrenamiento (se ejecuta en macOS, NO es parte de la app)
//
//  Entrena el clasificador de riesgo de decisiones financieras (capa 2 de la
//  arquitectura de IA) con Create ML y lo exporta como
//  ModeloRiesgoFinanciero.mlmodel.
//
//  USO (desde la carpeta Training/):
//      swift EntrenarClasificador.swift
//
//  Decisión técnica: MLTextClassifier con algoritmo maxEnt e idioma español.
//  Con ~160 ejemplos el entrenamiento tarda segundos y el modelo pesa unos
//  cuantos KB — perfecto para incluirlo en el bundle de la app.
//

import Foundation
import CreateML
import NaturalLanguage

let directorio = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let datasetURL = directorio.appendingPathComponent("dataset_decisiones.csv")
let salidaURL = directorio.appendingPathComponent("ModeloRiesgoFinanciero.mlmodel")

print("📚 Cargando dataset: \(datasetURL.path)")
let datos = try MLDataTable(contentsOf: datasetURL)
print("   \(datos.rows.count) ejemplos etiquetados")

// 85% entrenamiento / 15% prueba, con semilla fija para reproducibilidad.
let (entrenamiento, prueba) = datos.randomSplit(by: 0.85, seed: 42)

let parametros = MLTextClassifier.ModelParameters(
    algorithm: .maxEnt(revision: nil),
    language: .spanish
)

print("🧠 Entrenando MLTextClassifier (maxEnt, español)…")
let clasificador = try MLTextClassifier(trainingData: entrenamiento,
                                        textColumn: "texto",
                                        labelColumn: "etiqueta",
                                        parameters: parametros)

// Métricas
let errorEntrenamiento = clasificador.trainingMetrics.classificationError
let evaluacion = clasificador.evaluation(on: prueba,
                                         textColumn: "texto",
                                         labelColumn: "etiqueta")
let precision = (1.0 - evaluacion.classificationError) * 100
print(String(format: "   Precisión en prueba: %.1f%% (error de entrenamiento: %.3f)",
             precision, errorEntrenamiento))

// Pruebas rápidas de cordura
let ejemplos = [
    "Guardaré mi dinero en el banco",
    "Invertiré una parte en cetes y guardaré el resto",
    "Pondré mis ahorros en un negocio de comida",
    "Pediré un préstamo para apostarlo en la bolsa",
]
print("🔎 Predicciones de ejemplo:")
for ejemplo in ejemplos {
    let etiqueta = (try? clasificador.prediction(from: ejemplo)) ?? "?"
    print("   \"\(ejemplo)\" → \(etiqueta)")
}

let metadata = MLModelMetadata(
    author: "Equipo FinEdu",
    shortDescription: "Clasifica decisiones financieras en español por nivel de riesgo (conservadora, moderada, arriesgada, muy_arriesgada). Entrenado con Create ML para la capa 2 de FinEdu.",
    version: "1.0"
)

try clasificador.write(to: salidaURL, metadata: metadata)
print("✅ Modelo exportado en: \(salidaURL.path)")
print("   Cópialo a FinEdu/Resources/ y recompila la app.")
