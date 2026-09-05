---
title: "Checklist del dataset - Taller 2"
author: "Estadística Multidimensional"
date: "2026-09-04"
output:
  html_document:
    toc: true
    toc_depth: 3
    code_folding: show
---

Este documento revisa el dataset para covarianzas, correlaciones y distancias de Mahalanobis.
Todos los resultados se guardan en `outputs/taller-02/tables` y `outputs/taller-02/figures`.



## 1. Carga y limpieza

Los códigos geográficos se excluyen porque identifican lugares, pero no son magnitudes. Además,
`APROBACIÓN_TRANSICIÓN` y `REPROBACIÓN_TRANSICIÓN` son constantes en este archivo: se reportan y
se excluyen de los gráficos y cálculos que requieren variación.


``` r
datos <- read.csv(file.path(project_root, "data", "raw", "educacion_limpio.csv"),
                  check.names = FALSE,
                  stringsAsFactors = FALSE)

excluir <- c("CÓDIGO_MUNICIPIO", "CÓDIGO_DEPARTAMENTO")
X <- datos[, vapply(datos, is.numeric, logical(1)), drop = FALSE]
X <- X[, !names(X) %in% excluir, drop = FALSE]

# Convierte Inf y NaN a NA antes de cualquier cálculo o gráfico.
X[] <- lapply(X, function(x) {
  x[!is.finite(x)] <- NA_real_
  x
})

es_constante <- vapply(X, function(x) {
  valores <- x[is.finite(x)]
  length(valores) > 0 && length(unique(valores)) <= 1
}, logical(1))

columnas_constantes <- names(X)[es_constante]
write.csv(data.frame(Variable = columnas_constantes,
                     Motivo = "Constante o sin variación"),
          file.path(tables_dir, "Columnas_excluidas.csv"), row.names = FALSE)

# Evita rangos cero, correlaciones indefinidas y matrices singulares.
X <- X[, !es_constante, drop = FALSE]
write.csv(data.frame(Variable = names(X)),
          file.path(tables_dir, "Variables_usadas.csv"), row.names = FALSE)

cat("Columnas constantes excluidas:\n")
```

```
## Columnas constantes excluidas:
```

``` r
print(columnas_constantes)
```

```
## [1] "APROBACIÓN_TRANSICIÓN"  "REPROBACIÓN_TRANSICIÓN"
```

## 2. Tamaño y faltantes


``` r
n <- nrow(X)
p <- ncol(X)
filas_completas <- sum(complete.cases(X))
diagnostico <- data.frame(
  filas = n,
  variables = p,
  razon_n_p = n / p,
  porcentaje_faltantes = mean(is.na(as.matrix(X))) * 100,
  filas_completas = filas_completas
)
write.csv(diagnostico, file.path(tables_dir, "Diagnostico_dataset.csv"), row.names = FALSE)
kable(diagnostico, digits = 3)
```



| filas| variables| razon_n_p| porcentaje_faltantes| filas_completas|
|-----:|---------:|---------:|--------------------:|---------------:|
|  5063|        30|   168.767|                    0|            5063|

## 3. Resumen estadístico


``` r
resumen <- data.frame(
  Variable = names(X),
  Media = vapply(X, mean, numeric(1), na.rm = TRUE),
  Desv_Est = vapply(X, sd, numeric(1), na.rm = TRUE),
  Minimo = vapply(X, min, numeric(1), na.rm = TRUE),
  Mediana = vapply(X, median, numeric(1), na.rm = TRUE),
  Maximo = vapply(X, max, numeric(1), na.rm = TRUE),
  Faltantes = vapply(X, function(x) sum(is.na(x)), integer(1))
)
write.csv(resumen, file.path(tables_dir, "Resumen_estadistico.csv"), row.names = FALSE)
kable(resumen, digits = 4)
```



