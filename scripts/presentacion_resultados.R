# --------------------------------------------------------------------------
# Recalcula, desde data/raw/educacion_limpio.csv, las cifras y figuras que usan
# las presentaciones. Escribe en presentacion/ (carpeta ignorada por git):
#   presentacion/<deck>/figuras/*.png   y   presentacion/metricas.json
# Ejecutar desde la raiz:  Rscript scripts/presentacion_resultados.R
# Luego:                   python scripts/presentacion_construir.py
# --------------------------------------------------------------------------
tryCatch(Sys.setlocale("LC_ALL", "C.UTF-8"), error = function(e) NULL)
options(OutDec = ",")   # ejes con coma decimal
suppressPackageStartupMessages({
  library(ggplot2); library(dplyr); library(tidyr); library(psych); library(jsonlite)
})
raiz <- normalizePath(getwd(), mustWork = TRUE)
source(file.path(raiz, "scripts", "helpers_datos.R"))
source(file.path(raiz, "scripts", "helpers_33.R"))
datos <- cargar_educacion(raiz)
ind <- columnas_indicadores(datos)
X <- datos[, ind]
panel <- resumen_panel(datos)

decks <- c("taller-01", "taller-02", "taller-pca", "taller-factorial", "final-integrada")
for (d in decks) dir.create(file.path(raiz, "presentacion", d, "figuras"), recursive = TRUE, showWarnings = FALSE)
fig <- function(deck, nombre) file.path(raiz, "presentacion", deck, "figuras", nombre)

# ---- Estilo (paleta validada: azul, naranja; grises para el resto) ----------
AZ <- paleta$azul; NA_ <- paleta$naranja; GR <- paleta$gris; ROJO <- "#e34948"
tema <- theme_minimal(base_size = 17) +
  theme(panel.grid.minor = element_blank(), panel.grid.major.x = element_blank(),
        panel.grid.major.y = element_line(color = paleta$rejilla),
        plot.title = element_text(face = "bold", size = 19), plot.subtitle = element_text(color = "#52514e"),
        axis.text = element_text(color = "#52514e"), plot.background = element_rect(fill = "white", color = NA),
        legend.position = "top")
guardar <- function(p, deck, nombre, w = 11, h = 5.6) ggsave(fig(deck, nombre), p, width = w, height = h, dpi = 150, bg = "white")
pc <- function(x, d = 1) formatC(x, format = "f", digits = d, decimal.mark = ",")

M <- list()   # metricas para las diapositivas
M$panel <- list(registros = panel$registros, municipios = panel$municipios, departamentos = panel$departamentos,
                anios = panel$anios, municipios_14_anios = panel$municipios_14_anios,
                mediana_anios_por_municipio = median(panel$anios_por_municipio), indicadores = length(ind))

# ======================= TALLER 01 ===========================================
t1 <- "taller-01"
por_anio <- panel$por_anio; por_anio$AÑO <- as.integer(as.character(por_anio$AÑO))
M$t01 <- list(registros_2011 = por_anio$registros[1], registros_2012 = por_anio$registros[2], registros_2015 = por_anio$registros[5],
              referencia = round(median(por_anio$registros[por_anio$AÑO >= 2016])))
guardar(ggplot(por_anio, aes(factor(AÑO), registros, fill = AÑO < 2016)) + geom_col(width = 0.72) +
          geom_text(aes(label = fint(registros)), vjust = -0.4, size = 4.2, color = "#52514e") +
          scale_fill_manual(values = c(`TRUE` = NA_, `FALSE` = AZ), guide = "none") +
          scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
          tema + labs(title = "Los primeros cinco años tienen menos registros", subtitle = "Registros completos por año (naranja: 2011-2015)", x = NULL, y = NULL),
        t1, "panel.png")

clave6 <- c("POBLACIÓN_5_16", "COBERTURA_NETA", "DESERCIÓN", "APROBACIÓN", "REPROBACIÓN", "REPITENCIA")
largo <- X[, clave6] %>% pivot_longer(everything(), names_to = "Indicador", values_to = "Valor")
largo$Indicador <- factor(largo$Indicador, levels = clave6)
largo$Valor[largo$Indicador == "POBLACIÓN_5_16"] <- log10(largo$Valor[largo$Indicador == "POBLACIÓN_5_16"])
levels(largo$Indicador)[1] <- "POBLACIÓN_5_16 (log10)"
asim <- function(x) { m <- mean(x); mean((x - m)^3) / sd(x)^3 }
M$t01$asimetria <- sapply(X[, clave6], asim)
M$t01$media_pob <- mean(X$POBLACIÓN_5_16); M$t01$mediana_pob <- median(X$POBLACIÓN_5_16)
guardar(ggplot(largo, aes(Valor)) + geom_histogram(bins = 30, fill = AZ, color = "white", linewidth = 0.15) +
          facet_wrap(~Indicador, scales = "free", ncol = 3) + tema +
          theme(strip.text = element_text(face = "bold", size = 13), axis.text = element_text(size = 11)) +
          labs(title = "Forma de los indicadores clave", x = NULL, y = NULL), t1, "distribuciones.png", 12, 6)

sobre1 <- data.frame(Indicador = ind, Pct = sapply(X, function(x) 100 * mean(x > 1)))
sobre1 <- sobre1[sobre1$Indicador != "POBLACIÓN_5_16", ]   # conteo de personas, no tasa
sobre1 <- sobre1[sobre1$Pct > 0, ]; sobre1 <- sobre1[order(sobre1$Pct), ]
sobre1$Indicador <- factor(sobre1$Indicador, levels = sobre1$Indicador)
M$t01$n_sobre1 <- nrow(sobre1); M$t01$max_sobre1 <- max(sobre1$Pct)
M$t01$max_sobre1_nombre <- as.character(sobre1$Indicador[which.max(sobre1$Pct)])
guardar(ggplot(sobre1, aes(Indicador, Pct)) + geom_col(fill = AZ, width = 0.7) + coord_flip() +
          geom_text(aes(label = paste0(pc(Pct, 1), " %")), hjust = -0.15, size = 4.2, color = "#52514e") +
          scale_y_continuous(expand = expansion(mult = c(0, 0.15))) + tema + theme(panel.grid.major.y = element_blank(), panel.grid.major.x = element_line(color = paleta$rejilla)) +
          labs(title = "Registros con cobertura o matriculación sobre el 100 %", subtitle = "Once indicadores de tasa; son valores a validar, no a eliminar", x = NULL, y = NULL),
        t1, "sobre_100.png", 11, 5.8)

