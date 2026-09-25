"""La web y la partida, comprobadas contra el listado y la ROM.

Los comunes de la serie -las cifras de la portada atadas al listado y el
barrido de nombres y ficheros de otros juegos- y los de este cartucho: lo que
las paginas dicen del panadero, los mapaches y las fases, medido con
tools/figuras.py y tools/graficos.py.
"""

import os
import re
import subprocess
import sys
import unittest

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(RAIZ, "tools"))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from test_listado import ASM, FILA, lee      # noqa: E402

DOCS = os.path.join(RAIZ, "docs")

# Los demas juegos de la serie. Que el nombre de otro salga en una pagina de
# este es casi siempre un copia y pega: ya paso con cinco ficheros LICENSE, con
# el pie de catorce paginas de otro proyecto y con tests que apuntaban a
# src/soccer.asm.
OTROS_JUEGOS = (
    "Tennis", "Pitfall", "Temptations", "Stardust", "Ale Hop", "Colt 36",
    "Antarctic", "Athletic Land", "Monkey Academy", "F-1 Spirit", "Pippols",
    "Time Pilot", "Frogger", "Super Cobra", "Billiards", "Mahjong",
    "Hyper Rally", "Nemesis", "Demonia", "Cabbage", "Hole in One",
    "Casio World Open", "3D Golf", "Baseball", "Yie Ar Kung-Fu",
    "King's Valley", "Sky Jaguar", "Mopi Ranger", "Descubrimiento",
    "War in Middle Earth", "Ping Pong", "Soccer", "Football", "Road Fighter",
    "Hyper Sports", "Hyper Olympic", "Goonies", "Knightmare", "Twin Bee",
    "Penguin", "Bomber", "Circus Charlie", "Magical Tree",
)

# Sus dos hermanos de tanda se nombran A PROPOSITO donde el hallazgo es lo
# que comparten con ellos. La excepcion vale solo en esas paginas, solo para
# esos dos juegos y solo si aparece la palabra que la justifica.
CITAS_LEGITIMAS = {
    "HALLAZGOS.md": (("hermanos",), ("Circus Charlie", "Magical Tree")),
    "FINDINGS.md": (("siblings",), ("Circus Charlie", "Magical Tree")),
}
CITAS_LEGITIMAS["HALLAZGOS.html"] = CITAS_LEGITIMAS["HALLAZGOS.md"]
CITAS_LEGITIMAS["FINDINGS.html"] = CITAS_LEGITIMAS["FINDINGS.md"]


def lee_texto(ruta):
    with open(ruta, encoding="utf-8") as f:
        return f.read()


def bytes_de_datos_del_listado():
    """Cuantos bytes salen en filas defb/defw: los DATOS del cartucho."""
    n = 0
    for ln in lee_texto(ASM).splitlines():
        m = FILA.match(ln)
        if not m:
            continue
        toks = [t for t in m.group(2).split(",") if t.strip()]
        n += len(toks) * (1 if m.group(1) == "b" else 2)
    return n


