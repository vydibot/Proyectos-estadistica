# --------------------------------------------------------------------------
# PCA y analisis factorial con las 33 columnas del archivo limpio:
#   30 indicadores numericos + AÑO + MUNICIPIO + DEPARTAMENTO.
# Las tres categoricas se codifican con one-hot (AÑO nunca entra como numero).
#
# Variantes de codificacion (todas con AÑO en one-hot salvo la de referencia):
#   solo numericas | + AÑO | + AÑO + departamentos | + AÑO + municipios | + AÑO + ambos
# Dos pesos para las columnas one-hot en el PCA:
#   "z"       -> estandarizadas (como las demas variables)
#   "natural" -> solo centradas (su varianza es p(1-p))
# Base de indicadores: las 6 variables de los informes y los 30 indicadores.
#
# Escribe en outputs/taller-pca/analisis-33-variables/{tables,figures}.
# Ejecutar desde la raiz:  Rscript scripts/analisis_33_variables.R
# --------------------------------------------------------------------------
tryCatch(Sys.setlocale("LC_ALL", "C.UTF-8"), error = function(e) NULL)
options(OutDec = ",")
suppressPackageStartupMessages({ library(ggplot2); library(dplyr); library(tidyr); library(psych); library(jsonlite) })
raiz <- normalizePath(getwd(), mustWork = TRUE)
source(file.path(raiz, "scripts", "helpers_datos.R"))
dir_t <- file.path(raiz, "outputs", "taller-pca", "analisis-33-variables", "tables")
dir_f <- file.path(raiz, "outputs", "taller-pca", "analisis-33-variables", "figures")
dir.create(dir_t, recursive = TRUE, showWarnings = FALSE); dir.create(dir_f, recursive = TRUE, showWarnings = FALSE)

datos <- cargar_educacion(raiz)
ind <- columnas_indicadores(datos)
vars6 <- c("POBLACIÓN_5_16", "COBERTURA_NETA", "COBERTURA_NETA_MEDIA", "DESERCIÓN", "APROBACIÓN", "REPITENCIA")
n <- nrow(datos)
vul <- datos$DESERCIÓN > 0.065 | datos$COBERTURA_NETA <= 0.60
set.seed(20261023)

# ---- Matriz de diseno completa (one-hot con todos los niveles) --------------
onehot <- function(f, pref) { f <- factor(f); m <- model.matrix(~ f - 1); colnames(m) <- paste0(pref, levels(f)); m }
A <- onehot(datos$AÑO, "AÑO=")
D <- onehot(datos$DEPARTAMENTO, "DEP=")
Mu <- onehot(datos$ID_MUNICIPIO, "MUN=")
Znum <- scale(as.matrix(datos[ind]))                       # 30 indicadores z
Zfull <- cbind(Znum, scale(A), scale(D), scale(Mu))        # dummies z
Cnat <- cbind(Znum, sweep(A, 2, colMeans(A)), sweep(D, 2, colMeans(D)), sweep(Mu, 2, colMeans(Mu)))  # dummies centradas
idx <- list(num = seq_along(ind), A = 30 + seq_len(ncol(A)), D = 30 + ncol(A) + seq_len(ncol(D)),
            M = 30 + ncol(A) + ncol(D) + seq_len(ncol(Mu)))
cat("Dimensiones: numericas", length(ind), "| AÑO", ncol(A), "| deptos", ncol(D), "| municipios", ncol(Mu), "\n")
Rz <- cor(Zfull); Sn <- cov(Cnat)

geos <- c("Solo numéricas", "+ AÑO", "+ AÑO + departamentos", "+ AÑO + municipios", "+ AÑO + ambos")
cols_geo <- list(integer(0), idx$A, c(idx$A, idx$D), c(idx$A, idx$M), c(idx$A, idx$D, idx$M))
bases <- list(`6 variables` = match(vars6, ind), `30 indicadores` = seq_along(ind))

auc <- function(score, y) { r <- rank(score); n1 <- sum(y); (sum(r[y]) - n1 * (n1 + 1) / 2) / (n1 * (length(y) - n1)) }