|                           |Variable                   |     Media|  Desv_Est| Minimo|   Mediana|     Maximo| Faltantes|
|:--------------------------|:--------------------------|---------:|---------:|------:|---------:|----------:|---------:|
|POBLACIÓN_5_16             |POBLACIÓN_5_16             | 3143.4514| 2819.8031| 1.0050| 2220.0000| 14013.0000|         0|
|TASA_MATRICULACIÓN_5_16    |TASA_MATRICULACIÓN_5_16    |    0.8319|    0.1272| 0.4538|    0.8370|     1.2347|         0|
|COBERTURA_NETA             |COBERTURA_NETA             |    0.8413|    0.1146| 0.5130|    0.8514|     1.1704|         0|
|COBERTURA_NETA_TRANSICIÓN  |COBERTURA_NETA_TRANSICIÓN  |    0.5753|    0.1340| 0.2061|    0.5751|     0.9461|         0|
|COBERTURA_NETA_PRIMARIA    |COBERTURA_NETA_PRIMARIA    |    0.8104|    0.1202| 0.4793|    0.8130|     1.1562|         0|
|COBERTURA_NETA_SECUNDARIA  |COBERTURA_NETA_SECUNDARIA  |    0.7148|    0.1297| 0.3421|    0.7152|     1.0759|         0|
|COBERTURA_NETA_MEDIA       |COBERTURA_NETA_MEDIA       |    0.4310|    0.1211| 0.0765|    0.4345|     0.7619|         0|
|COBERTURA_BRUTA            |COBERTURA_BRUTA            |    0.9473|    0.1409| 0.5523|    0.9530|     1.3556|         0|
|COBERTURA_BRUTA_TRANSICIÓN |COBERTURA_BRUTA_TRANSICIÓN |    0.8220|    0.1766| 0.3478|    0.8190|     1.3480|         0|
|COBERTURA_BRUTA_PRIMARIA   |COBERTURA_BRUTA_PRIMARIA   |    1.0010|    0.1755| 0.5340|    1.0000|     1.4775|         0|
|COBERTURA_BRUTA_SECUNDARIA |COBERTURA_BRUTA_SECUNDARIA |    1.0058|    0.1812| 0.5160|    1.0060|     1.4966|         0|
|COBERTURA_BRUTA_MEDIA      |COBERTURA_BRUTA_MEDIA      |    0.7584|    0.1873| 0.2370|    0.7580|     1.2800|         0|
|DESERCIÓN                  |DESERCIÓN                  |    0.0302|    0.0160| 0.0000|    0.0280|     0.0831|         0|
|DESERCIÓN_TRANSICIÓN       |DESERCIÓN_TRANSICIÓN       |    0.0292|    0.0214| 0.0000|    0.0265|     0.0952|         0|
|DESERCIÓN_PRIMARIA         |DESERCIÓN_PRIMARIA         |    0.0228|    0.0154| 0.0000|    0.0202|     0.0702|         0|
|DESERCIÓN_SECUNDARIA       |DESERCIÓN_SECUNDARIA       |    0.0406|    0.0240| 0.0000|    0.0374|     0.1136|         0|
|DESERCIÓN_MEDIA            |DESERCIÓN_MEDIA            |    0.0283|    0.0187| 0.0000|    0.0252|     0.0845|         0|
|APROBACIÓN                 |APROBACIÓN                 |    0.9337|    0.0370| 0.8089|    0.9364|     1.0000|         0|
|APROBACIÓN_PRIMARIA        |APROBACIÓN_PRIMARIA        |    0.9485|    0.0342| 0.8321|    0.9535|     1.0000|         0|
|APROBACIÓN_SECUNDARIA      |APROBACIÓN_SECUNDARIA      |    0.9047|    0.0594| 0.6981|    0.9113|     1.0000|         0|
|APROBACIÓN_MEDIA           |APROBACIÓN_MEDIA           |    0.9411|    0.0368| 0.8175|    0.9463|     1.0000|         0|
|REPROBACIÓN                |REPROBACIÓN                |    0.0361|    0.0310| 0.0000|    0.0340|     0.1504|         0|
|REPROBACIÓN_PRIMARIA       |REPROBACIÓN_PRIMARIA       |    0.0287|    0.0282| 0.0000|    0.0230|     0.1265|         0|
|REPROBACIÓN_SECUNDARIA     |REPROBACIÓN_SECUNDARIA     |    0.0548|    0.0513| 0.0000|    0.0475|     0.2391|         0|
|REPROBACIÓN_MEDIA          |REPROBACIÓN_MEDIA          |    0.0306|    0.0302| 0.0000|    0.0228|     0.1250|         0|
|REPITENCIA                 |REPITENCIA                 |    0.0244|    0.0220| 0.0000|    0.0176|     0.1007|         0|
|REPITENCIA_TRANSICIÓN      |REPITENCIA_TRANSICIÓN      |    0.0030|    0.0056| 0.0000|    0.0000|     0.0245|         0|
|REPITENCIA_PRIMARIA        |REPITENCIA_PRIMARIA        |    0.0233|    0.0231| 0.0000|    0.0159|     0.0994|         0|
|REPITENCIA_SECUNDARIA      |REPITENCIA_SECUNDARIA      |    0.0343|    0.0338| 0.0000|    0.0233|     0.1413|         0|
|REPITENCIA_MEDIA           |REPITENCIA_MEDIA           |    0.0117|    0.0135| 0.0000|    0.0068|     0.0532|         0|

## 4. Boxplot sin rangos cero

La normalización solo se aplica a variables con rango positivo. Así no se produce `0 / 0 = NaN`
en las variables de transición ni en ninguna otra columna constante.