class LasCifrasDeLaPortada(unittest.TestCase):
    """Las cifras que declara make_web.py tienen que ser las del listado."""

    def setUp(self):
        import make_web
        self.w = make_web

    def test_la_suma_de_bytes_da_el_cartucho(self):
        self.assertEqual(self.w.CODIGO + self.w.DATOS, 16384)

    def test_las_cifras_de_bytes_son_las_de_este_listado(self):
        datos = bytes_de_datos_del_listado()
        self.assertEqual(self.w.DATOS, datos)
        self.assertEqual(self.w.CODIGO, 16384 - datos)

    def test_las_cifras_de_la_portada_son_las_del_listado(self):
        """Se EJECUTA tools/densidad.py y se le lee la salida."""
        salida = subprocess.run(
            [sys.executable, os.path.join(RAIZ, "tools", "densidad.py"), ASM],
            capture_output=True, text=True, check=True).stdout
        m = re.search(r"(\d+) instrucciones, (\d+) comentarios", salida)
        self.assertIsNotNone(m, "densidad.py no imprimio el total:\n" + salida)
        self.assertEqual(self.w.INSTRUCCIONES, int(m.group(1)))
        self.assertEqual(self.w.COMENTARIOS, int(m.group(2)))
        m = re.search(r"(\d+) rutinas por debajo del 10 %, de (\d+)", salida)
        self.assertIsNotNone(m)
        self.assertEqual(int(m.group(1)), 0, "hay rutinas flojas")
        self.assertEqual(self.w.RUTINAS, int(m.group(2)))

    def test_la_densidad_declarada_cuadra_con_las_dos_cuentas(self):
        pct = 100.0 * self.w.COMENTARIOS / self.w.INSTRUCCIONES
        self.assertAlmostEqual(pct, float(self.w.DENSIDAD.replace(",", ".")),
                               places=1)
        self.assertEqual(self.w.DENSIDAD.replace(",", "."), self.w.DENSIDAD_EN)

    def test_la_ficha_dice_el_sha_de_este_cartucho(self):
        sha = None
        for linea in lee_texto(os.path.join(RAIZ, "Makefile")).splitlines():
            if linea.startswith("SHA"):
                sha = linea.split("=")[1].strip()
        self.assertIsNotNone(sha)
        for idioma in ("es", "en"):
            ficha = " ".join(self.w.TXT[idioma]["ficha"])
            self.assertIn(sha[:8], ficha)
            self.assertIn("RC-714", ficha)


class SinNombresDeOtroJuego(unittest.TestCase):
    """El copia y pega de otro proyecto de la serie, cazado a tiempo."""

    def _revisa(self, ruta):
        texto = lee_texto(ruta)
        fn = os.path.basename(ruta)
        palabras, permitidos = CITAS_LEGITIMAS.get(fn, ((), ()))
        if permitidos and any(j in texto for j in permitidos):
            self.assertTrue(any(p in texto.lower() for p in palabras),
                            "%s puede nombrar %s solo si dice por que (%r)"
                            % (fn, permitidos, palabras))
        for juego in OTROS_JUEGOS:
            if juego in permitidos:
                continue
            self.assertNotIn(juego, texto, "%s nombra a %s" % (fn, juego))

    def test_el_encabezado_del_listado_es_de_este_juego(self):
        cabeza = "\n".join(lee_texto(ASM).splitlines()[:30])
        for juego in OTROS_JUEGOS:
            self.assertNotIn(juego, cabeza)

    def test_la_licencia_y_los_avisos_son_de_este_juego(self):
        for fn in ("LICENSE", "README.md", "README.es.md", "AVISO-LEGAL.md",
                   "LEGAL-NOTICE.md"):
            ruta = os.path.join(RAIZ, fn)
            self.assertTrue(os.path.exists(ruta), "falta %s" % fn)
            self._revisa(ruta)

    OTROS_FICHEROS = ("soccer", "hypersports", "roadfighter", "pingpong",
                      "mopiranger", "tennis", "baseball", "nemesis",
                      "pippols", "antarctic", "golf", "frogger",
                      "kingsvalley", "yiearkungfu", "skyjaguar", "hyperrally",
                      "goonies", "knightmare", "twinbee", "circus", "magical")

    def _sin_ficheros_de_otro(self, ruta):
        texto = lee_texto(ruta).lower()
        for otro in self.OTROS_FICHEROS:
            for pega in ("src/%s" % otro, "%s.asm" % otro, "%s.rom" % otro,
                         "%s.notes" % otro):
                self.assertNotIn(pega, texto, "%s nombra el fichero %s"
                                 % (os.path.relpath(ruta, RAIZ), pega))

    def test_las_herramientas_de_la_web_no_apuntan_a_otro_juego(self):
        for fn in ("make_web.py", "md2html.py", "contenido_web.py",
                   "figuras.py", "coteja_partida.py", "omsx_partida.tcl",
                   "graficos.py"):
            self._sin_ficheros_de_otro(os.path.join(RAIZ, "tools", fn))

    def test_ni_los_textos_publicados(self):
        for sitio in (RAIZ, DOCS, os.path.join(DOCS, "es")):
            for fn in os.listdir(sitio):
                ruta = os.path.join(sitio, fn)
                if os.path.isfile(ruta) and (
                        fn.endswith((".md", ".html")) or fn == "LICENSE"):
                    self._sin_ficheros_de_otro(ruta)

    def test_la_web_no_nombra_otro_juego(self):
        for raiz, _, ficheros in os.walk(DOCS):
            for fn in ficheros:
                if fn.endswith((".md", ".html")):
                    self._revisa(os.path.join(raiz, fn))


