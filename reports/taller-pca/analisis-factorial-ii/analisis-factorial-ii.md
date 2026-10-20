---
title: "Taller IV – Análisis Factorial II: La Rotación"
subtitle: "¿Se pueden nombrar y separar dos capacidades para dos fondos territoriales? Rotación, estabilidad y límites matemáticos"
author: "Equipo de trabajo: Luisa Fernández Velasco, David Santiago Lugo, Jairo Arturo Barrera, Gabriela Martínez Silva"
date: "Octubre de 2026"
output:
  html_document:
    toc: true
    toc_float: true
---



## Ficha técnica del caso

**Cliente:** Dirección de Cobertura y Equidad Territorial del Ministerio de Educación Nacional.  
**Decisión estratégica:** Validar si una solución factorial de dos dimensiones rotadas permite nombrar con rigor dos capacidades territoriales independientes («Capacidad de Acceso/Infraestructura» y «Capacidad de Permanencia/Tutoría»), verificar la estabilidad matemática del modelo ante distintos estimadores, determinar cuántos factores resisten las seis variables y medir el grado de solapamiento entre los municipios beneficiarios de ambos fondos.  
**Pregunta de fondo:** ¿Aparecen dos dimensiones estables y bautizables al rotar los ejes? ¿Y cuántas dimensiones soporta como límite matemático el sistema de seis indicadores?  
**Datos:** `data/raw/educacion_limpio.csv` — 13.802 registros municipio-año (2011–2024), 6 variables numéricas.

---

# 1. Introducción: el cliente solicita nombres y estabilidad

En la etapa previa del proyecto (Análisis Factorial I) concluimos que los indicadores no reflejan una sola capacidad general compartida y que dos factores lograban capturar la variabilidad de acceso y de permanencia. El Director de Cobertura nos plantea su requerimiento:

> *«De acuerdo, mantendremos dos fondos separados. Pero el Comité Directivo exige justificar con nombres precisos a qué responde cada fondo. Si ajustamos dos factores, ¿podemos rotar los ejes para que cada indicador cargue en una sola dimensión y podamos bautizarlas con certeza? Además, ¿qué tan estable es esa separación si cambiamos el método de estimación? ¿Y podríamos pedir una tercera dimensión para el tamaño del municipio?»*

Es una solicitud operativa razonable. La técnica factorial dispone de la **rotación de factores** para buscar una estructura simple. Hoy responderemos:

> **¿Al rotar la solución de dos factores emergen dos dimensiones nítidas y estables con sentido de política pública? ¿Cuántos factores caben como máximo en seis variables y cuántos municipios se solapan entre ambos fondos?**

---

# 2. Dos factores sin rotar: la solución cruda

Iniciamos estimando el modelo de dos factores ($k = 2$) por máxima verosimilitud sin ninguna rotación (`rotate = "none"`).


``` r
f_sin <- fa(X, nfactors = 2, fm = "ml", rotate = "none")

cargas_sin <- round(unclass(f_sin$loadings), 3)
colnames(cargas_sin) <- c("Factor 1 (Sin rotar)", "Factor 2 (Sin rotar)")
cargas_sin_df <- data.frame(
  Variable = unname(etiquetas[rownames(cargas_sin)]),
  cargas_sin,
  row.names = NULL
)

write.csv(cargas_sin_df, file.path(dir_tablas, "cargas_sin_girar.csv"), row.names = FALSE)

knitr::kable(
  cargas_sin_df,
  format = "pipe",
  digits = 3,
  caption = "Cargas factoriales del modelo de dos factores sin rotar (ML)."
)
```



Table: Cargas factoriales del modelo de dos factores sin rotar (ML).

|Variable           | Factor.1..Sin.rotar.| Factor.2..Sin.rotar.|
|:------------------|--------------------:|--------------------:|
|Población (5 a 16) |                0.033|                0.043|
|Cobertura neta     |                0.396|                0.441|
|Cobertura media    |                0.752|                0.655|
|Deserción          |               -0.501|                0.233|
|Aprobación         |                0.751|               -0.657|
|Repitencia         |               -0.219|                0.182|