at <- read.csv(file.path(raiz, "outputs", "taller-01", "tables", "Atipicos_IQR.csv"), check.names = FALSE)
at <- at[order(-at$Pct_atipicos), ][1:10, ]; at$Variable <- factor(at$Variable, levels = rev(at$Variable))
M$t01$atipicos_max <- list(variable = as.character(at$Variable[1]), pct = at$Pct_atipicos[1])
guardar(ggplot(at, aes(Variable, Pct_atipicos)) + geom_col(fill = NA_, width = 0.7) + coord_flip() +
          geom_text(aes(label = paste0(pc(Pct_atipicos, 1), " %")), hjust = -0.15, size = 4.2, color = "#52514e") +
          scale_y_continuous(expand = expansion(mult = c(0, 0.2))) + tema + theme(panel.grid.major.y = element_blank(), panel.grid.major.x = element_line(color = paleta$rejilla)) +
          labs(title = "Registros fuera de los bigotes (regla 1,5 × IQR)", subtitle = "Diez indicadores con mayor porcentaje (distancia estadística, no diagnóstico)", x = NULL, y = NULL),
        t1, "atipicos.png", 11, 5.8)

ma <- read.csv(file.path(raiz, "outputs", "taller-01", "tables", "Mediana_anual_indicadores_clave.csv"), check.names = FALSE)
guardar(ggplot(ma, aes(AÑO, Mediana)) + geom_line(color = AZ, linewidth = 1.2) + geom_point(color = AZ, size = 2.5) +
          geom_vline(xintercept = 2019.5, linetype = "dashed", color = NA_) +
          facet_wrap(~Indicador, scales = "free_y") + tema + scale_x_continuous(breaks = seq(2011, 2024, 3)) +
          theme(strip.text = element_text(face = "bold", size = 14)) +
          labs(title = "La repitencia cambia de nivel desde 2020", subtitle = "Mediana anual; línea punteada: entre 2019 y 2020", x = NULL, y = NULL),
        t1, "tiempo.png", 12, 5.8)
rep_m <- ma$Mediana[ma$Indicador == "REPITENCIA"]; names(rep_m) <- ma$AÑO[ma$Indicador == "REPITENCIA"]
cor_anio <- read.csv(file.path(raiz, "outputs", "taller-01", "tables", "Correlacion_con_anio.csv"), check.names = FALSE)
M$t01$rep_2019 <- rep_m[["2019"]]; M$t01$rep_2020 <- rep_m[["2020"]]; M$t01$rep_2024 <- rep_m[["2024"]]
M$t01$r_repitencia_anio <- cor_anio$r_con_AÑO[cor_anio$Indicador == "REPITENCIA"]

sens <- read.csv(file.path(raiz, "outputs", "taller-01", "tables", "Correlaciones_clave_sensibilidad.csv"), check.names = FALSE)
etq <- c("Cobertura neta ~ bruta", "Aprobación ~ reprobación (secundaria)", "Deserción ~ deserción secundaria", "Repitencia ~ repitencia primaria",
         "Aprobación ~ reprobación", "Deserción ~ repitencia", "Cobertura neta ~ deserción", "Población ~ cobertura neta")
sens$Etiqueta <- factor(etq, levels = rev(etq))
M$t01$sens <- sens[, c("Par", "r_Pearson", "IC95_inf", "IC95_sup", "r_2016_2024", "r_dentro_de_año", "r_dentro_de_municipio", "r_Spearman")]
guardar(ggplot(sens, aes(r_Pearson, Etiqueta)) + geom_vline(xintercept = 0, color = GR) +
          geom_errorbarh(aes(xmin = IC95_inf, xmax = IC95_sup), height = 0.25, color = AZ, linewidth = 0.9) +
          geom_point(color = AZ, size = 4) +
          geom_text(aes(label = pc(r_Pearson, 2)), vjust = -1.1, size = 4.2, color = "#52514e") +
          scale_x_continuous(limits = c(-1, 1)) + tema + theme(panel.grid.major.x = element_line(color = paleta$rejilla), panel.grid.major.y = element_blank()) +
          labs(title = "Qué se mueve junto y qué no", subtitle = "Correlación de Pearson con IC95 (bootstrap por municipio)", x = NULL, y = NULL),
        t1, "correlaciones.png", 11, 5.6)
file.copy(file.path(raiz, "outputs", "taller-01", "figures", "Heatmap_Correlacion.png"), fig(t1, "heatmap.png"), overwrite = TRUE)

