#!/usr/bin/env python3
"""Construye las cinco presentaciones (.pptx) en presentacion/.

Requisitos:  pip install python-pptx
Entradas:    presentacion/metricas.json y presentacion/<deck>/figuras/*.png
             (generados por scripts/presentacion_resultados.R)
Uso:         python scripts/presentacion_construir.py

Todas las cifras de las diapositivas salen de metricas.json; ninguna se escribe a mano
salvo los valores marcados como "guardado" (informes de PCA sin recalcular).
"""
import json
import os
from pathlib import Path

from PIL import Image
from pptx import Presentation
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE
from pptx.enum.text import MSO_ANCHOR, PP_ALIGN
from pptx.util import Inches, Pt

RAIZ = Path(__file__).resolve().parent.parent
PRES = RAIZ / "presentacion"
M = json.loads((PRES / "metricas.json").read_text(encoding="utf-8"))

# --- Paleta (azul/naranja validados; tintas neutras) -------------------------------
NAVY, AZUL, NARANJA = RGBColor(0x0D, 0x36, 0x6B), RGBColor(0x2A, 0x78, 0xD6), RGBColor(0xEB, 0x68, 0x34)
TINTA, GRIS, CLARO = RGBColor(0x0B, 0x0B, 0x0B), RGBColor(0x52, 0x51, 0x4E), RGBColor(0xF0, 0xEF, 0xEC)
BLANCO, LINEA = RGBColor(0xFF, 0xFF, 0xFF), RGBColor(0xE1, 0xE0, 0xD9)
FUENTE = "Calibri"
W, H = Inches(13.333), Inches(7.5)


# --- Formato numerico en español ------------------------------------------------------
def es(x, d=0):
    s = f"{x:,.{d}f}"
    return s.replace(",", "§").replace(".", ",").replace("§", ".")


def pct(x, d=1):
    return es(x, d) + " %"


class Deck:
    def __init__(self, carpeta, archivo, fase, kicker_base):
        self.dir = PRES / carpeta
        self.archivo = archivo
        self.fase = fase
        self.kicker_base = kicker_base
        self.prs = Presentation()
        self.prs.slide_width, self.prs.slide_height = W, H
        self.n = 0

    # -- primitivas ---------------------------------------------------------------------
    def _slide(self, fondo=BLANCO, notas=""):
        s = self.prs.slides.add_slide(self.prs.slide_layouts[6])
        self.n += 1
        s.background.fill.solid()
        s.background.fill.fore_color.rgb = fondo
        if notas:
            s.notes_slide.notes_text_frame.text = notas
        return s

    def _texto(self, s, x, y, w, h, texto, size=16, bold=False, color=TINTA, align=PP_ALIGN.LEFT,
               anchor=MSO_ANCHOR.TOP, italic=False):
        tb = s.shapes.add_textbox(x, y, w, h)
        tf = tb.text_frame
        tf.word_wrap = True
        tf.vertical_anchor = anchor
        tf.margin_left = tf.margin_right = Inches(0.05)
        tf.margin_top = tf.margin_bottom = Inches(0.03)
        partes = texto if isinstance(texto, list) else [texto]
        for i, parte in enumerate(partes):
            p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
            p.alignment = align
            r = p.add_run()
            r.text = parte
            r.font.size, r.font.bold, r.font.italic = Pt(size), bold, italic
            r.font.color.rgb, r.font.name = color, FUENTE
            if i > 0:
                p.space_before = Pt(size * 0.45)
        return tb

    def _rect(self, s, x, y, w, h, color, forma=MSO_SHAPE.RECTANGLE):
        r = s.shapes.add_shape(forma, x, y, w, h)
        r.fill.solid()
        r.fill.fore_color.rgb = color
        r.line.fill.background()
        r.shadow.inherit = False
        return r

    def _marco(self, s, kicker, titulo):
        self._rect(s, 0, 0, W, Inches(0.12), AZUL)
        self._texto(s, Inches(0.6), Inches(0.3), Inches(10), Inches(0.35), kicker.upper(), 12, True, AZUL)
        self._texto(s, Inches(0.6), Inches(0.62), Inches(12.1), Inches(1.1), titulo, 28, True, TINTA, anchor=MSO_ANCHOR.TOP)
        self._texto(s, Inches(0.6), Inches(7.05), Inches(9), Inches(0.3),
                    f"Indicadores educativos municipales · 2011-2024 · {self.fase}", 10, False, GRIS)
        self._texto(s, Inches(12.0), Inches(7.05), Inches(0.8), Inches(0.3), str(self.n), 10, False, GRIS, PP_ALIGN.RIGHT)

    # -- plantillas -----------------------------------------------------------------------
    def portada(self, titulo, subtitulo, notas=""):
        s = self._slide(NAVY, notas)
        self._rect(s, Inches(0.6), Inches(2.1), Inches(0.12), Inches(2.3), NARANJA)
        self._texto(s, Inches(0.95), Inches(1.4), Inches(11), Inches(0.4), self.fase.upper(), 14, True, RGBColor(0x9E, 0xC5, 0xF4))
        self._texto(s, Inches(0.95), Inches(2.0), Inches(11.4), Inches(1.7), titulo, 44, True, BLANCO)
        self._texto(s, Inches(0.95), Inches(3.8), Inches(11), Inches(1.0), subtitulo, 20, False, RGBColor(0xCD, 0xE2, 0xFB))
        self._texto(s, Inches(0.95), Inches(6.5), Inches(11.5), Inches(0.5),
                    "Para: Dirección de Cobertura y Equidad Territorial · Indicadores educativos municipales de Colombia, 2011-2024",
                    13, False, RGBColor(0x9E, 0xC5, 0xF4))

    def cifras(self, kicker, titulo, tiles, pie="", notas=""):
        """Fichas con cifras grandes: tiles = [(valor, etiqueta)]."""
        s = self._slide(BLANCO, notas)
        self._marco(s, kicker, titulo)
        n = len(tiles)
        gap = Inches(0.3)
        ancho = int((Inches(12.1) - gap * (n - 1)) / n)
        for i, (valor, etiqueta) in enumerate(tiles):
            x = Inches(0.6) + i * (ancho + gap)
            self._rect(s, x, Inches(2.2), ancho, Inches(2.8), CLARO)
            self._rect(s, x, Inches(2.2), ancho, Inches(0.08), AZUL if i % 2 == 0 else NARANJA)
            self._texto(s, x, Inches(2.5), ancho, Inches(1.3), valor, 54, True, NAVY, PP_ALIGN.CENTER, MSO_ANCHOR.MIDDLE)
            self._texto(s, x + Inches(0.15), Inches(3.9), ancho - Inches(0.3), Inches(1.0), etiqueta, 16, False, GRIS, PP_ALIGN.CENTER)
        if pie:
            self._texto(s, Inches(0.6), Inches(5.5), Inches(12.1), Inches(1.2), pie, 18, False, TINTA)

    def figura(self, kicker, titulo, png, bloques, notas="", ancho_fig=7.9):
        """Figura a la izquierda; a la derecha 'Qué vemos / Qué significa / Qué decidir'."""
        s = self._slide(BLANCO, notas)
        self._marco(s, kicker, titulo)
        ruta = self.dir / "figuras" / png
        w_px, h_px = Image.open(ruta).size
        max_w, max_h = Inches(ancho_fig), Inches(5.0)
        esc = min(max_w / w_px, max_h / h_px)
        w, h = int(w_px * esc), int(h_px * esc)
        y0 = Inches(1.85) + int((max_h - h) / 2)
        s.shapes.add_picture(str(ruta), Inches(0.5), y0, w, h)
        x = Inches(0.5) + max_w + Inches(0.3)
        ancho = W - x - Inches(0.5)
        y = Inches(1.9)
        alto_bloque = int(Inches(4.9) / len(bloques))
        colores = {"Qué vemos": AZUL, "Qué significa": NAVY, "Qué decidir": NARANJA, "Cuidado": NARANJA}
        for etiqueta, texto in bloques:
            self._rect(s, x, y + Inches(0.05), Inches(0.06), alto_bloque - Inches(0.25), colores.get(etiqueta, AZUL))
            self._texto(s, x + Inches(0.15), y, ancho - Inches(0.15), Inches(0.3), etiqueta.upper(), 11, True, colores.get(etiqueta, AZUL))
            self._texto(s, x + Inches(0.15), y + Inches(0.28), ancho - Inches(0.15), alto_bloque - Inches(0.35), texto, 14, False, TINTA)
            y += alto_bloque

    def tabla(self, kicker, titulo, cabecera, filas, anchos, pie="", notas="", size=13, alto_fila=0.42):
        s = self._slide(BLANCO, notas)
        self._marco(s, kicker, titulo)
        ntot = len(filas) + 1
        gf = s.shapes.add_table(ntot, len(cabecera), Inches(0.6), Inches(1.9), Inches(sum(anchos)), Inches(alto_fila * ntot))
        t = gf.table
        for j, a in enumerate(anchos):
            t.columns[j].width = Inches(a)
        for i in range(ntot):
            t.rows[i].height = Inches(alto_fila)
            for j in range(len(cabecera)):
                c = t.cell(i, j)
                valor = cabecera[j] if i == 0 else filas[i - 1][j]
                c.text = str(valor)
                c.margin_left = c.margin_right = Inches(0.08)
                c.vertical_anchor = MSO_ANCHOR.MIDDLE
                c.fill.solid()
                c.fill.fore_color.rgb = NAVY if i == 0 else (CLARO if i % 2 == 0 else BLANCO)
                for p in c.text_frame.paragraphs:
                    for r in p.runs:
                        r.font.size, r.font.name = Pt(size), FUENTE
                        r.font.bold = i == 0
                        r.font.color.rgb = BLANCO if i == 0 else TINTA
        if pie:
            self._texto(s, Inches(0.6), Inches(1.95 + alto_fila * ntot + 0.2), Inches(12.1), Inches(1.2), pie, 15, False, GRIS)

    def texto(self, kicker, titulo, items, notas="", size=18, dos_columnas=None):
        """Lista de ideas; dos_columnas = (titulo_izq, items_izq, titulo_der, items_der)."""
        s = self._slide(BLANCO, notas)
        self._marco(s, kicker, titulo)
        if dos_columnas:
            ti, li, td, ld = dos_columnas
            for k, (tt, ll, col) in enumerate([(ti, li, AZUL), (td, ld, NARANJA)]):
                x = Inches(0.6) + k * Inches(6.2)
                self._rect(s, x, Inches(1.95), Inches(5.9), Inches(0.5), col)
                self._texto(s, x + Inches(0.1), Inches(1.98), Inches(5.7), Inches(0.45), tt, 16, True, BLANCO, anchor=MSO_ANCHOR.MIDDLE)
                self._texto(s, x, Inches(2.6), Inches(5.9), Inches(4.2), ["• " + i for i in ll], size - 3, False, TINTA)
        else:
            self._texto(s, Inches(0.6), Inches(1.95), Inches(12.1), Inches(4.9), ["• " + i for i in items], size, False, TINTA)

    def flujo(self, kicker, titulo, pasos, pie="", notas=""):
        """Pasos encadenados (embudo / recorrido): pasos = [(titulo, cifra, detalle)]."""
        s = self._slide(BLANCO, notas)
        self._marco(s, kicker, titulo)
        n = len(pasos)
        gap = Inches(0.25)
        ancho = int((Inches(12.1) - gap * (n - 1)) / n)
        for i, (tt, cifra, det) in enumerate(pasos):
            x = Inches(0.6) + i * (ancho + gap)
            self._rect(s, x, Inches(2.0), ancho, Inches(0.7), NAVY if i < n - 1 else NARANJA, MSO_SHAPE.PENTAGON if i < n - 1 else MSO_SHAPE.RECTANGLE)
            self._texto(s, x + Inches(0.1), Inches(2.0), ancho - Inches(0.3), Inches(0.7), tt, 15, True, BLANCO, anchor=MSO_ANCHOR.MIDDLE)
            self._texto(s, x, Inches(2.95), ancho, Inches(0.9), cifra, 34, True, AZUL, PP_ALIGN.CENTER, MSO_ANCHOR.MIDDLE)
            self._texto(s, x + Inches(0.05), Inches(3.9), ancho - Inches(0.1), Inches(2.0), det, 13.5, False, TINTA)
        if pie:
            self._rect(s, Inches(0.6), Inches(5.95), Inches(12.1), Inches(0.9), CLARO)
            self._texto(s, Inches(0.75), Inches(5.97), Inches(11.8), Inches(0.85), pie, 15, False, TINTA, anchor=MSO_ANCHOR.MIDDLE)

    def guardar(self):
        self.dir.mkdir(parents=True, exist_ok=True)
        ruta = self.dir / self.archivo
        self.prs.save(ruta)
        print(f"{ruta.relative_to(RAIZ)}  ({self.n} diapositivas)")