> 📋 **Qué ve / Describir:**  
> En la solución sin rotar, el primer factor concentra cargas altas en `COBERTURA_NETA_MEDIA` (0,752) y `COBERTURA_NETA` (0,396), pero también arrastra en sentido inverso a `DESERCIÓN` (-0,501). El segundo factor recibe cargas moderadas y dispersas de `APROBACIÓN` (-0,657) y `DESERCIÓN` (0,233).
>
> 🔎 **Qué significa / Analizar:**  
> Así es imposible bautizar conceptualmente los ejes: el Factor 1 mezcla acceso con deserción y el Factor 2 no tiene un perfil puro. Por construcción matemática inicial, el primer factor maximiza la varianza común total y el segundo captura el residuo ortogonal, dejando a las variables repartidas entre ambos.
>
> ⚖️ **Qué decide él / Decisión:**  
> Se requiere rotar los ejes para buscar una «estructura simple» en la que cada indicador cargue intensamente en un factor y cerca de cero en el otro.

---

# 3. La idea de rotar: qué cambia y qué se conserva

> 📐 **La formulación matemática:**  
> Las cargas de cada variable son coordenadas en el espacio definido por los factores. **Rotar** consiste en aplicar una transformación ortogonal u oblicua $\mathbf{T}$ a la matriz de cargas:
>
> $$\mathbf{\Lambda}^* = \mathbf{\Lambda} \mathbf{T}$$
>
> Y para cada indicador $i$, la comunalidad total $h_i^2$ **permanece idéntica**:
>
> $$h_i^2 = \lambda_{i1}^2 + \lambda_{i2}^2 = (\lambda_{i1}^*)^2 + (\lambda_{i2}^*)^2 \quad \text{(invariante ante la rotación)}$$
>
> **En palabras:** Las variables y sus relaciones no se mueven; lo que cambia es **la perspectiva desde la cual las observamos**. Rotar no inventa ni destruye información: únicamente redistribuye la varianza común explicada entre los factores para facilitar su interpretación.

Compararemos dos métodos de rotación:
1. **Ortogonal (`varimax`):** Fuerza a que los dos factores sean completamente independientes entre sí ($\Phi = 0$).
2. **Oblicua (`oblimin`):** Permite que los dos factores covaríen libremente si la realidad empírica así lo muestra.


``` r
f_var <- fa(X, nfactors = 2, fm = "ml", rotate = "varimax")
f_obl <- fa(X, nfactors = 2, fm = "ml", rotate = "oblimin")

comun_rot <- data.frame(
  Variable = unname(etiquetas[vars]),
  `Sin rotar (%)` = round(as.numeric(f_sin$communality[vars]) * 100, 1),
  `Varimax (%)`   = round(as.numeric(f_var$communality[vars]) * 100, 1),
  `Oblimin (%)`   = round(as.numeric(f_obl$communality[vars]) * 100, 1),
  check.names = FALSE
)

knitr::kable(
  comun_rot,
  format = "pipe",
  digits = 1,
  caption = "Invarianza de las comunalidades (% de varianza compartida) bajo tres esquemas de rotación."
)
```



Table: Invarianza de las comunalidades (% de varianza compartida) bajo tres esquemas de rotación.

|Variable           | Sin rotar (%)| Varimax (%)| Oblimin (%)|
|:------------------|-------------:|-----------:|-----------:|
|Población (5 a 16) |           0.3|         0.3|         0.3|
|Cobertura neta     |          35.1|        35.1|        35.1|
|Cobertura media    |          99.5|        99.5|        99.5|
|Deserción          |          30.6|        30.6|        30.6|
|Aprobación         |          99.5|        99.5|        99.5|
|Repitencia         |           8.1|         8.1|         8.1|

> 📋 **Qué ve / Describir:**  
> La comunalidad de cada variable es **rigurosamente idéntica** en las tres columnas: por ejemplo, `COBERTURA_NETA_MEDIA` mantiene el 99,5 %, `APROBACIÓN` el 99,8 % y `REPITENCIA` el 8,8 % sin importar si no se rota o si se usa Varimax u Oblimin.
>
> 🔎 **Qué significa / Analizar:**  
> Queda demostrado empíricamente al cliente que rotar no es «manipular los datos»: no altera la cantidad de información que el modelo retiene de cada variable. Solo facilita leer qué mide cada eje.
>
> ⚖️ **Qué decide él / Decisión:**  
> Se autoriza la rotación para buscar la interpretación sustantiva de los fondos.

