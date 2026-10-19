# Informe de calendario – Análisis de Componentes Principales (PCA)

**Proyecto:** Estadística Multidimensional – Indicadores Educativos  
**Repositorio:** `Proyectos estadistica`  
**Lenguaje:** R (RStudio Project)  
**Duración del sprint PCA:** 1 semana (5 días hábiles)  
**Equipo:** Milu, David, Jairo y Gabriela  
**Fecha de elaboración:** 17 de octubre de 2026

---

## 1. Contexto y estado actual del repositorio

El proyecto ya cuenta con un avance considerable, por lo que este cronograma no parte de cero. Se enfoca exclusivamente en el análisis de componentes principales y su entrega.

| Elemento | Estado | Ubicación en el repositorio |
|---|---|---|
| Entorno | RStudio Project, R 4.5.3 | `Proyectos estadistica.Rproj` |
| Dataset limpio | 5 063 filas × 30 columnas, sin valores faltantes | `data/raw/educacion_limpio.csv` |
| Variables para análisis | 28 indicadores educativos (2 excluidas por falta de varianza) | `outputs/taller-02/tables/Variables_usadas.csv` |
| Datos normalizados | Ya listos (z-score) | `outputs/taller-02/tables/Datos_normalizados.csv` |
| Matriz de correlación | Ya calculada | `outputs/taller-02/tables/Matriz_correlacion.csv` |
| Matriz de covarianzas | Ya calculada | `outputs/taller-02/tables/Matriz_covarianzas.csv` |
| Reportes previos | Taller 1, Taller 2 y Corte 1 entregados | `reports/taller-01/`, `reports/taller-02/`, `reports/entrega-corte-1/` |
| Scripts de soporte | Instalación, validación y renderizado | `scripts/install_dependencies.R`, `scripts/check_project.R`, `scripts/render_reports.R` |

**Conclusión:** las etapas de carga, limpieza, selección de variables, normalización y matriz de correlación ya están resueltas. El sprint PCA comienza directamente con el cálculo de autovalores, selección de componentes, cargas, scores e informe final.

---

## 2. Objetivo del sprint

Aplicar PCA sobre los 28 indicadores educativos normalizados para:
- Identificar los componentes principales que explican la mayor parte de la varianza.
- Reducir la dimensionalidad del dataset.
- Interpretar qué indicadores agrupan cada componente.
- Proyectar las observaciones en el nuevo espacio de componentes (scores y biplot).
- Entregar un informe reproducible en R Markdown.

---

## 3. Asignación de roles (4 integrantes)

| Integrante | Rol principal | Actividades clave |
|---|---|---|
| **Milu** | Autovalores y selección de componentes | Cálculo de autovalores/autovectores, scree plot, regla de Kaiser, criterio del codo, varianza acumulada. |
| **David** | Cargas (loadings) e interpretación | Cargas de variables por componente, identificación de indicadores dominantes, interpretación temática. |
| **Jairo** | Scores y visualización | Proyección de observaciones, cálculo de scores, biplot, gráficos de componentes. |
| **Gabriela** | Informe, validación y entrega | Redacción del `.Rmd`, integración de tablas y figuras, revisión cruzada, renderizado final, documentación. |

Todos participan en el **kickoff inicial**, la **validación de la selección de componentes (martes)** y la **revisión final (viernes)**.

---

## 4. Cronograma día a día