# ======================================================================================
P, T1, T2, PCA, FA = M["panel"], M["t01"], M["t02"], M["pca"], M["fa"]
CLIENTE = "Dirección de Cobertura y Equidad Territorial"
ETQ = {"POBLACIÓN_5_16": "Población 5-16", "COBERTURA_NETA": "Cobertura neta", "COBERTURA_NETA_MEDIA": "Cobertura media",
       "DESERCIÓN": "Deserción", "APROBACIÓN": "Aprobación", "REPITENCIA": "Repitencia"}


# ----------------------------- FASE 1 · TALLER 1 --------------------------------------
def deck_taller1():
    d = Deck("taller-01", "taller-01-exploracion.pptx", "Fase 1 de 4 · Exploración", "Taller 1")
    asim = T1["asimetria"]
    sens = {s["Par"]: s for s in T1["sens"]}
    s_ap, s_cn, s_de = sens["APROBACIÓN ~ REPROBACIÓN"], sens["COBERTURA_NETA ~ COBERTURA_BRUTA"], sens["COBERTURA_NETA ~ DESERCIÓN"]
    d.portada("Conocer el terreno antes de decidir",
              "Qué dicen —y qué no dicen— los indicadores educativos de los municipios colombianos",
              "Abrimos la historia con una idea simple: antes de priorizar a nadie hay que saber qué estamos mirando. "
              "Esta primera fase es la exploración. Presentamos la versión corregida tras la auditoría del proyecto.")
    d.cifras("El punto de partida", "Antes de decidir, aclaremos qué estamos mirando",
             [(es(P["registros"]), "registros municipio-año"), (es(P["municipios"]), "municipios distintos"),
              (str(P["indicadores"]), "indicadores educativos"), (str(P["anios"]), "años (2011-2024)")],
             pie="Cada fila es un municipio en un año, no un municipio único: el mismo municipio aparece hasta 14 veces. "
                 "Por eso nunca contamos «municipios» a partir de filas.",
             notas="Primer mensaje: la unidad de análisis. Son 13.802 filas, pero 1.123 municipios. Si contáramos filas como municipios "
                   "exageraríamos la evidencia, porque un mismo municipio repetido en varios años no aporta información independiente.")
    d.figura("El punto de partida", "El mapa tiene huecos: 2011-2015 está subrepresentado", "panel.png",
             [("Qué vemos", f"Entre 2011 y 2015 hay entre {es(T1['registros_2015'])} y {es(T1['registros_2012'])} registros por año; desde 2016 hay cerca de {es(T1['referencia'])}."),
              ("Qué significa", f"Solo {es(P['municipios_14_anios'])} de {es(P['municipios'])} municipios aparecen los 14 años. "
                               "Cualquier promedio global pesa más a 2016-2024."),
              ("Qué decidir", "No se puede descartar un sesgo de selección: el archivo limpio no dice qué municipios faltan. Se valida con la fuente original.")],
             "Mostramos el panel como es: incompleto en los años iniciales. No lo corregimos con ponderación todavía; lo declaramos y probamos que las "
             "conclusiones principales se mantienen si se usan solo los años 2016-2024.")
    em = T1["eta_med"]
    d.figura("Las tres categóricas", f"Las 33 variables incluyen 3 categóricas: el municipio explica {es(em['MUNICIPIO'], 0)} % de cada indicador", "categoricas.png",
             [("Qué vemos", f"R² ajustado mediano: municipio {pct(em['MUNICIPIO'], 0)} (hasta {pct(T1['eta_max_mun'], 0)} en {T1['eta_max_mun_ind'].replace('_', ' ').lower()}), departamento {pct(em['DEPARTAMENTO'], 0)}, año {pct(em['AÑO'], 0)}. Hay {T1['departamentos']} departamentos con {es(T1['dep_reg_min'])} a {es(T1['dep_reg_max'])} registros."),
              ("Qué significa", "Los registros de un mismo municipio se parecen entre sí porque el municipio se repite durante años: es persistencia, no un patrón educativo nuevo."),
              ("Qué decidir", "Usar la geografía para comparar grupos o separar variación entre y dentro de municipios, y no tratar las filas como independientes.")],
             "Con esto analizamos las 33 variables: 30 numéricas con histogramas, boxplots y correlaciones, y las 3 categóricas con frecuencias y su peso sobre cada indicador.",
             ancho_fig=7.0)
    d.tabla("Lo que corregimos", "Encontramos y corregimos siete problemas antes de contar la historia",
            ["Antes", "Ahora"],
            [["El informe fallaba: buscaba códigos DANE que no existen en el archivo limpio (y una solución intermedia usaba un dataset sin las 33 variables)", "Se analizan las 33 variables de educacion_limpio.csv; el municipio se identifica por nombre y departamento"],
             ["Las 3 categóricas no se analizaban", "Frecuencias y R² ajustado de cada categórica sobre los indicadores"],
             ["El año entraba como un indicador numérico más", "El año es una categoría; se analizan 30 indicadores"],
             ["Las filas se trataban como municipios independientes", "Incertidumbre con bootstrap por municipio"],
             ["Cientos de pruebas de significancia sin ajuste", "Se reporta la magnitud de r y su intervalo, sin valores p"],
             ["Boxplots Min-Max, que no aportan información", "Boxplots por indicador en su escala, con conteo de atípicos"],
             ["Frases como «crisis severas» o «correlación perfecta»", "Conclusiones con cifras calculadas y sus límites"]],
            [6.0, 6.1],
            notas="Esto es transparencia con el cliente: la primera versión tenía errores que cambiaban la lectura. Los corregimos y dejamos constancia. "
                  "Lo más importante: el año ya no se mezcla con los indicadores, y las conclusiones ya no usan adjetivos que los datos no respaldan.",
            size=13, alto_fila=0.55)
    d.figura("Qué forma tienen los datos", "La mayoría de municipios está bien; unos pocos concentran los valores altos", "distribuciones.png",
             [("Qué vemos", f"Deserción, reprobación y repitencia tienen cola hacia valores altos; la aprobación se concentra cerca de 1 y su cola va hacia abajo. "
                            f"Población: media {es(T1['media_pob'])}, mediana {es(T1['mediana_pob'])}."),
              ("Qué significa", "Lo habitual son tasas bajas de abandono y repitencia; la preocupación está en una minoría de registros."),
              ("Cuidado", "La primera versión describía estos sesgos al revés.")],
             "La forma de las distribuciones importa para elegir las herramientas. Una media de población de 9.399 contra una mediana de 3.242 nos dice que hay pocos municipios muy grandes.",
             ancho_fig=8.2)
    d.figura("Qué forma tienen los datos", "Hay tasas por encima del 100 %: son preguntas, no errores", "sobre_100.png",
             [("Qué vemos", f"{T1['n_sobre1']} indicadores de cobertura y matriculación superan 100 %; en cobertura bruta primaria ocurre en el {pct(T1['max_sobre1'])} de los registros."),
              ("Qué significa", "En cobertura bruta es esperable (incluye estudiantes con extraedad). En cobertura neta y matriculación indica que matrícula y población de referencia no cuadran."),
              ("Qué decidir", "Conservar los valores y validar definiciones y denominadores con la fuente oficial antes de usarlos para asignar recursos.")],
             "Un porcentaje mayor a 100 no necesariamente es un error, pero tampoco es ignorable. Lo marcamos para validar. Sacar estos registros sin entenderlos sería decidir a ciegas.")
    d.figura("Qué forma tienen los datos", "Atípico no significa crisis", "atipicos.png",
             [("Qué vemos", f"Con la regla de 1,5 × IQR, hasta el {pct(T1['atipicos_max']['pct'])} de los registros de un indicador (p. ej. repitencia en transición) queda fuera de los bigotes."),
              ("Qué significa", "Es una distancia estadística. Puede ser un municipio pequeño con una tasa inestable, uno grande o un cambio de definición."),
              ("Cuidado", "No se interpreta como crisis educativa sin evidencia externa.")],
             "Aquí corregimos una frase de la versión original que hablaba de enclaves con crisis severas. Lo que sabemos es que son valores extremos respecto al resto; no sabemos por qué.")
    d.figura("El tiempo importa", "La repitencia cambia de nivel desde 2020", "tiempo.png",
             [("Qué vemos", f"La mediana de repitencia pasa de {es(T1['rep_2019'], 3)} (2019) a {es(T1['rep_2020'], 3)} (2020) y {es(T1['rep_2024'], 3)} (2024). Su correlación con el año es {es(T1['r_repitencia_anio'], 2)}."),
              ("Qué significa", "Si el año entra como número, parte de lo que parece relación entre indicadores es solo tendencia compartida."),
              ("Cuidado", "La coincidencia con 2020 es una pista, no una explicación; falta confirmarla con la fuente.")],
             "Este es el hallazgo que justificó tratar el año como categoría. El salto en la repitencia ocurre justo en 2020, pero no afirmamos por qué: eso exige validar con información administrativa.",
             ancho_fig=8.2)
    d.figura("Qué se asocia con qué", "Algunos indicadores repiten la misma historia; otros no se hablan", "correlaciones.png",
             [("Qué vemos", f"Cobertura neta y bruta: r = {es(s_cn['r_Pearson'], 2)}. Aprobación y reprobación: r = {es(s_ap['r_Pearson'], 2)} (fuerte, no «perfecta»). "
                            f"Cobertura neta y deserción: r = {es(s_de['r_Pearson'], 2)}."),
              ("Qué significa", "Las asociaciones más altas son redundancias de medición entre niveles. La cobertura agregada no explica la deserción."),
              ("Cuidado", "Estas asociaciones son descriptivas; no indican causa. Se mantienen al usar solo 2016-2024, dentro de cada año o dentro de cada municipio.")],
             "Medimos la incertidumbre con bootstrap por municipio, porque las filas de un mismo municipio no son independientes. Las barras son los intervalos al 95 %. "
             "Una correlación alta entre cobertura neta y bruta no es un hallazgo, es que ambas miden lo mismo.",
             ancho_fig=8.2)
    d.figura("Qué se asocia con qué", "El mapa de relaciones muestra bloques de indicadores redundantes", "heatmap.png",
             [("Qué vemos", f"De {es(T2['pares_total'])} parejas, {T2['pares_09']} tienen |r| ≥ 0,90 y {T2['pares_07']} tienen |r| ≥ 0,70."),
              ("Qué significa", "Muchos indicadores son versiones por nivel de lo mismo. Conviene elegir pocos representantes por bloque antes de modelar."),
              ("Qué decidir", "No se reportan valores p: con 13.802 filas todo sería «significativo» y las filas no son independientes.")],
             "Esta redundancia explica por qué el siguiente paso reduce dimensionalidad. Sin ajustar por comparaciones múltiples ni por dependencia, los valores p serían engañosos; por eso usamos magnitudes e intervalos.",
             ancho_fig=5.6)
    d.texto("Lo que sabemos y lo que no", "Qué podemos afirmar y qué falta validar", [],
            dos_columnas=("Podemos afirmar", [
                f"Son {es(P['registros'])} registros de {es(P['municipios'])} municipios, con panel incompleto en 2011-2015.",
                "Las tasas de deserción, reprobación y repitencia son bajas en la mayoría de registros, con cola alta.",
                "Hay bloques de indicadores casi redundantes entre niveles educativos.",
                "La repitencia cambió de nivel desde 2020."],
                "Falta validar", [
                "Qué municipios faltan entre 2011 y 2015 y por qué.",
                "Definiciones y denominadores de las tasas por encima de 100 %.",
                "La causa del salto de repitencia en 2020.",
                "Si los resultados se sostienen al ponderar por población."]),
            notas="Cerramos la fase 1 con honestidad: afirmamos lo que los datos respaldan y listamos lo que debe validarse con fuentes externas. Nada de lo mostrado indica causalidad.")
    d.texto("Lo que sigue", "Siguiente capítulo: ¿cómo se ve el conjunto completo?",
            ["Del análisis de pares de indicadores pasamos a la estructura conjunta de los 30 indicadores.",
             "Revisaremos covarianzas, condicionamiento de la matriz y registros lejanos del patrón general (distancia de Mahalanobis).",
             "Y mostraremos qué habría cambiado si el año hubiera seguido entrando como indicador."],
            notas="Puente hacia el taller 2: pasamos de mirar pares a mirar el conjunto.")
    d.guardar()


