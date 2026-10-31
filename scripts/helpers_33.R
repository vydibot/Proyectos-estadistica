# Lectura de los resultados de scripts/analisis_33_variables.R para los informes y las presentaciones.
cargar_33 <- function(raiz) {
  d <- file.path(raiz, "outputs", "taller-pca", "analisis-33-variables", "tables")
  if (!file.exists(file.path(d, "metricas_33.json"))) stop("Ejecute primero: Rscript scripts/analisis_33_variables.R")
  list(
    pca = read.csv(file.path(d, "pca_comparacion_variantes.csv"), check.names = FALSE),
    fa = read.csv(file.path(d, "fa_comparacion_variantes.csv"), check.names = FALSE),
    eta = read.csv(file.path(d, "r2_ajustado_por_categorica.csv"), check.names = FALSE),
    cargas2 = read.csv(file.path(d, "fa30_cargas_2factores.csv"), check.names = FALSE),
    cargask = read.csv(file.path(d, "fa30_cargas_kfactores.csv"), check.names = FALSE),
    kmo30 = read.csv(file.path(d, "fa30_kmo.csv"), check.names = FALSE),
    m = jsonlite::fromJSON(file.path(d, "metricas_33.json"))
  )
}
# Ruta relativa a la imagen, valida desde reports/taller-pca/<informe>/
img33 <- function(nombre) paste0("../../../outputs/taller-pca/analisis-33-variables/figures/", nombre)
# Fila de la tabla PCA para una base, codificacion y peso
fila_pca <- function(tab, base, cod, peso = "—") tab[tab$base == base & tab$codificacion == cod & tab$peso == peso, ]
# Inserta una imagen en el Markdown del informe (usar en chunks con results = 'asis')
mostrar_img <- function(nombre, alt = "") cat(sprintf("\n\n![%s](%s)\n\n", alt, img33(nombre)))
