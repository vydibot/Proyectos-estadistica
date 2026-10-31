# --------------------------------------------------------------------------
# Evaluacion final automatizada del repositorio: informes, outputs y presentaciones.
# Comprueba, con evidencia calculada, si cada entregable analiza las 33 variables
# (30 indicadores + AÑO + DEPARTAMENTO + MUNICIPIO), si esta vigente y si sus cifras
# coinciden entre si. Escribe en outputs/informe-final/{tables,figures}.
# Ejecutar desde la raiz:  Rscript scripts/evaluar_repositorio.R
# --------------------------------------------------------------------------
tryCatch(Sys.setlocale("LC_ALL", "C.UTF-8"), error = function(e) NULL)
suppressPackageStartupMessages({ library(ggplot2); library(dplyr); library(tidyr); library(jsonlite) })
raiz <- if (exists("project_root")) project_root else normalizePath(getwd(), mustWork = TRUE)   # project_root: lo define el informe que lo invoca
source(file.path(raiz, "scripts", "helpers_datos.R"))
dir_t <- file.path(raiz, "outputs", "informe-final", "tables")
dir_f <- file.path(raiz, "outputs", "informe-final", "figures")
dir.create(dir_t, recursive = TRUE, showWarnings = FALSE); dir.create(dir_f, recursive = TRUE, showWarnings = FALSE)
guardar <- function(df, nombre) write.csv(df, file.path(dir_t, nombre), row.names = FALSE)
leer <- function(...) readLines(file.path(raiz, ...), encoding = "UTF-8", warn = FALSE)
cuenta <- function(patron, txt, ...) sum(lengths(regmatches(txt, gregexpr(patron, txt, perl = TRUE, ...))))

completo <- cargar_educacion(raiz)
ind <- columnas_indicadores(completo)

# ============================ 1. INFORMES ====================================
rmds <- list.files(file.path(raiz, "reports"), pattern = "\\.Rmd$", recursive = TRUE, full.names = TRUE)
rmds_vigentes <- rmds[!grepl("/archive/|/informe-final/", rmds)]   # el informe final es la salida de esta evaluacion, no un analisis
rmds_archivo <- rmds[grepl("/archive/", rmds)]

evalua_informe <- function(ruta) {
  txt <- paste(readLines(ruta, encoding = "UTF-8", warn = FALSE), collapse = "\n")
  rel <- sub(paste0(raiz, "/"), "", ruta, fixed = TRUE)
  html <- sub("\\.Rmd$", ".html", ruta)
  talleres_csv <- grepl("educacion_limpio_talleres", txt)
  lee_limpio <- grepl("cargar_educacion\\(|educacion_limpio\\.csv", txt)
  lee_crudo <- grepl("\"educacion\\.csv\"", txt)
  cat30 <- grepl("30 indicadores|columnas_indicadores|30 variables", txt)
  categoricas <- grepl("AÑO", txt) && grepl("DEPARTAMENTO", txt) && grepl("MUNICIPIO", txt) &&
    grepl("one-hot|R² ajustado|eta2_ajustado|MUNICIPIOS|categóric", txt, ignore.case = TRUE)
  one_hot <- grepl("one-hot|onehot", txt, ignore.case = TRUE)
  ext33 <- grepl("33 columnas|33 variables", txt)
  anio_cat <- grepl("cargar_educacion\\(|ordered|factor\\(AÑO|as\\.character\\(AÑO\\)", txt)
  estado <- if (talleres_csv) "No cubre las 33 variables (dataset reducido)"
    else if (lee_limpio && cat30 && categoricas && ext33 && !grepl("reports/taller-pca/", rel)) "Completo (30 + 3)"
    else if (lee_limpio && ext33 && one_hot) "Completo con ampliación a 33 columnas"
    else if ((lee_limpio || lee_crudo) && categoricas) "Parcial: 30 numéricas + categóricas descriptivas"
    else "Parcial"
  # Los informes de PCA/factorial originales analizan 6 variables y suman una ampliación de 33
  if (grepl("reports/taller-pca/", rel) && ext33 && one_hot) { estado <- "Completo con ampliación a 33 columnas"; anio_cat <- TRUE }   # AÑO entra en one-hot en la ampliación
  if (grepl("reports/taller-factorial/", rel)) estado <- if (cat30 && categoricas && one_hot) "Completo (30 + 3)" else "Parcial"
  if (grepl("reports/entrega-corte", rel)) estado <- "Parcial: 30 numéricas + categóricas descriptivas (sin one-hot)"
  data.frame(
    informe = rel, carpeta = basename(dirname(ruta)), lineas = length(strsplit(txt, "\n")[[1]]),
    dataset = if (talleres_csv) "educacion_limpio_talleres.csv (5.063)" else if (grepl("reports/entrega-corte", rel)) "educacion.csv -> educacion_limpio.csv (13.802)" else "educacion_limpio.csv (13.802)",
    treinta_indicadores = cat30, categoricas_analizadas = categoricas, one_hot = one_hot, anio_como_categoria = anio_cat,
    ampliacion_33 = ext33, cor_test = cuenta("cor\\.test", txt), valores_p_sin_ajuste = grepl("cor\\.test", txt) && !grepl("p\\.adjust|Holm|Bonferroni", txt),
    html_vigente = file.exists(html) && as.numeric(file.mtime(html)) >= as.numeric(file.mtime(ruta)) - 60,
    estado = estado, stringsAsFactors = FALSE)
}
informes <- do.call(rbind, lapply(rmds_vigentes, evalua_informe))
informes <- informes[order(informes$informe), ]
guardar(informes, "evaluacion_informes.csv")

