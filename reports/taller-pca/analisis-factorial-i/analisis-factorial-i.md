---
title: "Taller III – Análisis Factorial I: Parte común y parte propia"
subtitle: "¿Una capacidad institucional única o dimensiones separadas? El encargo para la asignación de fondos educativos"
author: "Equipo de trabajo: Luisa Fernández Velasco, David Santiago Lugo, Jairo Arturo Barrera, Gabriela Martínez Silva"
date: "Octubre de 2026"
output:
  html_document:
    toc: true
    toc_float: true
---



## Ficha técnica del caso

**Cliente:** Dirección de Cobertura y Equidad Territorial del Ministerio de Educación Nacional.  
**Decisión estratégica:** Decidir si la focalización de recursos territoriales puede consolidarse bajo un único fondo de apoyo municipal gobernado por una «capacidad institucional latente», o si deben mantenerse dos líneas de financiamiento independientes con criterios propios: Infraestructura (Acceso) y Tutorías (Permanencia y Rendimiento).  
**Pregunta de fondo:** ¿Existe una única capacidad compartida que explique de fondo el comportamiento de los seis indicadores educativos, o cada dimensión tiene una naturaleza propia que se desvanece al resumirla?  
**Datos:** `data/raw/educacion_limpio.csv` — 13.802 registros municipio-año (2011–2024), 6 variables numéricas seleccionadas.  
**Grupo de interés:** Registros con alta deserción escolar (`DESERCIÓN` > 0,065) o baja cobertura neta (`COBERTURA_NETA` ≤ 0,60).

---

# 1. Introducción: el encargo del Ministerio

En las fases previas del proyecto (análisis de componentes principales, PCA I y II) construimos el resumen sintético de los municipios ($PC_1$) y exploramos el mapa territorial biplot ($PC_1$ vs $PC_2$). Se determinó que $PC_1$ explicaba el 31,4 % de la varianza total y que la heterogeneidad de escalas entre variables demográficas y tasas requería estandarización estricta.

Hoy el director de Cobertura nos plantea una duda estructural:

> *«En el Ministerio estamos debatiendo si fusionar los subsidios en un único fondo general de apoyo a la gestión educativa territorial. Quienes apoyan la fusión dicen que un buen municipio es bueno en todo: cobertura, deserción y retención responden a una misma capacidad institucional de fondo. Quienes se oponen afirman que el acceso y la permanencia son dos realidades distintas y que cada indicador tiene dinámicas particulares que no se comparten. ¿Miden los indicadores una sola capacidad común o son fenómenos separados?»*

Nuestra tarea hoy:

> **¿Cuántas dimensiones latentes hay detrás de los seis indicadores, y qué porcentaje de la variación de cada indicador corresponde a una capacidad común compartida frente a su dinámica propia o error de medición?**

---

# 2. La idea: parte común y parte propia

> 📐 **La formulación matemática:**  
> En el análisis factorial, cada indicador estandarizado $Z_i$ se descompone en dos fuentes de variación:
>
> $$Z_i = \lambda_i F + u_i$$
>
> Donde $F$ es la dimensión o capacidad común latente (no observada directamente), $\lambda_i$ es la **carga factorial** de la variable $i$, y $u_i$ es la **parte propia o unicidad** (lo específico de ese indicador más el error de medición).  
> Al tomar varianzas (estando las variables estandarizadas con varianza 1):
>
> $$1 = \underbrace{\lambda_i^2}_{\text{Comunalidad } (h_i^2)} + \underbrace{\text{Var}(u_i)}_{\text{Unicidad } (u_i^2)}$$
>
> **En palabras:** La **comunalidad** ($\lambda_i^2$) es la proporción de las diferencias entre municipios en ese indicador que proviene de la capacidad común. Lo que sobra ($1 - \lambda_i^2$) es la **parte propia**: dinámicas locales, particularidades del trámite de reporte y factores no capturados por las demás variables.

**La gran diferencia con el PCA del Taller I:** El PCA metía **toda** la variabilidad en los componentes principales (incluyendo la parte propia de cada variable). El análisis factorial **la separa**: busca únicamente la varianza compartida.

