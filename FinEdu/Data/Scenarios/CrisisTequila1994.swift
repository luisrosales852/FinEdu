//
//  CrisisTequila1994.swift
//  FinEdu
//
//  Escenario 1: Crisis del Tequila (México, 1994-1996).
//  Todos los datos citados son históricos reales: Banco de México (tipo de
//  cambio, Cetes, reservas), INEGI (inflación, PIB, desempleo) y DOF (UDIs).
//

import Foundation

extension CatalogoEscenarios {

    static let crisisTequila1994 = Escenario(
        id: "tequila1994",
        titulo: "Crisis del Tequila",
        subtitulo: "México · El error de diciembre",
        periodo: "1994 – 1996",
        contextoHistorico: """
        Es noviembre de 1994. México acaba de firmar el TLCAN, la economía parece \
        sólida y el tipo de cambio lleva años estable (~3.4 pesos por dólar). Pero \
        bajo la superficie, las reservas internacionales del Banco de México \
        cayeron de 29,000 a menos de 13,000 millones de dólares en el año, y el \
        gobierno financió su gasto con Tesobonos indexados al dólar. \
        Tú eres un joven trabajador de la Ciudad de México. Lo que decidas en los \
        próximos meses definirá tu futuro financiero.
        """,
        fuentesDatos: [
            "Banco de México: series históricas de tipo de cambio FIX y tasas de Cetes 28 días",
            "INEGI: INPC (inflación 1995: 52.0%), PIB (-6.2% en 1995, +5.1% en 1996), ENEU (desempleo)",
            "Diario Oficial de la Federación: creación de las UDIs (1 de abril de 1995)",
        ],
        perfil: PerfilJugador(
            rol: "Joven trabajador en CDMX",
            descripcion: "Tienes 24 años, trabajo estable en una empresa mediana, ahorros en el banco y una deuda de tarjeta de crédito a tasa variable.",
            ingresoMensual: 3_000,
            ahorrosIniciales: 15_000,
            deudaInicial: 5_000,
            simboloMoneda: "$",
            nombreMoneda: "pesos (MXN)"
        ),
        turnos: [
            Turno(
                id: 1,
                titulo: "Calma tensa",
                evento: """
                Noviembre de 1994. En la oficina todos hablan de política, no de economía. \
                El dólar está a 3.44 pesos y el gobierno asegura que la paridad es sólida. \
                Pero tu tío, que vivió la crisis de 1982, te insiste: "el peso está \
                sobrevaluado, protégete". Acabas de cobrar tu aguinaldo. \
                ¿Qué haces con tus ahorros?
                """,
                datoHistorico: "Las reservas del Banco de México cayeron de ~29,000 mdd (febrero) a ~12,500 mdd (noviembre de 1994).",
                inflacionDelTurno: 1.0,
                efectos: [
                    .conservadora: EfectoDecision(
                        rangoCambioPatrimonio: -2...0, cambioLiquidez: 5, puntosResiliencia: 2,
                        narrativa: "Dejaste todo en pesos, en el banco. Por ahora no pasa nada: la calma de noviembre continúa y tu dinero está seguro… mientras la paridad aguante."),
                    .moderada: EfectoDecision(
                        rangoCambioPatrimonio: 0...3, cambioLiquidez: 0, puntosResiliencia: 6,
                        narrativa: "Repartiste tu dinero: una parte en pesos, otra en instrumentos distintos. No es espectacular, pero acabas de construir un escudo sin saberlo."),
                    .arriesgada: EfectoDecision(
                        rangoCambioPatrimonio: 0...6, cambioLiquidez: -10, puntosResiliencia: 4,
                        narrativa: "Moviste una parte importante de tus ahorros fuera del peso. Tus amigos se burlan: 'el dólar lleva años plano'. Diciembre les va a borrar la sonrisa."),
                    .muyArriesgada: EfectoDecision(
                        rangoCambioPatrimonio: -8...4, cambioLiquidez: -25, puntosResiliencia: -5,
                        narrativa: "Apostaste casi todo, incluso pensaste en endeudarte para invertir más. Quedaste sin colchón de efectivo justo antes del mes más peligroso en décadas."),
                ],
                conceptosFavorables: [.dolarizacion, .diversificacion, .fondoDeEmergencia],
                conceptosDesfavorables: [.deuda],
                ajustePorConcepto: 3,
                conceptoPrincipal: .diversificacion
            ),
            Turno(
                id: 2,
                titulo: "El error de diciembre",
                evento: """
                20 de diciembre de 1994. El gobierno amplía la banda cambiaria 15% y dos \
                días después deja flotar el peso. En cuestión de días el dólar pasa de \
                3.47 a más de 5 pesos; para marzo tocará 7.45. Todo lo importado se \
                dispara. En el banco hay filas de gente comprando dólares ya carísimos. \
                ¿Cómo reaccionas?
                """,
                datoHistorico: "El peso perdió ~50% de su valor entre el 19 de diciembre de 1994 y marzo de 1995 (Banco de México, tipo de cambio FIX: de 3.47 a 7.45).",
                inflacionDelTurno: 8.0,
                efectos: [
                    .conservadora: EfectoDecision(
                        rangoCambioPatrimonio: -12...(-6), cambioLiquidez: 5, puntosResiliencia: 0,
                        narrativa: "Te quedaste quieto, con tus pesos. No vendiste en pánico — eso es bueno —, pero cada semana tu dinero compra menos: la devaluación te alcanzó por omisión."),
                    .moderada: EfectoDecision(
                        rangoCambioPatrimonio: -6...0, cambioLiquidez: 0, puntosResiliencia: 5,
                        narrativa: "Tu parte diversificada amortiguó el golpe: lo que perdiste en pesos lo compensaste parcialmente. Aprendiste en carne propia para qué sirve no concentrar."),
                    .arriesgada: EfectoDecision(
                        rangoCambioPatrimonio: -2...10, cambioLiquidez: -5, puntosResiliencia: 4,
                        narrativa: "Si ya tenías dólares, hoy valen 50% más en pesos. Si apenas corriste a comprarlos, llegaste tarde y caro: el mercado ya había ajustado el precio del miedo."),
                    .muyArriesgada: EfectoDecision(
                        rangoCambioPatrimonio: -20...8, cambioLiquidez: -20, puntosResiliencia: -8,
                        narrativa: "Apostar fuerte en plena estampida es jugar volados con tu patrimonio: igual pudiste atinarle al dólar que quedarte atrapado en la bolsa, que se desplomó."),
                ],
                conceptosFavorables: [.dolarizacion, .diversificacion],
                conceptosDesfavorables: [.panicoFinanciero, .deuda],
                ajustePorConcepto: 4,
                conceptoPrincipal: .devaluacion
            ),
            Turno(
                id: 3,
                titulo: "Tasas por las nubes",
                evento: """
                Febrero-marzo de 1995. Para frenar la fuga de capitales, las tasas se \
                disparan: los Cetes pagan más de 80% anual y tu tarjeta de crédito ya \
                cobra arriba de 100%. Tu deuda de $5,000 crece sola cada mes. Miles de \
                familias dejan de pagar autos y casas. ¿Qué haces con tu deuda?
                """,
                datoHistorico: "Cetes a 28 días: 82.7% anual en marzo de 1995; la TIIE superó 100% en abril (Banco de México). La cartera vencida bancaria se triplicó.",
                inflacionDelTurno: 14.0,
                efectos: [
                    .conservadora: EfectoDecision(
                        rangoCambioPatrimonio: 2...8, cambioLiquidez: -10, puntosResiliencia: 10,
                        narrativa: "Sacrificaste gastos y liquidaste tu tarjeta. Dolió, pero acabas de 'ganar' 100% anual garantizado: cada peso de deuda pagada es interés que ya no te cobran."),
                    .moderada: EfectoDecision(
                        rangoCambioPatrimonio: -2...4, cambioLiquidez: 0, puntosResiliencia: 5,
                        narrativa: "Pagaste más del mínimo y renegociaste plazos. La deuda sigue ahí, pero dejó de crecer más rápido que tu sueldo. Sobrevivir también es estrategia."),
                    .arriesgada: EfectoDecision(
                        rangoCambioPatrimonio: -6...6, cambioLiquidez: -5, puntosResiliencia: -2,
                        narrativa: "Intentaste invertir aprovechando las tasas altas… con la tarjeta viva al 100%. Lo que los Cetes te dan por un lado, la tarjeta te lo arranca por el otro."),
                    .muyArriesgada: EfectoDecision(
                        rangoCambioPatrimonio: -25...(-10), cambioLiquidez: -15, puntosResiliencia: -12,
                        narrativa: "Pediste más crédito a tasa variable en el peor momento de la historia reciente para deber dinero. El interés compuesto ahora trabaja contra ti, a 100% anual."),
                ],
                conceptosFavorables: [.ahorro, .fondoDeEmergencia],
                conceptosDesfavorables: [.inversion, .panicoFinanciero],
                ajustePorConcepto: 3,
                conceptoPrincipal: .tasaDeInteres
            ),
            Turno(
                id: 4,
                titulo: "La recesión toca tu puerta",
                evento: """
                Mediados de 1995. La economía se contrae 6.2% en el año y el desempleo \
                se duplica. En tu empresa anuncian recorte de personal: te ofrecen \
                quedarte con sueldo congelado (con inflación de 52%, es un recorte \
                disfrazado) mientras tu gasto diario sube cada semana. \
                ¿Cómo proteges tu economía personal?
                """,
                datoHistorico: "PIB de México 1995: -6.2%; inflación anual: 52%; el desempleo abierto pasó de 3.7% a 7.4% entre 1994 y agosto de 1995 (INEGI).",
                inflacionDelTurno: 15.0,
                efectos: [
                    .conservadora: EfectoDecision(
                        rangoCambioPatrimonio: -4...0, cambioLiquidez: 10, puntosResiliencia: 8,
                        narrativa: "Recortaste gastos, armaste un fondo de emergencia y conservaste el empleo. Tu patrimonio resiente la inflación, pero duermes tranquilo: tienes oxígeno para meses."),
                    .moderada: EfectoDecision(
                        rangoCambioPatrimonio: -3...2, cambioLiquidez: 5, puntosResiliencia: 6,
                        narrativa: "Ajustaste el gasto y buscaste un ingreso extra de fin de semana. En una recesión, defender el flujo de efectivo mensual vale más que cualquier inversión."),
                    .arriesgada: EfectoDecision(
                        rangoCambioPatrimonio: -15...10, cambioLiquidez: -15, puntosResiliencia: -3,
                        narrativa: "Renunciaste para emprender en plena recesión. Hay quien lo logra — los negocios de consumo básico sobreviven —, pero arrancar cuando nadie tiene dinero es nadar contracorriente."),
                    .muyArriesgada: EfectoDecision(
                        rangoCambioPatrimonio: -30...(-5), cambioLiquidez: -25, puntosResiliencia: -10,
                        narrativa: "Apostaste tu liquidación y tus ahorros a un solo negocio sin reserva. Con el consumo desplomado, cada mes sin ventas se come tu patrimonio a mordidas de 52% anual."),
                ],
                conceptosFavorables: [.fondoDeEmergencia, .liquidez, .ahorro],
                conceptosDesfavorables: [.deuda],
                ajustePorConcepto: 3,
                conceptoPrincipal: .fondoDeEmergencia
            ),
            Turno(
                id: 5,
                titulo: "UDIs y reestructura",
                evento: """
                Abril de 1995. El gobierno crea las UDIs (unidades que crecen con la \
                inflación) para reestructurar deudas, y lanza programas de apoyo a \
                deudores. Las tasas siguen altas pero empiezan a bajar: los Cetes pagan \
                ~60% y la inflación va cediendo. Por primera vez en meses hay \
                instrumentos que le GANAN a la inflación. ¿Aprovechas?
                """,
                datoHistorico: "Las UDIs se crearon por decreto el 1 de abril de 1995 (DOF). Los Cetes pasaron de 82.7% (marzo) a ~48% al cierre de 1995, con inflación descendente: tasa real positiva.",
                inflacionDelTurno: 10.0,
                efectos: [
                    .conservadora: EfectoDecision(
                        rangoCambioPatrimonio: 0...4, cambioLiquidez: 5, puntosResiliencia: 4,
                        narrativa: "Mantuviste tu dinero a salvo y reestructuraste lo que debías. No exprimiste las tasas récord, pero consolidaste tu posición sin riesgo."),
                    .moderada: EfectoDecision(
                        rangoCambioPatrimonio: 2...8, cambioLiquidez: -5, puntosResiliencia: 8,
                        narrativa: "Metiste parte de tus ahorros a Cetes: con tasas de 60% e inflación bajando, tu dinero por fin crece MÁS rápido que los precios. Eso es tasa real positiva."),
                    .arriesgada: EfectoDecision(
                        rangoCambioPatrimonio: 0...12, cambioLiquidez: -15, puntosResiliencia: 4,
                        narrativa: "Invertiste fuerte en instrumentos de deuda gubernamental. El rendimiento es jugoso, aunque amarraste liquidez que podrías necesitar si la crisis se alarga."),
                    .muyArriesgada: EfectoDecision(
                        rangoCambioPatrimonio: -12...8, cambioLiquidez: -20, puntosResiliencia: -5,
                        narrativa: "Te fuiste con todo a la bolsa buscando 'la recuperación'. Llegará — pero nadie sabe cuándo —, y mientras tanto la volatilidad te tiene comiéndote las uñas."),
                ],
                conceptosFavorables: [.tasaDeInteres, .inversion, .ahorro],
                conceptosDesfavorables: [.panicoFinanciero],
                ajustePorConcepto: 3,
                conceptoPrincipal: .inflacion
            ),
            Turno(
                id: 6,
                titulo: "La recuperación exportadora",
                evento: """
                1996. Gracias al TLCAN y al peso barato, las exportaciones explotan y la \
                economía crece 5.1%. Las empresas vuelven a contratar y la bolsa rebota. \
                Quien sembró en lo peor de la crisis está cosechando. Con la lección \
                aprendida y tus finanzas más sanas: ¿cómo te posicionas para el futuro?
                """,
                datoHistorico: "PIB de México 1996: +5.1% (INEGI). Las exportaciones crecieron ~20% anual en 1995-1996 impulsadas por el TLCAN y el tipo de cambio competitivo.",
                inflacionDelTurno: 7.0,
                efectos: [
                    .conservadora: EfectoDecision(
                        rangoCambioPatrimonio: -3...1, cambioLiquidez: 5, puntosResiliencia: 0,
                        narrativa: "Te quedaste 100% en efectivo por miedo a otra crisis. Comprensible… pero la inflación de 1996 (27% anual) sigue mordiendo tu dinero quieto. La seguridad absoluta también cuesta."),
                    .moderada: EfectoDecision(
                        rangoCambioPatrimonio: 2...8, cambioLiquidez: 0, puntosResiliencia: 8,
                        narrativa: "Construiste un portafolio balanceado: fondo de emergencia + inversiones diversificadas. Es la jugada de libro de texto, y la que mejor envejece."),
                    .arriesgada: EfectoDecision(
                        rangoCambioPatrimonio: 5...15, cambioLiquidez: -10, puntosResiliencia: 5,
                        narrativa: "Invertiste en la recuperación — bolsa, un negocio, capacitación — y el viento sopla a favor: la economía crece 5% y tú con ella."),
                    .muyArriesgada: EfectoDecision(
                        rangoCambioPatrimonio: -5...18, cambioLiquidez: -20, puntosResiliencia: -3,
                        narrativa: "Otra vez todo a una sola carta. Esta vez el ciclo te favorece… pero no confundas un mercado alcista con ser invencible: la próxima crisis no avisará."),
                ],
                conceptosFavorables: [.inversion, .diversificacion, .activosReales],
                conceptosDesfavorables: [.panicoFinanciero],
                ajustePorConcepto: 3,
                conceptoPrincipal: .inversion
            ),
        ],
        icono: "banknote"
    )
}
