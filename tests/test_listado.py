"""Lo que se afirma del cartucho, comprobado contra sus bytes.

Corre con el cartucho delante y sin el: cuando no esta, la imagen se rehace
desde las filas defb/defw del listado, que si viaja con el repositorio. Aqui no
se comprueba nada del codigo, solo de los datos, que son justamente los que
salen como defb/defw.
"""

import os
import re
import sys
import unittest

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(RAIZ, "tools"))

ROM = os.path.join(RAIZ, "comicbakery.rom")
ASM = os.path.join(RAIZ, "src", "comicbakery.asm")
ORG = 0x4000

FILA = re.compile(r"^\s+def(b|w)\s+([0-9a-fA-F,h ]+)\s*;\s*([0-9a-f]{4})")


def imagen_desde_el_listado():
    img = bytearray(16384)
    with open(ASM, encoding="utf-8") as f:
        for ln in f:
            m = FILA.match(ln)
            if not m:
                continue
            ancho, cuerpo, dirr = m.group(1), m.group(2), int(m.group(3), 16)
            p = dirr - ORG
            for tok in cuerpo.split(","):
                tok = tok.strip().rstrip("h")
                if not tok:
                    continue
                v = int(tok, 16)
                if ancho == "b":
                    img[p] = v
                    p += 1
                else:
                    img[p] = v & 0xFF
                    img[p + 1] = v >> 8
                    p += 2
    return bytes(img)


def lee():
    if os.path.exists(ROM):
        with open(ROM, "rb") as f:
            return f.read()
    return imagen_desde_el_listado()


class Cabecera(unittest.TestCase):
    def test_es_un_cartucho_msx_de_16k(self):
        rom = lee()
        self.assertEqual(rom[:2], b"AB")
        self.assertEqual(len(rom), 16384)

    def test_init_es_40c7(self):
        rom = lee()
        self.assertEqual(rom[2] | (rom[3] << 8), 0x40C7)

    def test_solo_usa_init(self):
        """STATEMENT, DEVICE y TEXT a cero."""
        self.assertEqual(lee()[4:10], b"\x00" * 6)


class TablasDelDespachador(unittest.TestCase):
    """Las tres tablas pegadas detras de un `call L_4096`.

    Ninguna entrada puede caer dentro de la tabla: la mas baja marca donde
    acaba, porque el codigo al que apunta viene justo detras.
    """

    TABLAS = {0x4119: 16, 0x4282: 4, 0x432B: 8}

    def entradas(self, ini, n):
        rom = lee()
        p = ini - ORG
        return [rom[p + 2 * i] | (rom[p + 2 * i + 1] << 8) for i in range(n)]

    def test_toda_entrada_cae_dentro_del_cartucho(self):
        for ini, n in self.TABLAS.items():
            for e in self.entradas(ini, n):
                self.assertTrue(ORG <= e < ORG + 16384,
                                f"tabla 0x{ini:04X}: 0x{e:04X} se sale")

    def test_ninguna_entrada_cae_dentro_de_su_tabla(self):
        for ini, n in self.TABLAS.items():
            fin = ini + 2 * n
            for e in self.entradas(ini, n):
                self.assertFalse(ini <= e < fin,
                                 f"tabla 0x{ini:04X}: 0x{e:04X} cae dentro")

    def test_la_de_escenas_cierra_donde_apunta_su_primera_entrada(self):
        """0x4119 + 16*2 = 0x4139, y la primera palabra es 0x4139."""
        self.assertEqual(self.entradas(0x4119, 16)[0], 0x4119 + 16 * 2)


