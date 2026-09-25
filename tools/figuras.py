#!/usr/bin/env python3
"""EL PANADERO Y LOS MAPACHES, dibujados desde las tablas del cartucho.

Los patrones de sprite los monta tools/graficos.py como los monta 0x70D6: tres
bloques comprimidos y sus reflejos (cotejados contra openMSX a 0 bytes). Aqui
se componen las figuras con las tablas que usa el juego:

  EL PANADERO son cuatro sprites (0x4C51). Sus patrones salen de las catorce
  poses de 0x7124, cuatro por pose, y la fila, la columna y el color de cada
  uno, de la plantilla de 0x7096 que 0x7061 copia al bufer de sprites: el
  segundo va 0x10 por debajo del primero, el tercero 8 y el cuarto 0x20, y
  los colores son 15, 15, 9 y 7.

  LOS MAPACHES son dos sprites en fila (0x51D9): el segundo, dieciseis pixeles
  a la derecha y con el patron cuatro mas alla. Andando hacia la izquierda
  los patrones salen desde 0x78; hacia la derecha, 0x3C mas alla. El paso lo
  elige el contador de cuadros y solo da 0, 8 o 16. Los tres mapaches se
  distinguen por el color, el de la tabla de 0x51B2: 14, 10 y 8.

El listado los llamaba "carros" hasta que se dibujaron: son los mapaches.

Uso: figuras.py <rom> <org> <carpeta destino>
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import graficos as G            # noqa: E402

POSES = 0x7124                  # catorce poses de cuatro patrones
PLANTILLA = 0x7096              # los cuatro primeros sprites: el panadero
COLORES_DE_LOS_MAPACHES = 0x51B2  # tres entradas de ocho bytes
PASOS_DEL_MAPACHE = (0, 8, 16)  # lo que da la cuenta de 0x51E5..0x51F3


def lee(rom, a, n=1):
    return rom[a - G.ORG:a - G.ORG + n]


def el_panadero(rom, pose):
    """[(dy, dx, patron, color)] de los cuatro sprites de una pose."""
    plantilla = lee(rom, PLANTILLA, 16)
    y0, x0 = plantilla[0], plantilla[1]
    patrones = lee(rom, POSES + 4 * pose, 4)
    return [(plantilla[4 * k] - y0, plantilla[4 * k + 1] - x0, patrones[k],
             plantilla[4 * k + 3] & 0x0F) for k in range(4)]


def el_mapache(rom, cual, paso, a_la_derecha):
    """[(dy, dx, patron, color)] de los dos sprites de un mapache."""
    color = lee(rom, COLORES_DE_LOS_MAPACHES + 8 * cual + 3)[0] & 0x0F
    p = 0x78 + paso + (0x3C if a_la_derecha else 0)
    return [(0, 0, p, color), (0, 16, p + 4, color)]


def pinta_figura(px, w, v, x0, y0, sprites, esc):
    for dy, dx, patron, color in sprites:
        base = G.SPRITES + (patron & 0xFC) * 8
        tinta = G.PALETA[color]
        for f in range(16):
            fila = (v.b[base + f] << 8) | v.b[base + 16 + f]
            for c in range(16):
                if fila & (0x8000 >> c):
                    for a in range(esc):
                        for b in range(esc):
                            G.punto(px, w, x0 + (dx + c) * esc + b,
                                    y0 + (dy + f) * esc + a, tinta)


def main():
    rom = open(sys.argv[1], "rb").read()
    G.ORG = int(sys.argv[2], 0)
    sal = sys.argv[3]
    v = G.vram_de_la_escena(rom, 0)
    G.patrones_de_sprite(v, rom)
    esc = 3

    # EL PANADERO: las catorce poses en fila
    w, h = 14 * 24 * esc, 56 * esc
    px = G.lienzo(w, h, (0, 0, 0))
    for pose in range(14):
        pinta_figura(px, w, v, (4 + 24 * pose) * esc, 4 * esc, el_panadero(rom, pose), esc)
    fn = os.path.join(sal, "jugador.png")
    G.png(w, h, px, fn)
    print("  ", fn)

    # LOS MAPACHES: uno por fila, tres pasos a la izquierda y tres a la derecha
    w, h = 6 * 40 * esc, 3 * 24 * esc
    px = G.lienzo(w, h, (0, 0, 0))
    for cual in range(3):
        n = 0
        for derecha in (False, True):
            for paso in PASOS_DEL_MAPACHE:
                pinta_figura(px, w, v, (4 + 40 * n) * esc, (4 + 24 * cual) * esc,
                             el_mapache(rom, cual, paso, derecha), esc)
                n += 1
    fn = os.path.join(sal, "enemigos.png")
    G.png(w, h, px, fn)
    print("  ", fn)


if __name__ == "__main__":
    main()
