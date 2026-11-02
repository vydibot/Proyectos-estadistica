# Taller Factorial: análisis factorial completo de las 33 variables

Análisis factorial de `data/raw/educacion_limpio.csv` (30 indicadores numéricos + `AÑO`, `DEPARTAMENTO` y `MUNICIPIO`).

## Estructura

```text
reports/taller-factorial/
  taller-factorial.Rmd        Fuente del informe (19 puntos en 5 partes + preguntas conceptuales)
  taller-factorial.html       Informe renderizado
  README.md                   Este archivo
outputs/taller-factorial/
  tables/                     CSV de cada punto del informe
  figures/                    Gráficos del informe
presentacion/taller-factorial/   Presentación para el cliente (ignorada por git)
```

## Contenido del informe

El informe está en 5 partes y cierra con las preguntas conceptuales. Las Partes B y C usan máxima verosimilitud (`fm = "ml"`); desde el punto 10 el estimador de referencia es MinRes.

| Parte | Punto | Qué responde | Tablas principales (`outputs/taller-factorial/tables/`) |
|---|---|---|---|
| A. Los datos | 1 | Cómo entra cada una de las 33 variables | `variables_y_roles.csv` |
| | 2 | ¿Tiene sentido factorizar? (KMO, Bartlett) | `adecuacion.csv`, `kmo_por_variable.csv` |
| B. Un factor común | 3 | Un factor: parte común y parte propia | `un_factor_ml_comun_propia.csv` |
| | 4 | Indicadores que son casi todo parte propia y qué significan para el cliente | `un_factor_por_familia.csv` |
| | 5 | ¿Alcanza un factor? Correlaciones frente al producto de las cargas | `un_factor_correlaciones_vs_producto.csv` |
| | 6 | Dos factores: ¿el segundo tiene sentido o es una sola variable? | `uno_vs_dos_factores_ml.csv`, `cargas_2_factores_ml_oblimin.csv` |
| C. Girar y comprobar | 7 | Dos factores sin girar | `cargas_2_factores_ml_sin_girar.csv` |
| | 8 | Varimax y oblimin: la parte común no cambia | `comunalidades_por_giro.csv`, `comparacion_giros.csv`, `cargas_2_factores_ml_varimax.csv` |
| | 9 | Correlación entre los factores (Φ de oblimin) | — |
| | 10 | Otro método (MinRes y ejes principales) | `comparacion_estimadores_2_factores.csv` |
| | 11 | Cuántos factores caben (grados de libertad) y cuántos pedir (criterios, casos límite) | `grados_de_libertad.csv`, `criterios_numero_factores.csv`, `scree_y_paralelo.csv`, `casos_limite_por_numero_de_factores.csv` |
| D. Profundización | 12 | Solución de k factores: estimadores y lectura | `comparacion_estimadores.csv`, `cargas_*_factores_*.csv`, `comunalidades.csv`, `correlacion_entre_factores_k.csv` |
| | 13 | Ajuste del modelo | `ajuste_del_modelo.csv` |
| | 14 | Estabilidad (períodos, promedio por municipio, bootstrap por municipio) | `estabilidad_periodos_y_municipios.csv`, `bootstrap_*.csv` |
| | 15 | Puntajes factoriales por año, departamento y municipio | `r2_puntajes_por_categorica.csv`, `puntajes_por_anio.csv`, `puntajes_por_departamento.csv` |
| | 16 | Las 33 columnas con one-hot | `variantes_one_hot.csv` |
| E. Decisión y cierre | 17 | Un factor, dos fondos o indicadores directos | `costo_factor_unico.csv`, `solapamiento_fondos.csv`, `captura_grupo_prioritario.csv` |
| | 18 | Comparación con las 6 variables de los talleres anteriores | `comparacion_6_vs_30.csv`, `comparacion_medidas_6_vs_30.csv` |
| | 19 | Conclusiones y límites | `resumen_final.csv` |
| Preguntas conceptuales | — | Respuestas a las preguntas conceptuales, aplicadas a estos datos | — |

Figuras (`outputs/taller-factorial/figures/`): `kmo_por_variable.png` (punto 2), `un_factor_comun_propia.png` (3), `un_factor_correlaciones_vs_producto.png` (5), `cargas_por_giro.png` (8), `grados_de_libertad.png` y `paralelo.png` (11), `cargas_factoriales.png` (12), `bootstrap_congruencia.png` (14), `puntajes_por_anio.png` (15) y `variantes_one_hot.png` (16).

## Cómo regenerarlo

```r
source("scripts/render_talleres_pca.R")   # incluye este informe
```

El punto 16 lee `outputs/taller-pca/analisis-33-variables/`, que genera `Rscript scripts/analisis_33_variables.R` (unos 4 minutos).