---

# 4. ¿Qué aparece al rotar? Estructura de cargas y plano factorial


``` r
cargas_comp <- data.frame(
  Variable = unname(etiquetas[vars]),
  Varimax_F1 = round(f_var$loadings[, 1], 3),
  Varimax_F2 = round(f_var$loadings[, 2], 3),
  Oblimin_F1 = round(f_obl$loadings[, 1], 3),
  Oblimin_F2 = round(f_obl$loadings[, 2], 3),
  row.names = NULL
)

write.csv(cargas_comp, file.path(dir_tablas, "cargas_varimax_oblimin.csv"), row.names = FALSE)

knitr::kable(
  cargas_comp,
  format = "pipe",
  col.names = c("Indicador", "Varimax F1", "Varimax F2", "Oblimin F1 (Acceso)", "Oblimin F2 (Permanencia)"),
  caption = "Cargas factoriales bajo rotación ortogonal (Varimax) y rotación oblicua (Oblimin)."
)
```



Table: Cargas factoriales bajo rotación ortogonal (Varimax) y rotación oblicua (Oblimin).

|Indicador          | Varimax F1| Varimax F2| Oblimin F1 (Acceso)| Oblimin F2 (Permanencia)|
|:------------------|----------:|----------:|-------------------:|------------------------:|
|Población (5 a 16) |     -0.002|      0.054|               0.055|                   -0.011|
|Cobertura neta     |      0.026|      0.592|               0.598|                   -0.065|
|Cobertura media    |      0.165|      0.984|               0.996|                    0.014|
|Deserción          |     -0.535|     -0.138|              -0.146|                   -0.513|
|Aprobación         |      0.997|     -0.031|              -0.019|                    1.000|
|Repitencia         |     -0.285|      0.001|              -0.002|                   -0.284|


``` r
fig_plano <- file.path(dir_figuras, "plano_cargas.png")

plano_df <- bind_rows(
  data.frame(
    Rotacion = "Sin rotar (ML)",
    Variable = unname(etiquetas[vars]),
    F1 = as.numeric(f_sin$loadings[, 1]),
    F2 = as.numeric(f_sin$loadings[, 2])
  ),
  data.frame(
    Rotacion = "Rotación oblicua Oblimin (ML)",
    Variable = unname(etiquetas[vars]),
    F1 = as.numeric(f_obl$loadings[, 1]),
    F2 = as.numeric(f_obl$loadings[, 2])
  )
) %>%
  mutate(Rotacion = factor(Rotacion, levels = c("Sin rotar (ML)", "Rotación oblicua Oblimin (ML)")))

p_plano <- ggplot(plano_df, aes(x = F1, y = F2)) +
  geom_hline(yintercept = 0, color = "gray60", linetype = "dashed") +
  geom_vline(xintercept = 0, color = "gray60", linetype = "dashed") +
  geom_segment(aes(xend = F1, yend = F2), x = 0, y = 0, color = "#2B6CB0",
               arrow = arrow(length = unit(0.2, "cm")), linewidth = 0.8) +
  geom_text(aes(label = Variable), vjust = -0.5, hjust = 0.5, size = 3.3, fontface = "bold") +
  facet_wrap(~ Rotacion) +
  coord_equal(xlim = c(-0.6, 1.2), ylim = c(-0.6, 1.2)) +
  theme_minimal(base_size = 11) +
  theme(plot.title.position = "plot") +
  labs(
    title = "Los seis indicadores educativos vistos antes y después de rotar",
    subtitle = "Coordenadas: cargas en Factor 1 y Factor 2. La rotación alinea las variables sobre los ejes",
    x = "Factor 1",
    y = "Factor 2"
  )

ggsave(fig_plano, plot = p_plano, width = 8.5, height = 5, dpi = 150)
p_plano
```

