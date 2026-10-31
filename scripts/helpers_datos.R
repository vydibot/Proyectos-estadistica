# --------------------------------------------------------------------------
# Funciones compartidas por los talleres 1 y 2 y por las presentaciones.
# Fuente unica de datos: data/raw/educacion_limpio.csv
#
# Reglas que codifica este archivo (auditoria del proyecto):
#   * Cada fila es un registro MUNICIPIO-AÑO, no un municipio independiente.
#   * AÑO es una categoria ordenada, nunca una magnitud: no entra en
#     histogramas, correlaciones, covarianzas ni distancias entre indicadores.
#   * Los indicadores son las columnas numericas que quedan al excluir AÑO.
# --------------------------------------------------------------------------

encontrar_raiz <- function(inicio = getwd()) {
  ruta <- normalizePath(inicio, mustWork = TRUE)
  repeat {
    if (file.exists(file.path(ruta, "data", "raw", "educacion_limpio.csv")) &&
        dir.exists(file.path(ruta, "reports"))) {
      return(ruta)
    }
    padre <- dirname(ruta)
    if (padre == ruta) stop("No se encontró la raíz del proyecto.")
    ruta <- padre
  }
}

cargar_educacion <- function(raiz = encontrar_raiz()) {
  d <- read.csv(file.path(raiz, "data", "raw", "educacion_limpio.csv"),
                check.names = FALSE, stringsAsFactors = FALSE)
  d$ID_MUNICIPIO <- paste(d$MUNICIPIO, d$DEPARTAMENTO, sep = " | ")
  d$AÑO <- factor(d$AÑO, levels = sort(unique(d$AÑO)), ordered = TRUE)
  d
}

# Indicadores = columnas numericas (AÑO ya es factor). Falla si se cuela el año.
columnas_indicadores <- function(d) {
  cols <- names(d)[vapply(d, is.numeric, logical(1))]
  if ("AÑO" %in% cols) stop("AÑO no puede ser un indicador numérico.")
  cols
}

# --- Dataset de los talleres 1 y 2 (versión anterior, más pequeña) ---------------------
# data/raw/educacion_limpio_talleres.csv: 5.063 registros, sin año ni nombres; el municipio y el
# departamento solo aparecen como códigos DANE (identificadores, no magnitudes).
# Un mismo CÓDIGO_MUNICIPIO aparece varias veces, así que las filas siguen sin ser independientes.
cargar_talleres <- function(raiz = encontrar_raiz()) {
  d <- read.csv(file.path(raiz, "data", "raw", "educacion_limpio_talleres.csv"),
                check.names = FALSE, stringsAsFactors = FALSE)
  d$ID_MUNICIPIO <- as.character(d$CÓDIGO_MUNICIPIO)
  d$CÓDIGO_MUNICIPIO <- factor(d$CÓDIGO_MUNICIPIO)
  d$CÓDIGO_DEPARTAMENTO <- factor(d$CÓDIGO_DEPARTAMENTO)
  d
}

# Indicadores de los talleres: numéricas no constantes (los códigos ya son factores).
indicadores_talleres <- function(d) {
  cols <- names(d)[vapply(d, is.numeric, logical(1))]
  cols[!vapply(d[cols], function(x) length(unique(x)) <= 1, logical(1))]
}

# Resumen de la estructura de panel.
resumen_panel <- function(d) {
  por_anio <- as.data.frame(table(AÑO = d$AÑO), responseName = "registros")
  por_mun <- as.integer(table(d$ID_MUNICIPIO))
  list(
    registros = nrow(d),
    municipios = length(unique(d$ID_MUNICIPIO)),
    departamentos = length(unique(d$DEPARTAMENTO)),
    anios = nlevels(d$AÑO),
    por_anio = por_anio,
    anios_por_municipio = por_mun,
    municipios_14_anios = sum(por_mun == nlevels(d$AÑO))
  )
}

# Correlacion con intervalo de confianza por bootstrap de CONGLOMERADOS
# (se remuestrean municipios completos, no filas): respeta la repeticion
# municipal. Usa sumas por municipio, por lo que es rapido.
correlacion_cluster <- function(x, y, id, B = 1000, semilla = 2026) {
  ok <- is.finite(x) & is.finite(y)
  x <- as.numeric(x[ok]); y <- as.numeric(y[ok]); id <- id[ok]
  g <- factor(id)
  S <- cbind(n = 1, x = x, y = y, xx = x * x, yy = y * y, xy = x * y)
  T <- rowsum(S, g)
  cor_de <- function(t) {
    n <- t[1]; mx <- t[2] / n; my <- t[3] / n
    (t[6] / n - mx * my) / sqrt((t[4] / n - mx^2) * (t[5] / n - my^2))
  }
  r <- unname(cor_de(colSums(T)))
  set.seed(semilla)
  m <- nrow(T)
  rb <- replicate(B, cor_de(colSums(T[sample.int(m, m, replace = TRUE), , drop = FALSE])))
  c(r = r, lo = unname(quantile(rb, 0.025, na.rm = TRUE)),
    hi = unname(quantile(rb, 0.975, na.rm = TRUE)))
}

# Resta la media de cada grupo (año o municipio) a cada columna numerica.
centrar_por_grupo <- function(X, grupo) {
  as.data.frame(lapply(X, function(v) v - ave(v, grupo, FUN = mean)),
                check.names = FALSE)
}

# R2 (eta cuadrado) ajustado por numero de categorias: parte de la varianza de x que explica la categoria g.
eta2_ajustado <- function(x, g) {
  g <- factor(g); k <- nlevels(g); m <- ave(x, g, FUN = mean)
  sst <- sum((x - mean(x))^2); ssw <- sum((x - m)^2)
  1 - (ssw / (length(x) - k)) / (sst / (length(x) - 1))
}

# One-hot con todos los niveles (una columna por categoria).
onehot <- function(f, prefijo = "") {
  f <- factor(f); m <- model.matrix(~ f - 1)
  colnames(m) <- paste0(prefijo, levels(f)); m
}

# Formato numerico en español.
fnum <- function(x, d = 1) format(round(x, d), nsmall = d, decimal.mark = ",", big.mark = ".")
fint <- function(x) format(x, big.mark = ".", decimal.mark = ",", scientific = FALSE)

# Paleta de presentaciones/reportes (azul = categoria 1, naranja = categoria 2).
paleta <- list(azul = "#2a78d6", naranja = "#eb6834", aqua = "#1baf7a",
               gris = "#898781", tinta = "#0b0b0b", rejilla = "#e1e0d9")
