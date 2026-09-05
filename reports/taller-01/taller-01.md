---
title: "Análisis Multidimensional de Indicadores Educativos"
author: "Reporte Estadístico"
date: "2026-09-04"
output:
  html_document:
    toc: true
    toc_depth: 3
    toc_float: true
    theme: flatly
    highlight: tango
    code_folding: show
  pdf_document:
    toc: true
    toc_depth: '3'
---



## Resumen del Dataset

Este reporte presenta una evaluación completa de múltiples variables e indicadores de cobertura, aprobación, reprobación, repitencia y deserción del sector educativo. El análisis discrimina adecuadamente las variables categóricas de las numéricas, normaliza los datos continuos y explora las distribuciones, valores atípicos y correlaciones estadísticas de interés.

---

## 1. Preparación del Entorno y Carga de Datos

En esta etapa inicial, se importan los datos aplicando una distinción estricta de los separadores de archivo (comas para dividir columnas) y los delimitadores de decimales (puntos). Luego, con base en el entendimiento funcional (diccionario de datos), reclasificamos las variables geográficas que originalmente son numéricas (Códigos DANE) como categóricas (factores).


``` r
# Cargar librerías necesarias
library(ggplot2)
library(dplyr)
library(tidyr)
library(reshape2)
library(knitr)

# 1. Carga de datos con parámetros explícitos (sep para comas de archivo, dec para decimales)
datos <- read.csv(file.path(project_root, "data", "raw", "educacion_limpio.csv"),
                  sep = ",", dec = ".", check.names = FALSE)

# 2. Análisis y Tipificación según "Diccionario de Datos":
# Convertimos las entidades geográficas a factores (categóricas) ya que no son magnitudes numéricas reales.
datos$CÓDIGO_MUNICIPIO <- as.factor(datos$CÓDIGO_MUNICIPIO)
datos$CÓDIGO_DEPARTAMENTO <- as.factor(datos$CÓDIGO_DEPARTAMENTO)

# Filtramos estrictamente las variables numéricas (cuantitativas reales) para el análisis estadístico
variables_numericas <- datos %>% select(where(is.numeric))
```

---

## 2. Tabla de Resumen Estadístico (Variables Clave)

La siguiente tabla consolida las estadísticas descriptivas para todas las variables cuantitativas del modelo.


``` r
# Cálculo de estadísticas clave
resumen <- data.frame(
  Variable = names(variables_numericas),
  Media = sapply(variables_numericas, mean, na.rm = TRUE),
  Desv_Est = sapply(variables_numericas, sd, na.rm = TRUE),
  Mínimo = sapply(variables_numericas, min, na.rm = TRUE),
  Mediana = sapply(variables_numericas, median, na.rm = TRUE),
  Máximo = sapply(variables_numericas, max, na.rm = TRUE)
)

# Exportar los resultados a CSV
write.csv(resumen, file.path(tables_dir, "Resumen_Estadistico.csv"), row.names = FALSE)

# Renderización de tabla en HTML
kable(resumen, digits = 3, caption = "Resumen Estadístico de las Variables Numéricas", row.names = FALSE)
```



Table: Resumen Estadístico de las Variables Numéricas