# ======================= TALLER 02 ===========================================
t2 <- "taller-02"
R <- cor(X)
dg <- read.csv(file.path(raiz, "outputs", "taller-02", "tables", "Diagnostico_dataset.csv"))
cmp <- read.csv(file.path(raiz, "outputs", "taller-02", "tables", "Comparacion_con_sin_anio.csv"), check.names = FALSE)
sm <- read.csv(file.path(raiz, "outputs", "taller-02", "tables", "Mahalanobis_sensibilidad.csv"), check.names = FALSE)
pa <- read.csv(file.path(raiz, "outputs", "taller-02", "tables", "Mahalanobis_por_anio.csv"), check.names = FALSE)
dm <- read.csv(file.path(raiz, "outputs", "taller-02", "tables", "Distancias_Mahalanobis.csv"), check.names = FALSE)
X_anio <- centrar_por_grupo(X, datos$AÑO); dif <- abs(R - cor(X_anio)); diag(dif) <- NA
tri <- upper.tri(R)
suma3 <- datos$APROBACIÓN + datos$REPROBACIÓN + datos$DESERCIÓN
M$t02 <- list(n_p = dg$razon_n_p, condicion = dg$numero_condicion, min_autovalor = dg$menor_autovalor_correlacion,
              pares_09 = sum(abs(R[tri]) >= 0.9), pares_07 = sum(abs(R[tri]) >= 0.7), pares_05 = sum(abs(R[tri]) >= 0.5),
              pares_total = sum(tri), cambio_mediano_anio = median(dif[tri], na.rm = TRUE), cambio_max_anio = max(dif[tri], na.rm = TRUE),
              pares_cambian_01 = sum(dif[tri] > 0.1, na.rm = TRUE), suma3_mediana = median(suma3), suma3_menor_099 = sum(suma3 < 0.99),
              var_poblacion = var(X$POBLACIÓN_5_16), var_max_tasa = max(sapply(X[, setdiff(ind, "POBLACIÓN_5_16")], var)),
              todo_cero = sum(rowSums(X[, setdiff(ind, "POBLACIÓN_5_16")] == 0) == 29),
              marcados = sm$Marcados[1], pct_marcados = sm$Pct_marcados[1], umbral = sm$Umbral_chi2_99[1],
              sens = sm, anio_max = pa$AÑO[which.max(pa$Pct_marcados)], pct_anio_max = max(pa$Pct_marcados), pct_anio_min = min(pa$Pct_marcados),
              r_anio_rep = cmp$r_con_AÑO[cmp$Indicador == "REPITENCIA"],
              top5 = head(dm[order(-dm$Mahalanobis_D2), c("AÑO", "MUNICIPIO", "DEPARTAMENTO", "Mahalanobis_D2")], 5))

c10 <- cmp[order(-abs(cmp$r_con_AÑO)), ][1:10, ]; c10$Indicador <- factor(c10$Indicador, levels = rev(c10$Indicador))
guardar(ggplot(c10, aes(Indicador, r_con_AÑO, fill = r_con_AÑO > 0)) + geom_col(width = 0.7) + coord_flip() +
          geom_text(aes(label = pc(r_con_AÑO, 2), hjust = ifelse(r_con_AÑO > 0, -0.15, 1.15)), size = 4.2, color = "#52514e") +
          scale_fill_manual(values = c(`TRUE` = AZ, `FALSE` = NA_), guide = "none") +
          scale_y_continuous(limits = c(-0.45, 0.85)) + tema + theme(panel.grid.major.y = element_blank(), panel.grid.major.x = element_line(color = paleta$rejilla)) +
          labs(title = "Lo que el año calendario «explicaba» sin que nadie lo notara", subtitle = "Correlación de cada indicador con AÑO (10 mayores)", x = NULL, y = NULL),
        t2, "anio.png", 11, 5.6)

av <- data.frame(k = 1:30, autovalor = sort(eigen(R, symmetric = TRUE, only.values = TRUE)$values, decreasing = TRUE))
guardar(ggplot(av, aes(k, autovalor)) + geom_segment(aes(xend = k, y = 1e-7, yend = autovalor), color = "#cde2fb", linewidth = 1.5) + geom_point(color = AZ, size = 3.5) + scale_y_log10() +
          geom_hline(yintercept = 1, linetype = "dashed", color = NA_) +
          tema + labs(title = "La matriz de correlaciones tiene direcciones casi sin información", subtitle = "Autovalores en escala logarítmica; línea naranja: 1",
                      x = "Posición del autovalor", y = NULL),
        t2, "autovalores.png", 11, 5.2)

qq <- data.frame(teo = qchisq(ppoints(nrow(dm)), 30), obs = sort(dm$Mahalanobis_D2))
guardar(ggplot(qq, aes(teo, obs)) + geom_point(color = AZ, alpha = 0.4, size = 1.2) + geom_abline(slope = 1, intercept = 0, color = NA_, linetype = "dashed", linewidth = 1) +
          scale_x_log10() + scale_y_log10() + tema + theme(panel.grid.major.x = element_line(color = paleta$rejilla)) +
          labs(title = "D² frente a lo esperado bajo normalidad", subtitle = "Ejes logarítmicos; la cola se despega de la línea naranja", x = "Cuantil teórico χ² (30 gl)", y = "D² observada"),
        t2, "qq.png", 7, 5.6)
guardar(ggplot(pa, aes(factor(AÑO), Pct_marcados)) + geom_col(fill = AZ, width = 0.7) +
          geom_hline(yintercept = 1, linetype = "dashed", color = NA_, linewidth = 1) +
          annotate("text", x = 1, y = 2.6, label = "1 % esperado", color = NA_, hjust = 0, size = 5) +
          tema + labs(title = "Porcentaje de registros sobre el umbral, por año", x = NULL, y = "% marcado"),
        t2, "mahalanobis_anio.png", 11, 5.2)
file.copy(file.path(raiz, "outputs", "taller-02", "figures", "Heatmap_correlacion.png"), fig(t2, "heatmap.png"), overwrite = TRUE)