``` r
normalizar <- function(x) {
  rango <- range(x, na.rm = TRUE)
  if (!all(is.finite(rango)) || diff(rango) == 0) return(rep(NA_real_, length(x)))
  (x - rango[1]) / diff(rango)
}

datos_norm <- X %>% mutate(across(everything(), normalizar))
datos_norm_largo <- datos_norm %>%
  pivot_longer(everything(), names_to = "Variable", values_to = "Valor_normalizado") %>%
  filter(is.finite(Valor_normalizado))

p_box <- ggplot(datos_norm_largo,
                aes(x = reorder(Variable, Valor_normalizado, FUN = median, na.rm = TRUE),
                    y = Valor_normalizado)) +
  geom_boxplot(fill = "#2ecc71", color = "#1e8449", outlier.color = "#c0392b") +
  coord_flip() +
  theme_minimal() +
  labs(title = "Boxplots de variables normalizadas", x = NULL, y = "Escala [0, 1]")
print(p_box)
```

<div class="figure" style="text-align: center">
<img src="figure/boxplot-1.png" alt="plot of chunk boxplot"  />
<p class="caption">plot of chunk boxplot</p>
</div>

``` r
ggsave(file.path(figures_dir, "Boxplots_normalizados.png"), p_box,
  width = 10, height = 10, dpi = 150)
write.csv(datos_norm_largo, file.path(tables_dir, "Datos_normalizados.csv"), row.names = FALSE)
```

## 5. Correlación y heatmap


``` r
matriz_corr <- cor(X, use = "pairwise.complete.obs")
matriz_corr[!is.finite(matriz_corr)] <- NA_real_
write.csv(matriz_corr, file.path(tables_dir, "Matriz_correlacion.csv"))

corr_largo <- melt(matriz_corr, varnames = c("Variable_1", "Variable_2"),
                   value.name = "Correlacion", na.rm = TRUE)
corr_largo <- corr_largo[is.finite(corr_largo$Correlacion), ]

p_heatmap <- ggplot(corr_largo, aes(Variable_1, Variable_2, fill = Correlacion)) +
  geom_tile(color = "white") +
  scale_fill_gradient2(low = "#2166ac", mid = "white", high = "#b2182b",
                       midpoint = 0, limits = c(-1, 1), na.value = "grey90") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 8),
        axis.text.y = element_text(size = 8), axis.title = element_blank(),
        panel.grid = element_blank()) +
  labs(title = "Heatmap de correlaciones de Pearson", fill = "r")
print(p_heatmap)
```

<div class="figure" style="text-align: center">
<img src="figure/correlacion-1.png" alt="plot of chunk correlacion"  />
<p class="caption">plot of chunk correlacion</p>
</div>

``` r
ggsave(file.path(figures_dir, "Heatmap_correlacion.png"), p_heatmap,
  width = 12, height = 10, dpi = 150)
```

## 6. Covarianza y Mahalanobis


``` r
S <- cov(X, use = "pairwise.complete.obs")
write.csv(S, file.path(tables_dir, "Matriz_covarianzas.csv"))

filas_X_completas <- complete.cases(X)
X_completa <- X[filas_X_completas, , drop = FALSE]
# Se estandariza para evitar que POBLACIÓN_5_16 domine numéricamente a las tasas.
# Mahalanobis es invariante ante este cambio de escala.
X_mahalanobis <- as.data.frame(scale(X_completa))
S_mahalanobis <- cov(X_mahalanobis)
matriz_invertible <- nrow(X_mahalanobis) > ncol(X_mahalanobis) &&
  qr(S_mahalanobis)$rank == ncol(S_mahalanobis)

if (matriz_invertible) {
  distancias <- mahalanobis(X_mahalanobis,
                            center = colMeans(X_mahalanobis),
                            cov = S_mahalanobis)
  write.csv(data.frame(Fila = which(filas_X_completas), Mahalanobis = distancias),
            file.path(tables_dir, "Distancias_Mahalanobis.csv"), row.names = FALSE)
  cat("Distancias calculadas para", length(distancias), "filas completas.\n")
} else {
  write.csv(data.frame(Fila = integer(0), Mahalanobis = numeric(0)),
            file.path(tables_dir, "Distancias_Mahalanobis.csv"), row.names = FALSE)
  cat("No se pudo invertir la matriz de covarianzas.\n")
}
```

```
## Distancias calculadas para 5063 filas completas.
```

## 7. Resultado del checklist


``` r
cat("Filas:", n, " | Variables usadas:", p, " | n/p:", round(n / p, 2), "\n")
```

```
## Filas: 5063  | Variables usadas: 30  | n/p: 168.77
```

``` r
cat("Filas completas:", filas_completas, "\n")
```

```
## Filas completas: 5063
```

``` r
cat("Columnas constantes excluidas:", paste(columnas_constantes, collapse = ", "), "\n")
```

```
## Columnas constantes excluidas: APROBACIÓN_TRANSICIÓN, REPROBACIÓN_TRANSICIÓN
```

``` r
cat("Los CSV quedaron en outputs/taller-02/tables y las imágenes en outputs/taller-02/figures.\n")
```

```
## Los CSV quedaron en outputs/taller-02/tables y las imágenes en outputs/taller-02/figures.
```