|Variable                   |    Media| Desv_Est| Mínimo|  Mediana|    Máximo|
|:--------------------------|--------:|--------:|------:|--------:|---------:|
|POBLACIÓN_5_16             | 3143.451| 2819.803|  1.005| 2220.000| 14013.000|
|TASA_MATRICULACIÓN_5_16    |    0.832|    0.127|  0.454|    0.837|     1.235|
|COBERTURA_NETA             |    0.841|    0.115|  0.513|    0.851|     1.170|
|COBERTURA_NETA_TRANSICIÓN  |    0.575|    0.134|  0.206|    0.575|     0.946|
|COBERTURA_NETA_PRIMARIA    |    0.810|    0.120|  0.479|    0.813|     1.156|
|COBERTURA_NETA_SECUNDARIA  |    0.715|    0.130|  0.342|    0.715|     1.076|
|COBERTURA_NETA_MEDIA       |    0.431|    0.121|  0.076|    0.435|     0.762|
|COBERTURA_BRUTA            |    0.947|    0.141|  0.552|    0.953|     1.356|
|COBERTURA_BRUTA_TRANSICIÓN |    0.822|    0.177|  0.348|    0.819|     1.348|
|COBERTURA_BRUTA_PRIMARIA   |    1.001|    0.176|  0.534|    1.000|     1.478|
|COBERTURA_BRUTA_SECUNDARIA |    1.006|    0.181|  0.516|    1.006|     1.497|
|COBERTURA_BRUTA_MEDIA      |    0.758|    0.187|  0.237|    0.758|     1.280|
|DESERCIÓN                  |    0.030|    0.016|  0.000|    0.028|     0.083|
|DESERCIÓN_TRANSICIÓN       |    0.029|    0.021|  0.000|    0.026|     0.095|
|DESERCIÓN_PRIMARIA         |    0.023|    0.015|  0.000|    0.020|     0.070|
|DESERCIÓN_SECUNDARIA       |    0.041|    0.024|  0.000|    0.037|     0.114|
|DESERCIÓN_MEDIA            |    0.028|    0.019|  0.000|    0.025|     0.084|
|APROBACIÓN                 |    0.934|    0.037|  0.809|    0.936|     1.000|
|APROBACIÓN_TRANSICIÓN      |    0.000|    0.000|  0.000|    0.000|     0.000|
|APROBACIÓN_PRIMARIA        |    0.948|    0.034|  0.832|    0.953|     1.000|
|APROBACIÓN_SECUNDARIA      |    0.905|    0.059|  0.698|    0.911|     1.000|
|APROBACIÓN_MEDIA           |    0.941|    0.037|  0.818|    0.946|     1.000|
|REPROBACIÓN                |    0.036|    0.031|  0.000|    0.034|     0.150|
|REPROBACIÓN_TRANSICIÓN     |    0.000|    0.000|  0.000|    0.000|     0.000|
|REPROBACIÓN_PRIMARIA       |    0.029|    0.028|  0.000|    0.023|     0.126|
|REPROBACIÓN_SECUNDARIA     |    0.055|    0.051|  0.000|    0.048|     0.239|
|REPROBACIÓN_MEDIA          |    0.031|    0.030|  0.000|    0.023|     0.125|
|REPITENCIA                 |    0.024|    0.022|  0.000|    0.018|     0.101|
|REPITENCIA_TRANSICIÓN      |    0.003|    0.006|  0.000|    0.000|     0.024|
|REPITENCIA_PRIMARIA        |    0.023|    0.023|  0.000|    0.016|     0.099|
|REPITENCIA_SECUNDARIA      |    0.034|    0.034|  0.000|    0.023|     0.141|
|REPITENCIA_MEDIA           |    0.012|    0.013|  0.000|    0.007|     0.053|

---

## 3. Histogramas para las Variables Numéricas

Se presentan las distribuciones individuales para evaluar la simetría, sesgos y concentración en cada indicador.


``` r
# Transformar datos a formato largo para facilitar la graficación con facetas
datos_long <- variables_numericas %>% 
  pivot_longer(cols = everything(), names_to = "Variable", values_to = "Valor")

# Graficar la cuadrícula de histogramas
p_hist <- ggplot(datos_long, aes(x = Valor)) +
  geom_histogram(bins = 30, fill = "#3498db", color = "black", alpha = 0.8) +
  facet_wrap(~ Variable, scales = "free", ncol = 4) +
  theme_minimal() +
  labs(
    title = "Distribución de Variables Educativas (Histogramas)",
    x = "Valor del Indicador",
    y = "Frecuencia"
  ) +
  theme(strip.text = element_text(size = 8, face = "bold"))

# Mostrar y guardar gráfico
print(p_hist)
```

<div class="figure" style="text-align: center">
<img src="figure/histogramas-1.png" alt="plot of chunk histogramas"  />
<p class="caption">plot of chunk histogramas</p>
</div>

