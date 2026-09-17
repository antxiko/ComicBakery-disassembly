#!/usr/bin/env python3
"""Rehace la VRAM de Comic Bakery y la DIBUJA. Aqui no hay ni una captura.

Cada imagen sale de correr en Python los MISMOS pasos que da el Z80, citando la
direccion de cada paso. Si un dibujo sale mal, lo que esta mal es la lectura del
cartucho: por eso vale como comprobacion y no como adorno.

EL REPARTO DE LA VRAM
---------------------
Los ocho registros los baja 0x473E leyendolos de la copia que 0x4733 hace en
0xE038 desde 0x474F, que vale `02 E2 0E 7F 07 76 03 E1` -los mismos ocho que
Magical Tree, byte a byte-. En SCREEN 2 el R3 y el R4 no son direcciones sino
base y mascara:

    R2 = 0x0E   tabla de NOMBRES en 0x3800
    R3 = 0x7F   COLOR: bit 7 a cero, base 0x0000
    R4 = 0x07   PATRONES: bit 2 puesto, base 0x2000
    R5 = 0x76   atributos de sprite en 0x3B00
    R6 = 0x03   patrones de SPRITE en 0x1800

EL DESCOMPRESOR TIENE TRES PUERTAS y la tercera es la que hace falta entender:
por 0x43EE el bloque trae delante su destino, por 0x43F2 el destino viene en DE,
y por 0x43F5 NO SE TOCA EL PUNTERO, o sea que el bloque sigue escribiendo donde
lo dejo el anterior. Por eso aqui la VRAM se lleva con su puntero, como en el
VDP de verdad: si se reinicia en cada bloque, el de 0x6853 acaba en otro sitio.

EL MAPA
-------
Comic Bakery no guarda pantallas: guarda 92 COLUMNAS de diez celdas en 0x7604.
0x4D15 hace `A x 10 + 0x7604` -de ahi el `add hl,hl` tres veces mas `add hl,bc`,
que es ocho mas dos-, lee diez bytes y los va dejando una fila de pantalla (32
celdas) mas abajo cada vez, en el bufer de 0xE1BF. Y 0x4D07 corre los 320 bytes
del bufer -diez filas de 32- una columna hacia delante en cada paso: eso es el
desplazamiento lateral de la panaderia.

LO QUE SALE
-----------
    logotipo.png  el KONAMI que baja por la pantalla antes del titulo
    tiles.png     la hoja de patrones tal como queda en la VRAM
    fuente.png    los dibujos de texto, con su reparto
    mapa.png      las 92 columnas seguidas: la panaderia entera
    sprites.png   los patrones de sprite de 0x1800

Uso: graficos.py <rom> <org> <salida>
"""
import os
import struct
import sys
import zlib

ORG = 0x4000

PALETA = [
    (0, 0, 0), (0, 0, 0), (33, 200, 66), (94, 220, 120),
    (84, 85, 237), (125, 118, 252), (212, 82, 77), (66, 235, 245),
    (252, 85, 84), (255, 121, 120), (212, 193, 84), (230, 206, 128),
    (33, 176, 59), (201, 91, 186), (204, 204, 204), (255, 255, 255),
]

VDP = [0x02, 0xE2, 0x0E, 0x7F, 0x07, 0x76, 0x03, 0xE1]
NOMBRES = VDP[2] * 0x400
COLOR = (VDP[3] & 0x80) << 6
PATRONES = (VDP[4] & 0x04) << 11
SPRITES = VDP[6] * 0x800

MAPA = 0x7604
COLUMNAS = 92
ALTO = 10


