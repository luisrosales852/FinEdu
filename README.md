# FinEdu — Simulador de resiliencia financiera

App educativa para que jóvenes aprendan finanzas **decidiendo**, no leyendo teoría.
100% Swift + SwiftUI, **solo frameworks nativos de Apple**, **sin dependencias de
terceros** y **100% offline**: ningún dato sale del dispositivo y no hay ninguna
llamada de red.

Atiende el **ODS 4** (Educación de Calidad) y el **ODS 8** (Trabajo Decente y
Crecimiento Económico).

## Modos de juego

Desde el menú principal se accede a dos modalidades:

| Módulo | Qué hace |
|---|---|
| **Selección de crisis** | Revives crisis económicas históricas reales (México 1994, mundo 2008, hiperinflación) y decides con tus propias palabras qué hacer con tu dinero. |
| **Simulador de Bolsa** | Practicas invertir en las 10 empresas más valiosas del mundo con datos históricos, mes a mes, desde junio de 2023. |

## Módulo: Simulador de Bolsa

Segunda modalidad de juego. El usuario invierte un capital simulado en las **10
empresas más valiosas por capitalización (jun-2023 → may-2026)**: Apple (AAPL),
Microsoft (MSFT), NVIDIA (NVDA), Alphabet (GOOGL), Amazon (AMZN), Meta (META),
Broadcom (AVGO), Tesla (TSLA), Berkshire Hathaway (BRK.B) y TSMC (TSM).

### Flujo

1. **Onboarding (primera vez):** el usuario declara su presupuesto total (USD) y la
   IA on-device recomienda cuánto destinar a bolsa (con explicación educativa). La
   recomendación es **editable** mediante un slider antes de empezar.
2. **Simulación:** el tiempo arranca en **junio de 2023** y avanza **mes a mes** con
   el botón "Avanzar mes". El usuario solo ve precios hasta el mes actual, nunca el
   futuro. Puede **comprar y vender acciones fraccionarias** de cualquier empresa
   con su efectivo disponible.
3. **Gráfica central (Swift Charts):** valor total del portafolio, comparación
   "vs. dejar todo en efectivo" y composición por empresa.
4. **Resultados finales:** al llegar al último mes, rendimiento total, % vs. efectivo,
   mejor y peor decisión y retroalimentación educativa generada por IA.

### Características que refuerzan la rúbrica

- **Eventos educativos contextuales:** tarjetas con el evento real del mercado de
  cada mes (boom de IA de NVIDIA, recortes de tasas de la Fed, etc.).
- **Coach de IA on-device:** tras cada compra/venta, retroalimentación breve sobre
  diversificación y concentración de riesgo.
- **Métricas simples y visibles:** rendimiento total %, número de empresas y % de la
  mayor posición.
- **Accesibilidad:** VoiceOver con resúmenes en la gráfica, Dynamic Type (text
  styles), `accessibilityHint` en los botones y audio graphs de Swift Charts.
- **Disclaimers educativos:** se aclara en toda la UI que es un simulador educativo
  con datos históricos y **no asesoría de inversión**.

### Datos (offline, embebidos)

Todo el dataset vive en `FinEdu/Data/Market/market_data.json` (JSON estático en el
bundle): por cada empresa, ticker, nombre, sector, descripción educativa y 36
cierres mensuales, más eventos educativos por mes. Los precios **hasta
`realDataCutoff` (2024-12)** se basan en cierres históricos reales aproximados;
los meses posteriores son valores plausibles proyectados (es un simulador
educativo). El JSON documenta hasta dónde son reales para que el equipo los
actualice a mano. `MarketDataLoader` lo carga y **valida** al inicio (10 empresas
× 36 puntos, meses en orden, precios positivos).

### Persistencia (SwiftData)

Se modela y persiste todo lo del módulo, separado del modo de crisis para poder
reiniciarlo sin tocar el otro:

- `CarteraBolsa` — presupuesto total, monto asignado, efectivo actual, mes actual y
  bandera de onboarding.
- `Holding` — ticker, cantidad (fraccionaria) y precio promedio de compra.
- `Transaccion` — historial (mes simulado, ticker, compra/venta, cantidad, precio).
- `SnapshotMensual` — valor del portafolio por mes, para reconstruir la gráfica al
  reabrir la app.

El reinicio del simulador (desde el menú del módulo) borra **solo** estos datos.

## Tecnologías

- **Swift + SwiftUI** (arquitectura MVVM con el framework **Observation**, `@Observable`).
- **SwiftData** (`@Model`, `@Query`) para persistencia 100% local.
- **Swift Charts** para la gráfica del portafolio y los mini-sparklines.
- **Foundation Models** (Apple Intelligence) para la IA generativa on-device.
- **NaturalLanguage + Core ML** como capa de IA de respaldo.
- Sin librerías de terceros y sin acceso a red.

## Inteligencia artificial (on-device, con fallback)

FinEdu usa una **arquitectura de IA en dos capas con fallback automático y
transparente**, 100% en el dispositivo:

- **Capa 1 — Foundation Models (Apple Intelligence, iOS 26+):** un LLM on-device
  genera, con **salida estructurada** (`@Generable`), la recomendación de
  presupuesto del onboarding, los consejos del coach tras cada operación y la
  retroalimentación final. En el modo de crisis evalúa las decisiones en texto libre.
- **Capa 2 — Reglas deterministas + NaturalLanguage/Core ML:** si Apple Intelligence
  no está disponible, todo sigue funcionando con reglas claras y defendibles (ej.
  recomendar ~15% del capital tras señalar el fondo de emergencia; advertir si más
  del 50% del portafolio está en una sola empresa).

Ambas capas producen el mismo tipo de salida, así que la app es agnóstica al motor
y la degradación nunca interrumpe al usuario. **Justificación:** mantiene la
privacidad (nada sale del iPhone), funciona sin conexión y garantiza que la
experiencia educativa esté disponible en cualquier dispositivo, no solo en los que
soportan Apple Intelligence.

> Este proyecto es un **simulador educativo** con datos históricos. No constituye
> asesoría de inversión.