# ============================= PCA ============================================
eval_pca <- function(cols_num, cols_cat, esquema, ref = NULL) {
  cols <- c(cols_num, cols_cat)
  Mx <- if (esquema == "z") Rz[cols, cols] else Sn[cols, cols]
  e <- eigen(Mx, symmetric = TRUE)
  lam <- pmax(e$values, 0); V <- e$vectors
  tot <- sum(lam); k_num <- seq_along(cols_num)
  X0 <- (if (esquema == "z") Zfull else Cnat)[, cols, drop = FALSE]
  sc <- X0 %*% V[, 1:5]
  # orientacion: PC1 mayor = mejores condiciones (el grupo prioritario queda abajo)
  if (mean(sc[vul, 1]) > mean(sc[!vul, 1])) { sc[, 1] <- -sc[, 1]; V[, 1] <- -V[, 1] }
  g <- data.frame(vul = as.numeric(vul), sc[, 1:2]); names(g) <- c("vul", "p1", "p2")
  fit <- suppressWarnings(glm(vul ~ p1 + p2, data = g, family = binomial))
  list(
    pct1 = 100 * lam[1] / tot, pct12 = 100 * sum(lam[1:2]) / tot, n80 = which(cumsum(lam) / tot >= 0.8)[1],
    n_kaiser = if (esquema == "z") sum(lam > 1) else NA_integer_,
    var_total = tot, share_num = 100 * length(cols_num) / sum(diag(Mx)),  # (cols numericas tienen varianza 1)
    info_num_12 = 100 * sum(V[k_num, 1:2]^2 %*% diag(lam[1:2])) / length(cols_num),
    masa_num_12 = 100 * mean(colSums(V[k_num, 1:2, drop = FALSE]^2)),
    auc_pc1 = max(auc(sc[, 1], !vul), auc(-sc[, 1], !vul)),
    auc_pc12 = auc(fitted(fit), vul),
    marcados_pc1 = 100 * mean(sc[, 1] <= 0), capturados_pc1 = 100 * mean(sc[vul, 1] <= 0),
    r2_base1 = NA_real_, r2_base2 = NA_real_, scores = sc[, 1:2], lam = lam[1:15]
  )
}
res <- list(); filas <- list()
for (b in names(bases)) {
  cn <- bases[[b]]
  ref <- eval_pca(cn, integer(0), "z")
  sc_ref <- ref$scores
  for (g in seq_along(geos)) for (esq in if (g == 1) "z" else c("z", "natural")) {
    r <- if (g == 1) ref else eval_pca(cn, cols_geo[[g]], esq)
    r$r2_base1 <- summary(lm(sc_ref[, 1] ~ r$scores))$r.squared * 100
    r$r2_base2 <- summary(lm(sc_ref[, 2] ~ r$scores))$r.squared * 100
    nm <- paste(b, geos[g], esq, sep = " | ")
    res[[nm]] <- r
    filas[[nm]] <- data.frame(base = b, codificacion = geos[g], peso = ifelse(g == 1, "—", esq), columnas = length(cn) + length(cols_geo[[g]]),
                              pct_pc1 = r$pct1, pct_pc12 = r$pct12, n80 = r$n80, n_kaiser = r$n_kaiser,
                              pct_numericas_en_varianza = r$share_num, info_indicadores_en_pc12 = r$info_num_12,
                              masa_numericas_pc12 = r$masa_num_12, r2_pc1_base = r$r2_base1, r2_pc2_base = r$r2_base2,
                              auc_pc1 = r$auc_pc1, auc_pc12 = r$auc_pc12, marcados_pc1 = r$marcados_pc1, capturados_pc1 = r$capturados_pc1)
  }
  cat("PCA listo:", b, "\n")
}
pca_tab <- do.call(rbind, filas); rownames(pca_tab) <- NULL
write.csv(pca_tab, file.path(dir_t, "pca_comparacion_variantes.csv"), row.names = FALSE)

# Autovalores de las 15 primeras componentes (esquema z) para la figura
ev <- do.call(rbind, lapply(names(res)[grepl("30 indicadores", names(res)) & grepl("\\| (z|natural)$", names(res))], function(nm)
  data.frame(variante = nm, k = 1:15, autovalor = res[[nm]]$lam)))
ev$base <- "30"; ev$codificacion <- sub("^30 indicadores \\| (.*) \\| (z|natural)$", "\\1", ev$variante); ev$peso <- sub(".* \\| ", "", ev$variante)
write.csv(ev[, c("codificacion", "peso", "k", "autovalor")], file.path(dir_t, "pca_autovalores_30.csv"), row.names = FALSE)

