# Proyecto de Estadística Multidimensional

Repositorio de análisis de indicadores educativos y entregas recurrentes del Taller 1 y Taller 2.

## Estructura

```text
data/raw/                 Datos de entrada sin modificar
reports/taller-01/        Fuente y entregas del Taller 1
reports/taller-02/        Fuente y entregas del Taller 2
outputs/taller-01/tables  Resultados CSV del Taller 1
outputs/taller-01/figures Gráficos del Taller 1
outputs/taller-02/tables  Resultados CSV del Taller 2
outputs/taller-02/figures Gráficos del Taller 2
scripts/                  Instalación, validación y renderizado
reports/*/archive/        Archivos históricos o intermedios
```

## Requisitos

- R 4.5.3 o compatible.
- Pandoc para generar HTML desde R Markdown. Si no está instalado, el script genera Markdown y
	mantiene todos los CSV y gráficos.
- Paquetes: `rmarkdown`, `knitr`, `ggplot2`, `dplyr`, `tidyr` y `reshape2`.

Instale los paquetes una sola vez desde la raíz del proyecto:

```r
source("scripts/install_dependencies.R")
```

## Generar las entregas

Desde la raíz del repositorio:

```r
source("scripts/render_reports.R")
```

Los documentos fuente son:

- `reports/taller-01/taller-01.Rmd`
- `reports/taller-02/checklist-taller-02.Rmd`

Cada entrega escribe sus tablas y figuras en su carpeta correspondiente dentro de `outputs/`. Los
archivos se pueden regenerar sin editar manualmente los CSV o PNG.

## Validar el proyecto

```r
source("scripts/check_project.R")
```

La validación confirma que existe el dataset, que las carpetas de salida están disponibles y que los
resultados principales no contienen valores no finitos.

## Convenciones

- Las rutas y nombres de archivos nuevos usan ASCII, minúsculas y guiones.
- El dataset conserva los nombres originales de sus columnas porque hacen parte del análisis.
- `data/raw/` no se modifica durante los informes.
- Los resultados son derivados: se regeneran mediante los scripts, pero se conservan para cada entrega.
- Los archivos históricos y de compilación quedan dentro de `archive/`.
