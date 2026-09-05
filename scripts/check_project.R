project_root <- normalizePath(getwd(), mustWork = TRUE)
data_file <- file.path(project_root, "data", "raw", "educacion_limpio.csv")
required_paths <- c(
  data_file,
  file.path(project_root, "reports", "taller-01", "taller-01.Rmd"),
  file.path(project_root, "reports", "taller-02", "checklist-taller-02.Rmd"),
  file.path(project_root, "outputs", "taller-01", "tables"),
  file.path(project_root, "outputs", "taller-01", "figures"),
  file.path(project_root, "outputs", "taller-02", "tables"),
  file.path(project_root, "outputs", "taller-02", "figures")
)

missing_paths <- required_paths[!file.exists(required_paths) & !dir.exists(required_paths)]
if (length(missing_paths) > 0) {
  stop("Faltan rutas del proyecto:\n", paste(missing_paths, collapse = "\n"))
}

dataset <- read.csv(data_file, check.names = FALSE)
if (!all(vapply(dataset, function(x) all(is.finite(x)), logical(1))) ) {
  stop("El dataset contiene valores no finitos.")
}

cat("Proyecto válido.\n")
cat("Filas:", nrow(dataset), " | Columnas:", ncol(dataset), "\n")