# ----------------------------- FASE 2 · TALLER 2 --------------------------------------
def deck_taller2():
    d = Deck("taller-02", "taller-02-diagnostico-multivariado.pptx", "Fase 2 de 4 · Diagnóstico multivariado", "Taller 2")
    sm = T2["sens"]
    d.portada("De indicadores sueltos a un cuadro de conjunto",
              "Diagnóstico multivariado: correlaciones, covarianzas y registros que se alejan del patrón general",
              "Segunda fase: miramos los 30 indicadores a la vez. Es una versión corregida: eliminamos el año como indicador y regeneramos todas las tablas con el archivo limpio actual.")
    d.cifras("El diagnóstico", "¿Tenemos datos suficientes para mirar el conjunto?",
             [(es(T2["n_p"]), "registros por variable (n/p)"), ("30", "indicadores"), ("0", "valores faltantes"), (str(T2["todo_cero"]), "registros con todas las tasas en cero")],
             pie="Sí en cantidad, sin faltantes ni filas repetidas por municipio-año. Dos alertas: varios indicadores son casi combinaciones de otros, y cuatro registros de un mismo municipio traen todas las tasas en cero (posible dato ausente).",
             notas="460 registros por variable es mucho más de lo necesario. Lo delicado viene en la estructura de los indicadores, que veremos a continuación.")
    dz = T2["diseno"]
    d.tabla("Las 33 columnas", "Con one-hot de municipios y departamentos, la matriz tiene dependencias exactas",
            ["Codificación", "Columnas", "Rango", "Dependencias exactas"],
            [[r["Codificacion"], es(r["Columnas"]), es(r["Rango"]), es(r["Dependencias_exactas"])] for r in dz],
            [4.6, 2.2, 2.2, 3.1],
            pie="«Ambos» tiene 35 dependencias: cada departamento es la suma de sus municipios, así que no se puede invertir (ni distancia de Mahalanobis ni KMO). Por eso Mahalanobis usa los 30 indicadores y la geografía se analiza aparte.",
            notas="Respuesta a cómo entran las categóricas en el diagnóstico multivariado: como columnas one-hot solo en las variantes sin redundancia; con ambos, la matriz es singular.",
            size=14, alto_fila=0.62)
    d.figura("El primer hallazgo fue un error nuestro", "El año calendario se colaba entre los indicadores", "anio.png",
             [("Qué vemos", f"La versión anterior incluía el año como columna numérica. La repitencia tiene r = {es(T2['r_anio_rep'], 2)} con él; también varias repitencias por nivel."),
              ("Qué significa", "Parte de lo que se leía como relación entre indicadores era tendencia temporal compartida."),
              ("Qué decidir", "El año pasa a ser una categoría y se compara el resultado con y sin control por año.")],
             "Esto es lo que encontramos en la auditoría. El filtro anterior solo excluía códigos geográficos que ya no existen en el archivo limpio; el año quedaba dentro.")
    d.figura("Correlaciones", "Los indicadores forman bloques; la estructura general resiste el control del año", "heatmap.png",
             [("Qué vemos", f"{T2['pares_09']} pares con |r| ≥ 0,90, {T2['pares_07']} con |r| ≥ 0,70 y {T2['pares_05']} con |r| ≥ 0,50 (de {es(T2['pares_total'])})."),
              ("Qué significa", f"Al restar la media anual, la correlación cambia en mediana {es(T2['cambio_mediano_anio'], 3)}, pero hasta {es(T2['cambio_max_anio'], 2)} en pares con repitencia ({T2['pares_cambian_01']} pares cambian más de 0,10)."),
              ("Cuidado", "La estructura general es estable; las relaciones con repitencia mezclan tendencia temporal.")],
             "Mostramos las dos caras: la estructura de bloques es robusta, pero las correlaciones que involucran repitencia incluyen tendencia temporal compartida.",
             ancho_fig=5.6)
    d.figura("Condicionamiento", "La matriz es invertible, pero está casi pegada a ser singular", "autovalores.png",
             [("Qué vemos", f"Número de condición ≈ {T2['condicion']:.2e}; menor autovalor ≈ {T2['min_autovalor']:.1e}. Aprobación + reprobación + deserción suma ≈ 1 (mediana {es(T2['suma3_mediana'], 3)})."),
              ("Qué significa", "Cualquier método que invierta la matriz amplifica el ruido en esas direcciones casi redundantes."),
              ("Qué decidir", "Trabajar con pocos representantes por bloque (como en PCA) en vez de los 30 indicadores.")],
             "Aprobados, reprobados y desertores forman casi una identidad contable. Eso crea direcciones sin información real en el espacio de los 30 indicadores.")
    d.texto("Covarianzas", "La covarianza cuenta la escala, no la fuerza de la relación",
            [f"La varianza de la población 5-16 es del orden de {T2['var_poblacion']:.1e}; la mayor varianza entre las tasas es {es(T2['var_max_tasa'], 3)}.",
             "Por eso la matriz de covarianzas está dominada por la población y no sirve para comparar pares.",
             "Para comparar fuerza de asociación usamos la correlación; para la distancia de Mahalanobis usamos variables estandarizadas (el resultado es el mismo).",
             "La covarianza es útil como insumo de la distancia, no como medida de asociación entre indicadores."],
            notas="Mensaje corto: la covarianza depende de las unidades. Una variable en miles de personas y otras entre 0 y 1 no se pueden comparar por covarianza.")
    d.figura("Registros lejanos del patrón", "La distancia de Mahalanobis marca de más: 8,6 % frente al 1 % esperado", "qq.png",
             [("Qué vemos", f"{es(T2['marcados'])} registros ({pct(T2['pct_marcados'])}) superan el umbral χ² del 99 % ({es(T2['umbral'], 1)}); bajo normalidad serían el 1 %."),
              ("Qué significa", "Los indicadores son acotados, asimétricos y con muchos ceros: no hay normalidad multivariada. El umbral sirve como ranking, no como prueba."),
              ("Cuidado", "«Atípico» describe distancia al centro; no es error ni crisis.")],
             "El umbral clásico supone normalidad. Como los datos no la cumplen, el 8,6 % no significa que haya 1.190 anomalías. Úselo para ordenar y revisar, no para decidir.",
             ancho_fig=6.2)
    d.figura("Registros lejanos del patrón", f"El porcentaje marcado varía mucho por año: {es(T2['pct_anio_min'], 1)} % a {es(T2['pct_anio_max'], 1)} %", "mahalanobis_anio.png",
             [("Qué vemos", f"El año con más registros marcados es {T2['anio_max']} ({pct(T2['pct_anio_max'])}); en 2015 solo el {pct(T2['pct_anio_min'])}."),
              ("Qué significa", "El patrón de rareza no es homogéneo en el tiempo; algo de la captura o de la composición del año influye."),
              ("Qué decidir", "Revisar la fuente de 2014 antes de interpretar esos registros como casos reales.")],
             "Un solo año concentra casi una quinta parte de sus registros como lejanos. No sabemos por qué; es una pista para revisar la fuente, no una conclusión.")
    top = T2["top5"]
    filas_top = [[str(r["AÑO"]), r["MUNICIPIO"], r["DEPARTAMENTO"], es(r["Mahalanobis_D2"], 0)] for r in top] if isinstance(top, list) else []
    d.tabla("Sensibilidad", "El ranking de rareza es robusto, aunque el número de marcados cambia",
            ["Versión", "Variables", "Marcados", "% marcado", "Coinciden con la base (top 100)"],
            [[r["Version"], r["Variables"], es(r["Marcados"]), pct(r["Pct_marcados"]), r["Coinciden_top100_con_base"]] for r in sm],
            [5.0, 1.4, 1.5, 1.5, 2.7],
            pie="Sin los indicadores casi colineales (reprobación) o con el error anterior del año, los 100 registros más lejanos casi no cambian. "
                "Lo que sí cambia es cuántos pasan el umbral.",
            notas="Esta tabla resume por qué el ranking es útil pese a que el umbral no lo sea: el orden de los casos más lejanos es estable ante cambios razonables.",
            size=14, alto_fila=0.6)
    if filas_top:
        d.tabla("Para revisión", "Cinco registros más lejanos del patrón: candidatos a revisar, no diagnósticos",
                ["Año", "Municipio", "Departamento", "D²"], filas_top, [1.2, 4.2, 3.6, 1.8],
                pie="Cuatro de estos cinco registros son de Papunaua (Vaupés) y tienen todos los indicadores de tasa en cero con 208-229 niños en edad escolar: es más compatible con ausencia de información codificada como 0 que con un resultado real. Confirmar con la fuente.", size=15, alto_fila=0.6,
                notas="Cuatro de los cinco más lejanos son Papunaua, con ceros en todo. Es un hallazgo de calidad de datos, no de desempeño educativo.")
    d.texto("Lo que sabemos y lo que no", "Qué dejamos establecido y qué sigue pendiente", [],
            dos_columnas=("Establecido", [
                "El análisis usa 30 indicadores y el año es una categoría.",
                "Cuatro registros de Papunaua traen todas las tasas en cero (posible dato ausente).",
                "Hay bloques redundantes y una matriz casi singular.",
                "La estructura general resiste el control por año, salvo en pares con repitencia.",
                "El umbral χ² de Mahalanobis marca de más; sirve como ranking."],
                "Pendiente", [
                "Distancia robusta (MCD) o por municipio.",
                "Revisar registros con coberturas > 100 % y el año 2014.",
                "Causa del cambio de nivel desde 2020.",
                "Modelos que reconozcan el panel de municipios."]),
            notas="Cerramos la fase 2 con lo establecido y lo pendiente. El siguiente paso lógico: resumir los indicadores redundantes en pocas dimensiones.")
    d.texto("Lo que sigue", "Siguiente capítulo: resumir en pocas dimensiones",
            ["Como los indicadores son redundantes, probaremos si dos o tres números resumen lo esencial.",
             "Es el análisis de componentes principales (PCA), con seis variables elegidas una por dimensión de la decisión.",
             "La pregunta del cliente: ¿basta un solo número para priorizar municipios?"])
    d.guardar()


