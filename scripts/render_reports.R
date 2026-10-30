# --------------------------------------------------------------------------
# Renderizado de las entregas de corte y de los talleres 1 y 2.
# Ejecutar desde la raíz del proyecto: source("scripts/render_reports.R")
#
# El informe del Corte 2 va primero porque regenera data/raw/educacion_limpio.csv,
# que usan los demás informes.
# --------------------------------------------------------------------------

project_root <- normalizePath(getwd(), mustWork = TRUE)
if (!file.exists(file.path(project_root, "data", "raw", "educacion.csv"))) {
  stop("Ejecute este script desde la raíz del proyecto.")
}

required_packages <- c("rmarkdown", "knitr", "ggplot2", "dplyr", "tidyr", "reshape2",
                       "readr", "forcats", "corrplot", "DT")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages) > 0) {
  stop("Faltan paquetes. Ejecute source('scripts/install_dependencies.R'): ",
       paste(missing_packages, collapse = ", "))
}

reports <- c(
  file.path(project_root, "reports", "entrega-corte-2", "Analisis_Indicadores_Educativos.Rmd"),
  file.path(project_root, "reports", "entrega-corte-1", "Analisis_Indicadores_Educativos.Rmd"),
  file.path(project_root, "reports", "taller-01", "taller-01.Rmd"),
  file.path(project_root, "reports", "taller-02", "checklist-taller-02.Rmd"),
  file.path(project_root, "reports", "taller-02", "taller-02-html.Rmd")
)

# Los talleres 1 y 2 leen data/raw/educacion_limpio_talleres.csv, la versión del dataset con
# la que se hicieron. Si algún informe falla, se informa y se sigue con los demás.
tejer <- function(report) {
  if (rmarkdown::pandoc_available()) {
    rmarkdown::render(
      input = report,
      output_dir = dirname(report),
      quiet = TRUE,
      envir = new.env(parent = globalenv())
    )
  } else {
    markdown_output <- file.path(
      dirname(report),
      paste0(tools::file_path_sans_ext(basename(report)), ".md")
    )
    knitr::knit(input = report, output = markdown_output, quiet = TRUE)
    warning("Pandoc no está instalado; se generó Markdown en ", markdown_output)
  }
}

fallidos <- character(0)
for (report in reports) {
  cat("\nTejiendo:", report, "\n")
  tryCatch(
    tejer(report),
    error = function(e) {
      fallidos <<- c(fallidos, report)
      message("No se pudo tejer ", report, ": ", conditionMessage(e))
    }
  )
}

if (length(fallidos) > 0) {
  cat("\nNo se generaron:\n", paste0("  ", fallidos, "\n"), sep = "")
} else {
  cat("\nEntregas generadas. Consulte los archivos .md si Pandoc no está instalado.\n")
}