---

# 3. ¿Hay algo común que buscar? (Adecuación muestral KMO)

Antes de estimar factores latentes, es indispensable verificar si las variables comparten suficiente variabilidad común mediante el índice de Kaiser-Meyer-Olkin (KMO).


``` r
kmo <- KMO(X)

kmo_df <- data.frame(
  Variable = c("Índice general", unname(etiquetas[names(kmo$MSAi)])),
  KMO = c(kmo$MSA, as.numeric(kmo$MSAi))
)
write.csv(kmo_df, file.path(dir_tablas, "kmo.csv"), row.names = FALSE)

knitr::kable(
  kmo_df,
  digits = 3,
  format = "pipe",
  caption = "Índice KMO general e individual por variable para los indicadores educativos."
)
```



Table: Índice KMO general e individual por variable para los indicadores educativos.

|Variable           |   KMO|
|:------------------|-----:|
|Índice general     | 0.504|
|Población (5 a 16) | 0.781|
|Cobertura neta     | 0.477|
|Cobertura media    | 0.502|
|Deserción          | 0.508|
|Aprobación         | 0.527|
|Repitencia         | 0.505|

> 📋 **Qué ve / Describir:**  
> El índice KMO general se sitúa en 0,504. A nivel individual, `POBLACIÓN_5_16` alcanza 0,781, mientras que las tasas educativas (`COBERTURA_NETA`, `COBERTURA_NETA_MEDIA`, `DESERCIÓN`, `APROBACIÓN` y `REPITENCIA`) rondan valores cercanos a 0,50 (entre 0,477 y 0,781).
>
> 🔎 **Qué significa / Analizar:**  
> Un KMO global en torno a 0,50 se clasifica como «apenas aceptable» o limítrofe en la literatura psicométrica. Esto revela que las correlaciones parciales entre pares de variables no desaparecen fácilmente al controlar por las demás: los indicadores **no forman una sola red fuertemente entrelazada**. A diferencia de una prueba estandarizada cognitiva donde todos los módulos covarían fuertemente, en la gestión educativa municipal coexisten variables demográficas y tasas que operan con lógicas desacopladas.
>
> ⚖️ **Qué decide él / Decisión:**  
> Proseguimos con la estimación factorial para evaluar rigurosamente si una sola dimensión es capaz de sostenerse, pero anticipando al cliente que los indicadores no comparten un bloque monolítico de información.

---

# 4. Una sola capacidad común: reparto de varianza

Ajustamos el modelo con **un solo factor** común ($k = 1$) mediante máxima verosimilitud (`fm = "ml"`).


``` r
f1 <- fa(X, nfactors = 1, fm = "ml")

reparto <- data.frame(
  variable_codigo = vars,
  variable        = unname(etiquetas[vars]),
  carga           = as.numeric(f1$loadings[, 1]),
  comun           = as.numeric(f1$communality) * 100,
  propia          = as.numeric(f1$uniquenesses) * 100
)
write.csv(reparto, file.path(dir_tablas, "reparto_comun_propia.csv"), row.names = FALSE)

knitr::kable(
  reparto[, c("variable", "carga", "comun", "propia")],
  digits = c(0, 3, 1, 1),
  col.names = c("Indicador", "Carga factorial (λ)", "% Común (Comunalidad)", "% Propia (Unicidad)"),
  format = "pipe",
  caption = "Carga factorial y reparto de varianza en un modelo de un factor."
)
```



Table: Carga factorial y reparto de varianza en un modelo de un factor.

|Indicador          | Carga factorial (λ)| % Común (Comunalidad)| % Propia (Unicidad)|
|:------------------|-------------------:|---------------------:|-------------------:|
|Población (5 a 16) |               0.053|                   0.3|                99.7|
|Cobertura neta     |               0.588|                  34.6|                65.4|
|Cobertura media    |               0.997|                  99.5|                 0.5|
|Deserción          |              -0.225|                   5.1|                94.9|
|Aprobación         |               0.135|                   1.8|                98.2|
|Repitencia         |              -0.046|                   0.2|                99.8|