# ============ Cuanto explica cada categorica de cada indicador (eta2 ajustado) ===========
eta2_adj <- function(x, g) {
  g <- factor(g); k <- nlevels(g); m <- ave(x, g, FUN = mean)
  sst <- sum((x - mean(x))^2); ssw <- sum((x - m)^2)
  1 - (ssw / (length(x) - k)) / (sst / (length(x) - 1))
}
eta <- data.frame(indicador = ind,
                  AÑO = sapply(ind, function(v) eta2_adj(datos[[v]], datos$AÑO)),
                  DEPARTAMENTO = sapply(ind, function(v) eta2_adj(datos[[v]], datos$DEPARTAMENTO)),
                  MUNICIPIO = sapply(ind, function(v) eta2_adj(datos[[v]], datos$ID_MUNICIPIO)))
eta[, -1] <- 100 * pmax(eta[, -1], 0)
write.csv(eta, file.path(dir_t, "r2_ajustado_por_categorica.csv"), row.names = FALSE)

# ============================= FACTORIAL ======================================
cols_fa_drop <- function(cols_cat) {   # elimina el primer nivel de cada categorica (evita singularidad exacta)
  q <- list(A = idx$A, D = idx$D, M = idx$M); keep <- c()
  for (nm in names(q)) if (any(q[[nm]] %in% cols_cat)) keep <- c(keep, q[[nm]][-1])
  keep
}
fa_variantes <- list()
ref_fa <- NULL
filas_fa <- list()
for (g in seq_along(geos)) {
  cols <- c(seq_along(ind), cols_fa_drop(cols_geo[[g]]))
  Rm <- Rz[cols, cols]
  t0 <- Sys.time()
  f <- tryCatch(suppressWarnings(suppressMessages(fa(Rm, nfactors = 2, n.obs = n, fm = "pa", rotate = "oblimin", max.iter = 100, warnings = FALSE))), error = function(e) NULL)
  seg <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  # KMO necesita invertir R: con columnas linealmente dependientes (municipio anidado en departamento) no existe
  kmo <- if (qr(Rm)$rank < ncol(Rm)) NA_real_ else tryCatch(suppressWarnings(KMO(Rm)$MSA), error = function(e) NA_real_)
  if (is.null(f)) { cat("FA falló:", geos[g], "\n"); next }
  L <- unclass(f$loadings)[seq_along(ind), , drop = FALSE]; h2 <- f$communality
  if (is.null(ref_fa)) ref_fa <- L
  tuck <- function(a, b) abs(sum(a * b)) / sqrt(sum(a^2) * sum(b^2))
  c1 <- (tuck(L[, 1], ref_fa[, 1]) + tuck(L[, 2], ref_fa[, 2])) / 2
  c2 <- (tuck(L[, 1], ref_fa[, 2]) + tuck(L[, 2], ref_fa[, 1])) / 2
  filas_fa[[g]] <- data.frame(codificacion = geos[g], columnas = length(cols), segundos = seg, kmo_global = kmo,
                              pct_comun = 100 * sum(h2) / length(h2), h2_numericas_media = mean(h2[seq_along(ind)]),
                              h2_dummies_media = if (length(cols) > 30) mean(h2[-seq_along(ind)]) else NA_real_,
                              pct_comun_en_numericas = 100 * sum(h2[seq_along(ind)]) / sum(h2),
                              congruencia_con_solo_numericas = max(c1, c2),
                              heywood_numericas = sum(h2[seq_along(ind)] > 0.995))
  fa_variantes[[g]] <- f
  cat("FA listo:", geos[g], round(seg, 1), "s\n")
}
fa_tab <- do.call(rbind, filas_fa)
write.csv(fa_tab, file.path(dir_t, "fa_comparacion_variantes.csv"), row.names = FALSE)

