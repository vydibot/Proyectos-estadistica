# Taller Factorial: análisis factorial completo de las 33 variables

Análisis factorial de `data/raw/educacion_limpio.csv` (30 indicadores numéricos + `AÑO`, `DEPARTAMENTO` y `MUNICIPIO`).

## Estructura

```text
reports/taller-factorial/
  taller-factorial.Rmd        Fuente del informe (12 puntos)
  taller-factorial.html       Informe renderizado
  README.md                   Este archivo
outputs/taller-factorial/
  tables/                     CSV de cada punto del informe
  figures/                    Gráficos del informe
presentacion/taller-factorial/   Presentación para el cliente (ignorada por git)
```

## Contenido del informe

| Punto | Qué responde | Tablas principales (`outputs/taller-factorial/tables/`) |
|---|---|---|
| 1 | Cómo entra cada una de las 33 variables | `variables_y_roles.csv` |
| 2 | ¿Tiene sentido factorizar? (KMO, Bartlett, condicionamiento) | `adecuacion.csv`, `kmo_por_variable.csv` |
| 3 | ¿Cuántos factores? (Kaiser, paralelo, MAP, BIC, casos límite) | `criterios_numero_factores.csv`, `scree_y_paralelo.csv`, `casos_limite_por_numero_de_factores.csv` |
| 4 | ¿Importa el estimador? (MinRes, ML, ejes principales) | `comparacion_estimadores.csv` |
| 5 | Rotación y lectura (Oblimin y Varimax) | `cargas_*_factores_*.csv`, `comunalidades.csv`, `correlacion_entre_factores_k.csv` |
| 6 | Ajuste del modelo | `ajuste_del_modelo.csv` |
| 7 | Estabilidad (períodos, promedios por municipio, bootstrap por municipio) | `estabilidad_periodos_y_municipios.csv`, `bootstrap_*.csv` |
| 8 | Puntajes factoriales y categóricas (año, departamento, municipio) | `r2_puntajes_por_categorica.csv`, `puntajes_por_anio.csv`, `puntajes_por_departamento.csv` |
| 9 | Las 33 columnas con one-hot | `variantes_one_hot.csv` |
| 10 | Decisión: un factor, dos fondos, indicadores directos | `costo_factor_unico.csv`, `solapamiento_fondos.csv`, `captura_grupo_prioritario.csv` |
| 11 | Comparación con las 6 variables | `comparacion_6_vs_30.csv`, `comparacion_medidas_6_vs_30.csv` |
| 12 | Resumen y límites | `resumen_final.csv` |

## Cómo regenerarlo

```r
source("scripts/render_talleres_pca.R")   # incluye este informe
```

El punto 9 lee `outputs/taller-pca/analisis-33-variables/`, que genera `Rscript scripts/analisis_33_variables.R` (unos 4 minutos).