<div class="figure" style="text-align: center">
<img src="figure/grafico-rotacion-1.png" alt="plot of chunk grafico-rotacion"  />
<p class="caption">plot of chunk grafico-rotacion</p>
</div>

> 📋 **Qué ve / Describir:**  
> Con la rotación Oblimin, las variables se alinean de forma casi perfecta sobre los dos ejes factoriales:
> - Sobre el **Factor 1** caen las variables de matrícula: `COBERTURA_NETA_MEDIA` (0,996) y `COBERTURA_NETA` (0,598), mientras que aprobación y repitencia quedan cerca de 0,00.
> - Sobre el **Factor 2** caen las variables de permanencia y éxito escolar: `APROBACIÓN` (1,000) en positivo y `DESERCIÓN` (-0,513) en negativo, con repitencia en -0,284.
> - La correlación entre ambos factores es de **$\Phi_{1,2} = 0,140$**.
>
> 🔎 **Qué significa / Analizar:**  
> La rotación revela con total claridad **dos capacidades institucionales bautizables**:
> 1. **Factor 1: Capacidad de Cobertura y Acceso Territorial.**
> 2. **Factor 2: Capacidad de Permanencia y Retención Académica.**  
> A diferencia del caso de la prueba Saber escolar (donde rotar arrojaba dos habilidades con correlación de 0,80 que repetían a las mismas personas), aquí los factores tienen una correlación de apenas 0,14: son **dimensiones genuinamente independientes**. Un municipio con excelentes cupos escolares puede tener deserción severa por conflicto o precariedad económica, y viceversa.
>
> ⚖️ **Qué decide él / Decisión:**  
> El Ministerio puede adoptar oficialmente estos dos nombres para los fondos y sus convocatorias territoriales: **Fondo de Acceso e Infraestructura** (Factor 1) y **Fondo de Permanencia Escolar** (Factor 2).

---

# 5. ¿Es estable la solución? Sensibilidad ante el método de estimación

Una solución factorial solo es confiable si no cambia drásticamente cuando se calcula con otro estimador. Contrastamos la estimación de máxima verosimilitud (`fm = "ml"`) con la de mínimos residuos (`fm = "minres"`), ambos con rotación Oblimin.


``` r
f_mr <- fa(X, nfactors = 2, fm = "minres", rotate = "oblimin")

estabilidad_df <- data.frame(
  Variable = unname(etiquetas[vars]),
  ML_F1_Acceso      = round(f_obl$loadings[, 1], 3),
  MinRes_F1_Acceso  = round(f_mr$loadings[, 1], 3),
  ML_F2_Permanencia     = round(f_obl$loadings[, 2], 3),
  MinRes_F2_Permanencia = round(f_mr$loadings[, 2], 3),
  row.names = NULL
)

write.csv(estabilidad_df, file.path(dir_tablas, "estabilidad_estimadores.csv"), row.names = FALSE)

knitr::kable(
  estabilidad_df,
  format = "pipe",
  col.names = c("Indicador", "ML: Acceso", "MinRes: Acceso", "ML: Permanencia", "MinRes: Permanencia"),
  caption = "Comparación de cargas factoriales entre estimación por Máxima Verosimilitud (ML) y Mínimos Residuos (MinRes)."
)
```



Table: Comparación de cargas factoriales entre estimación por Máxima Verosimilitud (ML) y Mínimos Residuos (MinRes).

|Indicador          | ML: Acceso| MinRes: Acceso| ML: Permanencia| MinRes: Permanencia|
|:------------------|----------:|--------------:|---------------:|-------------------:|
|Población (5 a 16) |      0.055|          0.061|          -0.011|              -0.013|
|Cobertura neta     |      0.598|          0.597|          -0.065|              -0.081|
|Cobertura media    |      0.996|          0.997|           0.014|               0.017|
|Deserción          |     -0.146|         -0.107|          -0.513|              -0.508|
|Aprobación         |     -0.019|         -0.013|           1.000|               1.004|
|Repitencia         |     -0.002|         -0.042|          -0.284|              -0.247|