| Día | Fecha | Actividad | Responsable principal | Entrada (repositorio) | Salida / Entregable |
|---|---|---|---|---|---|
| **Lunes** | Día 1 | Cálculo de autovalores y autovectores de la matriz de correlación. Tabla de varianza explicada por componente. Construcción del scree plot. | Milu | `Datos_normalizados.csv`, `Matriz_correlacion.csv` | `outputs/pca/tables/autovalores.csv`<br>`outputs/pca/figures/scree_plot.png` |
| **Martes** | Día 2 | Selección del número de componentes: Kaiser (autovalor > 1), método del codo y varianza acumulada (≥ 70–80 %). Decisión documentada y validada por el equipo. | Milu (validación: equipo) | Autovalores del Día 1 | Decisión: número de componentes y justificación escrita |
| **Miércoles** | Día 3 | Cálculo de cargas (loadings) de cada variable sobre los componentes retenidos. Identificación de variables dominantes por componente. | David | Matriz de correlación, autovectores | `outputs/pca/tables/loadings.csv`<br>Interpretación por componente |
| **Jueves** | Día 4 | Cálculo de scores y proyección de las 5 063 observaciones. Construcción e interpretación del biplot (variables + observaciones). | Jairo | Datos normalizados, loadings | `outputs/pca/tables/scores.csv`<br>`outputs/pca/figures/biplot.png` |
| **Viernes** | Día 5 | Redacción del informe en R Markdown, integración de tablas y figuras, revisión cruzada del equipo, renderizado final y entrega. | Gabriela (todos revisan) | Todo lo anterior | `reports/pca/analisis_pca.Rmd`<br>`reports/pca/analisis_pca.html`<br>Presentación final |

---

## 5. Estructura de carpetas propuesta (consistente con el repositorio)

Siguiendo las convenciones del proyecto (rutas en minúsculas, guiones, resultados derivados):

```
outputs/pca/
  tables/
    autovalores.csv
    loadings.csv
    scores.csv
  figures/
    scree_plot.png
    biplot.png
reports/pca/
  analisis_pca.Rmd
  analisis_pca.html
```

Comando para crear las carpetas desde R (raíz del proyecto):

```r
dir.create("outputs/pca/tables", recursive = TRUE)
dir.create("outputs/pca/figures", recursive = TRUE)
dir.create("reports/pca", recursive = TRUE)
```

---

## 6. Ritmo de trabajo y sincronías

| Instancia | Frecuencia | Duración | Propósito |
|---|---|---|---|
| Stand-up diario | Cada mañana | 15 min | Qué se hizo ayer, qué se hace hoy, bloqueos |
| Sincronía de selección | Martes al mediodía | 30 min | Validar el número de componentes (depende del lunes) |
| Revisión final | Viernes | 60 min | Revisar informe, tablas, figuras y renderizado antes de entregar |
| Control de versiones | Continuo | — | Commits en Git para compartir avances y evitar sobrescribir CSV/PNG |

---

## 7. Entregables finales

1. `outputs/pca/tables/autovalores.csv` – tabla de autovalores y varianza explicada.
2. `outputs/pca/tables/loadings.csv` – cargas de variables por componente.
3. `outputs/pca/tables/scores.csv` – scores de las 5 063 observaciones.
4. `outputs/pca/figures/scree_plot.png` – gráfico de codo.
5. `outputs/pca/figures/biplot.png` – biplot de componentes y variables.
6. `reports/pca/analisis_pca.Rmd` – informe reproducible en R Markdown.
7. `reports/pca/analisis_pca.html` – informe renderizado.
8. Presentación final (opcional, según requerimiento del curso).

---

## 8. Requisitos técnicos

- R 4.5.3 o compatible.
- Paquetes base de R suficientes para PCA (`stats::prcomp`, `stats::princomp`) o bien `FactoMineR` si se decide usar.
- Los paquetes ya instalados en el proyecto: `rmarkdown`, `knitr`, `ggplot2`, `dplyr`, `tidyr`, `reshape2` (ver `scripts/install_dependencies.R`).
- Pandoc para generar HTML desde R Markdown (si no está instalado, el script genera Markdown y conserva CSV y gráficos).

Validación previa disponible:

```r
source("scripts/check_project.R")
```

---

## 9. Notas

- El dataset en `data/raw/` **no se modifica** durante este sprint.
- Los resultados son derivados: se regeneran mediante scripts y se conservan en `outputs/pca/`.
- Los nombres de archivos nuevos deben usar ASCII, minúsculas y guiones, según las convenciones del repositorio.

---

*Informe generado para coordinar al equipo (Milu, David, Jairo y Gabriela) en la aplicación de PCA sobre el proyecto de indicadores educativos.*