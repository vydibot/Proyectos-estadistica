# Estadística Multidimensional: Indicadores Educativos Municipales de Colombia (2011–2024)

Proyecto del curso **Estadística Multidimensional** (Universidad Distrital Francisco José de Caldas). Se
analizan los indicadores educativos de los municipios colombianos entre 2011 y 2024, con datos del
Ministerio de Educación Nacional, para encontrar relaciones y patrones entre muchas variables a la vez.

**Equipo:** David Santiago Lugo Piñeros, Luisa Fernández Velasco López, Jairo Arturo Barrera Mosquera y
Gabriela Martínez Silva.

## Objetivos

- Examinar las relaciones entre múltiples variables simultáneamente para encontrar patrones y
  asociaciones.
- Descubrir interdependencias entre dimensiones de los datos que no serían evidentes al analizar las
  variables por separado.
- Reducir la dimensionalidad del conjunto de indicadores e interpretar las dimensiones que resultan.
- Traducir los resultados a decisiones para un cliente: la Dirección de Cobertura y Equidad Territorial
  del Ministerio de Educación Nacional.

## Informe principal

El informe que integra todo el proyecto es **`reports/entrega-corte-2/Analisis_Indicadores_Educativos.Rmd`**.
Parte del informe del Corte 1, que es la base del proyecto, y le agrega el Análisis de Componentes
Principales sobre todas las variables.

| Entrega | Archivo | Contenido |
|---|---|---|
| **Corte 1** | `reports/entrega-corte-1/Analisis_Indicadores_Educativos.Rmd` | Limpieza de los datos, análisis univariado, bivariado y multivariado (matriz de covarianzas, estandarización y distancias de Mahalanobis). |
| **Corte 2** | `reports/entrega-corte-2/Analisis_Indicadores_Educativos.Rmd` | Todo el Corte 1 más el **PCA con las 30 variables numéricas**: ¿un número o varios? y el mapa de los municipios (biplot, grupos, cortes de decisión). |

Los talleres son ejercicios cortos que deja el docente para entender cada técnica. Trabajan con pocas
variables y sirven de antecedente para las entregas de corte.

| Taller | Archivo |
|---|---|
| Taller 1 | `reports/taller-01/taller-01.Rmd` |
| Taller 2 | `reports/taller-02/checklist-taller-02.Rmd` |
| **Taller factorial** (análisis factorial completo de las 33 variables) | `reports/taller-factorial/taller-factorial.Rmd` |
| **Informe y evaluación final** del repositorio | `reports/informe-final/informe-final.Rmd` |
| Componentes principales I | `reports/taller-pca/componentes-principales-i/componentes-principales-i.Rmd` |
| Componentes principales II | `reports/taller-pca/componentes-principales-ii/componentes-principales-ii.Rmd` |
| Análisis factorial I | `reports/taller-pca/analisis-factorial-i/analisis-factorial-i.Rmd` |
| Análisis factorial II | `reports/taller-pca/analisis-factorial-ii/analisis-factorial-ii.Rmd` |

## Datos

| Archivo | Descripción |
|---|---|
| `data/raw/educacion.csv` | Datos originales del Ministerio de Educación Nacional: 15.707 registros municipio-año y 41 variables. **No se modifica.** |
| `data/raw/educacion_limpio.csv` | Dataset depurado: **13.802 registros y 33 variables** (año, municipio, departamento y 30 indicadores numéricos), sin valores faltantes. Lo usan los informes de corte y todos los talleres (1, 2, PCA, factorial y taller factorial). |
| `data/raw/educacion_limpio_talleres.csv` | Versión anterior y reducida del dataset depurado (5.063 registros; códigos DANE, sin año ni nombres). **Registro histórico:** ningún informe vigente la usa, porque todos analizan las 33 variables de `educacion_limpio.csv`. No se modifica. |

El dataset depurado **lo genera el informe de corte** a partir de `educacion.csv`, en la sección
«Carga, Depuración y Limpieza de Datos». Si el archivo se daña o queda desactualizado, basta con volver
a tejer el informe del Corte 2 (o del Corte 1) para regenerarlo.

La unidad de análisis es el registro **municipio-año**: un mismo municipio aparece hasta 14 veces.

## Estructura del repositorio

```text
data/raw/                         Datos originales y dataset depurado
reports/
  entrega-corte-1/                Informe del Corte 1 (.Rmd y .html)
  entrega-corte-2/                Informe del Corte 2: Corte 1 + PCA (.Rmd y .html)
  taller-01/                      Taller 1 (archive/: archivos históricos)
  taller-02/                      Taller 2
  taller-pca/                     Talleres de componentes principales y análisis factorial I y II
  taller-factorial/               Análisis factorial completo de las 33 variables (.Rmd, .html y README)
  informe-final/                  Informe y evaluación final del repositorio
outputs/
  entrega-corte-1/                Histogramas, boxplots y gráficos de Mahalanobis del Corte 1
  entrega-corte-2/                Lo mismo para el Corte 2, más pca/ con las tablas y figuras del PCA
  taller-01/, taller-02/          tables/ y figures/ de cada taller
  taller-pca/                     tables/ y figures/ de cada taller de PCA y análisis factorial, y analisis-33-variables/
  taller-factorial/, informe-final/   tables/ y figures/
scripts/                          Instalación, validación, renderizado, análisis con 33 columnas y presentaciones
presentacion/                     Presentaciones para el cliente (.pptx); ignorada por git
informe_calendario_pca.md         Cronograma y roles del sprint de PCA
```