# ----------------------------- FASE 3 · PCA -------------------------------------------
def deck_pca():
    d = Deck("taller-pca", "taller-pca-resumen.pptx", "Fase 3 de 4 · Componentes principales", "PCA")
    pv, pa, ev = PCA["pct"], PCA["pct_acum"], PCA["autovalores"]
    c = PCA["cortes"]
    cu = {r["q"]: r for r in PCA["cuadrantes"]}
    d.portada("¿Un número o varios?",
              "Análisis de Componentes Principales para priorizar municipios",
              "Tercera fase. El cliente pregunta si un único índice basta para decidir a quién dirigir fondos extraordinarios de infraestructura y tutoría.")
    d.cifras("El encargo", "La decisión: ¿a quién dirigir fondos de infraestructura y tutoría?",
             [(es(PCA["n"]), "registros municipio-año"), ("6", "variables, una por dimensión de la decisión"), (es(PCA["n_vul"]), "registros prioritarios"), (pct(PCA["pct_vul"]), "de la base")],
             pie="Grupo prioritario (definición operativa de este análisis): deserción mayor a 6,5 % o cobertura neta de 60 % o menos. "
                 "Son umbrales de trabajo, no criterios presupuestales validados.",
             notas="El encargo es una decisión de asignación. Para evaluar si un resumen sirve, definimos un grupo prioritario con dos reglas simples. "
                   "Importante: es una definición operativa; no está calibrada externamente.")
    d.tabla("Qué medimos", "Seis variables, una por dimensión de la decisión",
            ["Variable", "Dimensión", "Por qué está"],
            [["Población 5-16", "Tamaño del municipio", "Es la única en conteo; separa grandes de pequeños"],
             ["Cobertura neta", "Acceso", "Dice si los niños entran al sistema"],
             ["Cobertura neta media", "Acceso en grados 10° y 11°", "Dice si el acceso se sostiene hasta el final"],
             ["Deserción", "Permanencia", "Dice si los que entran se quedan"],
             ["Aprobación", "Rendimiento", "Reemplaza a reprobación, casi complementaria"],
             ["Repitencia", "Rezago", "Distinta de la aprobación, no una identidad con ella"]],
            [3.0, 3.4, 5.7],
            pie="Se dejaron fuera las que repetían la misma información (cobertura bruta, tasa de matriculación, versiones por nivel, reprobación).",
            notas="Elegimos una variable por dimensión de la decisión y descartamos las redundantes que mostró el taller 2.", size=15, alto_fila=0.55)
    d.figura("Primera revisión", "Solo dos parejas de variables se parecen", "correlaciones.png",
             [("Qué vemos", f"Las dos coberturas (r = {es(PCA['r_cob'], 2)}) y deserción con aprobación (r = {es(PCA['r_des_apr'], 2)}). La población no se relaciona con ninguna tasa (|r| ≤ {es(PCA['r_pob_max'], 2)})."),
              ("Qué significa", "Las variables cuentan historias distintas: no se puede esperar que un solo número las resuma bien."),
              ("Qué decidir", "Mantener las seis y medir cuánto se pierde al resumir.")],
             "Si las variables fueran muy parecidas, un solo número bastaría. Aquí solo dos parejas se parecen, y eso anticipa que un único índice perderá bastante.",
             ancho_fig=6.6)
    d.figura("Primera revisión", "Estandarizar no es opcional", "estandarizar.png",
             [("Qué vemos", f"Sin estandarizar, el primer componente concentra más del 99,999 % de la varianza: es simplemente la población."),
              ("Qué significa", "La población se mide en miles y las demás variables entre 0 y 1; el PCA reparte varianza y la escala gana."),
              ("Qué decidir", "Todo el análisis usa variables estandarizadas (media 0, desviación 1).")],
             "Este paso no es un detalle técnico: sin estandarizar, el resultado es un artefacto de las unidades.", ancho_fig=8.4)
    d.figura("Cuánto se conserva", f"Dos componentes guardan {es(pa[1], 1)} %; harían falta {PCA['n80']} para llegar al 80 %", "scree.png",
             [("Qué vemos", f"PC1 = {pct(pv[0])}, PC2 = {pct(pv[1])}. Dos componentes superan autovalor 1 (criterio de Kaiser); PC3 queda en {es(ev[2], 3)}, justo debajo."),
              ("Qué significa", "Resumir en 2 dimensiones pierde cerca de la mitad de la información; es una elección exploratoria."),
              ("Cuidado", "La frontera de Kaiser es frágil: PC3 está a " + es(1 - ev[2], 3) + " del umbral.")],
             "Un único número guarda menos de un tercio de la información. Dos números, poco más de la mitad. No es un resumen fuerte, y hay que decirlo así.",
             ancho_fig=7.4)
    d.figura("Qué significa cada eje", "PC1 mide rendimiento y acceso general; PC2, la brecha entre media y aprobación", "cargas.png",
             [("Qué vemos", "PC1: cobertura y aprobación suben, deserción y repitencia bajan. PC2 contrasta cobertura frente a aprobación y deserción."),
              ("Qué significa", "PC1 se lee como «mejores condiciones educativas». PC2 es un eje de segundo orden, más difícil de nombrar."),
              ("Cuidado", "El signo de cada componente es arbitrario; se fijó para que cobertura neta pese en positivo en PC1.")],
             "Las cargas indican qué variables empujan cada eje. Los nombres son una lectura nuestra, no una propiedad del método.",
             ancho_fig=7.9)
    d.figura("El mapa", "Los registros prioritarios se desplazan en el mapa, pero no se separan", "mapa.png",
             [("Qué vemos", f"Los {es(PCA['n_vul'])} registros prioritarios se concentran hacia PC1 bajo, pero se mezclan con el resto."),
              ("Qué significa", "Estar en el lado izquierdo del mapa es una señal, no una etiqueta: hay traslape entre grupos."),
              ("Cuidado", "El grupo prioritario se define con dos variables que también forman el PCA: el resultado no es una validación independiente.")],
             "Este es el matiz clave: el mapa orienta, pero no sustituye al criterio. Además hay circularidad: la etiqueta usa variables del propio PCA.",
             ancho_fig=6.6)
    d.figura("La decisión", "¿Dónde cortar? Más cobertura implica más registros marcados", "cortes.png",
             [("Qué vemos", f"Con PC1 ≤ 0 se marca el {pct(c[1]['pct_marcados'])} de la base y se captura el {pct(c[1]['pct_capturados'])} del grupo prioritario."),
              ("Qué significa", f"Endurecer el corte (−0,5) baja a {pct(c[0]['pct_marcados'])} marcados, pero pierde el {pct(100 - c[0]['pct_capturados'])} del grupo."),
              ("Qué decidir", "El corte depende del presupuesto y del costo de dejar fuera a alguien; no lo fija la estadística.")],
             "Hay un intercambio claro: cortes más amplios capturan más casos prioritarios pero marcan casi dos tercios de los registros. La decisión es de política, no estadística.",
             ancho_fig=7.4)
    d.tabla("Los cuadrantes", "Dos cuadrantes concentran casi todos los casos prioritarios",
            ["Cuadrante", "Lectura", "Registros", "Prioritarios", "% prioritarios"],
            [["Q1", "Buen desempeño general y alta cobertura media", es(cu["Q1"]["n"]), es(cu["Q1"]["vul"]), pct(cu["Q1"]["pct_vul"])],
             ["Q2", "Baja retención: prioridad tutorías", es(cu["Q2"]["n"]), es(cu["Q2"]["vul"]), pct(cu["Q2"]["pct_vul"])],
             ["Q3", "Buen rendimiento, brecha en media", es(cu["Q3"]["n"]), es(cu["Q3"]["vul"]), pct(cu["Q3"]["pct_vul"])],
             ["Q4", "Doble rezago: intervención integral", es(cu["Q4"]["n"]), es(cu["Q4"]["vul"]), pct(cu["Q4"]["pct_vul"])]],
            [1.3, 5.4, 1.7, 1.8, 1.9],
            pie=f"Q2 y Q4 reúnen {es(cu['Q2']['vul'] + cu['Q4']['vul'])} de {es(PCA['n_vul'])} registros prioritarios ({pct(100 * (cu['Q2']['vul'] + cu['Q4']['vul']) / PCA['n_vul'])}). "
                "Los nombres de los cuadrantes son interpretación, no diagnóstico.",
            notas="Los cuadrantes traducen el mapa a acciones posibles: tutorías en Q2, intervención integral en Q4. Pero en cada cuadrante hay registros que no son prioritarios por nuestro criterio, así que sirven para orientar y no para asignar de forma automática.",
            size=14, alto_fila=0.62)
    V = M["v33"]
    def fp(base, cod, peso="—"):
        return next(r for r in V["pca"] if r["base"] == base and r["codificacion"] == cod and r["peso"] == peso)
    s30, d30, u30, x30 = fp("30 indicadores", "Solo numéricas"), fp("30 indicadores", "+ AÑO + departamentos", "z"), fp("30 indicadores", "+ AÑO + municipios", "z"), fp("30 indicadores", "+ AÑO + ambos", "z")
    s6, d6, u6, x6 = fp("6 variables", "Solo numéricas"), fp("6 variables", "+ AÑO + departamentos", "z"), fp("6 variables", "+ AÑO + municipios", "z"), fp("6 variables", "+ AÑO + ambos", "z")
    em = V["eta_med"]
    d.figura("Ampliación: las 33 columnas", f"Con los 30 indicadores, PC1+PC2 guardan {pct(s30['pct_pc12'])}; la geografía en one-hot no cambia lo que se conserva", "pca30_info_conservada.png",
             [("Qué vemos", f"Con 30 indicadores hacen falta {s30['n80']} componentes para el 80 % (con 6 variables, {PCA['n80']}). Con one-hot estandarizado PC1 baja a {pct(u30['pct_pc1'])}, pero los indicadores siguen guardando {pct(u30['info_indicadores_en_pc12'])} en PC1+PC2."),
              ("Qué significa", "Las columnas one-hot casi no se correlacionan con los indicadores: solo agregan componentes de autovalor ≈ 1 que diluyen el porcentaje."),
              ("Qué decidir", "No agregar one-hot geográfico al PCA: no aporta información y complica la lectura.")],
             "Repetimos el PCA con las 33 columnas. El resultado clave: los dos primeros componentes de los 30 indicadores se conservan intactos aunque se agreguen mil columnas de municipios; lo que cambia es el porcentaje, que se diluye.",
             ancho_fig=7.6)
    d.tabla("Ampliación: ¿qué variante da mejores resultados?", "Sin one-hot geográfico es lo mejor; con geografía, solo departamentos",
            ["Codificación", "Columnas (30 ind.)", "% varianza de los indicadores", "R² PC1 / PC2 (30)", "R² PC1 / PC2 (6 variables)"],
            [["Solo numéricas", es(s30["columnas"]), pct(s30["pct_numericas_en_varianza"], 0), "100 / 100", "100 / 100"],
             ["+ AÑO + departamentos", es(d30["columnas"]), pct(d30["pct_numericas_en_varianza"], 0), f"{es(d30['r2_pc1_base'], 1)} / {es(d30['r2_pc2_base'], 1)}", f"{es(d6['r2_pc1_base'], 0)} / {es(d6['r2_pc2_base'], 0)}"],
             ["+ AÑO + municipios", es(u30["columnas"]), pct(u30["pct_numericas_en_varianza"], 1), f"{es(u30['r2_pc1_base'], 1)} / {es(u30['r2_pc2_base'], 1)}", f"{es(u6['r2_pc1_base'], 0)} / {es(u6['r2_pc2_base'], 0)}"],
             ["+ AÑO + ambos", es(x30["columnas"]), pct(x30["pct_numericas_en_varianza"], 1), f"{es(x30['r2_pc1_base'], 1)} / {es(x30['r2_pc2_base'], 1)}", f"{es(x6['r2_pc1_base'], 0)} / {es(x6['r2_pc2_base'], 1)}"]],
            [3.4, 1.9, 2.4, 2.1, 2.3],
            pie="R²: parte de PC1 y PC2 de la versión sin geografía que recuperan PC1+PC2 de cada variante (one-hot estandarizado). «Ambos» es redundante: cada municipio pertenece a un solo departamento (matriz singular). Con columnas centradas el resultado es idéntico a «solo numéricas».",
             notas="Respuesta a la pregunta de cuál variante da mejores resultados: ninguna supera a no usar one-hot. Si se quiere geografía, departamentos es la opción menos dañina; municipios diluye la varianza y ambos es redundante. Con solo 6 variables la geografía incluso desordena PC2.",
            size=14, alto_fila=0.62)
    d.figura("Ampliación: las 33 columnas", f"El municipio explica {es(em['MUNICIPIO'], 0)} % de cada indicador, pero es persistencia, no un patrón nuevo", "geo_r2_ajustado.png",
             [("Qué vemos", f"R² ajustado mediano: municipio {pct(em['MUNICIPIO'], 0)} (entre {pct(V['eta_min_mun'], 0)} y {pct(V['eta_max_mun'], 0)}), departamento {pct(em['DEPARTAMENTO'], 0)}, año {pct(em['AÑO'], 0)}. La población 5-16 es {pct(V['eta_pob_mun'], 0)} identidad municipal."),
              ("Qué significa", "El mismo municipio se repite varios años con valores parecidos: esa estabilidad no ordena mejor a los municipios que los propios indicadores."),
              ("Qué decidir", "Usar la geografía para comparar grupos sobre el mismo mapa, o para separar variación entre y dentro de municipios (pendiente).")],
             "La geografía sí importa, pero en el PCA solo agrega etiquetas de identidad. Una alternativa mejor, que dejamos pendiente, es separar variación entre y dentro de municipios.",
             ancho_fig=7.2)
    d.figura("Ampliación: las 33 columnas", "Más columnas tampoco mejoran la priorización con PC1 ≤ 0", "pca33_captura.png",
             [("Qué vemos", f"PC1 ≤ 0 encuentra el {pct(s6['capturados_pc1'])} del grupo de interés con 6 variables y el {pct(s30['capturados_pc1'])} con 30 indicadores. Con 6 variables y geografía baja hasta {pct(x6['capturados_pc1'])}."),
              ("Qué significa", "Los 30 indicadores repiten el mismo fenómeno por nivel, así que PC1 mezcla más y encuentra menos."),
              ("Cuidado", "La etiqueta usa dos variables del propio PCA: compara variantes entre sí, no valida el corte.")],
             "Más columnas no significan mejor priorización. Mantener el mapa de 6 variables sin one-hot geográfico.",
             ancho_fig=8.0)
    d.texto("Lo que sabemos y lo que no", "Qué podemos afirmar sobre el PCA y qué falta validar", [],
            dos_columnas=("Podemos afirmar", [
                f"Un solo número (PC1) guarda {pct(pv[0])} de la información; dos guardan {pct(pa[1])}.",
                f"Con PC1 ≤ 0 se captura el {pct(c[1]['pct_capturados'])} del grupo prioritario, pero se marca el {pct(c[1]['pct_marcados'])} de la base.",
                "El mapa orienta: los casos prioritarios se desplazan, no se separan."],
                "Falta validar", [
                "Umbrales de 6,5 % y 60 %: no están calibrados externamente.",
                "Etiqueta de vulnerabilidad definida con variables del propio PCA.",
                "Variación entre y dentro de municipios, en lugar de one-hot, queda pendiente.",
                "Municipios repetidos en el panel pesan más.",
                "No se evaluó clustering formal."]),
            notas="Cerramos con la respuesta a la pregunta del cliente: un solo número no basta, y dos orientan pero no resuelven.")
    d.texto("Lo que sigue", "Siguiente capítulo: ¿hay capacidades latentes detrás de los indicadores?",
            ["El PCA resume varianza total; el análisis factorial busca causas comunes latentes.",
             "Probaremos si dos factores («acceso» y «permanencia») sostienen dos fondos separados.",
             "Y revisaremos qué tan estable es esa separación."])
    d.guardar()