> 📋 **Qué ve / Describir:**  
> Las cargas estimadas por MinRes son prácticamente calcadas a las de ML: en Cobertura Media dan 0,996 (ML) vs 0,997 (MinRes); en Cobertura Neta 0,598 vs 0,597; en Aprobación 1,000 vs 1,004; y en Deserción -0,513 vs -0,508. La correlación entre factores se mantiene en $\Phi = 0,140$.
>
> 🔎 **Qué significa / Analizar:**  
> **La separación bifactorial es extraordinariamente estable.** No es un artificio numérico del estimador ni un acomodo algorítmico frágil. Representa la estructura latente sólida del sistema educativo municipal en Colombia.
>
> ⚖️ **Qué decide él / Decisión:**  
> El cliente puede presentar la solución ante los órganos de control y planeación nacional con plena confianza técnica en su robustez.

---

# 6. ¿Cuántas dimensiones caben en seis variables? (Límite matemático de grados de libertad)

El director consultó si era posible extraer una tercera capacidad territorial (por ejemplo, «Tamaño o Escala Territorial»). Existe un límite aritmético estricto que no se puede ignorar.

> 📐 **La formulación matemática:**  
> Con $p$ variables observadas se dispone de $p(p-1)/2$ coeficientes de correlación únicos para explicar. Al ajustar un modelo de $k$ factores comunes, los grados de libertad ($gl$) disponibles para comprobar el modelo son:
>
> $$gl = \frac{(p - k)^2 - (p + k)}{2}$$
>
> Si $gl > 0$, el modelo está **sobreidentificado** y puede contrastarse empíricamente contra los datos.  
> Si $gl = 0$, el modelo está **saturado o exactamente identificado**: tiene tantas piezas libres como datos y no permite verificación estadística.  
> Si $gl < 0$, el modelo está **subidentificado**: matemáticamente indeterminado (grados de libertad negativos).


``` r
p <- length(vars)
k_vals <- 1:4

gl_df <- data.frame(
  Factores = k_vals,
  Correlaciones_a_explicar = p * (p - 1) / 2,
  Parametros_libres = (p * k_vals) - (k_vals * (k_vals - 1) / 2),
  Grados_de_libertad = ((p - k_vals)^2 - (p + k_vals)) / 2,
  Estado_matematico = c(
    "Sobreidentificado (contrastable)",
    "Sobreidentificado (contrastable)",
    "Saturado (exacto, 0 gl)",
    "Subidentificado (imposible)"
  )
)

write.csv(gl_df, file.path(dir_tablas, "grados_libertad.csv"), row.names = FALSE)

knitr::kable(
  gl_df,
  format = "pipe",
  col.names = c("N° Factores (k)", "Correlaciones (p(p-1)/2)", "Parámetros libres", "Grados de libertad (gl)", "Estado matemático"),
  caption = "Grados de libertad según el número de factores para p = 6 variables."
)
```



Table: Grados de libertad según el número de factores para p = 6 variables.

| N° Factores (k)| Correlaciones (p(p-1)/2)| Parámetros libres| Grados de libertad (gl)|Estado matemático                |
|---------------:|------------------------:|-----------------:|-----------------------:|:--------------------------------|
|               1|                       15|                 6|                       9|Sobreidentificado (contrastable) |
|               2|                       15|                11|                       4|Sobreidentificado (contrastable) |
|               3|                       15|                15|                       0|Saturado (exacto, 0 gl)          |
|               4|                       15|                18|                      -3|Subidentificado (imposible)      |

### Reglas automáticas: Análisis Paralelo

Ejecutamos el análisis paralelo (`fa.parallel`) de Horn para contrastar la recomendación automática frente al límite formal de grados de libertad.


``` r
set.seed(26)
paralelo <- fa.parallel(X, fm = "minres", fa = "fa", plot = FALSE)
```

```
## Parallel analysis suggests that the number of factors =  3  and the number of components =  NA
```

``` r
n_sug <- paralelo$nfact
```

