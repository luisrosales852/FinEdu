//
//  BudgetClassifier.swift
//  FinEdu
//
//  Lógica de clasificación del presupuesto, 100% en el dispositivo. Mismo
//  patrón de degradación que el resto de la app:
//
//  Vía A) Si el bundle incluye un modelo de Create ML (ModeloPresupuesto.mlmodel
//         → compilado a .mlmodelc), se carga con NLModel y se le pasa la
//         distribución como cadena estructurada ("renta:40 comida:10 ...").
//         Las instrucciones y el dataset están en Training/.
//
//  Vía B) Si el modelo no está, un clasificador basado en reglas financieras
//         (la regla 50/30/20) decide el estado. SIEMPRE disponible, sin red.
//
//  En ambos casos las reglas calculan qué categorías son problemáticas y la
//  retroalimentación contextual: el modelo solo aporta (si existe) la etiqueta.
//

import Foundation
import CoreML
import NaturalLanguage

struct BudgetClassifier {

    /// Modelo de Create ML cargado del bundle (si existe). Opcional: la app
    /// funciona perfectamente sin él gracias a las reglas.
    private let modeloNL: NLModel?

    init() {
        // Xcode compilaría ModeloPresupuesto.mlmodel → ModeloPresupuesto.mlmodelc.
        if let url = Bundle.main.url(forResource: "ModeloPresupuesto", withExtension: "mlmodelc"),
           let modelo = try? MLModel(contentsOf: url),
           let nl = try? NLModel(mlModel: modelo) {
            modeloNL = nl
        } else {
            modeloNL = nil
        }
    }

    /// Analiza una distribución de presupuesto y devuelve el resultado completo.
    /// - Parameters:
    ///   - salario: salario mensual simulado en MXN (> 0).
    ///   - montos: monto asignado a cada categoría en MXN.
    func clasificar(salario: Double, montos: [CategoriaPresupuesto: Double]) -> ResultadoPresupuesto {
        // 1. Porcentaje de cada categoría respecto al salario.
        let porcentajes = Self.porcentajes(salario: salario, montos: montos)

        // 2. Análisis determinista por reglas: estado + categorías problemáticas.
        let analisis = analizarPorReglas(porcentajes: porcentajes)

        // 3. Si hay modelo de Core ML, su etiqueta tiene prioridad para el estado.
        var clasificacion = analisis.clasificacion
        var motor: MotorIA = .reglasConLexico
        if let modeloNL,
           let etiqueta = modeloNL.predictedLabel(for: Self.cadenaEstructurada(porcentajes)),
           let estado = ClasificacionPresupuesto(rawValue: etiqueta) {
            clasificacion = estado
            motor = .reglasConCoreML
        }

        // 4. Meses de colchón financiero estimados (educativo, ver más abajo).
        let meses = Self.mesesDeColchon(montos: montos)

        // 5. Retroalimentación: mensaje principal + consejos por categoría.
        let principal = PlantillasFeedback.principal(para: clasificacion, mesesDeColchon: meses)
        let consejos = analisis.problematicas.map { PlantillasFeedback.consejo(para: $0) }

        return ResultadoPresupuesto(clasificacion: clasificacion,
                                    motor: motor,
                                    porcentajes: porcentajes,
                                    categoriasProblematicas: analisis.problematicas,
                                    mesesDeColchon: meses,
                                    feedbackPrincipal: principal,
                                    consejos: consejos)
    }

    // MARK: - Cálculos auxiliares

    /// Porcentaje (0–100+) de cada categoría respecto al salario.
    static func porcentajes(salario: Double, montos: [CategoriaPresupuesto: Double]) -> [CategoriaPresupuesto: Double] {
        guard salario > 0 else { return [:] }
        var resultado: [CategoriaPresupuesto: Double] = [:]
        for categoria in CategoriaPresupuesto.allCases {
            resultado[categoria] = (montos[categoria] ?? 0) / salario * 100
        }
        return resultado
    }

    /// Cadena estructurada que recibe el modelo de Create ML, p. ej.:
    /// "renta:40 comida:10 ahorro:5 entretenimiento:25 transporte:10 otros:10".
    /// El orden es fijo para que coincida con el formato del dataset.
    static func cadenaEstructurada(_ porcentajes: [CategoriaPresupuesto: Double]) -> String {
        let orden: [CategoriaPresupuesto] = [.renta, .alimentacion, .ahorro,
                                             .entretenimiento, .transporte, .otros]
        return orden
            .map { "\($0.claveModelo):\(Int((porcentajes[$0] ?? 0).rounded()))" }
            .joined(separator: " ")
    }

    /// Meses de colchón financiero (proxy educativo): si el usuario sostuviera
    /// este ritmo de ahorro durante un año, ¿cuántos meses de gastos esenciales
    /// podría cubrir sin ingresos? = (ahorro mensual × 12) / gastos esenciales.
    static func mesesDeColchon(montos: [CategoriaPresupuesto: Double]) -> Int {
        let ahorroMensual = montos[.ahorro] ?? 0
        let esenciales = (montos[.renta] ?? 0) + (montos[.alimentacion] ?? 0) + (montos[.transporte] ?? 0)
        guard esenciales > 0 else { return 0 }
        let meses = ahorroMensual * 12 / esenciales
        return max(0, Int(meses.rounded()))
    }

