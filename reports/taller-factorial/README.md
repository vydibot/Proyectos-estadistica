# Taller Factorial: actividades de Análisis factorial I y II con 9 indicadores

Resuelve las actividades prácticas de las notas de clase **Análisis factorial I** y **Análisis factorial II**
con `data/raw/educacion_limpio.csv`. Como pide la actividad 1 de Análisis factorial I, se escogen
**entre 4 y 10 variables** (aquí 9), y **las mismas 9 variables se usan en las dos notas**.

El análisis factorial de **todas las variables** (30 indicadores y las 3 categóricas, con estabilidad,
puntajes, one-hot y decisión) está en el informe del Corte 2:
`reports/entrega-corte-2/Analisis_Indicadores_Educativos.Rmd`, sección «Análisis Factorial».

## Las 9 variables

| Grupo | Variables |
|---|---|
| Acceso | `COBERTURA_NETA_TRANSICIÓN`, `COBERTURA_NETA_PRIMARIA`, `COBERTURA_NETA_SECUNDARIA`, `COBERTURA_NETA_MEDIA` |
| Permanencia y rendimiento | `APROBACIÓN_PRIMARIA`, `APROBACIÓN_SECUNDARIA`, `APROBACIÓN_MEDIA`, `DESERCIÓN`, `REPITENCIA` |

Criterios: no mezclar un indicador agregado con sus niveles, no meter a la vez aprobación, reprobación y
deserción generales (suman casi 1 y dejan la matriz casi singular) y dejar fuera la población (mide el
tamaño del municipio). KMO global 0,664; ninguna variable por debajo de 0,5.

## Estructura

```text
reports/taller-factorial/
  taller-factorial.Rmd        Fuente del informe (10 actividades + conclusión + preguntas conceptuales)
  taller-factorial.html       Informe renderizado
  README.md                   Este archivo
outputs/taller-factorial/
  tables/                     CSV de cada actividad (se regeneran completos al tejer)
  figures/                    Gráficos del informe
```

## Contenido del informe

| Parte | Actividad | Qué responde | Tablas (`outputs/taller-factorial/tables/`) |
|---|---|---|---|
| A. Análisis factorial I | 1 | Las 9 variables y el KMO | `variables_usadas.csv`, `kmo.csv` |
| | 2 | Un factor (`fm = "ml"`): parte común y parte propia | `un_factor_comun_propia.csv` |
| | 3 | La variable casi toda propia y su costo para el cliente | `costo_factor_unico.csv` |
| | 4 | ¿Alcanza un factor? Correlaciones frente al producto de las cargas | `un_factor_correlaciones_vs_producto.csv` |
| | 5 | Dos factores: ¿el segundo tiene sentido o es una sola variable? | `uno_vs_dos_factores.csv`, `cargas_2_factores_ml_oblimin.csv` |
| B. Análisis factorial II | 1 | Dos factores sin girar | `cargas_2_factores_sin_girar.csv` |
| | 2 | Varimax y oblimin: la parte común no cambia | `comunalidades_por_giro.csv`, `cargas_2_factores_ml_varimax.csv`, `plano_de_cargas.csv` |
| | 3 | Cuánto van juntos los factores (Φ) y solapamiento de dos fondos | `solapamiento_fondos.csv` |
| | 4 | Otro método (`minres`, y ejes principales) | `comparacion_metodos.csv`, `cargas_2_factores_minres_oblimin.csv` |
| | 5 | Cuántos factores caben como máximo (grados de libertad) | `grados_de_libertad.csv`, `ajuste_por_numero_de_factores.csv` |
| Conclusión | — | Lo que se le entrega al cliente | `resumen_final.csv` |
| Preguntas conceptuales | — | Respuestas de las dos notas, aplicadas a estos datos | — |

Figuras (`outputs/taller-factorial/figures/`): `correlaciones.png` (A1), `un_factor_comun_propia.png` (A2),
`un_factor_correlaciones_vs_producto.png` (A4), `plano_de_cargas.png` (B2) y `grados_de_libertad.png` (B5).

## Resultado en una línea

Un factor es solo el acceso; con dos aparecen **Acceso** y **Rendimiento y permanencia**, casi independientes
(Φ ≈ 0,11), iguales con cualquier giro y con ML, MinRes o ejes principales. Con 9 variables caben hasta 5
factores, pero dos bastan. Es la misma conclusión que da el análisis de los 30 indicadores en el Corte 2.

## Cómo regenerarlo

En RStudio, abrir `taller-factorial.Rmd` y presionar **Knit**, o desde la raíz del proyecto:

```r
rmarkdown::render("reports/taller-factorial/taller-factorial.Rmd")
source("scripts/render_talleres_pca.R")   # talleres de PCA y este informe
```

Necesita `psych`, `GPArotation` y `ggrepel` (`source("scripts/install_dependencies.R")`). Tarda unos segundos.