# ---- Variables categóricas y diseño one-hot (33 columnas) ----
eta33 <- read.csv(file.path(raiz, "outputs", "taller-01", "tables", "R2_ajustado_por_categorica.csv"), check.names = FALSE)
M$t01$eta_med <- as.list(sapply(eta33[c("AÑO", "DEPARTAMENTO", "MUNICIPIO")], median))
M$t01$eta_max_mun <- max(eta33$MUNICIPIO); M$t01$eta_max_mun_ind <- eta33$Indicador[which.max(eta33$MUNICIPIO)]
M$t01$departamentos <- length(unique(datos$DEPARTAMENTO))
pdep <- read.csv(file.path(raiz, "outputs", "taller-01", "tables", "Categoricas_registros_por_departamento.csv"), check.names = FALSE)
M$t01$dep_reg_min <- min(pdep$registros); M$t01$dep_reg_max <- max(pdep$registros)
file.copy(file.path(raiz, "outputs", "taller-01", "figures", "Categoricas_R2_ajustado.png"), fig("taller-01", "categoricas.png"), overwrite = TRUE)
M$t02$diseno <- read.csv(file.path(raiz, "outputs", "taller-02", "tables", "Diseno_33_columnas.csv"), check.names = FALSE)

# Alertas de calidad del dataset completo (para la presentación integrada)
zer <- rowSums(datos[, setdiff(ind, "POBLACIÓN_5_16")] == 0) == length(ind) - 1
M$completo <- list(todo_cero = sum(zer), todo_cero_mun = paste(unique(paste0(datos$MUNICIPIO[zer], " (", datos$DEPARTAMENTO[zer], ")")), collapse = "; "),
                   todo_cero_anios = paste(sort(as.character(datos$AÑO[zer])), collapse = ", "),
                   pob_min = min(datos$POBLACIÓN_5_16[zer]), pob_max = max(datos$POBLACIÓN_5_16[zer]))
M$t01$registros_completo <- nrow(datos); M$t01$municipios_completo <- length(unique(datos$ID_MUNICIPIO))

# ======================= TALLER PCA ==========================================
tp <- "taller-pca"
vars <- c("POBLACIÓN_5_16", "COBERTURA_NETA", "COBERTURA_NETA_MEDIA", "DESERCIÓN", "APROBACIÓN", "REPITENCIA")
etiq <- c(POBLACIÓN_5_16 = "Población 5-16", COBERTURA_NETA = "Cobertura neta", COBERTURA_NETA_MEDIA = "Cobertura media",
          DESERCIÓN = "Deserción", APROBACIÓN = "Aprobación", REPITENCIA = "Repitencia")
S6 <- datos[, vars]
r6 <- cor(S6)
pc_s <- prcomp(S6, center = TRUE, scale. = TRUE); pc_n <- prcomp(S6, center = TRUE, scale. = FALSE)
ev <- pc_s$sdev^2; pv <- 100 * ev / sum(ev)
sg1 <- sign(pc_s$rotation["COBERTURA_NETA", 1]); sg2 <- sign(pc_s$rotation["COBERTURA_NETA_MEDIA", 2])
sc <- data.frame(PC1 = sg1 * pc_s$x[, 1], PC2 = sg2 * pc_s$x[, 2], S6)
sc$vul <- sc$DESERCIÓN > 0.065 | sc$COBERTURA_NETA <= 0.60
carga <- data.frame(Variable = rep(etiq[vars], 2), Componente = rep(c("PC1", "PC2"), each = 6),
                    Carga = c(sg1 * pc_s$rotation[, 1], sg2 * pc_s$rotation[, 2]))
sd_orig <- sapply(S6, sd)
cortes <- sapply(c(-0.5, 0, 0.5), function(u) c(marcados = sum(sc$PC1 <= u), captura = sum(sc$PC1 <= u & sc$vul)))
nv <- sum(sc$vul)
cuad <- with(sc, ifelse(PC1 > 0 & PC2 > 0, "Q1", ifelse(PC1 <= 0 & PC2 > 0, "Q2", ifelse(PC1 > 0 & PC2 <= 0, "Q3", "Q4"))))
M$pca <- list(n = nrow(S6), vars = vars, autovalores = ev, pct = pv, pct_acum = cumsum(pv), n80 = which(cumsum(pv) >= 80)[1], kaiser = sum(ev > 1),
              pct_pc1_sin_estandarizar = 100 * pc_n$sdev[1]^2 / sum(pc_n$sdev^2), sd_orig = sd_orig,
              r_max_abs = max(abs(r6[upper.tri(r6)])), r_cob = r6["COBERTURA_NETA", "COBERTURA_NETA_MEDIA"], r_des_apr = r6["DESERCIÓN", "APROBACIÓN"],
              r_pob_max = max(abs(r6["POBLACIÓN_5_16", -1])),
              n_vul = nv, pct_vul = 100 * nv / nrow(sc),
              cortes = data.frame(umbral = c(-0.5, 0, 0.5), marcados = cortes["marcados", ], pct_marcados = 100 * cortes["marcados", ] / nrow(sc),
                                  capturados = cortes["captura", ], pct_capturados = 100 * cortes["captura", ] / nv),
              cuadrantes = data.frame(q = c("Q1", "Q2", "Q3", "Q4"), n = as.integer(table(factor(cuad, c("Q1", "Q2", "Q3", "Q4")))),
                                      vul = as.integer(table(factor(cuad[sc$vul], c("Q1", "Q2", "Q3", "Q4"))))),
              loadings = carga,
              pc1_pesos_pob = abs(sg1 * pc_s$rotation["POBLACIÓN_5_16", 1]))
M$pca$cuadrantes$pct_vul <- 100 * M$pca$cuadrantes$vul / M$pca$cuadrantes$n

cl6 <- as.data.frame(as.table(r6)); names(cl6) <- c("a", "b", "r")
cl6$a <- factor(etiq[as.character(cl6$a)], levels = etiq); cl6$b <- factor(etiq[as.character(cl6$b)], levels = rev(etiq))
guardar(ggplot(cl6, aes(a, b, fill = r)) + geom_tile(color = "white", linewidth = 1) +
          geom_text(aes(label = pc(r, 2), color = abs(r) > 0.45), size = 5) + scale_color_manual(values = c(`TRUE` = "white", `FALSE` = "#0b0b0b"), guide = "none") +
          scale_fill_gradient2(low = AZ, mid = "#f0efec", high = ROJO, limits = c(-1, 1), name = "r") + tema +
          theme(panel.grid = element_blank(), axis.title = element_blank(), legend.position = "right", axis.text.x = element_text(angle = 30, hjust = 1)) +
          labs(title = "Seis variables, solo dos parejas que se parecen"), tp, "correlaciones.png", 8.2, 5.8)