# ---- Detalle con los 30 indicadores -------------------------------------------
R30 <- cor(datos[ind])
kmo30 <- KMO(R30)
kmo_tab <- data.frame(variable = ind, KMO = as.numeric(kmo30$MSAi)); write.csv(kmo_tab, file.path(dir_t, "fa30_kmo.csv"), row.names = FALSE)
pa30 <- fa.parallel(datos[ind], fa = "fa", fm = "minres", n.iter = 30, plot = FALSE)
pa30_A <- fa.parallel(cbind(datos[ind], A[, -1]), fa = "fa", fm = "minres", n.iter = 10, plot = FALSE)
pa30_AD <- fa.parallel(cbind(datos[ind], A[, -1], D[, -1]), fa = "fa", fm = "minres", n.iter = 10, plot = FALSE)
k_pa <- pa30$nfact
write.csv(data.frame(k = seq_along(pa30$fa.values), real = pa30$fa.values, simulado = pa30$fa.sim), file.path(dir_t, "fa30_paralelo.csv"), row.names = FALSE)

ajusta <- function(k, fm) tryCatch(suppressWarnings(fa(datos[ind], nfactors = k, fm = fm, rotate = "oblimin", scores = "regression")), error = function(e) NULL)
f30_2 <- ajusta(2, "minres"); f30_k <- ajusta(k_pa, "minres"); f30_2ml <- ajusta(2, "ml")
carga_tab <- function(f) { L <- unclass(f$loadings); data.frame(variable = rownames(L), round(L, 3), h2 = round(f$communality, 3), check.names = FALSE) }
write.csv(carga_tab(f30_2), file.path(dir_t, "fa30_cargas_2factores.csv"), row.names = FALSE)
write.csv(carga_tab(f30_k), file.path(dir_t, "fa30_cargas_kfactores.csv"), row.names = FALSE)
top_por_factor <- function(f, top = 4) { L <- unclass(f$loadings); lapply(seq_len(ncol(L)), function(j) { o <- order(-abs(L[, j]))[1:top]; setNames(round(L[o, j], 2), rownames(L)[o]) }) }

# Costo de un solo factor y solapamiento de 2 factores con los 30 indicadores
f30_1 <- ajusta(1, "minres")
s1 <- as.numeric(f30_1$scores); if (cor(s1, datos$APROBACIÓN) < 0) s1 <- -s1
peor1 <- s1 <= quantile(s1, 0.2)
crit <- list(des = datos$DESERCIÓN > 0.065, cob = datos$COBERTURA_NETA <= 0.60, uni = vul)
omit <- sapply(crit, function(g) 100 * sum(g & !peor1) / sum(g))
S2 <- f30_2$scores; L2 <- unclass(f30_2$loadings)
for (j in 1:2) { sg <- sign(L2["COBERTURA_NETA", j] + L2["APROBACIÓN", j] - L2["DESERCIÓN", j] - L2["REPITENCIA", j]); if (sg < 0) S2[, j] <- -S2[, j] }
b1 <- S2[, 1] <= quantile(S2[, 1], 0.2); b2 <- S2[, 2] <= quantile(S2[, 2], 0.2)

# ---- Comparacion con el modelo de 6 variables (ML, 2 factores, oblimin) ---------------
f6_2 <- fa(datos[vars6], nfactors = 2, fm = "ml", rotate = "oblimin")
h2_cmp <- data.frame(variable = vars6, h2_6 = f6_2$communality[vars6], h2_30 = f30_2$communality[vars6])
write.csv(h2_cmp, file.path(dir_t, "fa_comunalidad_6_vs_30.csv"), row.names = FALSE)

# ============================= FIGURAS ========================================
AZ <- paleta$azul; NR <- paleta$naranja; GR <- paleta$gris
tema <- theme_minimal(base_size = 13) + theme(panel.grid.minor = element_blank(), panel.grid.major.x = element_blank(),
        panel.grid.major.y = element_line(color = paleta$rejilla), plot.title = element_text(face = "bold"),
        plot.subtitle = element_text(color = "#52514e"), legend.position = "top", plot.background = element_rect(fill = "white", color = NA))
guardar <- function(p, nombre, w = 10, h = 5.2) ggsave(file.path(dir_f, nombre), p, width = w, height = h, dpi = 150, bg = "white")
niv <- geos
p30 <- pca_tab[pca_tab$base == "30 indicadores", ]; p30$codificacion <- factor(p30$codificacion, levels = niv)
p30$etq <- ifelse(p30$peso == "—", "—", ifelse(p30$peso == "z", "dummies z", "dummies centradas"))

