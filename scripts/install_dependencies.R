required_packages <- c(
  "rmarkdown",
  "knitr",
  "ggplot2",
  "dplyr",
  "tidyr",
  "reshape2"
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