sdd <- data.frame(Variable = factor(etiq[vars], levels = rev(etiq[vars])), Varianza = sd_orig^2)
guardar(ggplot(sdd, aes(Variable, Varianza)) + geom_segment(aes(xend = Variable, y = 1e-3, yend = Varianza), color = "#cde2fb", linewidth = 2) + geom_point(color = AZ, size = 4.5) + coord_flip() + scale_y_log10() +
          tema + theme(panel.grid.major.y = element_blank(), panel.grid.major.x = element_line(color = paleta$rejilla)) +
          labs(title = "Sin estandarizar, la población se queda con casi toda la varianza", subtitle = "Varianza en escala original (logarítmica)", x = NULL, y = NULL),
        tp, "estandarizar.png", 10, 4.6)

scree <- data.frame(PC = factor(paste0("PC", 1:6), labels = paste0("PC", 1:6, "\n", pc(pv, 1), " %")), pv = pv, acum = cumsum(pv))
guardar(ggplot(scree, aes(PC, pv)) + geom_col(fill = AZ, width = 0.7) +
          geom_line(aes(y = acum, group = 1), color = NA_, linewidth = 1.2) + geom_point(aes(y = acum), color = NA_, size = 3) +
          geom_hline(yintercept = 80, linetype = "dashed", color = GR) +
          geom_text(aes(y = acum, label = paste0(pc(acum, 1), " %")), vjust = -1, size = 4.6, color = NA_) +
          annotate("text", x = 6.45, y = 83, label = "80 %", color = GR, size = 5, hjust = 1) +
          scale_y_continuous(limits = c(0, 105)) + tema +
          labs(title = "Dos componentes guardan poco más de la mitad", subtitle = "Barras azules: % de cada componente (bajo el eje). Línea naranja: acumulado", x = NULL, y = NULL),
        tp, "scree.png", 10, 5.4)

carga$Variable <- factor(carga$Variable, levels = rev(etiq[vars]))
guardar(ggplot(carga, aes(Variable, Carga, fill = Carga > 0)) + geom_col(width = 0.7) + coord_flip() + facet_wrap(~Componente) +
          geom_text(aes(label = pc(Carga, 2), hjust = ifelse(Carga > 0, -0.15, 1.15)), size = 4.2, color = "#52514e") +
          scale_fill_manual(values = c(`TRUE` = AZ, `FALSE` = NA_), guide = "none") + scale_y_continuous(limits = c(-0.85, 1.15)) +
          tema + theme(panel.grid.major.y = element_blank(), panel.grid.major.x = element_line(color = paleta$rejilla), strip.text = element_text(face = "bold", size = 15)) +
          labs(title = "Qué pesa en cada componente", subtitle = "PC1 ≈ rendimiento y acceso general; PC2 ≈ brecha en media vs. aprobación", x = NULL, y = NULL),
        tp, "cargas.png", 11, 5.2)

guardar(ggplot(sc, aes(PC1, PC2, color = vul)) + geom_point(alpha = 0.3, size = 1.1) +
          geom_hline(yintercept = 0, color = GR) + geom_vline(xintercept = 0, color = GR) +
          scale_color_manual(values = c(`FALSE` = AZ, `TRUE` = NA_), labels = c("Resto", "Deserción > 6,5 % o cobertura neta ≤ 60 %"), name = NULL) +
          coord_cartesian(xlim = c(-6, 4), ylim = c(-4, 5)) + tema + theme(panel.grid.major.x = element_line(color = paleta$rejilla)) +
          guides(color = guide_legend(override.aes = list(alpha = 1, size = 3))) +
          labs(title = "Los registros prioritarios se desplazan, pero no se separan", subtitle = "Cada punto es un registro municipio-año", x = "PC1", y = "PC2"),
        tp, "mapa.png", 10, 6)

ct <- M$pca$cortes
ct$Corte <- factor(c("PC1 ≤ −0,5", "PC1 ≤ 0", "PC1 ≤ +0,5"), levels = c("PC1 ≤ −0,5", "PC1 ≤ 0", "PC1 ≤ +0,5"))
ctl <- rbind(data.frame(Corte = ct$Corte, Medida = "% de registros marcados", Valor = ct$pct_marcados),
             data.frame(Corte = ct$Corte, Medida = "% del grupo prioritario capturado", Valor = ct$pct_capturados))
guardar(ggplot(ctl, aes(Corte, Valor, fill = Medida)) + geom_col(position = position_dodge(0.75), width = 0.7) +
          geom_text(aes(label = paste0(pc(Valor, 1), " %")), position = position_dodge(0.75), vjust = -0.5, size = 4.6, color = "#52514e") +
          scale_fill_manual(values = c(AZ, NA_), name = NULL) + scale_y_continuous(limits = c(0, 110)) + tema +
          labs(title = "Mover el corte cambia cuántos se atienden y cuántos se pierden", x = NULL, y = NULL),
        tp, "cortes.png", 10, 5.2)

