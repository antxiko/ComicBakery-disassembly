#!/usr/bin/env python3
"""Coteja la partida dibujada desde la ROM contra los volcados de openMSX.

Los volcados los hace tools/omsx_partida.tcl (work/partida/faseN_cK.*). En
cada uno se mira:

  1. LAS TABLAS: color, patrones y patrones de sprite contra
     graficos.vram_de_la_partida con el contador de fase del propio volcado
     (0xE051). Tienen que dar CERO bytes distintos.
  2. LA PANADERIA: las diez filas de la banda (desde la 13) contra el mapa de
     0x7604, en la columna del mapa que mejor encaje. Solo se admiten las
     celdas que el juego anima encima del decorado fijo: la cinta y la
     lampara que alternan patron (0x5C/0x5E, 0x5D/0x5F, 0xC2/0xA6/0xA7), el
     pan recien puesto (0xB0, 0xAD) y los pasos de la masa que va por la
     cinta, los patrones de la tabla de 0x4010.
  3. EL PANADERO: sus cuatro sprites son una pose de 0x7124, con las filas
     y los colores de la plantilla de 0x7096. La columna no se compara: en el
     salto, 0x4CA1 reparte el arco de 0x4CC3 entre los cuatro y se separan
     uno o dos pixeles.
  4. LOS MAPACHES: los que andan -sprites 6 a 11- llevan un paso de los que
     da 0x51D9 y el color de su hueco en 0x51B2. Los que estan en otro estado
     (subiendo al horno, alcanzados) se cuentan aparte, sin afirmar nada.

Sale con 1 si una tabla difiere, si hay una celda de la panaderia que no se
explica o si el panadero no es una pose de la tabla.

Uso: coteja_partida.py <rom> <carpeta de volcados>
"""

import glob
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import figuras as F             # noqa: E402
import graficos as G            # noqa: E402

ANIMADAS = {(0x5C, 0x5E), (0x5D, 0x5F), (0xC2, 0xA6), (0xC2, 0xA7),
            (0x00, 0xB0), (0x00, 0xAD)}


def animadas(rom):
    """Las de arriba, mas los pasos de la masa que va por la cinta: los
    patrones de la tabla de 0x4010 (0x4FA9) pintados sobre la celda vacia."""
    masa = {b for b in rom[0x4010 - 0x4000:0x4028 - 0x4000] if b}
    return ANIMADAS | {(0x00, b) for b in masa}


def main():
    rom = open(sys.argv[1], "rb").read()
    G.ORG = 0x4000
    mapa = rom[G.MAPA - G.ORG:G.MAPA - G.ORG + G.COLUMNAS * G.ALTO]
    poses = [tuple((dy, p, c) for dy, _, p, c in F.el_panadero(rom, n))
             for n in range(14)]
    explicadas = animadas(rom)
    andando = {}
    for cual in range(3):
        for paso in F.PASOS_DEL_MAPACHE:
            for der in (False, True):
                m = F.el_mapache(rom, cual, paso, der)
                andando[(m[0][2], m[1][2], m[0][3])] = cual
    malo = False
    vistos = {}
    total = dict(volcados=0, celdas=0, animadas=0, mapaches=0, otros=0)
    for fn in sorted(glob.glob(os.path.join(sys.argv[2], "fase*_c*.vram"))):
        vram = open(fn, "rb").read()
        ram = open(fn[:-5] + ".ram", "rb").read()
        fase = ram[0x51]
        if fase not in vistos:
            vistos[fase] = G.vram_de_la_partida(rom, fase)
        v = vistos[fase]
        tablas = sum(v.b[i] != vram[i] for i in range(0, 0x3800))
        nt = vram[0x3800:0x3B00]
        fila0 = G.FILA_DE_LA_PANADERIA
        mejor = None
        for s in range(G.COLUMNAS - 31):
            dif = [(mapa[(s + x) * 10 + k], nt[(fila0 + k) * 32 + x])
                   for x in range(32) for k in range(10)
                   if nt[(fila0 + k) * 32 + x] != mapa[(s + x) * 10 + k]]
            if mejor is None or len(dif) < len(mejor[1]):
                mejor = (s, dif)
        s, dif = mejor
        raras = [d for d in dif if d not in explicadas]
        at = vram[0x3B00:0x3B80]
        y0 = at[0]
        panadero = tuple((at[4 * k] - y0, at[4 * k + 2], at[4 * k + 3] & 15)
                         for k in range(4))
        pose = poses.index(panadero) if panadero in poses else None
        for k in (6, 8, 10):
            y = at[4 * k]
            if y >= 0xC0:
                continue
            clave = (at[4 * k + 2], at[4 * k + 6], at[4 * k + 3] & 15)
            if andando.get(clave) == (k - 6) // 2:
                total["mapaches"] += 1
            else:
                total["otros"] += 1
        total["volcados"] += 1
        total["celdas"] += 320 - len(dif)
        total["animadas"] += len(dif) - len(raras)
        estado = "OK" if tablas == 0 and not raras and pose is not None else "DIFIERE"
        malo |= estado != "OK"
        print(f"{os.path.basename(fn)[:-5]}: contador {fase}, tablas {tablas}, "
              f"panaderia en la columna {s}: {320 - len(dif)} iguales, "
              f"{len(dif) - len(raras)} animadas, {len(raras)} sin explicar; "
              f"panadero en la pose {pose}  {estado}")
    print(f"{total['volcados']} volcados: {total['celdas']} celdas del decorado "
          f"iguales y {total['animadas']} animadas; {total['mapaches']} mapaches "
          f"andando con un paso de la ROM y {total['otros']} en otro estado")
    sys.exit(1 if malo or not total["volcados"] else 0)


if __name__ == "__main__":
    main()