# ----------------------------- FASE 4 · FACTORIAL -------------------------------------
def deck_factorial():
    d = Deck("taller-factorial", "taller-factorial-capacidades.pptx", "Fase 4 de 4 · Análisis factorial", "Factorial")
    TF = M["tf"]
    ad = {r["Medida"]: r["Valor"] for r in TF["adecuacion"]}
    cr = {r["Criterio"].split(" (")[0].split(":")[0]: r["Factores_sugeridos"] for r in TF["criterios"]}
    k_kaiser, k_pa, k_map = cr["Kaiser"], cr["Análisis paralelo"], cr["MAP de Velicer"]
    hey = {r["Factores"]: r for r in TF["heywood"]}
    est = TF["estimadores"]
    ajs = {r["Modelo"]: r for r in TF["ajuste"]}
    eb = TF["estab"]
    bt = {r["Medida"]: r for r in TF["boot"]}
    eta = {r["Puntaje"]: r for r in TF["eta"]}
    sol = {r["Grupo"]: r for r in TF["solape"]}
    cost = {r["Criterio"]: r for r in TF["costo"]}
    cap = {r["Regla"].split(":")[0]: r for r in TF["captura"]}
    voh = {r["codificacion"]: r for r in TF["var_oh"]}
    med6 = {r["Medida"]: r for r in TF["medidas6"]}
    c2 = {r["Variable"]: r for r in TF["cargas2"]}
    k_trab = max(r["Factores"] for r in est)
    kmo_g = ad["KMO global"]
    d.portada("¿Dos capacidades o una sola historia?",
              "Análisis factorial completo de las 33 variables: qué hay detrás de los 30 indicadores y qué aportan año, departamento y municipio",
              "Cuarta fase. El análisis factorial busca factores comunes que expliquen por qué los indicadores se mueven juntos. Aquí se hace completo, con las 30 variables numéricas y las 3 categóricas.")
    d.cifras("El punto de partida", "Las 33 variables: qué entra al modelo y qué se usa para leerlo",
             [("33", "variables en total"), ("30", "indicadores en el modelo factorial"), ("3", "categóricas: año, departamento y municipio"), (es(P["registros"]), "registros municipio-año")],
             pie="Las categóricas se prueban como columnas one-hot (diagnóstico), se miden por su R² sobre los indicadores y se usan para leer los puntajes por año, departamento y municipio. Un mismo municipio se repite hasta 14 veces.",
             notas="El análisis factorial supone variables continuas, por eso los 30 indicadores forman el modelo y las 3 categóricas se tratan aparte de tres maneras complementarias.")
    d.figura("¿Tiene sentido factorizar?", f"El KMO global es {kmo_g}: hay correlación, pero el piso es débil", "kmo_por_variable.png",
             [("Qué vemos", f"KMO global {kmo_g}; {ad['Variables con KMO < 0,5']} de los 30 indicadores quedan por debajo de 0,5. Número de condición de la matriz: {ad['Número de condición de R']}."),
              ("Qué significa", "Aprobación + reprobación + deserción suma casi 1, así que la matriz está casi pegada a ser singular. Bartlett rechaza la matriz identidad, pero con 13.802 filas casi todo se rechaza."),
              ("Qué decidir", "Factorizar como exploración y comprobar que las conclusiones no dependen del estimador, del período ni de repetir municipios.")],
             "El KMO mide si hay suficiente correlación parcial. Está por encima del mínimo, pero con varias variables por debajo de 0,5 y una matriz casi singular.",
             ancho_fig=6.2)
    d.figura("¿Cuántos factores?", f"Los criterios no coinciden: Kaiser {k_kaiser}, paralelo {k_pa}, MAP {k_map}", "paralelo.png",
             [("Qué vemos", f"Kaiser sugiere {k_kaiser}, el análisis paralelo {k_pa} y el MAP {k_map}; el BIC sigue bajando hasta 10. La hipótesis de política es 2."),
              ("Qué significa", f"Los 30 indicadores son familias repetidas por nivel educativo, por eso los datos sostienen entre {k_map} y {k_pa} factores. Con {k_map} factores ya aparecen {hey[k_map]['Comunalidades_mayores_099']} comunalidades cercanas a 1."),
              ("Qué decidir", f"Trabajar con 2 factores (política) y con {k_map} (datos), y mostrar ambas soluciones.")],
             "No existe el número de factores. Dos es la hipótesis simple de política; los datos piden más, pero con más factores aparecen casos límite.",
             ancho_fig=6.8)
    d.tabla("¿Importa el método?", "No: los tres estimadores dan casi las mismas cargas",
            ["Factores", "Método", "% varianza común", "Comunalidades > 0,99", "Congruencia con MinRes"],
            [[r["Factores"], {"minres": "MinRes", "ml": "Máxima verosimilitud", "pa": "Ejes principales"}[r["Metodo"]], pct(r["Varianza_comun_pct"]), r["Comunalidades_mayores_099"], es(r["Congruencia_con_MinRes"], 3)] for r in est],
            [1.4, 3.4, 2.4, 2.6, 2.3],
            pie="El resultado depende de qué variables se usan y de cuántos factores se piden, no del estimador. MinRes es la referencia porque no exige normalidad.",
            notas="Tres métodos, dos números de factores: las cargas son casi idénticas.", size=14, alto_fila=0.55)
    d.figura("Rotación y lectura", "Dos factores: acceso, y permanencia y rendimiento", "cargas_2_factores.png",
             [("Qué vemos", f"Factor 1: cobertura y matriculación (cargas hasta {es(c2['COBERTURA_NETA'].get('MR1', 0.99), 2)}). Factor 2: aprobación (−0,97), reprobación (+0,84), deserción y repitencia (0,35 a 0,5)."),
              ("Qué significa", f"Con los 30 indicadores los nombres «Acceso» y «Permanencia y rendimiento» son defendibles y cada factor lo definen familias de indicadores. Con {k_trab} factores se separan por familia y nivel."),
              ("Cuidado", "Una correlación casi nula entre factores no prueba independencia. Las cargas mayores que 1 son casos límite.")],
             "Con los 30 indicadores los factores se leen mejor que con 6 variables, donde cada factor lo definía casi una sola variable.",
             ancho_fig=8.0)
    d.tabla("Ajuste del modelo", "El ajuste habitual no se alcanza, pero estos índices no son fiables aquí",
            ["Modelo", "RMSR", "RMSEA", "TLI", "% varianza común"],
            [[m, es(float(ajs[m]["RMSR"]), 3), es(float(ajs[m]["RMSEA"]), 2), es(float(ajs[m]["TLI"]), 2), pct(float(ajs[m]["Varianza_comun_pct"]))] for m in ajs],
            [3.0, 2.0, 2.0, 2.0, 3.0],
            pie="Referencias: RMSEA ≤ 0,08 y TLI ≥ 0,90. La matriz casi singular y los indicadores acotados distorsionan RMSEA y TLI; el RMSR sí mejora al agregar factores, pero eso no valida los nombres.",
            notas="Los índices de ajuste son malos, pero no son confiables con esta estructura de datos.", size=14, alto_fila=0.6)
    d.tabla("Estabilidad", "Los 2 factores son estables ante el período, la unidad de análisis y el bootstrap",
            ["Subconjunto", "Registros", "Congruencia (2 factores)", f"Congruencia ({k_trab} factores)"],
            [[r["Subconjunto"], es(r["Registros"]), es(r["Congruencia_2_factores"], 3), es(r["Congruencia_k_factores"], 3)] for r in eb] +
            [["Bootstrap por municipio (mediana; IC95)", "100 réplicas", f"{es(bt['Congruencia con la solución completa']['Mediana'], 3)} ({es(bt['Congruencia con la solución completa']['IC95_inf'], 3)}-{es(bt['Congruencia con la solución completa']['IC95_sup'], 3)})", "—"]],
            [4.6, 1.8, 2.8, 2.8],
            pie="Congruencia de Tucker con la solución de todos los registros (1 = idénticas). Con 2 factores la estructura se repite; con más factores es más sensible. Con solo 6 variables, el segundo factor cambiaba de sentido al promediar por municipio.",
            notas="Esta es la prueba de estabilidad: períodos, promedio por municipio y remuestreo por municipios completos.", size=14, alto_fila=0.62)
    d.figura("Las categóricas", f"El municipio explica {es(eta['Acceso']['MUNICIPIO'], 0)} % del puntaje de acceso y casi nada del de permanencia", "puntajes_por_anio.png",
             [("Qué vemos", f"Acceso: municipio {pct(eta['Acceso']['MUNICIPIO'], 0)}, departamento {pct(eta['Acceso']['DEPARTAMENTO'], 0)}, año {pct(eta['Acceso']['AÑO'], 1)}. Permanencia y rendimiento: municipio {pct(eta['Permanencia y rendimiento']['MUNICIPIO'], 0)}, departamento {pct(eta['Permanencia y rendimiento']['DEPARTAMENTO'], 1)}, año {pct(eta['Permanencia y rendimiento']['AÑO'], 1)}."),
              ("Qué significa", "El acceso es una característica estable del municipio; la permanencia y el rendimiento varían de un año a otro dentro de cada municipio."),
              ("Qué decidir", "Para acceso, un promedio histórico por municipio; para permanencia, definir el período de referencia y validar la señal anual con la fuente.")],
             "Así se leen las tres categóricas: año, departamento y municipio explican de forma muy distinta los dos puntajes.",
             ancho_fig=7.4)
    d.figura("Las 33 columnas", "El one-hot no crea factores nuevos: hunde el KMO y multiplica los factores sugeridos", "variantes_one_hot.png",
             [("Qué vemos", f"KMO: {es(voh['Solo numéricas']['kmo_global'], 2)} (solo numéricas), {es(voh['+ AÑO + departamentos']['kmo_global'], 2)} (+ departamentos), {es(voh['+ AÑO + municipios']['kmo_global'], 3)} (+ municipios); con ambos no se puede calcular."),
              ("Qué significa", f"Las columnas one-hot no pertenecen a ningún factor (comunalidad media {es(voh['+ AÑO + municipios']['h2_dummies_media'], 3)}); las cargas de los 30 indicadores no cambian."),
              ("Qué decidir", "Sin one-hot geográfico. Las dummies son binarias y el modelo supone variables continuas: son solo diagnóstico.")],
             "La mejor codificación también es no usar one-hot geográfico. «Ambos» es redundante y deja una matriz singular.",
             ancho_fig=7.2)
    d.tabla("La decisión", "Un factor no basta; dos fondos recogen más, pero su solapamiento no es «mínimo»",
            ["Medida", "Valor"],
            [["Grupo prioritario que deja fuera un factor único", pct(cost["Cumple al menos uno"]["Pct_omitido"])],
             ["  · de deserción alta", pct(cost["Deserción > 6,5 %"]["Pct_omitido"])],
             ["  · de cobertura baja", pct(cost["Cobertura neta ≤ 60 %"]["Pct_omitido"])],
             ["Coinciden en ambos fondos (20 % inferior de cada factor)", f"{es(sol['En ambos fondos']['Registros'])} registros ({pct(sol['En ambos fondos']['Porcentaje_del_cupo'])}; 20 % si fueran independientes)"],
             ["Grupo prioritario capturado por los dos fondos", pct(cap["Unión de ambos fondos"]["Grupo_prioritario_capturado_pct"])]],
            [7.0, 5.1],
            pie="Con 6 variables el solapamiento era 26,5 %; con 30 indicadores es 17,4 %: la cifra depende de las variables. El grupo prioritario usa dos variables del propio modelo: compara reglas, no valida el corte.",
            notas="Un solo índice sigue sin bastar. Dos fondos capturan más, pero el solapamiento no sostiene hablar de mínimo.", size=14, alto_fila=0.6)
    d.tabla("Frente a las 6 variables", "Con los 30 indicadores el análisis factorial cambia de carácter",
            ["Medida", "6 variables", "30 indicadores"],
            [[r["Medida"], r["6 variables"], r["30 indicadores"]] for r in TF["medidas6"]] +
            [["Comunalidad de cobertura neta / media", f"{es(next(r for r in TF['cmp6'] if r['Variable']=='COBERTURA_NETA')['Comunalidad_6_variables'], 2)} / {es(next(r for r in TF['cmp6'] if r['Variable']=='COBERTURA_NETA_MEDIA')['Comunalidad_6_variables'], 2)}",
              f"{es(next(r for r in TF['cmp6'] if r['Variable']=='COBERTURA_NETA')['Comunalidad_30_indicadores'], 2)} / {es(next(r for r in TF['cmp6'] if r['Variable']=='COBERTURA_NETA_MEDIA')['Comunalidad_30_indicadores'], 2)}"]],
            [5.6, 3.2, 3.3],
            pie="Con más indicadores el KMO sube y los factores dejan de estar definidos por una sola variable.",
            notas="Comparación directa entre el análisis factorial con 6 variables y el completo.", size=14, alto_fila=0.6)
    d.texto("Lo que sabemos y lo que no", "Qué podemos afirmar sobre el análisis factorial y qué falta validar", [],
            dos_columnas=("Podemos afirmar", [
                "Hay dos factores nombrables: acceso, y permanencia y rendimiento, estables ante método, período, unidad de análisis y bootstrap.",
                "Un único factor no basta: omite casi la mitad del grupo prioritario.",
                "Las categóricas no forman factores; sí explican el puntaje de acceso (municipio).",
                "Los tres estimadores coinciden."],
                "Falta validar", [
                f"KMO {kmo_g}, matriz casi singular y ajuste habitual no alcanzado.",
                f"El número de factores: {k_kaiser}, {k_pa} o {k_map} según el criterio.",
                "Las filas de un municipio no son independientes.",
                "Umbrales de 6,5 % y 60 % y solapamiento entre fondos."]),
            notas="Cerramos con lo que el análisis sostiene y con lo que sigue sin validarse.")
    d.texto("Lo que sigue", "Cerramos el recorrido: integrar las cuatro fases",
            ["Reuniremos lo aprendido de la exploración, el diagnóstico, el PCA y el análisis factorial.",
             "Y traduciremos todo a una recomendación para la Dirección de Cobertura y Equidad Territorial."])
    d.guardar()