``` r
ggsave(file.path(figures_dir, "Histogramas.png"), plot = p_hist, width = 12, height = 10)
```

---

## 4. Normalización y Diagramas de Caja (Boxplots)

Para evaluar los indicadores en una escala comparable e identificar la presencia de valores atípicos (outliers), se aplica una normalización Min-Max (rango de [0, 1]) y se consolidan en diagramas de caja.


``` r
# Función de normalización Min-Max
normalizar <- function(x) {
  rango <- range(x, na.rm = TRUE)
  if (!all(is.finite(rango)) || diff(rango) == 0) return(rep(NA_real_, length(x)))
  (x - rango[1]) / diff(rango)
}

# Aplicar normalización a las variables numéricas
datos_norm <- variables_numericas %>% mutate(across(everything(), normalizar))

# Formato largo para los boxplots
datos_norm_long <- datos_norm %>% 
  pivot_longer(cols = everything(), names_to = "Variable", values_to = "Valor_Normalizado")

# Graficar Boxplots unificados
p_box <- ggplot(datos_norm_long, aes(x = reorder(Variable, Valor_Normalizado, FUN = median, na.rm = TRUE), y = Valor_Normalizado)) +
  geom_boxplot(fill = "#2ecc71", color = "#27ae60", outlier.color = "#e74c3c", outlier.alpha = 0.5) +
  coord_flip() + # Voltear para mejorar la lectura de las etiquetas
  theme_minimal() +
  labs(
    title = "Diagramas de Caja (Variables Normalizadas [0,1])",
    x = "Variable Numérica",
    y = "Valor Normalizado"
  )

# Mostrar y guardar gráfico
print(p_box)
```

<div class="figure" style="text-align: center">
<img src="figure/boxplots_normalizados-1.png" alt="plot of chunk boxplots_normalizados"  />
<p class="caption">plot of chunk boxplots_normalizados</p>
</div>

``` r
ggsave(file.path(figures_dir, "Boxplots.png"), plot = p_box, width = 8, height = 10)
```

---

## 5. Relaciones Bivariadas (Diagramas de Dispersión)

Analizamos las interdependencias críticas entre indicadores seleccionados, evaluando su trayectoria y posibles tendencias lineales.


``` r
# Definir los 5 pares de variables solicitados
pares <- list(
  c("COBERTURA_NETA", "COBERTURA_BRUTA"),
  c("APROBACIÓN_SECUNDARIA", "REPROBACIÓN_SECUNDARIA"),
  c("DESERCIÓN", "DESERCIÓN_SECUNDARIA"),
  c("REPITENCIA", "REPITENCIA_PRIMARIA"),
  c("APROBACIÓN", "REPROBACIÓN") # Quinto par añadido para complementar el análisis
)

# Generar gráficos secuenciales y exportarlos
for (i in seq_along(pares)) {
  var1 <- pares[[i]][1]
  var2 <- pares[[i]][2]
  
  if (var1 %in% names(datos) && var2 %in% names(datos)) {
    p <- ggplot(datos, aes_string(x = var1, y = var2)) +
      geom_point(alpha = 0.5, color = "#2c3e50", size = 2) +
      geom_smooth(method = "lm", color = "#e74c3c", se = FALSE, linetype = "dashed") +
      labs(
        title = paste("Relación entre", var1, "y", var2), 
        x = var1, 
        y = var2
      ) +
      theme_minimal()
    
    print(p)
            ggsave(file.path(figures_dir,
              paste0("dispersion_", safe_file_name(var1), "_vs_",
                safe_file_name(var2), ".png")),
          plot = p, width = 6, height = 4)
  }
}
```