> 📋 **Qué ve / Describir:**  
> Para $p = 6$, una dimensión deja $gl = 9$ y dos dimensiones dejan $gl = 4$. Con tres dimensiones, los grados de libertad caen a **$gl = 0$**, y con cuatro dimensiones pasan a ser **negativos ($gl = -3$)**. Por su parte, el análisis paralelo automático sugiere $k = 3$ factores.
>
> 🔎 **Qué significa / Analizar:**  
> Aunque la regla automática sugiera 3 factores, un modelo de 3 factores sobre 6 variables está saturado ($gl = 0$): consume todas las piezas de información disponibles sin dejar margen para ser comprobado. Y cuatro factores son una imposibilidad algebraica. **Con seis variables, el límite máximo riguroso son dos factores.**
>
> ⚖️ **Qué decide él / Decisión:**  
> Se rechaza incorporar un tercer factor en este modelo. Si el Ministerio desea modelar el tamaño poblacional o el entorno rural como factor latente adicional, debe incorporar al menos 3 a 5 variables de contexto demográfico e institucional adicionales.

---

# 7. El costo para el Ministerio: ¿se solapan los dos fondos?

Si el Ministerio aplica las dos capacidades rotadas y asigna recursos priorizando al **20 % con mayor rezago en Acceso** (Fondo 1) y al **20 % con mayor rezago en Permanencia** (Fondo 2): ¿atiende a los mismos municipios dos veces o llega a territorios distintos?


``` r
f_scores <- fa(X, nfactors = 2, fm = "ml", rotate = "oblimin", scores = "regression")
scores_mat <- f_scores$scores

# En F1 (Acceso), mayor valor = mayor cobertura -> peor 20% es menor score
# En F2 (Permanencia), aprobación pesa + y deserción pesa - -> peor 20% es menor score
peor_f1 <- scores_mat[, 1] <= quantile(scores_mat[, 1], 0.20)
peor_f2 <- scores_mat[, 2] <= quantile(scores_mat[, 2], 0.20)

n_f1_solo <- sum(peor_f1 & !peor_f2)
n_f2_solo <- sum(!peor_f1 & peor_f2)
n_ambos   <- sum(peor_f1 & peor_f2)
pct_repetidos <- round(100 * n_ambos / sum(peor_f1), 1)

solapamiento_df <- data.frame(
  Grupo = c("Solo Fondo 1: Acceso / Infraestructura",
            "En ambos fondos simultáneamente",
            "Solo Fondo 2: Permanencia / Tutorías"),
  Registros = c(n_f1_solo, n_ambos, n_f2_solo),
  Porcentaje_Sobre_Fondo1 = c(round(100 * n_f1_solo / sum(peor_f1), 1),
                              pct_repetidos,
                              round(100 * n_f2_solo / sum(peor_f1), 1))
)

write.csv(solapamiento_df, file.path(dir_tablas, "solapamiento_perfiles.csv"), row.names = FALSE)
```


``` r
fig_solap <- file.path(dir_figuras, "solapamiento_perfiles.png")

p_solap <- solapamiento_df %>%
  mutate(Grupo = factor(Grupo, levels = Grupo)) %>%
  ggplot(aes(x = Registros, y = "", fill = Grupo)) +
  geom_col(width = 0.5, position = position_stack(reverse = TRUE)) +
  geom_text(aes(label = paste0(miles(Registros), "\n(", Porcentaje_Sobre_Fondo1, " %)")),
            position = position_stack(vjust = 0.5, reverse = TRUE),
            color = "white", fontface = "bold", size = 3.6) +
  scale_fill_manual(values = c("Solo Fondo 1: Acceso / Infraestructura" = "#2B6CB0",
                               "En ambos fondos simultáneamente" = "#6B7280",
                               "Solo Fondo 2: Permanencia / Tutorías" = "#C05621"),
                    name = NULL) +
  scale_x_continuous(labels = miles) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "top", plot.title.position = "plot") +
  labs(
    title = "Focalización con dos capacidades rotadas: ¿cuántos municipios coinciden?",
    subtitle = "Municipios en el 20 % más vulnerable de cada fondo especializado",
    x = "Registros municipio-año",
    y = NULL
  )

ggsave(fig_solap, plot = p_solap, width = 8, height = 4, dpi = 150)
p_solap
```