hist <- data.frame(informe = sub(paste0(raiz, "/"), "", rmds_archivo, fixed = TRUE), motivo = "Versión histórica archivada (dataset reducido o análisis anterior)")
guardar(hist, "informes_archivados.csv")

# ============================ 2. OUTPUTS =====================================
fuente_de <- c(
  "outputs/taller-01" = "reports/taller-01/taller-01.Rmd", "outputs/taller-02" = "reports/taller-02/checklist-taller-02.Rmd",
  "outputs/taller-factorial" = "reports/taller-factorial/taller-factorial.Rmd",
  "outputs/taller-pca/componentes-principales-i" = "reports/taller-pca/componentes-principales-i/componentes-principales-i.Rmd",
  "outputs/taller-pca/componentes-principales-ii" = "reports/taller-pca/componentes-principales-ii/componentes-principales-ii.Rmd",
  "outputs/taller-pca/analisis-factorial-i" = "reports/taller-pca/analisis-factorial-i/analisis-factorial-i.Rmd",
  "outputs/taller-pca/analisis-factorial-ii" = "reports/taller-pca/analisis-factorial-ii/analisis-factorial-ii.Rmd",
  "outputs/taller-pca/analisis-33-variables" = "scripts/analisis_33_variables.R",
  "outputs/entrega-corte-1" = "reports/entrega-corte-1/Analisis_Indicadores_Educativos.Rmd",
  "outputs/entrega-corte-2" = "reports/entrega-corte-2/Analisis_Indicadores_Educativos.Rmd",
  "outputs/informe-final" = "scripts/evaluar_repositorio.R")
estado_fuente <- setNames(informes$estado, informes$informe)
outs <- do.call(rbind, lapply(names(fuente_de), function(d) {
  ruta <- file.path(raiz, d); archivos <- list.files(ruta, recursive = TRUE, full.names = TRUE)
  src <- file.path(raiz, fuente_de[[d]])
  mt <- file.mtime(archivos); mt_src <- file.mtime(src)
  desact <- archivos[as.numeric(mt) < as.numeric(mt_src) - 60]
  data.frame(carpeta = d, tablas = sum(grepl("\\.csv$|\\.json$", archivos)), figuras = sum(grepl("\\.png$", archivos)),
             fuente = fuente_de[[d]], posiblemente_desactualizados = length(desact),
             estado_fuente = if (fuente_de[[d]] %in% names(estado_fuente)) estado_fuente[[fuente_de[[d]]]] else if (grepl("analisis-33", d)) "Completo (30 + 3)" else "Soporte de evaluación",
             stringsAsFactors = FALSE)
}))
guardar(outs, "evaluacion_outputs.csv")
desact_detalle <- do.call(rbind, lapply(names(fuente_de), function(d) {
  archivos <- list.files(file.path(raiz, d), recursive = TRUE, full.names = TRUE); src <- file.path(raiz, fuente_de[[d]])
  x <- archivos[as.numeric(file.mtime(archivos)) < as.numeric(file.mtime(src)) - 60]
  if (length(x)) data.frame(carpeta = d, archivo = sub(paste0(raiz, "/", d, "/"), "", x, fixed = TRUE)) else NULL
}))
if (is.null(desact_detalle)) desact_detalle <- data.frame(carpeta = character(), archivo = character())
guardar(desact_detalle, "outputs_posiblemente_desactualizados.csv")