class LasDosPantallasDeMenu(unittest.TestCase):
    """Las dos pantallas que graficos.py monta desde la ROM, y que NO son la
    misma: la de LA CASA (el logotipo de KONAMI y su rotulo) y la de TITULO
    (el menu con "COMIC BAKERY", ":KONAMI 1984" y "PLAY SELECT").

    Contra los volcados del emulador las dos dan CERO bytes de diferencia en
    las cuatro tablas (tools/coteja_vram.py, que necesita el volcado).
    """

    def monta(self, cual, *a, **k):
        import graficos
        graficos.ORG = ORG
        return getattr(graficos, cual)(lee(), *a, **k)

    def celda(self, v, fila, col):
        return v.b[0x3800 + fila * 32 + col]

    def test_el_logotipo_acaba_en_la_fila_4_columna_10(self):
        """Diecisiete pasadas y el reflejo respecto de 0x3AAA lo dejan en
        0x388A, que es la MISMA celda que en Circus Charlie y en Magical Tree.
        Lo unico que cambia entre los tres es el patron por el que empieza:
        0x40 aqui, 0x41 en Circus y 0x60 en Magical Tree."""
        v = self.monta("vram_de_la_presentacion")
        self.assertEqual([self.celda(v, 4, 10 + i) for i in range(3)],
                         [0x40, 0x41, 0x42])
        self.assertEqual([self.celda(v, 5, 10 + i) for i in range(11)],
                         list(range(0x43, 0x4E)))
        self.assertEqual([self.celda(v, 6, 10 + i) for i in range(12)],
                         list(range(0x4E, 0x5A)))

    def test_al_borrar_un_rotulo_se_escribe_el_patron_1(self):
        """En este cartucho la celda vacia es la 1, no la 0 (0x40BF), al reves
        que en sus dos hermanos. Si se borrara con ceros se veria el dibujo del
        patron 0 por toda la franja."""
        v = self.monta("vram_de_la_seleccion")
        fuera = [self.celda(v, 11, c) for c in range(6, 25)]
        self.assertEqual(set(fuera), {0x01})

    def test_el_cursor_sale_de_una_ROTACION_y_no_de_una_division(self):
        import graficos
        self.assertEqual([graficos.donde_va_el_cursor(k) for k in range(4)],
                         [0x3A05, 0x3A45, 0x3A85, 0x3AC5])
        v = self.monta("vram_de_la_seleccion")
        self.assertEqual(self.celda(v, 16, 5), 0x3E)
        self.assertEqual(self.celda(v, 16, 6), 0x3F)

    def test_el_bloque_de_la_fase_no_se_elige_con_fase_igual_a_cero(self):
        """0x6138 y 0x615E hacen `dec a / rra / jr c`, o sea que el primer
        bloque solo sale con la fase PAR Y MAYOR QUE CERO. Implementado como
        "si fase == 0" -que es como estaba- el montaje se separa del cartucho
        en 182 bytes de patrones y 63 de color."""
        import graficos
        self.assertEqual(
            [graficos.elige_por_la_fase(f, "par", "otro") for f in range(6)],
            ["otro", "otro", "par", "otro", "par", "otro"])


class Guiones(unittest.TestCase):
    """El interprete de rotulos de 0x40AE, ejecutado.

    Aqui la fuente empieza en el espacio -desplazamiento 0x20-, como en Circus
    Charlie y al reves que en Magical Tree. Lo decide el contenido: con cero,
    "PLAY SELECT" salia "0,!9 3%,%#4".
    """

    def texto(self, tramos):
        """El tile 0 es el espacio en blanco, no el caracter 0."""
        return ["".join(" " if b == 0 else chr(b + 0x20) for b in cuerpo)
                for _, cuerpo in tramos]

    def test_el_marcador_tiene_su_propio_rotulo(self):
        """BEAM es de este cartucho: los otros dos de la tanda no lo llevan."""
        from guiones import ejecuta
        fin, tramos = ejecuta(lee(), ORG, 0x5D8E)
        self.assertEqual(fin, 0x5DAB)
        self.assertEqual(self.texto(tramos), ["HI@", "STAGE@", "BEAM@", "1P@"])

    def test_el_menu_ofrece_joystick_y_teclado(self):
        from guiones import ejecuta
        fin, tramos = ejecuta(lee(), ORG, 0x5DB1)
        self.assertEqual(fin, 0x5E2A)
        t = self.texto(tramos)
        self.assertEqual(t[0], "PLAY SELECT")
        self.assertTrue(t[1].startswith("1PLAYER"), t[1])
        self.assertTrue(t[1].endswith("JOYSTICK"), t[1])
        self.assertTrue(t[4].endswith("KEYBOARD"), t[4])
        self.assertTrue(t[5].endswith("KONAMI 1984"), t[5])

    def test_el_cartucho_se_anuncia(self):
        from guiones import ejecuta
        self.assertEqual(self.texto(ejecuta(lee(), ORG, 0x5E42)[1]),
                         ["@ VIDEO CARTRIDGE @"])

    def test_player_1(self):
        from guiones import ejecuta
        self.assertEqual(self.texto(ejecuta(lee(), ORG, 0x5E37)[1]), ["PLAYER 1"])


class Interprete(unittest.TestCase):
    """Las tres puertas del interprete de rotulos, que si son las mismas que
    las de los otros dos cartuchos de la tanda aunque el descompresor no lo
    sea: 0x40AA borra (mascara 0x00), 0x40AE pinta (0xFF) y 0x40B0 es el
    cuerpo."""

    def test_las_dos_mascaras(self):
        rom = lee()
        self.assertEqual(rom[0x40AA - ORG:0x40AC - ORG], bytes([0x0E, 0x00]))
        self.assertEqual(rom[0x40AE - ORG:0x40B0 - ORG], bytes([0x0E, 0xFF]))


if __name__ == "__main__":
    unittest.main()