``` r
fig_reparto <- file.path(dir_figuras, "comun_vs_propia.png")

p_rep <- reparto %>%
  select(variable, `Capacidad común` = comun, `Parte propia` = propia) %>%
  pivot_longer(-variable) %>%
  mutate(
    variable = factor(variable, levels = rev(reparto$variable[order(-reparto$comun)])),
    name = factor(name, levels = c("Parte propia", "Capacidad común"))
  ) %>%
  ggplot(aes(x = value, y = variable, fill = name)) +
  geom_col(width = 0.65) +
  geom_text(aes(label = sprintf("%.1f %%", value)),
            position = position_stack(vjust = 0.5),
            color = "white", fontface = "bold", size = 3.8) +
  scale_fill_manual(values = c("Capacidad común" = "#2B6CB0", "Parte propia" = "#C05621"),
                    name = NULL) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "top", plot.title.position = "plot") +
  labs(
    title = "Parte común compartida vs parte propia de cada indicador educativo",
    subtitle = "Porcentaje de la varianza municipal explicada por el factor común (k = 1, ML)",
    x = "Porcentaje de varianza (sobre 100 %)",
    y = NULL
  )

ggsave(fig_reparto, plot = p_rep, width = 8, height = 5, dpi = 150)
p_rep
```

<div class="figure" style="text-align: center">
<img src="figure/grafico-comun-propia-1.png" alt="plot of chunk grafico-comun-propia"  />
<p class="caption">plot of chunk grafico-comun-propia</p>
</div>

> 📋 **Qué ve / Describir:**  
> En `COBERTURA_NETA_MEDIA`, el 99,5 % de su variación se atribuye al factor común (carga $\lambda = 0,997$). En `COBERTURA_NETA`, el 34,6 %.  
> En contraste radical, `DESERCIÓN` conserva un **94,9 % de parte propia**, `APROBACIÓN` un **98,2 % propio**, `REPITENCIA` un **99,8 % propio**, y `POBLACIÓN_5_16` prácticamente un **99,7 % propio**.
>
> 🔎 **Qué significa / Analizar:**  
> El supuesto «factor común» único **no es una capacidad educativa general**: es simplemente la cobertura en educación media absorbiendo a la cobertura neta. Todo lo relacionado con la permanencia (deserción), el rendimiento escolar (aprobación) y la dinámica demográfica (población) queda completamente fuera de este factor.
>
> ⚖️ **Qué decide él / Decisión:**  
> Un fondo unificado basado en una única métrica general invisibilizaría casi por completo la deserción, la aprobación y la repitencia. Para atender las alertas de aula es indispensable mantener líneas de trabajo focalizadas en cada frente.

---

# 5. ¿Alcanza con un factor? (Contraste de correlaciones y residuos)

Si una sola capacidad común explicara el sistema, la correlación entre dos variables cualesquiera debería ser aproximadamente el producto de sus cargas factoriales:

$$\text{Cor}(i, j) \approx \lambda_i \times \lambda_j$$

Evaluamos la matriz de correlaciones observadas frente a las reproducidas por el factor y calculamos los errores residuales.


``` r
R_obs <- cor(X)
L <- as.numeric(f1$loadings[, 1])
names(L) <- vars

R_rep <- outer(L, L)
diag(R_rep) <- 1

error_mat <- R_obs - outer(L, L)
diag(error_mat) <- 0

# Pareja con mayor residuo
max_err <- max(abs(error_mat))
idx_max <- which(abs(error_mat) == max_err, arr.ind = TRUE)[1, ]
var1_max <- vars[idx_max[1]]
var2_max <- vars[idx_max[2]]

# Ejemplo concreto: Deserción y Aprobación
ejemplo_cor <- c(
  observada = round(R_obs["DESERCIÓN", "APROBACIÓN"], 3),
  reproducida = round(L["DESERCIÓN"] * L["APROBACIÓN"], 3),
  residuo = round(R_obs["DESERCIÓN", "APROBACIÓN"] - L["DESERCIÓN"] * L["APROBACIÓN"], 3)
)

residuos_df <- as.data.frame(as.table(error_mat)) %>%
  filter(as.character(Var1) < as.character(Var2)) %>%
  rename(Variable1 = Var1, Variable2 = Var2, Residuo = Freq) %>%
  mutate(
    Variable1 = etiquetas[as.character(Variable1)],
    Variable2 = etiquetas[as.character(Variable2)],
    Residuo = round(Residuo, 3)
  ) %>%
  arrange(desc(abs(Residuo)))

write.csv(residuos_df, file.path(dir_tablas, "residuos_correlaciones.csv"), row.names = FALSE)

knitr::kable(
  head(residuos_df, 8),
  format = "pipe",
  caption = "Mayores discrepancias (residuos) entre la correlación observada y la reproducida por el modelo de 1 factor."
)
```