# ----------------------------- FINAL · INTEGRADA --------------------------------------
def deck_final():
    d = Deck("final-integrada", "proyecto-integrado-del-dato-a-la-decision.pptx", "Presentación integrada", "Integrado")
    pv, pa = PCA["pct"], PCA["pct_acum"]
    TF = M["tf"]
    costo30 = next(r for r in TF["costo"] if r["Criterio"] == "Cumple al menos uno")["Pct_omitido"]
    com30 = next(r for r in TF["ajuste"] if r["Modelo"] == "2 factores")["Varianza_comun_pct"]
    kmo30 = next(r for r in TF["adecuacion"] if r["Medida"] == "KMO global")["Valor"]
    c = PCA["cortes"][1]
    sol = FA["solape"]
    d.portada("Del dato a la decisión",
              "Qué aprendimos de los indicadores educativos municipales y cómo usarlo con prudencia",
              "Presentación de cierre que integra las cuatro fases. El hilo conductor: cada fase respondió una pregunta y dejó otra abierta.")
    d.texto("Resumen ejecutivo", "Tres mensajes para la Dirección de Cobertura y Equidad Territorial",
            [f"Los datos permiten orientar, no decidir solos: {es(P['registros'])} registros municipio-año de {es(P['municipios'])} municipios, con panel incompleto en 2011-2015.",
             f"Un solo índice no basta: PC1 guarda {pct(pv[0])} de la información; dos dimensiones, {pct(pa[1])}. Un factor único omite el " + pct(costo30) + " del grupo prioritario (30 indicadores).",
             "Dos dimensiones (acceso, y permanencia y rendimiento) son estables en los 30 indicadores, pero exploratorias (ajuste pobre, filas no independientes): hay que validarlas antes de crear dos fondos oficiales."],
            size=20,
            notas="Si el cliente solo recuerda tres cosas: los datos orientan pero no deciden; un índice no basta; y la separación en dos fondos necesita validación.")
    d.flujo("El recorrido", "Cuatro fases, cuatro preguntas",
            [("1 · Exploración", "30", "¿Qué hay en los datos? Corregimos repetición de municipios, atípicos y conclusiones."),
             ("2 · Diagnóstico", f"{T2['pares_07']}", f"pares con |r| ≥ 0,70: hay redundancia y la matriz es casi singular; Mahalanobis marca de más."),
             ("3 · PCA", pct(pa[1]), "de la información en 2 componentes. Un número no basta; dos orientan."),
             ("4 · Factorial", "2", f"factores estables en 30 indicadores (KMO {kmo30}); ajuste pobre y one-hot sin factores nuevos.")],
            pie="De 30 indicadores a 6 variables y de ahí a 2 dimensiones: cada paso gana claridad y pierde información.",
            notas="Este es el hilo de la historia. Cada fase respondió una pregunta y abrió otra.")
    C, V = M["completo"], M["v33"]
    d.tabla("Los datos", "Todo el proyecto analiza las 33 variables de un solo dataset",
            ["Bloque", "Variables", "Cómo se analizan"],
            [["Indicadores numéricos", "30", "Resumen, histogramas, boxplots, correlaciones, covarianzas, Mahalanobis, PCA y análisis factorial"],
             ["AÑO", "1", "Categoría ordenada (nunca número): frecuencias, R² sobre indicadores, one-hot en PCA y factorial, scores por año"],
             ["DEPARTAMENTO y MUNICIPIO", "2", "Categorías: frecuencias, R² ajustado, one-hot (solo departamentos, solo municipios y ambos) y scores por categoría"]],
            [3.2, 1.3, 7.6],
            pie=f"Fuente única: educacion_limpio.csv, {es(P['registros'])} registros municipio-año de {es(P['municipios'])} municipios. Cada fila es un municipio en un año, no un municipio independiente.",
            notas="Todo el proyecto usa el dataset de 13.802 registros y 33 variables. El dataset reducido de los talleres queda solo como registro histórico.",
            size=14, alto_fila=0.9)
    d.tabla("Qué cambió con la auditoría", "Seis correcciones que modifican la lectura de los resultados",
            ["Tema", "Antes", "Ahora"],
            [["Año (dataset completo)", "Variable numérica en el análisis de 13.802 registros", "Categoría, nunca indicador; 30 indicadores"],
             ["Unidad de análisis", "Filas tratadas como municipios", "Municipio-año; bootstrap por municipio"],
             ["Inferencia", "Pruebas sin ajuste", "Magnitud con intervalo; sin valores p"],
             ["Atípicos", "«Crisis severas»", "Distancia estadística a validar"],
             ["Mahalanobis", "Umbral χ² sin discutir", f"{pct(T2['pct_marcados'])} marcado vs 1 % esperado; ranking"],
             ["Solapamiento de fondos", "«Mínimo»", f"{pct(sol['pct_ambos'])} vs 20 % esperado si fueran independientes"]],
            [2.6, 4.4, 5.1],
            notas="Transparencia: estas correcciones modifican conclusiones, no solo la forma. Las dos últimas filas son correcciones de interpretación frente a los informes anteriores.",
            size=14, alto_fila=0.58)
    d.texto("Alertas de calidad", "Tres alertas del dataset completo que conviene validar con la fuente", [
            f"Año: la repitencia cambia de nivel desde 2020 (mediana {es(T1['rep_2019'], 3)} en 2019, {es(T1['rep_2020'], 3)} en 2020, {es(T1['rep_2024'], 3)} en 2024; r = {es(T1['r_repitencia_anio'], 2)} con el año). Si el año entra como número, esa tendencia se mezcla con las relaciones entre indicadores; por eso es una categoría.",
            f"Ceros sospechosos: {C['todo_cero']} registros ({C['todo_cero_mun']}, años {C['todo_cero_anios']}) tienen todos los indicadores de tasa en cero con {es(C['pob_min'])}-{es(C['pob_max'])} niños en edad escolar: es más compatible con dato ausente codificado como 0 que con un resultado real.",
            "Panel incompleto: 2011-2015 tiene menos registros que 2016-2024; el archivo no dice qué municipios faltan.",
            "Ninguna de las tres se ha confirmado con la fuente administrativa."],
            size=18, notas="Estos hallazgos vienen del dataset completo. Son alertas de calidad de datos, no conclusiones sobre desempeño educativo.")
    d.tabla("Las 33 columnas", "¿Y si usamos todas las columnas con one-hot de municipios y departamentos?",
            ["Técnica", "Mejor codificación", "Por qué", "Peor"],
            [["PCA", "Sin one-hot geográfico (si se quiere geografía: solo departamentos)", f"PC1+PC2 guardan {pct(V['pca'][9]['pct_pc12'])} con 30 indicadores; el one-hot no aporta información y diluye la varianza", "Ambos: redundante (singular); con 6 variables desordena PC2"],
             ["Factorial", "Sin one-hot geográfico", f"KMO baja de {es(V['fa'][0]['kmo_global'], 2)} a {es(V['fa'][2]['kmo_global'], 2)} con departamentos; las dummies no pertenecen a ningún factor", "Municipios: KMO ≈ 0 y factores sugeridos: 43"],
             ["Ambas", "Usar la geografía para comparar grupos o separar entre y dentro de municipios", f"El municipio explica {pct(V['eta_med']['MUNICIPIO'], 0)} de cada indicador (mediana), pero es persistencia del mismo municipio", "Mil columnas de identidad"]],
            [1.6, 3.7, 4.2, 2.6],
            notas="Respuesta directa a la pregunta de cuál codificación da mejores resultados: ninguna supera a no usar one-hot geográfico; con geografía, departamentos es la menos dañina.",
            size=13, alto_fila=0.95)
    if "eval" in M:
        EV = M["eval"]
        n_comp = sum(1 for r in EV["informes"] if r["estado"].startswith("Completo"))
        n_cruz = sum(1 for r in EV["cruzadas"] if r["resultado"] == "Coincide")
        d.cifras("Evaluación final del repositorio", "Qué analiza cada entregable: informes, outputs y presentaciones",
                 [(f"{n_comp} de {len(EV['informes'])}", "informes con las 33 variables (4 como ampliación)"), (f"{sum(1 for r in EV['presentaciones'] if r['cubre_33'])} de {len(EV['presentaciones'])}", "presentaciones con las 33 variables"),
                  (f"{n_cruz} de {len(EV['cruzadas'])}", "verificaciones cruzadas de cifras que coinciden"), (str(sum(1 for r in EV["criterios"] if r["estado"] == "Cumple")) + " de " + str(len(EV["criterios"])), "criterios de calidad cumplidos")],
                 pie="Los dos informes de corte, de otro equipo, analizan 30 indicadores y describen las categóricas, sin one-hot. El PCA de 30 indicadores del Corte 2 coincide con el de este proyecto (PC1 25,56 %): dos implementaciones independientes.",
                 notas="Evaluación automática: scripts/evaluar_repositorio.R. Mide cobertura de las 33 variables, vigencia y coherencia de cifras; no reemplaza la revisión de un especialista.")
        d.tabla("Evaluación final del repositorio", "Criterios de calidad: qué cumple y qué sigue pendiente",
                ["Criterio", "Estado"], [[r["criterio"], r["estado"]] for r in EV["criterios"]], [9.0, 3.1],
                pie="Pendiente no significa error de código: son umbrales sin calibrar externamente. Parcial: faltan modelos que reconozcan el panel de municipios y ajuste de pruebas en los informes de corte.",
                notas="Cumple: unidad de análisis, año como categoría, cifras coherentes, reproducibilidad y presentaciones. Parcial: fuente única en los informes de corte, inferencia por municipio, pruebas sin ajuste y lenguaje. Pendiente: umbrales.",
                size=12, alto_fila=0.38)
    d.tabla("Dos técnicas, dos preguntas", "PCA y análisis factorial responden cosas distintas",
            ["", "PCA", "Análisis factorial"],
            [["Pregunta", "¿Cuánta varianza total resumen pocos números?", "¿Qué factores comunes explican las correlaciones?"],
             ["Resultado", f"2 componentes = {pct(pa[1])} (6 variables)", f"2 factores = {pct(com30)} de varianza común (30 indicadores)"],
             ["Fortaleza", "Mapa claro; cuadrantes accionables", "Nombres con sentido de política pública"],
             ["Debilidad", f"PC1 ≤ 0 marca {pct(c['pct_marcados'])} de la base", f"KMO {kmo30}, ajuste pobre y matriz casi singular"],
             ["Uso recomendado", "Exploración y orden de casos", "Hipótesis a validar"]],
            [2.4, 4.9, 4.8],
            notas="No son competidores: el PCA es una herramienta de resumen; el factorial, una hipótesis sobre causas comunes que hoy es frágil.",
            size=14, alto_fila=0.62)
    d.texto("Recomendación", "Qué hacer con esto hoy", [],
            dos_columnas=("Usar ahora", [
                "El mapa PC1-PC2 y sus cuadrantes para ordenar y revisar, nunca para asignar automáticamente.",
                "Los 30 indicadores solo como base de contexto; trabajar con 6 variables representativas.",
                "El corte de PC1 como escenario de presupuesto, con su costo de errores a la vista."],
                "No hacer todavía", [
                "Oficializar dos fondos con los nombres «Acceso» y «Permanencia».",
                "Interpretar registros atípicos como crisis educativas.",
                "Usar umbrales de 6,5 % y 60 % como criterios presupuestales."]),
            notas="La recomendación es práctica: usar el mapa para orientar, y detener lo que aún no tiene base suficiente.")
    d.texto("Riesgos y validaciones", "Lo que falta antes de decidir con estos resultados",
            ["Panel: ponderar o modelar municipios repetidos; evaluar sensibilidad con 2016-2024.",
             "Datos: validar tasas > 100 %, el cambio de nivel desde 2020 y los registros con todos los indicadores en cero.",
             "Umbrales: calibrar 6,5 % y 60 % con criterios externos y evitar circularidad con las variables del PCA.",
             "Estructura: revisar los casos límite (comunalidades ≈ 1), comparar con clustering formal y validar los factores con otra muestra.",
             "Todas las asociaciones son descriptivas: ninguna se interpreta como causa."],
            size=18, notas="Estos son los pasos que convierten una exploración en evidencia utilizable para decidir.")
    d.texto("Hoja de ruta", "Próximos pasos propuestos",
            ["1. Validar con la fuente administrativa los puntos pendientes (ceros de Papunaua, 2020, tasas > 100 %).",
             "2. Repetir PCA y factorial con ponderación por población y con solo 2016-2024.",
             "3. Separar variación entre y dentro de municipios (en lugar de one-hot) e incorporar un análisis de conglomerados con índices de estabilidad.",
             "4. Definir con el equipo del cliente criterios de prioridad y costo de errores.",
             "5. Decidir entonces si procede un esquema de uno o dos fondos."],
            size=19)
    d.texto("Cierre", "Los datos orientan; la decisión sigue siendo del cliente",
            [f"Un solo número no alcanza. Dos dimensiones orientan, con límites claros.",
             "Todo lo mostrado es asociación, no causalidad, y describe registros municipio-año.",
             "Estamos listos para el siguiente paso: validar y refinar con la información que solo el Ministerio posee."],
            size=20, notas="Cerramos devolviendo la decisión al cliente, con los límites claros.")
    d.guardar()


if __name__ == "__main__":
    deck_taller1()
    deck_taller2()
    deck_pca()
    deck_factorial()
    deck_final()