class LaPartida(unittest.TestCase):
    """Lo que las paginas dicen del panadero, los mapaches y las fases."""

    def setUp(self):
        import figuras
        import graficos
        self.f = figuras
        self.g = graficos
        graficos.ORG = 0x4000
        self.rom = lee()

    def test_las_imagenes_no_ejecutan_el_cartucho(self):
        for fn in ("figuras.py", "graficos.py", "coteja_partida.py"):
            fuente = lee_texto(os.path.join(RAIZ, "tools", fn))
            self.assertNotIn("z80run", fuente)

    def test_la_pose_del_cuadro_800_es_la_9(self):
        """La que lleva el panadero en work/partida/fase0_c0800: 48 68 4C 6C,
        con las filas 0, +0x10, +8 y +0x20 y los colores 15, 15, 9 y 7."""
        self.assertEqual(self.f.el_panadero(self.rom, 9),
                         [(0, 0, 0x48, 15), (0x10, 0, 0x68, 15),
                          (8, 0, 0x4C, 9), (0x20, 0, 0x6C, 7)])

    def test_los_tres_mapaches_gris_amarillo_y_rojo(self):
        self.assertEqual([self.f.el_mapache(self.rom, c, 0, False)[0][3]
                          for c in range(3)], [14, 10, 8])

    def test_el_mapache_son_dos_sprites_en_fila(self):
        m = self.f.el_mapache(self.rom, 0, 8, True)
        self.assertEqual(m, [(0, 0, 0xBC, 14), (0, 16, 0xC0, 14)])

    def test_los_sprites_ya_no_salen_en_negro(self):
        v = self.g.vram_de_la_partida(self.rom, 0)
        llenos = sum(1 for i in range(64)
                     if any(v.b[0x1800 + 32 * i:0x1820 + 32 * i]))
        self.assertEqual(llenos, 64)

    def test_las_fases_1_y_2_se_ven_igual_y_la_3_no(self):
        v = [self.g.vram_de_la_partida(self.rom, f).b[0:0x3800]
             for f in (0, 1, 2, 3, 4)]
        self.assertEqual(v[0], v[1])
        self.assertNotEqual(v[0], v[2])
        self.assertEqual(v[1], v[3])
        self.assertEqual(v[2], v[4])

    def test_la_panaderia_son_92_columnas_de_diez(self):
        self.assertEqual((self.g.MAPA, self.g.COLUMNAS, self.g.ALTO),
                         (0x7604, 92, 10))
        self.assertEqual(self.g.FILA_DE_LA_PANADERIA, 13)

    def test_las_imagenes_estan_publicadas(self):
        for fn in ("rotulo.png", "jugador.png", "enemigos.png",
                   "panaderia-fases-1-2-4.png", "panaderia-fases-3-5-7.png",
                   "sprites.png"):
            self.assertTrue(os.path.exists(
                os.path.join(DOCS, "imagenes", fn)), fn)


if __name__ == "__main__":
    unittest.main()