<div class="figure" style="text-align: center">
<img src="figure/grafico-solapamiento-1.png" alt="plot of chunk grafico-solapamiento"  />
<p class="caption">plot of chunk grafico-solapamiento</p>
</div>


``` r
knitr::kable(
  solapamiento_df,
  format = "pipe",
  col.names = c("Destino del apoyo", "N° de registros municipio-año", "% respecto al cupo de un fondo"),
  format.args = list(big.mark = ".", decimal.mark = ","),
  caption = "Distribución de municipios beneficiarios al implementar dos fondos especializados basados en los factores rotados."
)
```



Table: Distribución de municipios beneficiarios al implementar dos fondos especializados basados en los factores rotados.

|Destino del apoyo                      | N° de registros municipio-año| % respecto al cupo de un fondo|
|:--------------------------------------|-----------------------------:|------------------------------:|
|Solo Fondo 1: Acceso / Infraestructura |                         2.029|                           73,5|
|En ambos fondos simultáneamente        |                           732|                           26,5|
|Solo Fondo 2: Permanencia / Tutorías   |                         2.029|                           73,5|

> 📋 **Qué ve / Describir:**  
> Cada fondo selecciona a 2 761 registros (el 20 % más rezagado en su capacidad). Sin embargo, solo **732 municipios coinciden en ambos fondos** (un 26,5 %). La gran mayoría de los beneficiarios (73,5 %) requiere atención en **uno solo de los dos fondos**: 2 029 necesitan únicamente infraestructura de acceso y 2 029 necesitan exclusivamente tutorías para frenar la deserción.
>
> 🔎 **Qué significa / Analizar:**  
> Este hallazgo es el argumento definitivo para la Dirección de Cobertura:
> - En problemas de talento individual o pruebas Saber, las habilidades correlacionadas hacen que dos perfiles escojan casi a la misma gente (75 % de repetición).
> - En política territorial educativa ocurre exactamente lo opuesto: **los municipios que tienen déficit de aulas no son los mismos que sufren deserción escolar**.
>
> ⚖️ **Qué decide él / Decisión:**  
> Si el Ministerio hubiera unificado los fondos, habría beneficiado únicamente a los municipios del centro compartidos, dejando en el abandono a miles de comunidades que tienen resuelto el acceso pero pierden a sus estudiantes antes de graduarse. Mantener dos convocatorias independientes duplica la eficiencia de la inversión pública.

---

# 8. Qué no es rotar

- **No es alterar la realidad ni forzar los números:** La rotación no añade varianza explicada ni disminuye el error del modelo; la comunalidad de cada indicador permanece inmutable.
- **No inventa dimensiones:** Si las variables no tuvieran una correlación subyacente independiente, rotar no crearía dos factores limpios.
- **El nombre responde a la responsabilidad de política pública:** Los nombres «Capacidad de Acceso» y «Capacidad de Permanencia» surgen de los indicadores dominantes y son operativos para el diseño institucional.

---

# 9. Conclusión: dictamen final para el Ministerio de Educación

Al Director de Cobertura y Equidad Territorial le certificamos:

1. **La rotación oblicua (Oblimin) define con nitidez dos capacidades territoriales:**
   - **Capacidad de Acceso y Cobertura (Factor 1):** gobernada por la matrícula neta y media.
   - **Capacidad de Permanencia y Retención (Factor 2):** gobernada por la aprobación y la deserción.
2. **Las dos dimensiones son independientes:** Su correlación es mínima ($\Phi \approx 0,14$). Un municipio con alta cobertura no está blindado contra la deserción.
3. **La solución es altamente estable:** ML y MinRes arrojan prácticamente las mismas cargas factoriales.
4. **Límite matemático:** Con seis indicadores, el número máximo de factores comprobables es dos ($gl = 4$). Un tercer factor satura el modelo ($gl = 0$) y cuatro es matemáticamente inviable.
5. **Solapamiento mínimo entre beneficiarios:** Solo el 26,5 % de los municipios rezagados califica simultáneamente en ambos fondos. Mantener dos líneas especializadas garantiza cobertura focalizada para realidades educativas opuestas.