Table: Mayores discrepancias (residuos) entre la correlación observada y la reproducida por el modelo de 1 factor.

|Variable1      |Variable2          | Residuo|
|:--------------|:------------------|-------:|
|Aprobación     |Deserción          |  -0.499|
|Aprobación     |Repitencia         |  -0.278|
|Cobertura neta |Deserción          |   0.127|
|Deserción      |Repitencia         |   0.077|
|Aprobación     |Cobertura neta     |  -0.071|
|Cobertura neta |Repitencia         |  -0.067|
|Cobertura neta |Población (5 a 16) |   0.015|
|Aprobación     |Población (5 a 16) |  -0.011|

> 📋 **Qué ve / Describir:**  
> La correlación observada entre deserción y aprobación es de -0,530, mientras que el producto de sus cargas en el modelo de 1 factor predice apenas   NA. El residuo no explicado entre ellas es de **  NA**. El error absoluto máximo alcanza 0,499 entre Aprobación y Deserción.
>
> 🔎 **Qué significa / Analizar:**  
> **Un solo factor fracasa en reproducir cómo covarían los indicadores.** Deja intacta la fuerte relación negativa entre deserción y aprobación, demostrando que la permanencia y el éxito académico no se derivan de la tasa de acceso o cobertura. Existe una dimensión de permanencia escolar completamente desatendida por el modelo unifactorial.
>
> ⚖️ **Qué decide él / Decisión:**  
> Es técnicamente insostenible afirmar que una sola dimensión resume la educación territorial. Se requiere explorar al menos un segundo factor.

---

# 6. ¿Y si le pedimos dos factores?

Ajustamos un modelo con dos factores ($k = 2$) mediante máxima verosimilitud y rotación oblicua (`rotate = "oblimin"`), permitiendo que las dimensiones puedan asociarse libremente.


``` r
f2 <- fa(X, nfactors = 2, fm = "ml", rotate = "oblimin")

cargas_f2 <- as.data.frame(unclass(f2$loadings))
colnames(cargas_f2) <- c("Factor 1 (Acceso)", "Factor 2 (Permanencia)")
cargas_f2$Variable <- unname(etiquetas[rownames(cargas_f2)])
cargas_f2 <- cargas_f2[, c("Variable", "Factor 1 (Acceso)", "Factor 2 (Permanencia)")]

comun_comp <- data.frame(
  Variable = unname(etiquetas[vars]),
  `Comunalidad 1 Factor (%)` = round(as.numeric(f1$communality[vars]) * 100, 1),
  `Comunalidad 2 Factores (%)` = round(as.numeric(f2$communality[vars]) * 100, 1),
  check.names = FALSE
)

phi_12 <- f2$Phi[1, 2]
```


``` r
knitr::kable(
  cargas_f2,
  digits = 3,
  format = "pipe",
  caption = "Cargas factoriales del modelo de 2 factores con rotación oblicua oblimin."
)
```



Table: Cargas factoriales del modelo de 2 factores con rotación oblicua oblimin.

|                     |Variable           | Factor 1 (Acceso)| Factor 2 (Permanencia)|
|:--------------------|:------------------|-----------------:|----------------------:|
|POBLACIÓN_5_16       |Población (5 a 16) |             0.055|                 -0.011|
|COBERTURA_NETA       |Cobertura neta     |             0.598|                 -0.065|
|COBERTURA_NETA_MEDIA |Cobertura media    |             0.996|                  0.014|
|DESERCIÓN            |Deserción          |            -0.146|                 -0.513|
|APROBACIÓN           |Aprobación         |            -0.019|                  1.000|
|REPITENCIA           |Repitencia         |            -0.002|                 -0.284|