# ======================= TALLER FACTORIAL ====================================
tf <- "taller-factorial"
set.seed(20261023)
kmo <- KMO(S6)
f1 <- fa(S6, nfactors = 1, fm = "ml")
paral <- fa.parallel(S6, fa = "fa", fm = "ml", n.iter = 100, plot = FALSE)
f2o <- fa(S6, nfactors = 2, fm = "ml", rotate = "oblimin")
f2v <- fa(S6, nfactors = 2, fm = "ml", rotate = "varimax")
f2m <- fa(S6, nfactors = 2, fm = "minres", rotate = "oblimin")
f2n <- fa(S6, nfactors = 2, fm = "ml", rotate = "none")
# Metodo por municipio (promedio de sus años): evita que los municipios con mas años pesen mas
Xm <- aggregate(S6, by = list(clave = datos$ID_MUNICIPIO), FUN = mean); Xm$clave <- NULL
kmo_m <- KMO(Xm); paral_m <- fa.parallel(Xm, fa = "fa", fm = "ml", n.iter = 100, plot = FALSE)
f2m_mun <- fa(Xm, nfactors = 2, fm = "ml", rotate = "oblimin")
# Scores y solapamiento
f2s <- fa(S6, nfactors = 2, fm = "ml", rotate = "oblimin", scores = "regression")
fo <- function(f) { l <- unclass(f$loadings); data.frame(var = rownames(l), F1 = l[, 1], F2 = l[, 2]) }
lo <- fo(f2o); lv <- fo(f2v); lm_ <- fo(f2m); ln <- fo(f2n)
# Etiqueta de factor: el que tenga la mayor carga de COBERTURA_NETA_MEDIA es "Acceso"
acc <- if (abs(lo$F1[lo$var == "COBERTURA_NETA_MEDIA"]) > abs(lo$F2[lo$var == "COBERTURA_NETA_MEDIA"])) "F1" else "F2"
perm <- setdiff(c("F1", "F2"), acc)
sc_acc <- f2s$scores[, which(c("F1", "F2") == acc)]; sc_per <- f2s$scores[, which(c("F1", "F2") == perm)]
peor_a <- sc_acc <= quantile(sc_acc, 0.2); peor_p <- sc_per <= quantile(sc_per, 0.2)
n_amb <- sum(peor_a & peor_p)
# Factor unico: costo
f1s <- fa(S6, nfactors = 1, fm = "ml", scores = "regression"); peor1 <- as.numeric(f1s$scores) <= quantile(as.numeric(f1s$scores), 0.2)
crit <- list(`Deserción > 6,5 %` = S6$DESERCIÓN > 0.065, `Cobertura neta ≤ 60 %` = S6$COBERTURA_NETA <= 0.60,
             `Cumple al menos uno` = S6$DESERCIÓN > 0.065 | S6$COBERTURA_NETA <= 0.60)
costo <- data.frame(Criterio = names(crit), Registros = sapply(crit, sum), Omitidos = sapply(crit, function(g) sum(g & !peor1)))
costo$PctOmitido <- 100 * costo$Omitidos / costo$Registros
phi <- f2o$Phi
M$fa <- list(kmo_global = kmo$MSA, kmo_var = kmo$MSAi, kmo_mun_global = kmo_m$MSA, n_municipios = nrow(Xm),
             pa_registros = paral$nfact, pa_municipios = paral_m$nfact,
             f1_comunalidad = f1$communality, f1_pct_var = 100 * f1$Vaccounted["Proportion Var", 1],
             f2_pct_var_ml = 100 * sum(f2o$communality) / 6,
             comunalidades_f2 = f2o$communality, uniq_f2 = f2o$uniquenesses,
             oblimin = lo, varimax = lv, minres = lm_, sin_rotar = ln, phi = phi[1, 2], acc = acc,
             max_carga_ml = max(abs(unlist(lo[, c("F1", "F2")]))), max_carga_minres = max(abs(unlist(lm_[, c("F1", "F2")]))),
             heywood_ml = any(f2o$uniquenesses < 0.005), heywood_minres = any(f2m$uniquenesses < 0.005),
             uniq_min_ml = min(f2o$uniquenesses), uniq_min_minres = min(f2m$uniquenesses),
             f2_tli = f2o$TLI, f2_rmsea = f2o$RMSEA[1], f2_dof = f2o$dof, f2_chi_p = f2o$PVAL, f1_dof = f1$dof, f1_rmsea = f1$RMSEA[1], f1_tli = f1$TLI,
             f2_munic = fo(f2m_mun), phi_mun = f2m_mun$Phi[1, 2],
             solape = list(cupo = sum(peor_a), ambos = n_amb, pct_ambos = 100 * n_amb / sum(peor_a), esperado_indep = 20),
             f1_costo = costo,
             gl = data.frame(factores = 1:4, correlaciones = 15, parametros = c(6, 11, 15, 18), gl = c(9, 4, 0, -3)))

kv <- data.frame(Variable = factor(etiq[names(M$fa$kmo_var)], levels = rev(etiq[vars])), KMO = as.numeric(M$fa$kmo_var))
guardar(ggplot(kv, aes(Variable, KMO)) + geom_col(fill = AZ, width = 0.7) + coord_flip() +
          geom_hline(yintercept = 0.5, linetype = "dashed", color = NA_, linewidth = 1) +
          geom_text(aes(label = pc(KMO, 2)), hjust = -0.15, size = 4.6, color = "#52514e") +
          scale_y_continuous(limits = c(0, 1), expand = expansion(mult = c(0, 0.05))) + tema +
          theme(panel.grid.major.y = element_blank(), panel.grid.major.x = element_line(color = paleta$rejilla)) +
          labs(title = paste0("KMO global: ", pc(kmo$MSA, 3), " (borde del mínimo aceptable)"), subtitle = "Línea naranja: 0,5. Casi todas las variables están en el límite", x = NULL, y = NULL),
        tf, "kmo.png", 10, 4.8)