## Requisitos

- R 4.5 o compatible, idealmente con RStudio.
- Pandoc (viene con RStudio) para generar los HTML.
- Paquetes de los informes de corte: `rmarkdown`, `knitr`, `ggplot2`, `dplyr`, `tidyr`, `reshape2`,
  `readr`, `forcats`, `corrplot` y `DT`. Al tejer, el informe instala los que falten de esta lista
  (salvo `rmarkdown`, que se necesita para tejer).
  `ggrepel` es opcional: si está instalado, se usa para que las etiquetas del biplot no se monten.
- Paquetes de los talleres de análisis factorial: `psych` y `GPArotation`. El script de los talleres
  de PCA usa además `commonmark` cuando no hay Pandoc.

Para instalar todos los paquetes desde la raíz del proyecto:

```r
source("scripts/install_dependencies.R")
```

## Cómo generar las entregas

**Informes de corte:** abrir el `.Rmd` en RStudio y presionar **Knit**, o desde la raíz del proyecto:

```r
rmarkdown::render("reports/entrega-corte-2/Analisis_Indicadores_Educativos.Rmd")
```

El informe del Corte 2 tarda unos minutos y genera un HTML de cerca de 30 MB, porque incluye todas las
figuras en alta resolución.

**Con los scripts**, desde la raíz del proyecto:

```r
source("scripts/render_reports.R")       # Corte 2, Corte 1, Taller 1, Taller 2 y Taller factorial
source("scripts/render_talleres_pca.R")  # Talleres de PCA, análisis factorial I y II y Taller factorial
```

`render_reports.R` teje primero el Corte 2, que regenera `educacion_limpio.csv`. Si un informe falla,
sigue con los demás y al final lista los que no se generaron. Los talleres 1, 2 y factorial analizan las
33 variables de `educacion_limpio.csv`; las versiones históricas (dataset reducido) están en `reports/*/archive/`.

**Validación del proyecto:**

```r
source("scripts/check_project.R")
```

Confirma que existen los datos y los `.Rmd` de todas las entregas, que `educacion_limpio.csv` tiene
13.802 filas y 33 columnas, y que sus variables numéricas no tienen valores faltantes ni infinitos.

## Análisis con las 33 columnas y presentaciones

El PCA y el análisis factorial de los talleres usan 6 variables. Para repetirlos con las 33 columnas de
`educacion_limpio.csv` (30 indicadores, año, municipio y departamento) y comparar el one-hot de
**solo departamentos, solo municipios y ambos**:

```bash
Rscript scripts/analisis_33_variables.R          # tarda unos 4 minutos; escribe outputs/taller-pca/analisis-33-variables/
```

Las secciones correspondientes están en los informes de componentes principales I y II y se leen con
`scripts/helpers_33.R`. Las presentaciones para el cliente (una por taller y una integrada) se generan con:

```bash
Rscript scripts/presentacion_resultados.R        # recalcula cifras y figuras
python scripts/presentacion_construir.py         # genera los .pptx en presentacion/ (requiere python-pptx)
```

**Evaluación final del repositorio** (informes, outputs y presentaciones; cobertura de las 33 variables, vigencia y cifras cruzadas):

```bash
Rscript scripts/evaluar_repositorio.R            # tablas en outputs/informe-final/
Rscript -e 'rmarkdown::render("reports/informe-final/informe-final.Rmd")'
```

`scripts/helpers_datos.R` concentra la carga de datos: en `educacion_limpio.csv` el año es una categoría
(nunca un indicador). `check_project.R` lo verifica.

## Convenciones

- Los nombres de carpetas y archivos nuevos usan ASCII, minúsculas y guiones.
- El dataset conserva los nombres originales de sus columnas (con tildes), porque hacen parte del análisis.
- `data/raw/educacion.csv` y `data/raw/educacion_limpio_talleres.csv` no se modifican.
- Las tablas y figuras de `outputs/` son derivadas: se regeneran al tejer cada informe, pero se conservan
  para cada entrega.
- Los informes se escriben en español, con coma decimal y punto de miles.
- Cada integrante puede tener el proyecto como `Proyectos estadistica.Rproj` o
  `Proyectos-estadistica.Rproj`: los informes y scripts reconocen los dos nombres.
- Los archivos históricos o intermedios van en una carpeta `archive/`.