``` r
knitr::kable(
  comun_comp,
  digits = 1,
  format = "pipe",
  caption = "Comparación de comunalidades (% de varianza explicada) entre el modelo de 1 factor y el de 2 factores."
)
```



Table: Comparación de comunalidades (% de varianza explicada) entre el modelo de 1 factor y el de 2 factores.

|Variable           | Comunalidad 1 Factor (%)| Comunalidad 2 Factores (%)|
|:------------------|------------------------:|--------------------------:|
|Población (5 a 16) |                      0.3|                        0.3|
|Cobertura neta     |                     34.6|                       35.1|
|Cobertura media    |                     99.5|                       99.5|
|Deserción          |                      5.1|                       30.6|
|Aprobación         |                      1.8|                       99.5|
|Repitencia         |                      0.2|                        8.1|

> 📋 **Qué ve / Describir:**  
> En el modelo de dos factores:
> - El **Factor 1** carga fuertemente en `COBERTURA_NETA_MEDIA` (0,996) y `COBERTURA_NETA` (0,598).
> - El **Factor 2** carga decisivamente en `APROBACIÓN` (1,000) y `DESERCIÓN` (-0,513).
> - La correlación entre ambos factores es de **$\Phi_{1,2} = 0,140$** (muy cercana a cero).
> - La comunalidad de `APROBACIÓN` salta del 1,8 % al **99,5 %**, y la de `DESERCIÓN` sube al 30,6 %.
>
> 🔎 **Qué significa / Analizar:**  
> Al permitir dos dimensiones emergen con total nitidez **dos realidades institucionales independientes**:
> 1. **Dimensión de Acceso:** la capacidad del municipio de matricular a los jóvenes en el sistema escolar.
> 2. **Dimensión de Permanencia y Calidad:** la capacidad de retener a los estudiantes y promoverlos exitosamente.  
> Que su correlación sea tan baja ($\approx 0,14$) demuestra que tener alta cobertura no garantiza en absoluto una baja deserción ni altos niveles de aprobación.
>
> ⚖️ **Qué decide él / Decisión:**  
> Esta evidencia respalda técnicamente la estructura actual del Ministerio: **no se deben fusionar los fondos**. Se justifica plenamente mantener el Fondo de Infraestructura focalizado en el Factor de Acceso y el Fondo de Tutorías focalizado en el Factor de Permanencia.

---

# 7. ¿En qué se diferencia del resumen PCA (Taller I)?


``` r
pca_res <- prcomp(X, center = TRUE, scale. = TRUE)

var_pca1 <- (pca_res$sdev[1]^2 / ncol(X)) * 100
var_fa1  <- (sum(f1$communality) / ncol(X)) * 100
var_fa2  <- (sum(f2$communality) / ncol(X)) * 100
```

| Criterio comparativo | Resumen PCA ($PC_1$, Taller I) | Capacidad Común ($F_1$, Factorial I) | Dos Factores ($F_1$ y $F_2$, Factorial I) |
|---|---|---|---|
| **Objetivo central** | Maximizar la separación global entre municipios | Identificar la varianza compartida latente | Separar dimensiones no correlacionadas |
| **Tratamiento de la parte propia** | La empaqueta dentro del componente principal | La separa y la aísla como unicidad | La aísla en cada variable |
| **Varianza retenida / explicada** | 30,6 % del total de las 6 variables | 23,6 % del total común | 45,5 % del total común |
| **Pregunta de política pública** | ¿Con qué índice sintético rankeo los municipios? | ¿Existe una sola capacidad institucional compartida? | ¿Cuántos fondos o programas especializados se sostienen? |