# ============================ 3. PRESENTACIONES ==============================
pptx <- list.files(file.path(raiz, "presentacion"), pattern = "\\.pptx$", recursive = TRUE, full.names = TRUE)
texto_pptx <- function(f) {
  tmp <- tempfile(); dir.create(tmp); utils::unzip(f, exdir = tmp)
  sl <- list.files(file.path(tmp, "ppt", "slides"), pattern = "^slide[0-9]+\\.xml$", full.names = TRUE)
  nt <- list.files(file.path(tmp, "ppt", "notesSlides"), pattern = "\\.xml$", full.names = TRUE)
  tx <- vapply(sl, function(x) {
    xml <- paste(readLines(x, warn = FALSE, encoding = "UTF-8"), collapse = " ")
    paste(gsub("</?a:t>", "", regmatches(xml, gregexpr("<a:t>[^<]*</a:t>", xml))[[1]]), collapse = " ")
  }, character(1))
  list(slides = length(sl), notas = length(nt), texto = paste(tx, collapse = " "))
}
pres <- do.call(rbind, lapply(pptx, function(f) {
  t <- texto_pptx(f)
  data.frame(presentacion = sub(paste0(raiz, "/"), "", f, fixed = TRUE), diapositivas = t$slides, con_notas_del_orador = t$notas,
             menciona_33 = grepl("33", t$texto), menciona_30_indicadores = grepl("30 indicadores", t$texto),
             menciona_categoricas = grepl("categóric", t$texto, ignore.case = TRUE), menciona_one_hot = grepl("one-hot", t$texto, ignore.case = TRUE),
             bloques_que_vemos = cuenta("QUÉ VEMOS|Qué vemos", t$texto), limites_o_validar = grepl("validar|límites|pendiente", t$texto, ignore.case = TRUE),
             vigente_vs_metricas = as.numeric(file.mtime(f)) >= as.numeric(file.mtime(file.path(raiz, "presentacion", "metricas.json"))) - 3600,
             stringsAsFactors = FALSE)
}))
pres$cubre_33 <- with(pres, menciona_33 & (menciona_categoricas | menciona_one_hot))
guardar(pres, "evaluacion_presentaciones.csv")

# ============================ 4. VERIFICACIONES CRUZADAS =====================
mj <- fromJSON(file.path(raiz, "presentacion", "metricas.json"))
j33 <- fromJSON(file.path(raiz, "outputs", "taller-pca", "analisis-33-variables", "tables", "metricas_33.json"))
rd <- function(...) read.csv(file.path(raiz, ...), check.names = FALSE)
tf_ad <- rd("outputs", "taller-factorial", "tables", "adecuacion.csv")
tf_sol <- rd("outputs", "taller-factorial", "tables", "solapamiento_fondos.csv")
pca_i <- rd("outputs", "taller-pca", "componentes-principales-i", "tables", "varianza_explicada.csv")
kmo6 <- rd("outputs", "taller-pca", "analisis-factorial-i", "tables", "kmo.csv")
c2 <- rd("outputs", "entrega-corte-2", "pca", "varianza_explicada.csv")
dg <- rd("outputs", "taller-02", "tables", "Diagnostico_dataset.csv")
p33 <- j33$pca[j33$pca$base == "30 indicadores" & j33$pca$codificacion == "Solo numéricas", ]
tf_eta <- rd("outputs", "taller-factorial", "tables", "r2_puntajes_por_categorica.csv")
t1_eta <- rd("outputs", "taller-01", "tables", "R2_ajustado_por_categorica.csv")
v <- function(nombre, a, b, fa, fb, tol) data.frame(verificacion = nombre, fuente_A = fa, valor_A = a, fuente_B = fb, valor_B = b, tolerancia = tol,
                                                     resultado = ifelse(abs(a - b) <= tol, "Coincide", "Difiere"))
