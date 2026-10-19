# --------------------------------------------------------------------------
# Script de inicializacion de carpetas - Talleres de Análisis de Componentes
# Principales (PCA)
# Proyecto: Estadística Multidimensional - Indicadores Educativos
# Municipales de Colombia (2011-2024)
#
# Ejecutar desde la raiz del proyecto RStudio: "Proyectos estadistica.Rproj"
# --------------------------------------------------------------------------

talleres <- c("componentes-principales-i", "componentes-principales-ii")

for (taller in talleres) {
  dir.create(
    file.path("outputs", "taller-pca", taller, "tables"),
    recursive = TRUE, showWarnings = FALSE
  )
  dir.create(
    file.path("outputs", "taller-pca", taller, "figures"),
    recursive = TRUE, showWarnings = FALSE
  )
  dir.create(
    file.path("reports", "taller-pca", taller),
    recursive = TRUE, showWarnings = FALSE
  )
}

cat("Estructura de carpetas creada exitosamente.\n")
cat("Rutas:\n")
for (taller in talleres) {
  cat("  outputs/taller-pca/", taller, "/{tables,figures}\n", sep = "")
  cat("  reports/taller-pca/", taller, "/\n", sep = "")
}
