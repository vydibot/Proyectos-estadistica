# --------------------------------------------------------------------------
# Renderizado de los talleres de PCA y análisis factorial.
# Si Pandoc está disponible (viene con RStudio) se usa rmarkdown::render; si no,
# se teje con knitr a Markdown y se convierte a HTML con commonmark.
#
# Ejecutar desde la raíz del proyecto: source("scripts/render_talleres_pca.R")
# --------------------------------------------------------------------------

tryCatch(Sys.setlocale("LC_ALL", "C.UTF-8"), error = function(e) NULL)

library(knitr)

project_root <- normalizePath(getwd(), mustWork = TRUE)

if (!file.exists(file.path(project_root, "data", "raw", "educacion_limpio.csv"))) {
  stop("Ejecute este script desde la raíz del proyecto ",
       "(si falta educacion_limpio.csv, teja primero el informe del Corte 2).")
}

rmds <- c(
  file.path("reports", "taller-pca", "componentes-principales-i", "componentes-principales-i.Rmd"),
  file.path("reports", "taller-pca", "componentes-principales-ii", "componentes-principales-ii.Rmd"),
  file.path("reports", "taller-pca", "analisis-factorial-i", "analisis-factorial-i.Rmd"),
  file.path("reports", "taller-pca", "analisis-factorial-ii", "analisis-factorial-ii.Rmd")
)

for (rmd_rel in rmds) {
  rmd_path <- file.path(project_root, rmd_rel)
  if (!file.exists(rmd_path)) {
    stop("No se encuentra el archivo: ", rmd_path)
  }

  cat("\nTejiendo:", rmd_rel, "\n")
  if (rmarkdown::pandoc_available()) {
    rmarkdown::render(rmd_path, output_dir = dirname(rmd_path), quiet = TRUE,
                      envir = new.env(parent = globalenv()))
  } else {
    md_path <- sub("\\.Rmd$", ".md", rmd_path)
    html_path <- sub("\\.Rmd$", ".html", rmd_path)
    knit(rmd_path, output = md_path, quiet = TRUE, encoding = "UTF-8")
    md_text <- readLines(md_path, encoding = "UTF-8")
    writeLines(commonmark::markdown_html(md_text), html_path, useBytes = TRUE)
  }
  cat("HTML generado:", sub("\\.Rmd$", ".html", rmd_path), "\n")
}

cat("\nEntregas generadas. Revise los archivos .html en reports/taller-pca/.\n")