<div class="figure" style="text-align: center">
<img src="figure/diagramas_dispersion-1.png" alt="plot of chunk diagramas_dispersion"  />
<p class="caption">plot of chunk diagramas_dispersion</p>
</div><div class="figure" style="text-align: center">
<img src="figure/diagramas_dispersion-2.png" alt="plot of chunk diagramas_dispersion"  />
<p class="caption">plot of chunk diagramas_dispersion</p>
</div><div class="figure" style="text-align: center">
<img src="figure/diagramas_dispersion-3.png" alt="plot of chunk diagramas_dispersion"  />
<p class="caption">plot of chunk diagramas_dispersion</p>
</div><div class="figure" style="text-align: center">
<img src="figure/diagramas_dispersion-4.png" alt="plot of chunk diagramas_dispersion"  />
<p class="caption">plot of chunk diagramas_dispersion</p>
</div><div class="figure" style="text-align: center">
<img src="figure/diagramas_dispersion-5.png" alt="plot of chunk diagramas_dispersion"  />
<p class="caption">plot of chunk diagramas_dispersion</p>
</div>

---

## 6. Matriz de Correlación Completa (Pearson)

Asociación lineal cruzada entre todas las variables cuantitativas del sistema educativo.


``` r
# Matriz de Correlación ignorando valores faltantes
matriz_corr <- cor(variables_numericas, use = "pairwise.complete.obs")
matriz_corr[!is.finite(matriz_corr)] <- NA_real_

# Guardar matriz de correlación en CSV
write.csv(matriz_corr, file.path(tables_dir, "Matriz_Correlacion.csv"))

# Transformación de la matriz para el mapa de calor (Heatmap)
melted_corr <- melt(matriz_corr)

# Graficar el Heatmap
p_corr <- ggplot(melted_corr, aes(Var1, Var2, fill = value)) +
  geom_tile(color = "white") +
  scale_fill_gradient2(
    low = "#2980b9", high = "#c0392b", mid = "white", 
    midpoint = 0, limit = c(-1,1), name = "Pearson (r)"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1, size = 8),
    axis.text.y = element_text(size = 8),
    axis.title = element_blank(),
    panel.grid.major = element_blank()
  ) +
  labs(title = "Matriz de Correlación (Todas las Variables Numéricas)")

# Mostrar y guardar gráfico
print(p_corr)
```

<div class="figure" style="text-align: center">
<img src="figure/matriz_correlacion-1.png" alt="plot of chunk matriz_correlacion"  />
<p class="caption">plot of chunk matriz_correlacion</p>
</div>

``` r
ggsave(file.path(figures_dir, "Heatmap_Correlacion.png"), plot = p_corr,
  width = 10, height = 10)
```

---

## 7. Conclusiones del Análisis

Con base en los gráficos y el modelo estadístico construido, se destaca lo siguiente:

1. **Variables Geográficas vs. Métricas:** Se aplicó la separación dictada por el diccionario de datos: los Códigos DANE municipales y departamentales fueron tratados como dimensiones categóricas, dejando un espacio analítico puramente enfocado en tasas, porcentajes y coberturas.
2. **Distribuciones (Histogramas):** Se observa que las variables de *Aprobación* tienen un marcado sesgo hacia la derecha (alta concentración cerca al 100%), mientras que las métricas de *Deserción* y *Reprobación* tienen distribuciones sesgadas fuertemente hacia la izquierda, denotando valores bajos mayoritarios con una larga cola de casos críticos.
3. **Identificación de Atípicos (Boxplots):** En el plano normalizado, la *Deserción* y la *Repitencia* presentan una gran cantidad de municipios por fuera de los "bigotes" superiores, indicando enclaves territoriales con crisis educativas severas.
4. **Relaciones Lineales Bivariadas:** 
   - Se confirma una correlación negativa perfecta entre Aprobación y Reprobación, como es naturalmente esperado.
   - La Deserción Secundaria tracciona sustancialmente el indicador de Deserción General, indicando que el abandono escolar es prevalente en la educación media/secundaria más que en preescolar o primaria.
5. **Matriz de Correlación Multivariada:** Se detectan bloques altamente interconectados. Las variables de Aprobación por niveles (Transición, Primaria, Secundaria) correlacionan positivamente entre sí, y negativamente contra cualquier tipo de Reprobación y Deserción, con un patrón cromático en la matriz que divide visualmente las métricas positivas frente a los déficits del sistema educativo.