pdat <- data.frame(k = seq_along(paral$fa.values), Real = paral$fa.values, Simulado = paral$fa.sim)
pl <- pivot_longer(pdat, c(Real, Simulado), names_to = "Serie", values_to = "Valor")
guardar(ggplot(pl, aes(k, Valor, color = Serie)) + geom_line(linewidth = 1.2) + geom_point(size = 3) + geom_hline(yintercept = 0, color = GR) +
          scale_color_manual(values = c(Real = AZ, Simulado = NA_), name = NULL) + scale_x_continuous(breaks = 1:6) + tema +
          theme(panel.grid.major.x = element_line(color = paleta$rejilla)) +
          labs(title = paste0("Análisis paralelo: ", paral$nfact, " factor(es) por encima del azar"), subtitle = "Autovalores reales frente a datos simulados", x = "Factor", y = "Autovalor"),
        tf, "paralelo.png", 9, 5)

lol <- rbind(data.frame(lo, Factor = "Factor Acceso"), data.frame(lo, Factor = "x"))[1:6, ]  # no usado
cargas_o <- data.frame(Variable = rep(etiq[lo$var], 2), Factor = rep(c(acc, perm), each = 6),
                       Carga = c(lo[[acc]], lo[[perm]]))
cargas_o$Factor <- factor(ifelse(cargas_o$Factor == acc, "Factor Acceso (cobertura)", "Factor Permanencia (aprobación)"),
                          levels = c("Factor Acceso (cobertura)", "Factor Permanencia (aprobación)"))
cargas_o$Variable <- factor(cargas_o$Variable, levels = rev(etiq[vars]))
guardar(ggplot(cargas_o, aes(Variable, Carga, fill = Carga > 0)) + geom_col(width = 0.7) + coord_flip() + facet_wrap(~Factor) +
          geom_text(aes(label = pc(Carga, 2), hjust = ifelse(Carga > 0, -0.15, 1.15)), size = 4.2, color = "#52514e") +
          scale_fill_manual(values = c(`TRUE` = AZ, `FALSE` = NA_), guide = "none") + scale_y_continuous(limits = c(-0.85, 1.35)) +
          tema + theme(panel.grid.major.y = element_blank(), panel.grid.major.x = element_line(color = paleta$rejilla), strip.text = element_text(face = "bold", size = 14)) +
          labs(title = "Dos factores con rotación oblicua (Oblimin)", subtitle = "Cada factor lo define casi una sola variable", x = NULL, y = NULL),
        tf, "cargas.png", 11.5, 5.2)

est <- rbind(data.frame(Variable = etiq[lo$var], Carga = c(lo[[acc]], lo[[perm]]), Metodo = "Máxima verosimilitud", Factor = rep(c("Acceso", "Permanencia"), each = 6)),
             data.frame(Variable = etiq[lm_$var], Carga = c(lm_[[acc]], lm_[[perm]]), Metodo = "Mínimos residuos", Factor = rep(c("Acceso", "Permanencia"), each = 6)))
est$Variable <- factor(est$Variable, levels = rev(etiq[vars]))
guardar(ggplot(est, aes(Carga, Variable, color = Metodo)) + geom_vline(xintercept = c(-1, 1), linetype = "dashed", color = ROJO) + geom_vline(xintercept = 0, color = GR) +
          geom_point(size = 4.5, alpha = 0.85, position = position_dodge(0.4)) + facet_wrap(~Factor) +
          scale_color_manual(values = c(AZ, NA_), name = NULL) + scale_x_continuous(limits = c(-0.7, 1.1)) + tema +
          theme(panel.grid.major.y = element_blank(), panel.grid.major.x = element_line(color = paleta$rejilla), strip.text = element_text(face = "bold", size = 14)) +
          labs(title = "Los dos métodos coinciden, pero una carga roza el límite de 1", subtitle = "Líneas rojas: ±1. Una carga ≥ 1 sugiere unicidad ≈ 0 (caso Heywood)", x = NULL, y = NULL),
        tf, "estabilidad.png", 11.5, 5.2)

so <- data.frame(Grupo = factor(c("Solo Fondo Acceso", "En ambos", "Solo Fondo Permanencia"), levels = c("Solo Fondo Acceso", "En ambos", "Solo Fondo Permanencia")),
                 n = c(sum(peor_a & !peor_p), n_amb, sum(peor_p & !peor_a)))
M$fa$solape$solo_acc <- so$n[1]; M$fa$solape$solo_per <- so$n[3]
guardar(ggplot(so, aes(Grupo, n, fill = Grupo)) + geom_col(width = 0.65) +
          geom_text(aes(label = fint(n)), vjust = -0.5, size = 5.2, color = "#52514e") +
          scale_fill_manual(values = c(AZ, GR, NA_), guide = "none") + scale_y_continuous(limits = c(0, max(so$n) * 1.15)) + tema +
          labs(title = "Quién entra a cada fondo (20 % más bajo de cada factor)", subtitle = paste0("Coinciden ", pc(M$fa$solape$pct_ambos, 1), " % del cupo; con factores independientes se esperaría 20 %"), x = NULL, y = NULL),
        tf, "solapamiento.png", 10, 5.2)

cs <- costo; cs$Criterio <- factor(cs$Criterio, levels = cs$Criterio)
guardar(ggplot(cs, aes(Criterio, PctOmitido)) + geom_col(fill = NA_, width = 0.65) +
          geom_text(aes(label = paste0(pc(PctOmitido, 1), " %")), vjust = -0.5, size = 5.2, color = "#52514e") +
          scale_y_continuous(limits = c(0, 75)) + tema +
          labs(title = "Un solo factor deja fuera a muchos registros prioritarios", subtitle = "% del grupo que queda fuera del 20 % inferior del puntaje F1", x = NULL, y = NULL),
        tf, "costo_factor_unico.png", 10, 5)