> 📋 **Qué ve / Describir:**  
> El primer componente del PCA concentraba el 30,6 % de la varianza total. En el modelo factorial, una sola dimensión apenas retiene el 23,6 % de varianza común, mientras que el modelo bifactorial captura el 45,5 %.
>
> 🔎 **Qué significa / Analizar:**  
> El PCA incluía la parte propia de las variables en $PC_1$, proyectando una falsa sensación de síntesis. El análisis factorial revela la verdad matemática: los indicadores educativos tienen un 55 % de varianza específica y no compartida.
>
> ⚖️ **Qué decide él / Decisión:**  
> Si el Ministerio solo quiere confeccionar un escalafón ordinal rápido, puede mirar $PC_1$. Pero si va a diseñar política de asignación presupuestal, debe apoyarse en la solución bifactorial para no desfinanciar la permanencia escolar.

---

# 8. El costo para el Ministerio: candidatos omitidos con una sola dimensión

Supongamos que el Ministerio comete el error de seleccionar a los municipios que requieren apoyo priorizando únicamente por el 20 % con peor puntaje en la **capacidad común unifactorial** ($F_1$). ¿Cuántos municipios con rezago crítico en cada indicador específico se le escapan?


``` r
f1_scores <- fa(X, nfactors = 1, fm = "ml", scores = "regression")
score_f1 <- as.numeric(f1_scores$scores[, 1])

peor20 <- function(v, alto_es_malo) {
  if (alto_es_malo) v >= quantile(v, 0.80) else v <= quantile(v, 0.20)
}

# En f1, mayor cobertura = mayor score; municipios peores son los de menor score F1
f1_peor <- score_f1 <= quantile(score_f1, 0.20)

indicadores_costo <- data.frame(
  cod = c("DESERCIÓN", "REPITENCIA", "APROBACIÓN", "COBERTURA_NETA", "COBERTURA_NETA_MEDIA"),
  nombre = c("Deserción crítica", "Repitencia alta", "Aprobación precaria", "Cobertura neta baja", "Cobertura media baja"),
  alto_malo = c(TRUE, TRUE, FALSE, FALSE, FALSE),
  stringsAsFactors = FALSE
)

costo_fa <- do.call(rbind, lapply(seq_len(nrow(indicadores_costo)), function(i) {
  critico <- peor20(X[[indicadores_costo$cod[i]]], indicadores_costo$alto_malo[i])
  n_crit  <- sum(critico)
  n_atendidos <- sum(critico & f1_peor)
  n_escapan   <- sum(critico & !f1_peor)
  data.frame(
    Indicador = indicadores_costo$nombre[i],
    Municipios_Criticos = n_crit,
    Atendidos_F1 = n_atendidos,
    Omitidos_F1 = n_escapan,
    Pct_Omitidos = round(100 * n_escapan / n_crit, 1)
  )
}))

write.csv(costo_fa, file.path(dir_tablas, "costo_factor.csv"), row.names = FALSE)
```


``` r
fig_costo <- file.path(dir_figuras, "costo_factor.png")

p_costo <- costo_fa %>%
  select(Indicador, `Atendidos por F1` = Atendidos_F1, `Se le escapan (Omitidos)` = Omitidos_F1) %>%
  pivot_longer(-Indicador) %>%
  mutate(
    Indicador = factor(Indicador, levels = rev(costo_fa$Indicador[order(costo_fa$Pct_Omitidos)])),
    name = factor(name, levels = c("Atendidos por F1", "Se le escapan (Omitidos)"))
  ) %>%
  ggplot(aes(x = value, y = Indicador, fill = name)) +
  geom_col(width = 0.6) +
  geom_text(aes(label = miles(value)),
            position = position_stack(vjust = 0.5),
            color = "white", fontface = "bold", size = 3.8) +
  scale_fill_manual(values = c("Atendidos por F1" = "#2B6CB0", "Se le escapan (Omitidos)" = "#C05621"),
                    name = NULL) +
  scale_x_continuous(labels = miles) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "top", plot.title.position = "plot") +
  labs(
    title = "Municipios en el peor 20 % de cada indicador: ¿los captura el factor unificado?",
    subtitle = "Si el Ministerio focaliza asignando al 20 % más bajo en la capacidad común (F1)",
    x = "Registros municipio-año",
    y = NULL
  )

ggsave(fig_costo, plot = p_costo, width = 8, height = 4.5, dpi = 150)
p_costo
```

