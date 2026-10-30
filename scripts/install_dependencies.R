required_packages <- c(
  # Tejido de los informes
  "rmarkdown",
  "knitr",
  "commonmark",
  # Manipulación y gráficos
  "ggplot2",
  "dplyr",
  "tidyr",
  "reshape2",
  "readr",
  "forcats",
  "scales",
  "corrplot",
  "DT",
  "ggrepel",
  # Análisis factorial
  "psych",
  "GPArotation"
)

missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]

if (length(missing_packages) > 0) {
  install.packages(missing_packages, repos = "https://cloud.r-project.org")
}

still_missing <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(still_missing) > 0) {
  stop("No se pudieron instalar: ", paste(still_missing, collapse = ", "))
}

cat("Dependencias disponibles:\n")
print(required_packages)