# ======================= ANALISIS CON 33 COLUMNAS (one-hot) ====================
r33 <- cargar_33(raiz)   # requiere: Rscript scripts/analisis_33_variables.R
M$v33 <- r33$m
M$v33$eta_med <- as.list(sapply(r33$eta[c("AÑO", "DEPARTAMENTO", "MUNICIPIO")], median))
M$v33$eta_min_mun <- min(r33$eta$MUNICIPIO); M$v33$eta_max_mun <- max(r33$eta$MUNICIPIO)
M$v33$eta_pob_mun <- r33$eta$MUNICIPIO[r33$eta$indicador == "POBLACIÓN_5_16"]
f33 <- file.path(raiz, "outputs", "taller-pca", "analisis-33-variables", "figures")
for (f in c("pca30_info_conservada.png", "pca30_alineacion.png", "pca30_autovalores.png", "pca33_captura.png", "geo_r2_ajustado.png", "pca30_dilucion.png"))
  file.copy(file.path(f33, f), fig("taller-pca", f), overwrite = TRUE)
for (f in c("fa30_paralelo.png", "fa30_cargas.png", "fa33_variantes.png"))
  file.copy(file.path(f33, f), fig("taller-factorial", f), overwrite = TRUE)

# ======================= TALLER FACTORIAL COMPLETO (33 variables) ==============
tfd <- file.path(raiz, "outputs", "taller-factorial", "tables")
lee <- function(f) read.csv(file.path(tfd, f), check.names = FALSE)
if (!file.exists(file.path(tfd, "resumen_final.csv"))) stop("Teja primero reports/taller-factorial/taller-factorial.Rmd")
M$tf <- list(adecuacion = lee("adecuacion.csv"), kmo = lee("kmo_por_variable.csv"), criterios = lee("criterios_numero_factores.csv"),
             heywood = lee("casos_limite_por_numero_de_factores.csv"), estimadores = lee("comparacion_estimadores.csv"),
             ajuste = lee("ajuste_del_modelo.csv"), estab = lee("estabilidad_periodos_y_municipios.csv"), boot = lee("bootstrap_resumen.csv"),
             eta = lee("r2_puntajes_por_categorica.csv"), solape = lee("solapamiento_fondos.csv"), costo = lee("costo_factor_unico.csv"),
             captura = lee("captura_grupo_prioritario.csv"), var_oh = lee("variantes_one_hot.csv"), medidas6 = lee("comparacion_medidas_6_vs_30.csv"),
             cmp6 = lee("comparacion_6_vs_30.csv"), cargas2 = lee("cargas_2_factores_oblimin.csv"), roles = lee("variables_y_roles.csv"))
ftf <- file.path(raiz, "outputs", "taller-factorial", "figures")
unlink(list.files(fig("taller-factorial", ""), full.names = TRUE))   # figuras antiguas (6 variables)
# Cargas de los 2 factores en horizontal (legible en una diapositiva)
c2 <- M$tf$cargas2; fcols <- setdiff(names(c2), c("Variable", "Comunalidad"))
acc_f <- fcols[which.max(abs(unlist(c2[c2$Variable == "COBERTURA_NETA", fcols])))]; per_f <- setdiff(fcols, acc_f)
cl <- rbind(data.frame(Variable = c2$Variable, Factor = "Factor Acceso", Carga = c2[[acc_f]]),
            data.frame(Variable = c2$Variable, Factor = "Factor Permanencia y rendimiento", Carga = c2[[per_f]]))
cl$Variable <- factor(cl$Variable, levels = c2$Variable)
guardar(ggplot(cl, aes(Variable, Carga, fill = Carga > 0)) + geom_col(width = 0.75) + facet_wrap(~Factor, ncol = 1) +
          geom_hline(yintercept = 0, color = GR) + scale_fill_manual(values = c(`TRUE` = AZ, `FALSE` = NA_), guide = "none") +
          tema + theme(axis.text.x = element_text(angle = 60, hjust = 1, size = 9), panel.grid.major.x = element_blank(), strip.text = element_text(face = "bold", size = 14)) +
          labs(title = "Cargas de dos factores con los 30 indicadores (MinRes, Oblimin)", x = NULL, y = NULL),
        "taller-factorial", "cargas_2_factores.png", 12, 6.6)

for (f in c("kmo_por_variable.png", "paralelo.png", "cargas_factoriales.png", "puntajes_por_anio.png", "variantes_one_hot.png", "bootstrap_congruencia.png"))
  file.copy(file.path(ftf, f), fig("taller-factorial", f), overwrite = TRUE)

# ======================= EVALUACION FINAL DEL REPOSITORIO ======================
ev <- file.path(raiz, "outputs", "informe-final", "tables")
if (file.exists(file.path(ev, "cumplimiento_criterios.csv"))) {
  M$eval <- list(criterios = read.csv(file.path(ev, "cumplimiento_criterios.csv"), check.names = FALSE),
                 informes = read.csv(file.path(ev, "evaluacion_informes.csv"), check.names = FALSE)[, c("informe", "estado")],
                 presentaciones = read.csv(file.path(ev, "evaluacion_presentaciones.csv"), check.names = FALSE)[, c("presentacion", "diapositivas", "cubre_33")],
                 cruzadas = read.csv(file.path(ev, "verificaciones_cruzadas.csv"), check.names = FALSE)[, c("verificacion", "resultado")])
}

# ======================= GUARDAR METRICAS ====================================
dir.create(file.path(raiz, "presentacion"), showWarnings = FALSE)
write(toJSON(M, auto_unbox = TRUE, digits = NA, pretty = TRUE, na = "null"), file.path(raiz, "presentacion", "metricas.json"))
cat("Figuras:", length(list.files(file.path(raiz, "presentacion"), pattern = "png$", recursive = TRUE)), "\n")
cat("KMO:", kmo$MSA, " PA:", paral$nfact, " PA mun:", paral_m$nfact, " KMO mun:", kmo_m$MSA, "\n")
cat("Cargas ML max:", M$fa$max_carga_ml, " MinRes max:", M$fa$max_carga_minres, " phi:", M$fa$phi, " acc:", acc, "\n")
cat("PCA pct:", round(pv, 2), " vul:", nv, "\n")
cat("solape:", n_amb, "/", sum(peor_a), "\n")