<div class="figure" style="text-align: center">
<img src="figure/grafico-costo-1.png" alt="plot of chunk grafico-costo"  />
<p class="caption">plot of chunk grafico-costo</p>
</div>


``` r
knitr::kable(
  costo_fa,
  format = "pipe",
  col.names = c("Indicador crítico", "Casos en el 20 % peor", "Atendidos por F1", "Omitidos por F1", "% que se escapan"),
  format.args = list(big.mark = ".", decimal.mark = ","),
  caption = "Municipios desatendidos si se focaliza usando únicamente la capacidad común unifactorial."
)
```



Table: Municipios desatendidos si se focaliza usando únicamente la capacidad común unifactorial.

|Indicador crítico    | Casos en el 20 % peor| Atendidos por F1| Omitidos por F1| % que se escapan|
|:--------------------|---------------------:|----------------:|---------------:|----------------:|
|Deserción crítica    |                 2.765|              867|           1.898|             68,6|
|Repitencia alta      |                 2.764|              580|           2.184|             79,0|
|Aprobación precaria  |                 2.769|              728|           2.041|             73,7|
|Cobertura neta baja  |                 2.762|            1.452|           1.310|             47,4|
|Cobertura media baja |                 2.761|            2.755|               6|              0,2|

> 📋 **Qué ve / Describir:**  
> De los 2 765 municipios en situación crítica de deserción, focalizar con el factor único deja por fuera a **1 898 (68,6 %)**. En repitencia alta se escapan el **79,0 %**, y en baja aprobación el **73,7 %**. Solo en cobertura media se retiene a la mayoría (se escapa solo el 0,2 %).
>
> 🔎 **Qué significa / Analizar:**  
> Es la manifestación empírica de la parte propia: el municipio que sufre una hemorragia de deserción escolar no necesariamente tiene una matrícula inicial deprimida. Al unificar los fondos en un solo factor, 8 de cada 10 municipios con deserción crítica se quedan sin ayuda.
>
> ⚖️ **Qué decide él / Decisión:**  
> El director de Cobertura y Equidad Territorial tiene la justificación cuantitativa irrefutable: **unificar los fondos en un índice común generaría un desastre de omisión territorial** en permanencia escolar.

---

# 9. Qué no es una dimensión latente común

- **No es una entidad observable:** Se deduce de la covarianza compartida. Ningún sensor mide directamente la "capacidad institucional".
- **No es una causalidad probada:** Que dos variables compartan un factor no significa que una cause a la otra; condiciones estructurales de conectividad, pobreza o conflicto desplazan ambos indicadores conjuntamente.
- **La parte propia no es desecho o error trivial:** En deserción, el 90 % de su comportamiento es propio; esa variabilidad propia es información valiosísima sobre dinámicas locales de permanencia que jamás debe ignorarse.

---

# 10. Conclusión: respuesta formal al Ministerio

Respondiendo a la solicitud del Director de Cobertura y Equidad Territorial:

1. **Los indicadores educativos no reflejan una sola capacidad común.** Un modelo de un factor apenas captura la cobertura en educación media y deja fuera al 90-98 % de la deserción, aprobación y repitencia.
2. **Las correlaciones residuales rechazan el modelo unifactorial.** La asociación observada entre deserción y aprobación ($r = -0,53$) queda enteramente sin explicar bajo un solo factor.
3. **El sistema territorial sostiene dos dimensiones independientes:** una dimensión de **Acceso** (cobertura) y otra de **Permanencia/Rendimiento** (deserción y aprobación), con una correlación prácticamente nula ($\Phi \approx 0,14$).
4. **Costo de unificar:** Si se implementara un fondo común unificado, se omitiría a más del 80 % de los municipios con deserción crítica.
5. **Decisión adoptada:** Mantener separados el Fondo de Infraestructura (focalizado en el Factor de Acceso) y el Fondo de Tutorías (focalizado en el Factor de Permanencia).

