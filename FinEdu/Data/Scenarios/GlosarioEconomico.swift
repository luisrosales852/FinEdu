//
//  GlosarioEconomico.swift
//  FinEdu
//
//  Definiciones del glosario educativo. Se desbloquean conforme el jugador
//  encuentra cada concepto en sus partidas (persistido con SwiftData).
//  Las definiciones están redactadas para jóvenes sin formación financiera
//  (ODS 4: Educación de Calidad).
//

import Foundation

extension ConceptoEconomico {
    /// Definición breve y accesible del concepto.
    var definicion: String {
        switch self {
        case .inflacion:
            return "Aumento generalizado y sostenido de los precios. Si los precios suben 50% y tu dinero sigue igual, en realidad te volviste 33% más pobre: compras menos con lo mismo."
        case .devaluacion:
            return "Pérdida de valor de una moneda frente a otras. Cuando el peso se devalúa, todo lo importado (y lo que depende de importaciones) se encarece de golpe."
        case .diversificacion:
            return "No poner todos los huevos en la misma canasta: repartir tu dinero entre distintos activos (efectivo, inversiones, moneda extranjera) para que una sola crisis no te quite todo."
        case .liquidez:
            return "Qué tan rápido puedes convertir lo que tienes en dinero para gastarlo. Una casa vale mucho pero es poco líquida; el efectivo es 100% líquido pero la inflación se lo come."
        case .tasaDeInteres:
            return "El precio del dinero. Si pides prestado, es lo que pagas de más; si ahorras o inviertes, es lo que ganas. En crisis, las tasas pueden dispararse y volver impagables las deudas."
        case .deuda:
            return "Dinero que debes y que cobra intereses. Es una herramienta: bien usada construye (un negocio, una casa); mal usada en una crisis con tasas altas, destruye patrimonios."
        case .ahorro:
            return "Ingresos que no gastas hoy para usarlos mañana. Es la base de la resiliencia financiera, pero OJO: ahorrar en una moneda que se devalúa o con alta inflación es perder en cámara lenta."
        case .inversion:
            return "Poner tu dinero a trabajar (negocio, bolsa, bonos) esperando que crezca. Implica riesgo: puede crecer más que la inflación… o perderse. El momento y la diversificación importan."
        case .dolarizacion:
            return "Refugiar tu dinero en una moneda más estable (típicamente dólares) cuando la moneda local pierde valor. Protege poder de compra, aunque puede tener costos y riesgos cambiarios."
        case .activosReales:
            return "Bienes físicos o productivos (inmuebles, mercancía, herramientas) que conservan valor cuando el dinero se devalúa, porque su precio sube junto con la inflación."
        case .panicoFinanciero:
            return "Decisiones tomadas por miedo colectivo: vender todo en el peor momento, sacar el dinero del banco en estampida. Históricamente, el pánico cristaliza las pérdidas en el punto más bajo."
        case .fondoDeEmergencia:
            return "Reserva líquida equivalente a 3–6 meses de gastos. Es tu amortiguador: te permite sobrevivir un despido o una crisis sin malvender tus activos ni endeudarte caro."
        }
    }

    /// Ejemplo histórico real que ancla el concepto (datos de los escenarios).
    var ejemploHistorico: String {
        switch self {
        case .inflacion:
            return "México 1995: la inflación anual llegó a 52%. Venezuela 2018: 130,060% según su propio banco central."
        case .devaluacion:
            return "México, diciembre de 1994: el peso pasó de 3.4 a más de 7 por dólar en tres meses (~50% de pérdida de valor)."
        case .diversificacion:
            return "En 2008, quien tenía TODO en vivienda o acciones perdió hasta 57%; quien diversificó amortiguó el golpe."
        case .liquidez:
            return "En 2008-2009, millones no pudieron vender su casa para pagar deudas: el mercado inmobiliario se congeló."
        case .tasaDeInteres:
            return "México, marzo de 1995: los Cetes a 28 días pagaban más de 80% anual y las tarjetas cobraban arriba de 100%."
        case .deuda:
            return "Crisis de 1995: miles de familias mexicanas perdieron casas y autos cuando sus deudas a tasa variable se volvieron impagables."
        case .ahorro:
            return "Venezuela 2017-2019: los ahorros en bolívares perdieron prácticamente todo su valor en menos de dos años."
        case .inversion:
            return "Quien invirtió en el S&P 500 en marzo de 2009 (el fondo de la crisis) ganó más de 60% en los 12 meses siguientes."
        case .dolarizacion:
            return "Venezuela 2019: ante la hiperinflación, más de la mitad de las transacciones pasaron a hacerse en dólares."
        case .activosReales:
            return "En hiperinflaciones, la gente convierte su dinero en mercancía, herramientas o inmuebles el mismo día que cobra."
        case .panicoFinanciero:
            return "29 de septiembre de 2008: el Dow Jones cayó 777 puntos en un día; quien vendió ahí compró el pánico y vendió barato."
        case .fondoDeEmergencia:
            return "EUA 2009: con desempleo de 10%, las familias con reserva de 6 meses evitaron rematar casas e inversiones."
        }
    }
}
