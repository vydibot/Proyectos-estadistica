project_root <- normalizePath(getwd(), mustWork = TRUE)
raw_file  <- file.path(project_root, "data", "raw", "educacion.csv")
data_file <- file.path(project_root, "data", "raw", "educacion_limpio.csv")

if (!file.exists(raw_file)) {
  stop("Ejecute este script desde la raíz del proyecto.")
}

# El proyecto se abre con "Proyectos estadistica.Rproj" o "Proyectos-estadistica.Rproj"
if (!any(file.exists(file.path(project_root, c("Proyectos estadistica.Rproj", "Proyectos-estadistica.Rproj"))))) {
  warning("No se encontró el archivo .Rproj en la raíz del proyecto.")
}

required_paths <- c(
  data_file,
  file.path(project_root, "data", "raw", "educacion_limpio_talleres.csv"),
  file.path(project_root, "reports", "entrega-corte-1", "Analisis_Indicadores_Educativos.Rmd"),
  file.path(project_root, "reports", "entrega-corte-2", "Analisis_Indicadores_Educativos.Rmd"),
  file.path(project_root, "reports", "taller-01", "taller-01.Rmd"),
  file.path(project_root, "reports", "taller-02", "checklist-taller-02.Rmd"),
  file.path(project_root, "reports", "taller-factorial", "taller-factorial.Rmd"),
  file.path(project_root, "reports", "taller-pca", "componentes-principales-i", "componentes-principales-i.Rmd"),
  file.path(project_root, "reports", "taller-pca", "componentes-principales-ii", "componentes-principales-ii.Rmd"),
  file.path(project_root, "reports", "taller-pca", "analisis-factorial-i", "analisis-factorial-i.Rmd"),
  file.path(project_root, "reports", "taller-pca", "analisis-factorial-ii", "analisis-factorial-ii.Rmd")
)

missing_paths <- required_paths[!file.exists(required_paths)]
if (length(missing_paths) > 0) {
  stop("Faltan rutas del proyecto:\n", paste(missing_paths, collapse = "\n"),
       "\nSi falta educacion_limpio.csv, teja el informe del Corte 2 para regenerarlo.")
}

# Dimensiones esperadas del dataset depurado (ver informe del Corte 1)
dataset <- read.csv(data_file, check.names = FALSE)
if (nrow(dataset) != 13802 || ncol(dataset) != 33) {
  stop("educacion_limpio.csv tiene ", nrow(dataset), " filas y ", ncol(dataset),
       " columnas; se esperaban 13802 y 33. Teja el informe del Corte 2 para regenerarlo.")
}

numericas <- dataset[vapply(dataset, is.numeric, logical(1))]
if (!all(vapply(numericas, function(x) all(is.finite(x)), logical(1)))) {
  stop("El dataset contiene valores no finitos.")
}

# --- Comprobaciones adicionales (auditoría) -------------------------------------------------
helpers <- file.path(project_root, "scripts", "helpers_datos.R")
if (file.exists(helpers)) {
  source(helpers)
  # Dataset completo: AÑO debe ser categoría y no puede colarse como indicador.
  completo <- cargar_educacion(project_root)
  indicadores <- columnas_indicadores(completo)           # falla si AÑO es numérico
  if (anyDuplicated(completo[, c("AÑO", "ID_MUNICIPIO")]) > 0) {
    stop("educacion_limpio.csv tiene registros duplicados por municipio-año.")
  }
  # Los talleres 1 y 2 analizan las 33 variables de educacion_limpio.csv: sus tablas deben corresponder al archivo.
  diag_file <- file.path(project_root, "outputs", "taller-02", "tables", "Diagnostico_dataset.csv")
  if (file.exists(diag_file)) {
    dg <- read.csv(diag_file)
    if (dg$filas != nrow(completo) || dg$variables != length(indicadores)) {
      stop("outputs/taller-02 está desactualizado: tabla con ", dg$filas, " filas y ", dg$variables,
           " variables; el dataset tiene ", nrow(completo), " y ", length(indicadores),
           ". Teja de nuevo reports/taller-02/checklist-taller-02.Rmd.")
    }
  }
  cat("Indicadores:", length(indicadores), "| Categóricas: 3 (AÑO, DEPARTAMENTO, MUNICIPIO) | Municipios:",
      length(unique(completo$ID_MUNICIPIO)), "\n")
}

cat("Proyecto válido.\n")
cat("Filas:", nrow(dataset), " | Columnas:", ncol(dataset),
    " | Numéricas:", ncol(numericas), "\n")
