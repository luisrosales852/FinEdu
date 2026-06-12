//
//  CrisisGlobal2008.swift
//  FinEdu
//
//  Escenario 2: Crisis financiera global (2006-2012).
//  Datos históricos: S&P Case-Shiller (vivienda), S&P 500, BLS (desempleo),
//  registros públicos de la quiebra de Lehman Brothers.
//

import Foundation

extension CatalogoEscenarios {

    static let crisisGlobal2008 = Escenario(
        id: "global2008",
        titulo: "Crisis Global 2008",
        subtitulo: "La burbuja inmobiliaria",
        periodo: "2006 – 2012",
        contextoHistorico: """
        Es 2006 en Estados Unidos. Los precios de las casas llevan años subiendo \
        sin parar (+84% desde 2000) y los bancos regalan hipotecas: sin enganche, \
        sin comprobar ingresos, con tasas 'promocionales' que luego se disparan. \
        Todo el mundo repite el mantra: "los precios de la vivienda nunca bajan". \
        Tú y tu pareja tienen empleos estables y un buen ahorro. Las decisiones de \
        los próximos años pondrán a prueba todo lo que creen saber del dinero.
        """,
        fuentesDatos: [
            "Índice S&P/Case-Shiller: precios de vivienda en EUA +84% (2000-2006), caída ~27% (2006-2012)",
            "S&P 500: -38.5% en 2008; mínimo de 676 puntos el 9 de marzo de 2009 (-57% desde el máximo)",
            "Bureau of Labor Statistics: desempleo en EUA llegó a 10.0% en octubre de 2009",
            "Quiebra de Lehman Brothers (15 de septiembre de 2008): la mayor de la historia de EUA (~613 mil mdd en pasivos)",
        ],
        perfil: PerfilJugador(
            rol: "Familia joven en EUA",
            descripcion: "Pareja de 28 años, dos ingresos estables, ahorro sólido y una deuda pequeña de auto. Sueñan con casa propia.",
            ingresoMensual: 4_500,
            ahorrosIniciales: 25_000,
            deudaInicial: 5_000,
            simboloMoneda: "$",
            nombreMoneda: "dólares (USD)"
        ),
        turnos: [
            Turno(
                id: 1,
                titulo: "El sueño americano en oferta",
                evento: """
                2006. Un broker hipotecario les ofrece una casa de $300,000 sin enganche, \
                con una hipoteca de tasa ajustable que empieza baratísima. "Si no la \
                toman, en un año valdrá $350,000", presiona. Sus amigos ya compraron dos \
                propiedades 'para invertir'. ¿Qué hacen?
                """,
                datoHistorico: "Los precios de la vivienda en EUA subieron ~84% en términos reales entre 2000 y 2006 (Case-Shiller). Las hipotecas subprime llegaron a ser ~20% de las nuevas hipotecas en 2005-2006.",
                inflacionDelTurno: 3.2,
                efectos: [
                    .conservadora: EfectoDecision(
                        rangoCambioPatrimonio: 0...3, cambioLiquidez: 5, puntosResiliencia: 8,
                        narrativa: "Decidieron seguir rentando y ahorrando para un enganche real. El broker los miró con lástima. En tres años, esa 'lástima' va a cambiar de bando."),
                    .moderada: EfectoDecision(
                        rangoCambioPatrimonio: 0...4, cambioLiquidez: 0, puntosResiliencia: 6,
                        narrativa: "Pusieron un límite: solo comprarían con enganche del 20% y tasa fija que su sueldo aguante. No encontraron nada así de sensato en este mercado eufórico — y eso ya es una señal."),
                    .arriesgada: EfectoDecision(
                        rangoCambioPatrimonio: -2...8, cambioLiquidez: -20, puntosResiliencia: 0,
                        narrativa: "Compraron una casa modesta estirando las cuentas. En 2006 los precios aún suben, así que en papel van ganando… en papel."),
                    .muyArriesgada: EfectoDecision(
                        rangoCambioPatrimonio: -5...12, cambioLiquidez: -30, puntosResiliencia: -8,
                        narrativa: "Firmaron la hipoteca ajustable sin enganche, 'total, la casa se paga sola al subir'. Acaban de comprar el activo más caro de su vida con el dinero de otros y sin red de seguridad."),
                ],
                conceptosFavorables: [.ahorro, .fondoDeEmergencia, .liquidez],
                conceptosDesfavorables: [.deuda],
                ajustePorConcepto: 3,
                conceptoPrincipal: .deuda
            ),
            Turno(
                id: 2,
                titulo: "Primeras grietas",
                evento: """
                2007. Las hipotecas 'promocionales' se reajustan y millones no pueden \
                pagar. En abril quiebra New Century (gigante subprime); en agosto, BNP \
                Paribas congela fondos porque "no puede valuar" sus activos hipotecarios. \
                Los precios de las casas caen por primera vez en una década. Sus \
                inversiones y planes: ¿los mueven?
                """,
                datoHistorico: "En agosto de 2007 BNP Paribas congeló tres fondos con exposición subprime. Los precios de vivienda en EUA acumulaban caídas de ~5-10% desde el pico de 2006 (Case-Shiller).",
                inflacionDelTurno: 3.0,
                efectos: [
                    .conservadora: EfectoDecision(
                        rangoCambioPatrimonio: 0...4, cambioLiquidez: 10, puntosResiliencia: 8,
                        narrativa: "Reforzaron su fondo de emergencia y revisaron cada deuda. Mientras el mercado discute si es 'una corrección pasajera', ustedes ya tienen el paraguas abierto."),
                    .moderada: EfectoDecision(
                        rangoCambioPatrimonio: -2...3, cambioLiquidez: 5, puntosResiliencia: 6,
                        narrativa: "Rebalancearon: menos exposición a bienes raíces y financieras, más reserva líquida. No es vender por pánico, es ajustar las velas cuando cambia el viento."),
                    .arriesgada: EfectoDecision(
                        rangoCambioPatrimonio: -10...2, cambioLiquidez: -10, puntosResiliencia: -3,
                        narrativa: "'Comprar la caída': metieron dinero a acciones de bancos y constructoras porque 'ya están baratas'. Spoiler de 2008: lo barato puede abaratarse mucho más."),
                    .muyArriesgada: EfectoDecision(
                        rangoCambioPatrimonio: -20...(-5), cambioLiquidez: -20, puntosResiliencia: -8,
                        narrativa: "Se apalancaron para comprar otra propiedad 'en oferta'. Acaban de duplicar su apuesta en el activo exacto que está reventando, con dinero prestado."),
                ],
                conceptosFavorables: [.diversificacion, .liquidez, .fondoDeEmergencia],
                conceptosDesfavorables: [.deuda],
                ajustePorConcepto: 3,
                conceptoPrincipal: .diversificacion
            ),
            Turno(
                id: 3,
                titulo: "Septiembre negro",
                evento: """
                15 de septiembre de 2008: Lehman Brothers quiebra. El 29, el Dow cae 777 \
                puntos en un solo día. Los noticieros hablan de 'colapso del sistema \
                financiero'. Sus inversiones de retiro han perdido un tercio de su valor \
                y los vecinos están vendiendo todo. El teléfono no para: "¡saca tu \
                dinero antes de que no quede nada!" ¿Qué hacen?
                """,
                datoHistorico: "El S&P 500 cerró 2008 con -38.5%. La quiebra de Lehman (≈613 mil mdd en pasivos) fue la mayor de la historia de EUA. El 29/09/2008 el Dow cayó 777.68 puntos, récord en puntos hasta entonces.",
                inflacionDelTurno: 0.5,
                efectos: [
                    .conservadora: EfectoDecision(
                        rangoCambioPatrimonio: -8...(-2), cambioLiquidez: 10, puntosResiliencia: 3,
                        narrativa: "Vendieron parte de sus inversiones y se refugiaron en efectivo. Frenaron la hemorragia… pero convirtieron pérdidas de papel en pérdidas reales, justo cuando el mercado se acerca al fondo."),
                    .moderada: EfectoDecision(
                        rangoCambioPatrimonio: -12...(-6), cambioLiquidez: 0, puntosResiliencia: 10,
                        narrativa: "Apretaron los dientes y mantuvieron el plan: siguieron aportando a su retiro sin mirar el saldo. Duele hoy — el mercado sigue cayendo — pero la historia premiará esta disciplina."),
                    .arriesgada: EfectoDecision(
                        rangoCambioPatrimonio: -18...(-6), cambioLiquidez: -10, puntosResiliencia: 0,
                        narrativa: "Compraron acciones en plena tormenta. La idea es correcta, el momento no: al mercado aún le quedan seis meses de caída antes de tocar fondo en marzo de 2009."),
                    .muyArriesgada: EfectoDecision(
                        rangoCambioPatrimonio: -40...(-15), cambioLiquidez: -25, puntosResiliencia: -12,
                        narrativa: "Apostaron con apalancamiento a 'el rebote inminente'. El mercado caerá otro 30% antes de rebotar, y las deudas no esperan: el apalancamiento convierte una mala racha en ruina."),
                ],
                conceptosFavorables: [.diversificacion, .fondoDeEmergencia],
                conceptosDesfavorables: [.panicoFinanciero, .deuda],
                ajustePorConcepto: 4,
                conceptoPrincipal: .panicoFinanciero
            ),
            Turno(
                id: 4,
                titulo: "El desempleo llega a casa",
                evento: """
                2009. El desempleo nacional toca 10% y la empresa de tu pareja cierra su \
                división completa. Un ingreso menos, hipoteca/renta igual. Hay vecinos \
                entregando las llaves de sus casas al banco. Con el dinero más apretado \
                que nunca: ¿cómo reorganizan sus finanzas?
                """,
                datoHistorico: "Desempleo en EUA: 10.0% en octubre de 2009 (BLS), el más alto en 26 años. Hubo ~2.9 millones de ejecuciones hipotecarias iniciadas solo en 2009 (RealtyTrac).",
                inflacionDelTurno: -0.4,
                efectos: [
                    .conservadora: EfectoDecision(
                        rangoCambioPatrimonio: -1...3, cambioLiquidez: 10, puntosResiliencia: 10,
                        narrativa: "El fondo de emergencia que construyeron es ahora su salvavidas: cubren meses de gastos sin malvender nada ni endeudarse. Esto es exactamente para lo que existía."),
                    .moderada: EfectoDecision(
                        rangoCambioPatrimonio: -3...2, cambioLiquidez: 5, puntosResiliencia: 7,
                        narrativa: "Recortaron gastos a lo esencial y tu pareja tomó trabajos temporales mientras busca empleo. El flujo mensual cuadra apenas, pero cuadra — y sin tocar el retiro."),
                    .arriesgada: EfectoDecision(
                        rangoCambioPatrimonio: -10...5, cambioLiquidez: -10, puntosResiliencia: -2,
                        narrativa: "Usaron parte del retiro para montar un negocio desde casa. Puede funcionar, pero retirar inversiones en el FONDO del mercado es vender barato lo que compraron caro."),
                    .muyArriesgada: EfectoDecision(
                        rangoCambioPatrimonio: -25...(-8), cambioLiquidez: -20, puntosResiliencia: -10,
                        narrativa: "Pidieron préstamos caros para 'mantener el nivel de vida mientras pasa la crisis'. La crisis durará más que su crédito: deber dinero sin ingreso es la trampa más vieja del manual."),
                ],
                conceptosFavorables: [.fondoDeEmergencia, .liquidez, .ahorro],
                conceptosDesfavorables: [.deuda],
                ajustePorConcepto: 3,
                conceptoPrincipal: .fondoDeEmergencia
            ),
            Turno(
                id: 5,
                titulo: "¿El fondo del abismo?",
                evento: """
                9 de marzo de 2009. El S&P 500 toca 676 puntos: -57% desde su máximo. \
                Las noticias dicen que 'la bolsa está muerta para una generación'. Pero \
                las empresas sólidas cotizan a precios de remate. Les queda algo de \
                ahorro disponible. ¿Se atreven a invertir cuando todos huyen?
                """,
                datoHistorico: "S&P 500: mínimo de 676.53 el 9 de marzo de 2009. En los 12 meses siguientes subió ~68%; quien invirtió en el fondo y mantuvo, duplicó su dinero para 2011.",
                inflacionDelTurno: 1.5,
                efectos: [
                    .conservadora: EfectoDecision(
                        rangoCambioPatrimonio: 0...2, cambioLiquidez: 5, puntosResiliencia: 2,
                        narrativa: "Se quedaron fuera 'hasta que se calme'. Es la reacción natural… y la más cara: los mejores días de la bolsa suelen llegar pegados a los peores, y se los perdieron."),
                    .moderada: EfectoDecision(
                        rangoCambioPatrimonio: 3...10, cambioLiquidez: -5, puntosResiliencia: 9,
                        narrativa: "Invirtieron poco a poco, cada mes, sin apostar todo a un día. Comprar en mínimos sin saberlo: así se ve la inversión disciplinada cuando el miedo grita."),
                    .arriesgada: EfectoDecision(
                        rangoCambioPatrimonio: 8...20, cambioLiquidez: -15, puntosResiliencia: 5,
                        narrativa: "Invirtieron una suma fuerte cerca del fondo del mercado. El rebote de +68% en 12 meses convertirá este momento de valentía en la mejor decisión financiera de su vida."),
                    .muyArriesgada: EfectoDecision(
                        rangoCambioPatrimonio: -10...25, cambioLiquidez: -25, puntosResiliencia: -5,
                        narrativa: "Todo el ahorro restante a acciones individuales de bancos rescatados. Algunas se multiplicaron… otras (como Citigroup) tardaron una década en recuperarse. Ganaron, pero por suerte, no por método."),
                ],
                conceptosFavorables: [.inversion, .diversificacion],
                conceptosDesfavorables: [.panicoFinanciero],
                ajustePorConcepto: 4,
                conceptoPrincipal: .inversion
            ),
            Turno(
                id: 6,
                titulo: "La lenta recuperación",
                evento: """
                2010-2012. La economía sana despacio: el empleo regresa gota a gota y la \
                bolsa recuperará su nivel pre-crisis hasta 2013. Ustedes tienen empleo \
                otra vez y cicatrices que valen oro. ¿Cómo reconstruyen su patrimonio \
                para la próxima década — y la próxima crisis?
                """,
                datoHistorico: "El S&P 500 recuperó su máximo de 2007 en marzo de 2013 (~5.5 años). Quien mantuvo sus aportaciones de retiro durante toda la crisis recuperó su patrimonio en ~4 años.",
                inflacionDelTurno: 2.5,
                efectos: [
                    .conservadora: EfectoDecision(
                        rangoCambioPatrimonio: 0...3, cambioLiquidez: 5, puntosResiliencia: 4,
                        narrativa: "Reconstruyeron primero su fondo de emergencia. Base sólida, aunque mantener TODO en efectivo otra década significaría regalarle ese dinero a la inflación."),
                    .moderada: EfectoDecision(
                        rangoCambioPatrimonio: 3...8, cambioLiquidez: 0, puntosResiliencia: 10,
                        narrativa: "Fondo de emergencia + aportaciones automáticas al retiro + inversiones diversificadas. Aburrido, sistemático… y estadísticamente imbatible a largo plazo."),
                    .arriesgada: EfectoDecision(
                        rangoCambioPatrimonio: 4...12, cambioLiquidez: -10, puntosResiliencia: 5,
                        narrativa: "Aprovecharon precios aún deprimidos en vivienda e índices. El viento de la recuperación sopla a favor, y esta vez entraron con enganche y números que sí cierran."),
                    .muyArriesgada: EfectoDecision(
                        rangoCambioPatrimonio: -8...10, cambioLiquidez: -20, puntosResiliencia: -3,
                        narrativa: "¿Otra vez todo a una sola apuesta? El mercado sube y los premia… por ahora. La crisis les enseñó la lección; está en ustedes si la aprendieron."),
                ],
                conceptosFavorables: [.ahorro, .diversificacion, .inversion],
                conceptosDesfavorables: [.panicoFinanciero],
                ajustePorConcepto: 3,
                conceptoPrincipal: .ahorro
            ),
        ],
        icono: "house.lodge"
    )
}