guardar(ggplot(p30, aes(codificacion, info_indicadores_en_pc12, fill = etq)) + geom_col(position = position_dodge(0.8), width = 0.75) +
          geom_text(aes(label = paste0(formatC(info_indicadores_en_pc12, format = "f", digits = 1, decimal.mark = ","), " %")), position = position_dodge(0.8), vjust = -0.4, size = 3.4) +
          scale_fill_manual(values = c(`—` = GR, `dummies z` = NR, `dummies centradas` = AZ), name = NULL) + scale_y_continuous(limits = c(0, 55)) + tema +
          theme(axis.text.x = element_text(angle = 15, hjust = 1)) +
          labs(title = "Información de los 30 indicadores que conservan PC1 + PC2", subtitle = "Con dummies estandarizadas, la geografía desplaza a los indicadores", x = NULL, y = "% de la varianza de los 30 indicadores"),
        "pca30_info_conservada.png", 10, 5.2)

dil <- p30[p30$peso %in% c("—", "z"), c("codificacion", "pct_numericas_en_varianza")]
dil$resto <- 100 - dil$pct_numericas_en_varianza
dl <- pivot_longer(dil, c(pct_numericas_en_varianza, resto), names_to = "parte", values_to = "pct")
dl$parte <- factor(dl$parte, levels = c("resto", "pct_numericas_en_varianza"), labels = c("Columnas one-hot", "30 indicadores"))
guardar(ggplot(dl, aes(codificacion, pct, fill = parte)) + geom_col(width = 0.7, color = "white") +
          scale_fill_manual(values = c(NR, AZ), name = NULL) + tema + theme(axis.text.x = element_text(angle = 15, hjust = 1)) +
          labs(title = "De dónde viene la varianza total cuando las dummies se estandarizan", x = NULL, y = "% de la varianza total"),
        "pca30_dilucion.png", 10, 5)

evz <- ev[ev$peso %in% c("z", "natural") & ev$k <= 12, ]
evz$codificacion <- factor(evz$codificacion, levels = niv); evz$peso <- ifelse(evz$peso == "z", "Dummies estandarizadas", "Dummies centradas")
guardar(ggplot(evz, aes(k, autovalor, color = codificacion)) + geom_hline(yintercept = 1, linetype = "dashed", color = GR) +
          geom_line(linewidth = 0.9) + geom_point(size = 1.8) + facet_wrap(~peso) + scale_y_log10() + scale_x_continuous(breaks = c(1, 4, 8, 12)) +
          scale_color_manual(values = c("#52514e", AZ, "#1baf7a", NR, "#6250d6"), name = NULL) + tema + theme(panel.grid.major.x = element_line(color = paleta$rejilla)) +
          guides(color = guide_legend(nrow = 2)) +
          labs(title = "Los primeros autovalores son los de los indicadores; la geografía agrega una meseta cerca de 1", subtitle = "Autovalores (escala logarítmica); línea punteada: 1", x = "Componente", y = NULL),
        "pca30_autovalores.png", 11, 5.2)

el <- pivot_longer(eta, c(AÑO, DEPARTAMENTO, MUNICIPIO), names_to = "categorica", values_to = "r2")
el$categorica <- factor(el$categorica, levels = c("AÑO", "DEPARTAMENTO", "MUNICIPIO"))
guardar(ggplot(el, aes(categorica, r2, color = categorica)) + geom_boxplot(width = 0.4, outlier.shape = NA, fill = NA, linewidth = 0.8) +
          geom_jitter(width = 0.12, size = 2.2, alpha = 0.8) + scale_color_manual(values = c(GR, NR, AZ), guide = "none") + tema +
          labs(title = "Cuánta varianza de cada indicador explica cada categórica", subtitle = "R² ajustado por número de categorías; un punto por indicador (30)", x = NULL, y = "% de la varianza"),
        "geo_r2_ajustado.png", 8.5, 5.2)