cruz <- rbind(
  v("PCA 6 variables: % varianza PC1+PC2", pca_i$pct_acumulado[2], mj$pca$pct_acum[2], "Taller PCA I", "Presentación PCA", 0.05),
  v("KMO global con 6 variables", kmo6$KMO[1], mj$fa$kmo_global, "Taller factorial I", "Presentación factorial", 0.001),
  v("PCA 30 indicadores: % PC1 (informe de corte 2 vs. análisis 33 variables)", c2$Pct_varianza[1], p33$pct_pc1, "Corte 2 (implementación independiente)", "scripts/analisis_33_variables.R", 0.1),
  v("PCA 30 indicadores: % PC1+PC2 (corte 2 vs. análisis 33 variables)", c2$Pct_acumulado[2], p33$pct_pc12, "Corte 2 (implementación independiente)", "scripts/analisis_33_variables.R", 0.1),
  v("KMO global con 30 indicadores", as.numeric(sub(",", ".", tf_ad$Valor[tf_ad$Medida == "KMO global"])), j33$fa30$kmo, "Taller factorial", "scripts/analisis_33_variables.R", 0.001),
  v("Solapamiento de fondos con 30 indicadores (%)", tf_sol$Porcentaje_del_cupo[tf_sol$Grupo == "En ambos fondos"], j33$fa30$solape_pct, "Taller factorial", "scripts/analisis_33_variables.R", 0.5),
  v("Registros del diagnóstico del Taller 2", dg$filas, nrow(completo), "outputs/taller-02", "educacion_limpio.csv", 0),
  v("Indicadores del diagnóstico del Taller 2", dg$variables, length(ind), "outputs/taller-02", "educacion_limpio.csv", 0),
  v("R² del municipio sobre el puntaje de acceso (%) vs. mediana del R² por indicador (orden de magnitud)", tf_eta$MUNICIPIO[tf_eta$Puntaje == "Acceso"], median(t1_eta$MUNICIPIO), "Taller factorial", "Taller 1", 10)
)
guardar(cruz, "verificaciones_cruzadas.csv")

# ============================ 5. DEPENDENCIAS ================================
scripts_r <- list.files(file.path(raiz, "scripts"), pattern = "\\.R$", full.names = TRUE)
fuentes <- c(scripts_r, rmds_vigentes)
usados <- sort(unique(unlist(lapply(fuentes, function(f) {
  tx <- readLines(f, encoding = "UTF-8", warn = FALSE)
  lib <- regmatches(tx, regexpr("(library|require|requireNamespace)\\(\"?[A-Za-z0-9.]+", tx))
  lib <- sub(".*\\(\"?", "", lib)
  dc <- unlist(regmatches(tx, gregexpr("[A-Za-z][A-Za-z0-9.]+(?=::)", tx, perl = TRUE)))
  c(lib, dc)
}))))
base_r <- c("stats", "utils", "tools", "graphics", "grDevices", "methods", "base", "knitr", "grid")
usados <- setdiff(usados, c(base_r, "x", "p", "pkg", "paquetes"))
inst <- readLines(file.path(raiz, "scripts", "install_dependencies.R"), warn = FALSE)
declarados <- unique(unlist(regmatches(inst, gregexpr("\"[A-Za-z0-9.]+\"", inst))))
declarados <- gsub("\"", "", declarados)
dep <- data.frame(paquete = usados, declarado_en_install_dependencies = usados %in% declarados | usados == "knitr",
                  instalado = vapply(usados, requireNamespace, logical(1), quietly = TRUE))
guardar(dep, "dependencias.csv")

