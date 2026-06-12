# Modelo de clasificación de presupuesto (Create ML)

Este documento explica cómo generar **`ModeloPresupuesto.mlmodel`**, el modelo
de clasificación de texto opcional que `BudgetClassifier` carga del bundle.

> La app **funciona sin el modelo**: si no está presente, `BudgetClassifier`
> usa el clasificador por reglas (regla 50/30/20). El modelo solo aporta la
> etiqueta del estado; las categorías problemáticas y la retroalimentación
> siempre las calculan las reglas en Swift. Todo es 100% en el dispositivo.

## Formato de entrada

El modelo recibe una **cadena estructurada** con el porcentaje (entero) que
cada categoría representa del salario, en este orden fijo:

```
renta:40 comida:10 ahorro:5 entretenimiento:25 transporte:10 otros:10
```

- `renta`            → Renta / Vivienda
- `comida`           → Alimentación
- `ahorro`           → Ahorro / Inversión
- `entretenimiento`  → Entretenimiento
- `transporte`       → Transporte
- `otros`            → Otros / Imprevistos

La construye `BudgetClassifier.cadenaEstructurada(_:)`.

## Etiquetas de salida

Tres clases, que coinciden con los `rawValue` de `ClasificacionPresupuesto`:

- `sostenible`
- `riesgoso`
- `critico`

## Dataset

`dataset_presupuesto.csv` tiene dos columnas: `text` y `label`. Es un punto de
partida; puedes ampliarlo para mejorar la precisión.

## Pasos en Create ML

1. Abre **Create ML** (Xcode ▸ Open Developer Tool ▸ Create ML).
2. Nuevo proyecto ▸ plantilla **Text Classification**.
3. En *Training Data* selecciona `dataset_presupuesto.csv`.
   - *Text Column*: `text`
   - *Label Column*: `label`
4. Algoritmo: **Maximum Entropy** (suficiente para texto corto y estructurado).
5. Entrena y revisa la matriz de confusión en *Evaluation*.
6. Exporta el modelo como **`ModeloPresupuesto.mlmodel`**.
7. Arrástralo a `FinEdu/Resources/` en Xcode (target FinEdu). Xcode lo compila
   a `ModeloPresupuesto.mlmodelc` automáticamente y `BudgetClassifier` lo
   detecta y usa la próxima vez que se ejecute la app.

No se necesita ningún cambio de código: la carga es por nombre de recurso.