al <- p30; al$etq2 <- paste0(al$codificacion, ifelse(al$peso == "—", "", ifelse(al$peso == "z", " (z)", " (centr.)")))
al$etq2 <- factor(al$etq2, levels = rev(unique(al$etq2)))
ala <- pivot_longer(al, c(r2_pc1_base, r2_pc2_base), names_to = "comp", values_to = "r2"); ala$comp <- ifelse(ala$comp == "r2_pc1_base", "PC1 de los 30 indicadores", "PC2 de los 30 indicadores")
guardar(ggplot(ala, aes(etq2, r2, fill = comp)) + geom_col(position = position_dodge(0.8), width = 0.75) + coord_flip() + scale_y_continuous(limits = c(0, 105)) +
          scale_fill_manual(values = c(AZ, NR), name = NULL) + tema + theme(panel.grid.major.y = element_blank(), panel.grid.major.x = element_line(color = paleta$rejilla)) +
          labs(title = "¿Se conserva la estructura de los indicadores al agregar la geografía?", subtitle = "% de PC1 y PC2 (solo indicadores) recuperado por PC1+PC2 de cada variante", x = NULL, y = "R² (%)"),
        "pca30_alineacion.png", 11, 5.6)

cp <- pca_tab; cp$etq <- paste0(cp$codificacion, ifelse(cp$peso == "—", "", ifelse(cp$peso == "z", " (z)", " (centr.)")))
cp$etq <- factor(cp$etq, levels = rev(unique(cp$etq)))
cpl <- pivot_longer(cp, c(marcados_pc1, capturados_pc1), names_to = "m", values_to = "v")
cpl$m <- ifelse(cpl$m == "marcados_pc1", "% de registros marcados (PC1 ≤ 0)", "% del grupo prioritario capturado")
guardar(ggplot(cpl, aes(etq, v, fill = m)) + geom_col(position = position_dodge(0.8), width = 0.75) + coord_flip() + facet_wrap(~base) +
          scale_fill_manual(values = c(AZ, NR), name = NULL) + scale_y_continuous(limits = c(0, 105)) + tema + guides(fill = guide_legend(nrow = 1)) +
          theme(panel.grid.major.y = element_blank(), panel.grid.major.x = element_line(color = paleta$rejilla)) +
          labs(title = "Corte PC1 ≤ 0: cuántos se marcan y cuántos del grupo prioritario se capturan", x = NULL, y = NULL),
        "pca33_captura.png", 12, 6)

guardar(ggplot(data.frame(k = seq_along(pa30$fa.values), real = pa30$fa.values, sim = pa30$fa.sim)[1:12, ] %>% pivot_longer(c(real, sim)), aes(k, value, color = name)) +
          geom_hline(yintercept = 0, color = GR) + geom_line(linewidth = 1) + geom_point(size = 2.5) +
          scale_color_manual(values = c(real = AZ, sim = NR), labels = c("Real", "Simulado"), name = NULL) + scale_x_continuous(breaks = 1:12) + tema +
          theme(panel.grid.major.x = element_line(color = paleta$rejilla)) +
          labs(title = paste0("Análisis paralelo con los 30 indicadores: ", k_pa, " factores"), subtitle = "Autovalores reales frente a datos simulados", x = "Factor", y = "Autovalor"),
        "fa30_paralelo.png", 9, 5)

Lk <- as.data.frame(unclass(f30_2$loadings)); Lk$variable <- rownames(Lk)
lg <- pivot_longer(Lk, -variable, names_to = "factor", values_to = "carga"); lg$variable <- factor(lg$variable, levels = rev(ind))
guardar(ggplot(lg, aes(variable, carga, fill = carga > 0)) + geom_col(width = 0.75) + coord_flip() + facet_wrap(~factor) +
          scale_fill_manual(values = c(`TRUE` = AZ, `FALSE` = NR), guide = "none") + tema + theme(panel.grid.major.y = element_blank(), panel.grid.major.x = element_line(color = paleta$rejilla), axis.text.y = element_text(size = 8)) +
          labs(title = "Cargas de dos factores con los 30 indicadores (MinRes, Oblimin)", x = NULL, y = NULL),
        "fa30_cargas.png", 10, 7.2)

