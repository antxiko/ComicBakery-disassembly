"""La tienda del final de la jornada, ejecutando el cartucho (tools/tienda.py).

Lo medido: el globo de cada cuenta de panes sale de 0x5D22 y se pinta en la
celda 0x3867; con menos de cuatro panes se pierde una vida y con diez no.
"""
import os
import sys
import unittest

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(RAIZ, "tools"))

import tienda  # noqa: E402

GLOBO = 0x3867          # la celda de 0x5CC1


class Tienda(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.rom = open(os.path.join(RAIZ, "comicbakery.rom"), "rb").read()

    def vuelve_a_jugar(self, panes):
        z = tienda.a_la_tienda(self.rom, panes)
        vidas, puntos = z.mem[0xE050], None
        globo = None
        for _ in range(3000):
            z.cuadro()
            if z.escena() == (15, 7) or z.escena() == (12, 2):
                globo = globo or z.maq.vdp.vram[GLOBO]
            if z.escena()[0] == 11:
                return vidas, z.mem[0xE050], z.mem[0xE051], globo
        self.fail("no se vuelve a jugar")

    def test_diez_panes_dicen_fine_y_no_cuestan_vidas(self):
        antes, despues, fase, globo = self.vuelve_a_jugar(10)
        self.assertEqual((antes, despues, fase, globo), (2, 2, 2, 0x56))

    def test_tres_panes_cuestan_una_vida(self):
        antes, despues, fase, _ = self.vuelve_a_jugar(3)
        self.assertEqual((antes, despues, fase), (2, 1, 2))

    def test_cuatro_panes_dicen_el_globo_0x50(self):
        self.assertEqual(self.vuelve_a_jugar(4)[3], 0x50)

    def test_las_imagenes_estan_publicadas(self):
        for fn in ("tienda.png", "tienda.gif", "tienda-falta.gif",
                   "tienda-globos.png"):
            self.assertTrue(os.path.exists(
                os.path.join(RAIZ, "docs", "imagenes", fn)), fn)


if __name__ == "__main__":
    unittest.main()