# ----------------------------------------------------------------- PNG
def png(w, h, px, fn):
    raw = b"".join(b"\0" + bytes(px[y * w * 3:(y + 1) * w * 3]) for y in range(h))

    def chunk(t, d):
        return (struct.pack(">I", len(d)) + t + d
                + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF))
    open(fn, "wb").write(b"\x89PNG\r\n\x1a\n"
                         + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
                         + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


def lienzo(w, h, c=(24, 24, 24)):
    return bytearray(bytes(c) * (w * h))


def punto(px, w, x, y, c):
    i = (y * w + x) * 3
    px[i], px[i + 1], px[i + 2] = c


# --------------------------------------------------------- la VRAM con puntero
class Vram:
    """La VRAM y SU PUNTERO DE ESCRITURA, que es lo que hace falta aqui.

    El VDP guarda por donde va escribiendo, y la tercera puerta del
    descompresor (0x43F5) cuenta con eso: entra sin tocarlo. Una VRAM sin
    puntero no puede reproducir esa cadena.
    """

    def __init__(self):
        self.b = bytearray(0x4000)
        self.pt = 0

    def sitúa(self, de):          # prepara_escritura_vram
        self.pt = de & 0x3FFF

    def escribe(self, v):         # el `out (c),a` del bucle
        self.b[self.pt] = v
        self.pt = (self.pt + 1) & 0x3FFF


def descomprime(v, rom, ini, destino=None, continuar=False):
    """Las tres puertas de 0x43EE / 0x43F2 / 0x43F5."""
    p = ini - ORG
    if not continuar:
        if destino is None:
            destino = rom[p] | (rom[p + 1] << 8)
            p += 2
        v.sitúa(destino)
    while True:
        ctrl = rom[p]
        p += 1
        cuenta = ctrl & 0x7F
        if cuenta == 0:
            if ctrl == 0x00:
                return ORG + p
            v.sitúa(rom[p] | (rom[p + 1] << 8))   # 0x80: otro destino
            p += 2
            continue
        if ctrl & 0x80:
            for i in range(cuenta):
                v.escribe(rom[p + i])
            p += cuenta
        else:
            for _ in range(cuenta):
                v.escribe(rom[p])
            p += 1


def vuelca(v, rom, ini, destino, n):
    v.sitúa(destino)
    for i in range(n):
        v.escribe(rom[ini - ORG + i])


def rellena(v, destino, n, valor):
    v.sitúa(destino)
    for _ in range(n):
        v.escribe(valor)


def monta_un_tercio(v, rom, de0, fase=0):
    """0x60C7: UN TERCIO ENTERO, color y patrones. Ocho pasos, no dos.

    Se le llama tres veces -0x6051, 0x6057 y 0x605D- con 0x0000, 0x0800 y
    0x1000, que son las bases de color de los tres tercios. Cada vuelta:

      0x60C7  dieciseis grupos de ocho bytes, uno mas en cada grupo
      0x60D7  592 celdas de 0xF1 detras
      0x60DF  0x6A7C SIN tocar el puntero, o sea pegado a lo anterior
      0x60E7  +0x400  el bloque que elige descomprime_dos_veces
      0x60F2  +0x680  0x6F7D
      0x60FF  +0x398  el que elige carga_el_bloque_b, segun la fase
      0x6109  +0x6000 -que enmascarado a 14 bits es la tabla de PATRONES-
              y ahi los otros cuatro: 0x61F5, 0x66A5, 0x6D26 y el de 0x616B
    """
    v.sitúa(de0)
    a = 0
    for _ in range(0x10):                       # 0x60C9: dieciseis grupos
        for _ in range(8):                      # 0x60CB: de ocho bytes
            v.escribe(a)
        a = (a + 1) & 0xFF
    for _ in range(0x250):                      # 0x60D7: 592 celdas de 0xF1
        v.escribe(0xF1)
    descomprime(v, rom, 0x6A7C, continuar=True)         # 0x60DF
    descomprime(v, rom, 0x6B34, destino=de0 + 0x400)    # 0x60E7, con A=0
    descomprime(v, rom, 0x6F7D, destino=de0 + 0x680)    # 0x60F2
    descomprime(v, rom, 0x6AC7 if fase == 0 else 0x6AB4,
                destino=de0 + 0x398)                    # 0x60FF
    pat = de0 + 0x6000                                  # 0x6109
    descomprime(v, rom, 0x61F5, destino=pat)            # 0x610F
    descomprime(v, rom, 0x66A5, destino=pat + 0x400)    # 0x611C
    descomprime(v, rom, 0x6D26, destino=pat + 0x680)    # 0x6129
    descomprime(v, rom, 0x657B if fase == 0 else 0x6521,
                destino=pat + 0x398)                    # 0x6135 -> 0x616B


def vram_de_la_escena(rom, fase=0):
    """La cadena de 0x6051, paso por paso y con su direccion."""
    v = Vram()
    for de in (0x0000, 0x0800, 0x1000):          # 0x6051, 0x6057, 0x605D
        monta_un_tercio(v, rom, de, fase)
    descomprime(v, rom, 0x65DF)                  # 0x6063  el decorado
    descomprime(v, rom, 0x6AEE)                  # 0x6069
    vuelca(v, rom, 0x61FA, 0x2500, 0x50)         # 0x606F
    descomprime(v, rom, 0x6853, continuar=True)  # 0x607B  sigue donde quedo
    descomprime(v, rom, 0x6C99)                  # 0x6081
    de = 0x06D0                                  # 0x6087: diecinueve tandas
    for _ in range(0x13):
        vuelca(v, rom, 0x6D14, de, 0x10)
        de += 0x10
    descomprime(v, rom, 0x6495)                  # 0x609E
    rellena(v, 0x1080, 0x170, 0x71)              # 0x60A4
    return v


# --------------------------------------------------------------- dibujar
def pinta_celda(px, w, x0, y0, patron, color, esc=1):
    for f in range(8):
        p, c = patron[f], color[f]
        tinta, fondo = PALETA[c >> 4], PALETA[c & 0x0F]
        for b in range(8):
            col = tinta if p & (0x80 >> b) else fondo
            for dy in range(esc):
                for dx in range(esc):
                    punto(px, w, x0 + b * esc + dx, y0 + f * esc + dy, col)


def celda(v, t, tercio=0):
    p = PATRONES + tercio * 0x800 + t * 8
    c = COLOR + tercio * 0x800 + t * 8
    return v.b[p:p + 8], v.b[c:c + 8]


def hoja(v, tercio, fn, cols=16, esc=2):
    w, h = cols * 8 * esc, (256 // cols) * 8 * esc
    px = lienzo(w, h)
    for t in range(256):
        pa, co = celda(v, t, tercio)
        pinta_celda(px, w, (t % cols) * 8 * esc, (t // cols) * 8 * esc, pa, co, esc)
    png(w, h, px, fn)


def rango(v, t0, n, fn, tercio=0, cols=10, esc=4):
    filas = (n + cols - 1) // cols
    w, h = cols * 8 * esc, filas * 8 * esc
    px = lienzo(w, h)
    for i in range(n):
        pa, co = celda(v, t0 + i, tercio)
        pinta_celda(px, w, (i % cols) * 8 * esc, (i // cols) * 8 * esc, pa, co, esc)
    png(w, h, px, fn)


def mapa(v, rom, fn, esc=2):
    """Las 92 columnas de diez celdas, una al lado de otra.

    El tercio lo decide la FILA de pantalla en la que cae cada celda, no la
    columna: 0x4D09 empieza el bufer en 0xE1BF y va bajando de 32 en 32, o sea
    una fila por byte. Las diez filas del mapa son las de la banda de juego.
    """
    w, h = COLUMNAS * 8 * esc, ALTO * 8 * esc
    px = lienzo(w, h)
    for x in range(COLUMNAS):
        base = MAPA - ORG + x * ALTO
        for y in range(ALTO):
            t = rom[base + y]
            pa, co = celda(v, t, (y + 14) // 8 if False else min(2, (y + 14) // 8))
            pinta_celda(px, w, x * 8 * esc, y * 8 * esc, pa, co, esc)
    png(w, h, px, fn)


def sprites(v, base, fn, n=16, cols=8, esc=3):
    filas = (n + cols - 1) // cols
    w, h = cols * 16 * esc, filas * 16 * esc
    px = lienzo(w, h)
    for i in range(n):
        d = base + i * 32
        x0, y0 = (i % cols) * 16 * esc, (i // cols) * 16 * esc
        for cuarto in range(4):
            cx, cy = (cuarto // 2) * 8 * esc, (cuarto % 2) * 8 * esc
            pinta_celda(px, w, x0 + cx, y0 + cy, v.b[d + cuarto * 8: d + cuarto * 8 + 8],
                        b"\xf0" * 8, esc)
    png(w, h, px, fn)


def logotipo(v, fn, esc=6):
    """El logotipo de KONAMI, montado como lo monta 0x48A4.

    Empieza en el patron 0x40 y los va pintando CORRELATIVOS (`inc a`) en tres
    filas seguidas. Cuantas celdas por fila no es una constante: sale de
    `ld a,00eh / sub c`, o sea catorce menos lo que se lleva, con C bajando de
    3 a 1. Da 3, 11 y 12: veintiseis celdas, del 0x40 al 0x59. Es el mismo
    reparto que usa Magical Tree (RC-713) para el mismo logotipo, alli desde
    el patron 0x60.
    """
    filas = [(0x40, 3), (0x43, 11), (0x4E, 12)]
    w, h = 12 * 8 * esc, 3 * 8 * esc
    px = lienzo(w, h)
    for r, (t0, n) in enumerate(filas):
        for i in range(n):
            pa, co = celda(v, t0 + i, 0)
            pinta_celda(px, w, i * 8 * esc, r * 8 * esc, pa, co, esc)
    png(w, h, px, fn)


def main():
    global ORG
    rom = open(sys.argv[1], "rb").read()
    ORG = int(sys.argv[2], 0)
    sal = sys.argv[3]
    os.makedirs(sal, exist_ok=True)

    v = vram_de_la_escena(rom)
    logotipo(v, os.path.join(sal, "logotipo.png"))
    hoja(v, 0, os.path.join(sal, "tiles.png"))
    hoja(v, 2, os.path.join(sal, "tiles-tercio3.png"))
    rango(v, 0x10, 43, os.path.join(sal, "fuente.png"))
    mapa(v, rom, os.path.join(sal, "mapa.png"))
    sprites(v, SPRITES, os.path.join(sal, "sprites.png"))

    for f in sorted(os.listdir(sal)):
        print("  ", os.path.join(sal, f))


if __name__ == "__main__":
    main()