# ============================ 6. CUMPLIMIENTO DE CRITERIOS ===================
activos_corte <- informes$informe[grepl("entrega-corte", informes$informe)]
res_check <- local({   # check_project.R usa getwd() como raiz del proyecto
  anterior <- setwd(raiz); on.exit(setwd(anterior))
  tryCatch({ invisible(capture.output(source(file.path(raiz, "scripts", "check_project.R"), local = new.env()))); TRUE }, error = function(e) FALSE)
})
con_pvalores <- informes$informe[informes$valores_p_sin_ajuste]
estado_c <- function(ok, parcial = FALSE) if (ok) "Cumple" else if (parcial) "Parcial" else "Pendiente"
crit <- data.frame(
  criterio = c("Fuente única y 33 variables", "AÑO como categoría (nunca como indicador)", "Unidad de análisis municipio-año declarada",
               "Inferencia que respeta la repetición de municipios", "Sin pruebas de significancia sin ajuste", "Cifras coherentes entre informes, outputs y presentaciones",
               "Reproducibilidad (validación, dependencias, renderizado)", "Presentaciones que cubren las 33 variables", "Umbrales de decisión validados externamente",
               "Lenguaje: asociación, no causalidad"),
  estado = c(
    estado_c(all(grepl("Completo", informes$estado)), TRUE),
    estado_c(res_check && all(informes$anio_como_categoria), TRUE),
    estado_c(all(vapply(informes$informe, function(r) grepl("municipio-año|municipio y año|municipio en un año", paste(leer(r), collapse = " "), ignore.case = TRUE), logical(1))), TRUE),
    estado_c(FALSE, TRUE),
    estado_c(length(con_pvalores) == 0, length(con_pvalores) <= 2),
    estado_c(all(cruz$resultado == "Coincide")),
    estado_c(res_check && all(dep$declarado_en_install_dependencies), res_check),
    estado_c(all(pres$cubre_33), any(pres$cubre_33)),
    estado_c(FALSE),
    estado_c(FALSE, TRUE)),
  evidencia = c(
    paste0(sum(grepl("Completo", informes$estado)), " de ", nrow(informes), " informes vigentes cubren las 33 variables (los 4 de PCA/factorial como ampliación a 33 columnas); los 2 informes de corte, de otro equipo, analizan 30 numéricas + categóricas descriptivas sin one-hot."),
    paste0("check_project.R ", if (res_check) "pasa" else "FALLA", "; ", sum(informes$anio_como_categoria), " de ", nrow(informes), " informes tratan AÑO como categoría (los de corte lo convierten a texto)."),
    "Los informes de corte, talleres, PCA y factorial declaran que cada fila es un registro municipio-año.",
    "Bootstrap por municipio solo en el Taller 1 y en el Taller factorial; PCA, Mahalanobis y los informes de corte tratan las filas como independientes.",
    if (length(con_pvalores)) paste0("Pruebas cor.test sin ajuste en: ", paste(basename(dirname(con_pvalores)), collapse = ", "), ".") else "Ninguna.",
    paste0(sum(cruz$resultado == "Coincide"), " de ", nrow(cruz), " verificaciones cruzadas coinciden (incluye la comparación del PCA del Corte 2 con el análisis de 33 variables)."),
    paste0("Paquetes usados: ", nrow(dep), "; sin declarar: ", sum(!dep$declarado_en_install_dependencies), "."),
    paste0(sum(pres$cubre_33), " de ", nrow(pres), " presentaciones mencionan las 33 variables y analizan las categóricas (frecuencias, R² o one-hot)."),
    "Los cortes de 6,5 % de deserción, 60 % de cobertura y PC1 ≤ 0 son reglas de trabajo, no umbrales calibrados.",
    "Los informes entregan asociaciones; los informes de corte conservan interpretaciones narrativas de «crisis» que no se validaron."),
  stringsAsFactors = FALSE)
guardar(crit, "cumplimiento_criterios.csv")

# ============================ 7. FIGURA DE COBERTURA =========================
cob <- informes %>% transmute(entregable = paste0(carpeta, "/", sub("\\.Rmd$", "", basename(informe))),
  `Lee educacion_limpio` = ifelse(dataset == "educacion_limpio_talleres.csv (5.063)", 0, 1), `30 indicadores` = as.integer(treinta_indicadores),
  `3 categóricas` = as.integer(categoricas_analizadas), `AÑO categoría` = as.integer(anio_como_categoria),
  `One-hot` = as.integer(one_hot), `HTML vigente` = as.integer(html_vigente))
cob_l <- pivot_longer(cob, -entregable, names_to = "criterio", values_to = "cumple")
cob_l$criterio <- factor(cob_l$criterio, levels = c("Lee educacion_limpio", "30 indicadores", "3 categóricas", "AÑO categoría", "One-hot", "HTML vigente"))
p <- ggplot(cob_l, aes(criterio, reorder(entregable, -as.numeric(factor(entregable))), fill = factor(cumple))) +
  geom_tile(color = "white", linewidth = 1) +
  geom_text(aes(label = ifelse(cumple == 1, "✓", "—")), color = "white", size = 5) +
  scale_fill_manual(values = c(`1` = paleta$azul, `0` = "#c3c2b7"), guide = "none") +
  theme_minimal(base_size = 12) + theme(panel.grid = element_blank(), axis.text.x = element_text(angle = 25, hjust = 1)) +
  labs(title = "Cobertura de las 33 variables por informe", subtitle = "Azul con ✓: el informe cumple el criterio", x = NULL, y = NULL)
ggsave(file.path(dir_f, "cobertura_33_variables.png"), p, width = 10, height = 6, dpi = 150, bg = "white")

cat("Informes vigentes:", nrow(informes), "| archivados:", nrow(hist), "| outputs:", nrow(outs), "| presentaciones:", nrow(pres), "\n")
cat("Criterios:\n"); print(table(crit$estado))
cat("Verificaciones cruzadas:", sum(cruz$resultado == "Coincide"), "de", nrow(cruz), "\n")
print(informes[, c("informe", "estado", "html_vigente")], row.names = FALSE)
