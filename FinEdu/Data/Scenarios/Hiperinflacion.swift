//
//  Hiperinflacion.swift
//  FinEdu
//
//  Escenario 3: Hiperinflación. Escenario genérico inspirado en casos reales
//  documentados (Venezuela 2017-2019, con ecos de Argentina y Zimbabue).
//  Datos: BCV (inflación 2018: 130,060%), criterio de Cagan (hiperinflación =
//  >50% mensual), reconversión monetaria de agosto de 2018.
//

import Foundation

extension CatalogoEscenarios {

    static let hiperinflacion = Escenario(
        id: "hiperinflacion",
        titulo: "Hiperinflación",
        subtitulo: "Cuando el dinero se derrite",
        periodo: "Inspirado en 2017 – 2021",
        contextoHistorico: """
        Vives en un país cuya moneda empieza a perder valor a una velocidad que \
        nadie de tu generación ha visto. Este escenario está inspirado en casos \
        reales y documentados — Venezuela llegó a 130,060% de inflación anual en \
        2018 según su propio banco central — pero le puede pasar a cualquier \
        economía mal manejada: ya pasó en Alemania (1923), Hungría (1946), \
        Zimbabue (2008) y Argentina (1989). \
        Tienes un pequeño negocio y ahorros en moneda local. Cada día que pasa, \
        ese dinero compra menos. El reloj corre.
        """,
        fuentesDatos: [
            "Banco Central de Venezuela: inflación 2018 de 130,060% anual",
            "Criterio de Cagan (1956): se considera hiperinflación cuando la inflación supera 50% MENSUAL",
            "Reconversión monetaria de Venezuela (20 de agosto de 2018): se eliminaron 5 ceros al bolívar",
            "Ecoanalítica: ~54% de las transacciones en Venezuela se realizaban en dólares hacia finales de 2019",
        ],
        perfil: PerfilJugador(
            rol: "Comerciante joven",
            descripcion: "Tienes 26 años y una pequeña tienda de abarrotes. Tus ahorros están en moneda local, en el banco. Tu mercancía es tu otro capital.",
            ingresoMensual: 30_000,
            ahorrosIniciales: 200_000,
            deudaInicial: 0,
            simboloMoneda: "Bs.",
            nombreMoneda: "bolívares (moneda local)"
        ),
        turnos: [
            Turno(
                id: 1,
                titulo: "El umbral de la hiperinflación",
                evento: """
                Los precios subieron 50% ESTE MES. Los economistas dicen que el país \
                acaba de cruzar el umbral técnico de la hiperinflación. En tu tienda ya \
                no sabes a cómo reponer la mercancía: lo que vendes hoy no alcanza para \
                recomprarlo mañana. Tus ahorros de toda la vida están en el banco, en \
                moneda local. ¿Qué haces con ellos esta misma semana?
                """,
                datoHistorico: "Según el criterio clásico de Cagan (1956), hay hiperinflación cuando los precios suben más de 50% en UN MES. Venezuela cruzó ese umbral en noviembre de 2017.",
                inflacionDelTurno: 60,
                efectos: [
                    .conservadora: EfectoDecision(
                        rangoCambioPatrimonio: -40...(-25), cambioLiquidez: 0, puntosResiliencia: -8,
                        narrativa: "Dejaste tus ahorros 'seguros' en el banco. En hiperinflación no existe esa seguridad: tu dinero sigue ahí, completo en números… pero cada semana compra la mitad. La prudencia de tiempos normales aquí es la decisión más cara."),
                    .moderada: EfectoDecision(
                        rangoCambioPatrimonio: -20...(-8), cambioLiquidez: -10, puntosResiliencia: 5,
                        narrativa: "Convertiste una parte a dólares y mercancía, y dejaste solo lo mínimo en moneda local. Vas tarde — siempre se va tarde — pero cada billete convertido es valor rescatado del incendio."),
                    .arriesgada: EfectoDecision(
                        rangoCambioPatrimonio: -5...10, cambioLiquidez: -25, puntosResiliencia: 8,
                        narrativa: "Vaciaste la cuenta y lo convertiste casi todo en dólares y mercancía para tu tienda. En cualquier país estable sería una locura; aquí es supervivencia financiera pura."),
                    .muyArriesgada: EfectoDecision(
                        rangoCambioPatrimonio: -25...15, cambioLiquidez: -35, puntosResiliencia: -3,
                        narrativa: "Además de convertir todo, te endeudaste para comprar más mercancía especulando con la escasez. Si calculas bien, la inflación licúa tu deuda; si no, te quedas sin liquidez en plena tormenta."),
                ],
                conceptosFavorables: [.dolarizacion, .activosReales],
                conceptosDesfavorables: [.ahorro, .liquidez],
                ajustePorConcepto: 5,
                conceptoPrincipal: .inflacion
            ),
            Turno(
                id: 2,
                titulo: "Los precios se duplican",
                evento: """
                Los precios ahora se duplican cada 25 días. En tu tienda remarcas \
                precios dos veces por semana y aun así pierdes. La gente cobra y corre \
                el mismo día a comprar comida, herramientas, lo que sea que conserve \
                valor. Aparece el trueque. Tu mercancía vale más cada día que el dinero \
                de venderla. ¿Cómo manejas tu negocio?
                """,
                datoHistorico: "En el pico de la hiperinflación venezolana (2018), los precios se duplicaban aproximadamente cada 19-26 días (estimaciones del FMI y Cato Institute).",
                inflacionDelTurno: 80,
                efectos: [
                    .conservadora: EfectoDecision(
                        rangoCambioPatrimonio: -45...(-30), cambioLiquidez: 5, puntosResiliencia: -8,
                        narrativa: "Seguiste vendiendo normal y guardando el efectivo de las ventas. Resultado brutal: vendes tu mercancía real a cambio de papel que se evapora. Tu tienda se está vaciando a cámara lenta."),
                    .moderada: EfectoDecision(
                        rangoCambioPatrimonio: -18...(-6), cambioLiquidez: -5, puntosResiliencia: 6,
                        narrativa: "Empezaste a reponer mercancía el MISMO día que vendes y a guardar el excedente en dólares. Tu dinero ya no duerme en bolívares: aprendiste que aquí la velocidad es rentabilidad."),
                    .arriesgada: EfectoDecision(
                        rangoCambioPatrimonio: 0...12, cambioLiquidez: -15, puntosResiliencia: 8,
                        narrativa: "Convertiste tu capital de trabajo en inventario no perecedero y cobras parte en dólares o en especie. Tu tienda se volvió tu mejor 'cuenta de ahorro': los activos reales no se devalúan con el papel."),
                    .muyArriesgada: EfectoDecision(
                        rangoCambioPatrimonio: -20...18, cambioLiquidez: -30, puntosResiliencia: -3,
                        narrativa: "Acaparaste mercancía masivamente apostando a la escasez. Puede salir muy bien… o atraer multas, robos y quedarte sin un solo billete líquido para emergencias. Filo de navaja."),
                ],
                conceptosFavorables: [.activosReales, .dolarizacion, .inversion],
                conceptosDesfavorables: [.liquidez, .ahorro],
                ajustePorConcepto: 5,
                conceptoPrincipal: .activosReales
            ),
            Turno(
                id: 3,
                titulo: "Controles y mercado paralelo",
                evento: """
                El gobierno responde con controles: precios máximos obligatorios (a veces \
                por debajo de tu costo), control de cambios y multas por 'especulación'. \
                Comprar dólares legalmente es casi imposible; el mercado paralelo cobra \
                el triple de la tasa oficial. Vender al precio oficial es perder dinero; \
                no vender es arriesgar una multa. ¿Qué camino tomas?
                """,
                datoHistorico: "Venezuela mantuvo control de cambios desde 2003 hasta 2019. La brecha entre el dólar oficial y el paralelo llegó a superar 10 veces. Los controles de precios produjeron escasez de ~80% en productos básicos (2016-2017).",
                inflacionDelTurno: 100,
                efectos: [
                    .conservadora: EfectoDecision(
                        rangoCambioPatrimonio: -35...(-20), cambioLiquidez: 5, puntosResiliencia: -3,
                        narrativa: "Cumpliste los precios oficiales al pie de la letra, vendiendo a pérdida. Evitaste multas, pero tu capital se encoge con cada venta: el control de precios te convirtió en donador involuntario."),
                    .moderada: EfectoDecision(
                        rangoCambioPatrimonio: -15...(-5), cambioLiquidez: 0, puntosResiliencia: 7,
                        narrativa: "Rotaste tu catálogo hacia productos sin precio controlado y diversificaste proveedores. Es la jugada del comerciante que sobrevive: adaptarse a las reglas sin quemarse en ellas."),
                    .arriesgada: EfectoDecision(
                        rangoCambioPatrimonio: -10...10, cambioLiquidez: -10, puntosResiliencia: 2,
                        narrativa: "Compraste dólares en el paralelo para proteger tu capital, pagando caro. El sobreprecio duele, pero menos que la inflación de 100% del periodo. Protegerse ya no es gratis."),
                    .muyArriesgada: EfectoDecision(
                        rangoCambioPatrimonio: -30...12, cambioLiquidez: -20, puntosResiliencia: -8,
                        narrativa: "Apostaste todo al arbitraje entre la tasa oficial y la paralela. Algunos se enriquecieron así; otros perdieron todo en un decomiso. Rentabilidad que depende de no ser atrapado no es estrategia, es ruleta."),
                ],
                conceptosFavorables: [.diversificacion, .activosReales],
                conceptosDesfavorables: [.panicoFinanciero],
                ajustePorConcepto: 4,
                conceptoPrincipal: .liquidez
            ),
            Turno(
                id: 4,
                titulo: "Le quitan cinco ceros",
                evento: """
                El gobierno anuncia una 'reconversión monetaria': le quitan CINCO CEROS \
                a la moneda y le cambian el nombre. 1,000,000 de bolívares viejos = 10 \
                nuevos. Prometen que esto 'derrota la inflación'. Hay días feriados \
                bancarios y confusión total con los precios. Tu instinto te dice que ya \
                viste esta película. ¿Qué haces durante la transición?
                """,
                datoHistorico: "El 20 de agosto de 2018, Venezuela eliminó 5 ceros de su moneda (ya había quitado 3 en 2008; quitaría otros 6 en 2021: 14 ceros en total). La inflación NO se detuvo: 2018 cerró en 130,060% (BCV).",
                inflacionDelTurno: 120,
                efectos: [
                    .conservadora: EfectoDecision(
                        rangoCambioPatrimonio: -40...(-25), cambioLiquidez: 0, puntosResiliencia: -5,
                        narrativa: "Creíste en la promesa oficial y volviste a confiar en la moneda local 'nueva'. Quitarle ceros a un billete no le quita la causa a la inflación: en semanas, los ceros empezaron a regresar."),
                    .moderada: EfectoDecision(
                        rangoCambioPatrimonio: -15...(-5), cambioLiquidez: -5, puntosResiliencia: 6,
                        narrativa: "Usaste el feriado bancario para convertir lo que quedaba en moneda local a dólares y mercancía. La reconversión fue cosmética, y tú ya no juegas con dinero de utilería."),
                    .arriesgada: EfectoDecision(
                        rangoCambioPatrimonio: 0...10, cambioLiquidez: -10, puntosResiliencia: 7,
                        narrativa: "Para este punto, tu patrimonio vive en dólares, inventario y equipo. La reconversión te dio igual: cuando tu riqueza está en activos reales, los ceros del billete son anécdota."),
                    .muyArriesgada: EfectoDecision(
                        rangoCambioPatrimonio: -15...15, cambioLiquidez: -20, puntosResiliencia: -2,
                        narrativa: "Especulaste con el caos de la transición comprando deudas y activos confundidos de precio. Operar en la niebla puede dar ganancias rápidas, pero un error de cálculo aquí no tiene deshacer."),
                ],
                conceptosFavorables: [.dolarizacion, .activosReales],
                conceptosDesfavorables: [.ahorro],
                ajustePorConcepto: 5,
                conceptoPrincipal: .devaluacion
            ),
            Turno(
                id: 5,
                titulo: "Dolarización de facto",
                evento: """
                La economía se rinde ante la evidencia: aunque nadie lo decreta, más de \
                la mitad de las compras ya se hacen en dólares. Llegan remesas de \
                familiares en el extranjero. En tu tienda, los clientes pagan con \
                billetes de dólar arrugados y hasta por transferencia extranjera. La \
                moneda local quedó para el transporte y el menudeo. ¿Cómo reorganizas \
                tu negocio y tu patrimonio?
                """,
                datoHistorico: "Hacia finales de 2019, ~54% de las transacciones en Venezuela se hacían en dólares (Ecoanalítica). Las remesas se volvieron sostén de millones de familias (~$3,500-4,000 mdd anuales estimados).",
                inflacionDelTurno: 90,
                efectos: [
                    .conservadora: EfectoDecision(
                        rangoCambioPatrimonio: -25...(-12), cambioLiquidez: 5, puntosResiliencia: -2,
                        narrativa: "Seguiste operando mayormente en moneda local 'por costumbre y por miedo a multas'. Cada día que tardaste en dolarizar tu flujo fue un pequeño impuesto pagado a la inercia."),
                    .moderada: EfectoDecision(
                        rangoCambioPatrimonio: -5...5, cambioLiquidez: 5, puntosResiliencia: 8,
                        narrativa: "Dolarizaste precios y cobros, y mantienes solo el mínimo en moneda local para cambios. Tu negocio por fin volvió a tener algo parecido a estabilidad: ya puedes planear a un mes."),
                    .arriesgada: EfectoDecision(
                        rangoCambioPatrimonio: 5...15, cambioLiquidez: -10, puntosResiliencia: 8,
                        narrativa: "Reinvertiste en el negocio cobrando 100% en dólares: más inventario, un congelador, mejores proveedores. En una economía dolarizada, el que tiene capital en dólares y activos productivos lidera la recuperación."),
                    .muyArriesgada: EfectoDecision(
                        rangoCambioPatrimonio: -10...18, cambioLiquidez: -25, puntosResiliencia: 0,
                        narrativa: "Tomaste deuda en dólares para expandirte agresivamente. Ojo: deber en moneda dura con ingresos aún mixtos es un riesgo cambiario inverso — ahora la deuda es la que no se devalúa."),
                ],
                conceptosFavorables: [.dolarizacion, .diversificacion, .inversion],
                conceptosDesfavorables: [.panicoFinanciero],
                ajustePorConcepto: 4,
                conceptoPrincipal: .dolarizacion
            ),
            Turno(
                id: 6,
                titulo: "Reconstruir sobre las cenizas",
                evento: """
                Años después, la inflación baja de miles por ciento a 'solo' tres \
                dígitos. La economía, ya dolarizada de facto, encuentra un piso. \
                Sobreviviste a la hiperinflación y tu negocio sigue de pie — eso ya te \
                pone en minoría. Ahora toca reconstruir: ¿cómo armas tus finanzas para \
                que NUNCA más un colapso de la moneda te tome desprotegido?
                """,
                datoHistorico: "La inflación venezolana bajó de >130,000% (2018) a ~234% en 2022 (BCV), con la economía operando mayoritariamente en dólares. La recuperación parcial llegó solo tras la dolarización de facto.",
                inflacionDelTurno: 40,
                efectos: [
                    .conservadora: EfectoDecision(
                        rangoCambioPatrimonio: 0...5, cambioLiquidez: 10, puntosResiliencia: 6,
                        narrativa: "Construiste un fondo de emergencia en moneda dura, fuera del alcance del próximo experimento monetario. La lección quedó grabada: la moneda es del gobierno, el patrimonio es tuyo."),
                    .moderada: EfectoDecision(
                        rangoCambioPatrimonio: 3...10, cambioLiquidez: 0, puntosResiliencia: 10,
                        narrativa: "Fondo de emergencia en dólares + inventario productivo + algo invertido afuera. Diversificación entre monedas, activos y geografías: el manual antifrágil del que ya sobrevivió una vez."),
                    .arriesgada: EfectoDecision(
                        rangoCambioPatrimonio: 2...12, cambioLiquidez: -10, puntosResiliencia: 5,
                        narrativa: "Expandiste el negocio aprovechando que la competencia quebró. Crecer en la salida de una crisis es comprar barato — solo cuida no volver a concentrar todo en un solo activo."),
                    .muyArriesgada: EfectoDecision(
                        rangoCambioPatrimonio: -12...10, cambioLiquidez: -20, puntosResiliencia: -5,
                        narrativa: "Apostaste fuerte a que 'lo peor ya pasó'. Quizá sí. Pero apostar el patrimonio completo a UNA predicción macroeconómica fue exactamente lo que arruinó a tantos en 2017. ¿Aprendimos?"),
                ],
                conceptosFavorables: [.fondoDeEmergencia, .diversificacion, .ahorro],
                conceptosDesfavorables: [.deuda],
                ajustePorConcepto: 4,
                conceptoPrincipal: .fondoDeEmergencia
            ),
        ],
        icono: "flame"
    )
}