fav <- fa_tab; fav$codificacion <- factor(fav$codificacion, levels = niv)
fl <- pivot_longer(fav, c(congruencia_con_solo_numericas, pct_comun_en_numericas), names_to = "medida", values_to = "v")
fl$v <- ifelse(fl$medida == "congruencia_con_solo_numericas", 100 * fl$v, fl$v)
fl$medida <- ifelse(fl$medida == "congruencia_con_solo_numericas", "Congruencia de cargas con el modelo de solo numéricas", "% de la varianza común que viene de los 30 indicadores")
guardar(ggplot(fl, aes(codificacion, v, fill = medida)) + geom_col(position = position_dodge(0.8), width = 0.75) +
          geom_text(aes(label = paste0(formatC(v, format = "f", digits = 0), " %")), position = position_dodge(0.8), vjust = -0.4, size = 3.5) +
          scale_fill_manual(values = c(AZ, NR), name = NULL) + scale_y_continuous(limits = c(0, 112)) + tema + theme(axis.text.x = element_text(angle = 15, hjust = 1)) + guides(fill = guide_legend(nrow = 2)) +
          labs(title = "Análisis factorial (2 factores): qué pasa al agregar las categóricas", x = NULL, y = NULL),
        "fa33_variantes.png", 10, 5.4)

# ============================= METRICAS =======================================
M <- list(
  dims = list(numericas = length(ind), anio = ncol(A), departamentos = ncol(D), municipios = ncol(Mu), total_dummies = ncol(A) + ncol(D) + ncol(Mu)),
  pca = pca_tab, fa = fa_tab, eta = eta,
  eta_resumen = lapply(c("AÑO", "DEPARTAMENTO", "MUNICIPIO"), function(g) c(mediana = median(eta[[g]]), min = min(eta[[g]]), max = max(eta[[g]]))) |> setNames(c("AÑO", "DEPARTAMENTO", "MUNICIPIO")),
  fa30 = list(kmo = kmo30$MSA, kmo_min = min(kmo30$MSAi), kmo_menores_05 = sum(kmo30$MSAi < 0.5), pa = pa30$nfact, pa_con_anio = pa30_A$nfact, pa_con_anio_depto = pa30_AD$nfact,
              pct_comun_2 = 100 * sum(f30_2$communality) / 30, pct_comun_k = 100 * sum(f30_k$communality) / 30, k = k_pa,
              heywood_2 = sum(f30_2$communality > 0.995), heywood_k = sum(f30_k$communality > 0.995),
              rmsea_2 = f30_2$RMSEA[1], tli_2 = f30_2$TLI, rmsea_k = f30_k$RMSEA[1], tli_k = f30_k$TLI,
              phi_2 = f30_2$Phi[1, 2], top2 = top_por_factor(f30_2), topk = top_por_factor(f30_k, 3),
              omision_desercion = unname(omit["des"]), omision_cobertura = unname(omit["cob"]), omision_union = unname(omit["uni"]),
              solape_ambos = sum(b1 & b2), solape_cupo = sum(b1), solape_pct = 100 * sum(b1 & b2) / sum(b1),
              h2_cmp = h2_cmp, kmo_vars = kmo_tab),
  n_vul = sum(vul)
)
write(toJSON(M, auto_unbox = TRUE, digits = NA, pretty = TRUE, na = "null"), file.path(dir_t, "metricas_33.json"))
cat("\n== PCA 30 indicadores ==\n")
print(p30[, c("codificacion", "peso", "pct_pc1", "pct_pc12", "n80", "pct_numericas_en_varianza", "info_indicadores_en_pc12", "r2_pc1_base", "r2_pc2_base", "auc_pc12", "capturados_pc1", "marcados_pc1")] %>% mutate(across(where(is.numeric), ~ round(., 1))))
cat("\n== PCA 6 variables ==\n")
print(pca_tab[pca_tab$base == "6 variables", c("codificacion", "peso", "pct_pc1", "pct_pc12", "n80", "info_indicadores_en_pc12", "r2_pc1_base", "auc_pc12")] %>% mutate(across(where(is.numeric), ~ round(., 1))))
cat("\n== FA ==\n"); print(fa_tab %>% mutate(across(where(is.numeric), ~ round(., 2))))
cat("\n== eta2 resumen ==\n"); print(M$eta_resumen)
cat("\nFA30: KMO", kmo30$MSA, " PA", pa30$nfact, pa30_A$nfact, pa30_AD$nfact, " comun2", M$fa30$pct_comun_2, " Heywood2", M$fa30$heywood_2, " omision", omit, " solape", M$fa30$solape_pct, "\n")
print(M$fa30$top2); print(M$fa30$topk)
