project_root <- normalizePath(getwd(), mustWork = TRUE)
if (!file.exists(file.path(project_root, "data", "raw", "educacion_limpio.csv"))) {
  stop("Ejecute este script desde la raíz del proyecto.")
}

required_packages <- c("rmarkdown", "knitr", "ggplot2", "dplyr", "tidyr", "reshape2")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages) > 0) {
  stop("Faltan paquetes. Ejecute source('scripts/install_dependencies.R'): ",
       paste(missing_packages, collapse = ", "))
}

reports <- c(
  file.path(project_root, "reports", "taller-01", "taller-01.Rmd"),
  file.path(project_root, "reports", "taller-02", "checklist-taller-02.Rmd")
)

for (report in reports) {
  if (rmarkdown::pandoc_available()) {
    rmarkdown::render(
      input = report,
      output_dir = dirname(report),
      quiet = FALSE,
      envir = new.env(parent = globalenv())
    )
  } else {
    markdown_output <- file.path(
      dirname(report),
      paste0(tools::file_path_sans_ext(basename(report)), ".md")
    )
    knitr::knit(input = report, output = markdown_output, quiet = FALSE)
    warning("Pandoc no está instalado; se generó Markdown en ", markdown_output)
  }
}

cat("Entregas generadas. Consulte los archivos .md si Pandoc no está instalado.\n")