    // MARK: - Clasificador por reglas (regla 50/30/20)

    /// Aplica las mejores prácticas financieras conocidas y devuelve el estado
    /// y la lista de categorías problemáticas. Funciona siempre, sin modelo.
    private func analizarPorReglas(porcentajes: [CategoriaPresupuesto: Double]) -> (clasificacion: ClasificacionPresupuesto, problematicas: [CategoriaPresupuesto]) {
        let ahorro = porcentajes[.ahorro] ?? 0
        let renta = porcentajes[.renta] ?? 0
        let entretenimiento = porcentajes[.entretenimiento] ?? 0
        let otros = porcentajes[.otros] ?? 0

        // Gasto total que NO es ahorro: si supera el 100% del salario, el
        // usuario está gastando más de lo que gana.
        let gastoNoAhorro = CategoriaPresupuesto.allCases
            .filter { $0 != .ahorro }
            .reduce(0.0) { $0 + (porcentajes[$1] ?? 0) }

        var problematicas: [CategoriaPresupuesto] = []
        var puntos = 0

        // Ahorro bajo: la regla 50/30/20 sugiere ~20%.
        if ahorro < 5 {
            puntos += 2
            problematicas.append(.ahorro)
        } else if ahorro < 10 {
            puntos += 1
            problematicas.append(.ahorro)
        }

        // Vivienda cara: lo ideal es ~30%; alerta por encima del 35%.
        if renta > 45 {
            puntos += 2
            problematicas.append(.renta)
        } else if renta > 35 {
            puntos += 1
            problematicas.append(.renta)
        }

        // Entretenimiento (un "deseo"): alerta por encima del 25%.
        if entretenimiento > 40 {
            puntos += 2
            problematicas.append(.entretenimiento)
        } else if entretenimiento > 25 {
            puntos += 1
            problematicas.append(.entretenimiento)
        }

        // Imprevistos demasiado altos pueden esconder gasto sin control.
        if otros > 25 {
            puntos += 1
            problematicas.append(.otros)
        }

        // Decisión final del estado.
        let gastaDeMas = gastoNoAhorro > 100.5
        let sinAhorro = ahorro < 1
        let clasificacion: ClasificacionPresupuesto
        if gastaDeMas || (sinAhorro && gastoNoAhorro >= 95) || puntos >= 5 {
            clasificacion = .critico
        } else if puntos >= 2 {
            clasificacion = .riesgoso
        } else {
            clasificacion = .sostenible
        }

        return (clasificacion, problematicas)
    }
}

// MARK: - Plantillas de retroalimentación

/// Textos de retroalimentación "de la IA". Decisión de producto: el mensaje
/// principal de cada estado está redactado a mano y conecta con una crisis
/// histórica real (vinculación con el modo de "Selección de crisis"). Los
/// consejos por categoría se añaden según lo que detectaron las reglas.
enum PlantillasFeedback {

    /// Mensaje principal según el estado clasificado.
    static func principal(para clasificacion: ClasificacionPresupuesto, mesesDeColchon meses: Int) -> String {
        switch clasificacion {
        case .sostenible:
            return """
            Tu distribución se acerca a la regla 50/30/20. Con este nivel de \
            ahorro, podrías sobrevivir hasta \(meses) \(meses == 1 ? "mes" : "meses") \
            sin ingresos ante una crisis como la de 2008.
            """
        case .riesgoso:
            return """
            Gastas más del 40% en entretenimiento y menos del 10% en ahorro. \
            Durante períodos de inflación alta (como México 2022), esto puede \
            erosionar tu poder adquisitivo rápidamente.
            """
        case .critico:
            return """
            Sin fondo de emergencia y con gastos superiores al ingreso, una \
            crisis como el 'Error de Diciembre' de 1994 podría dejarte sin \
            capacidad de respuesta financiera.
            """
        }
    }

    /// Consejo puntual para una categoría detectada como problemática.
    static func consejo(para categoria: CategoriaPresupuesto) -> String {
        switch categoria {
        case .ahorro:
            return "Tu ahorro es bajo. Intenta acercarte al 20% para construir un fondo de emergencia."
        case .renta:
            return "La vivienda consume una porción alta de tu ingreso (más del 35%). Lo ideal es mantenerla cerca del 30%."
        case .entretenimiento:
            return "El entretenimiento supera lo recomendado. Reducirlo libera dinero para ahorrar e invertir."
        case .otros:
            return "Tus 'imprevistos' son altos. Revisa en qué se va este dinero para poder planearlo mejor."
        case .alimentacion:
            return "Revisa tu gasto en alimentación: cocinar en casa suele liberar presupuesto."
        case .transporte:
            return "El transporte pesa en tu presupuesto. Evalúa alternativas más económicas."
        }
    }
}
