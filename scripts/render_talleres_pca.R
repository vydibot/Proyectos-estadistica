# --------------------------------------------------------------------------
# Renderizado de los talleres PCA: .Rmd -> .md -> .html
# (Pandoc no esta disponible en el entorno, por tanto se teje con knitr a
# Markdown y se convierte a HTML con commonmark).
#
# Ejecutar desde la raiz del proyecto: source("scripts/render_talleres_pca.R")
# --------------------------------------------------------------------------

library(knitr)
library(commonmark)

project_root <- normalizePath(getwd(), mustWork = TRUE)

if (!file.exists(file.path(project_root, "data", "raw", "educacion_limpio.csv"))) {
  stop("Ejecute este script desde la raiz del proyecto.")
}

rmds <- c(
  file.path("reports", "taller-pca", "componentes-principales-i", "componentes-principales-i.Rmd"),
  file.path("reports", "taller-pca", "componentes-principales-ii", "componentes-principales-ii.Rmd")
)

for (rmd_rel in rmds) {
  rmd_path <- file.path(project_root, rmd_rel)
  if (!file.exists(rmd_path)) {
    stop("No se encuentra el archivo: ", rmd_path)
  }
  md_path <- sub("\\.Rmd$", ".md", rmd_path)
  html_path <- sub("\\.Rmd$", ".html", rmd_path)

  cat("\nTejiendo:", rmd_rel, "\n")
  knit(rmd_path, output = md_path, quiet = FALSE, encoding = "UTF-8")

  md_text <- readLines(md_path, encoding = "UTF-8")
  html_text <- markdown_html(md_text)
  writeLines(html_text, html_path, useBytes = TRUE)
  cat("HTML generado:", html_path, "\n")
}

cat("\nEntregas generadas. Revise los archivos .html en reports/taller-pca/.\n")
