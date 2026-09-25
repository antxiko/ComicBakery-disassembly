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
    panaderia-fases-1-2-4.png, panaderia-fases-3-5-7.png
                  las 92 columnas seguidas: la panaderia entera, con los
                  bloques de cada juego de fases
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


def elige_por_la_fase(fase, si_par, si_no):
    """El criterio de 0x6138 y de 0x615E, que NO es "fase 0 o no".

        ld a,(0e051h) / or a / jr z,<el otro> / dec a / rra / jr c,<este>

    `rra` mete en el acarreo el bit 0 de (fase-1), asi que el primer bloque
    solo sale con la fase PAR Y MAYOR QUE CERO; con la fase 0 y con las
    impares sale el segundo. Estaba implementado al reves -`si fase == 0`-, y
    por eso el montaje de la pantalla se separaba del cartucho en 182 bytes de
    patrones y 63 de color, justo en el trozo que cargan estas dos llamadas
    (0x398 de cada tercio). Corregido da CERO.
    """
    return si_par if (fase and ((fase - 1) & 1)) else si_no


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
    descomprime(v, rom, elige_por_la_fase(fase, 0x6AC7, 0x6AB4),
                destino=de0 + 0x398)                    # 0x60FF -> 0x6138
    pat = de0 + 0x6000                                  # 0x6109
    descomprime(v, rom, 0x61F5, destino=pat)            # 0x610F
    descomprime(v, rom, 0x66A5, destino=pat + 0x400)    # 0x611C
    descomprime(v, rom, 0x6D26, destino=pat + 0x680)    # 0x6129
    descomprime(v, rom, elige_por_la_fase(fase, 0x657B, 0x6521),
                destino=pat + 0x398)                    # 0x6135 -> 0x615E


def vram_de_la_partida(rom, fase):
    """La pantalla de la escena (0x6051) y, encima, lo grafico del montaje de
    la fase (0x49BB..0x49E7), con el bloque que elige cada rutina segun
    (0xE051). Tres criterios distintos, cada uno como lo escribe el codigo:
    A, C, D, E, F y la pareja de 0x619A con elige_por_la_fase; G (0x61AD)
    mira el bit 0 de la fase misma, no el de fase-1."""
    # la pantalla de 0x6051 se monta UNA vez, en la escena 0 (0x4140), con la
    # RAM recien puesta a cero por INIT: o sea, con la fase 0. Al empezar cada
    # fase solo se recargan los bloques de aqui abajo.
    v = vram_de_la_escena(rom, 0)
    e = lambda si, no: elige_por_la_fase(fase, si, no)
    descomprime(v, rom, e(0x6AC7, 0x6AB4), 0x0B98)       # 0x49BE  A
    descomprime(v, rom, e(0x6ADD, 0x6ABA), 0x13E8)       # 0x49C4  C
    for de in (0x0C00, 0x1400):                          # 0x49CA, 0x49D0
        descomprime(v, rom, e(0x6BE6, 0x6B34), de)
    g = 0x6B14 if (fase and not fase & 1) else 0x6AF4    # 0x61B0
    descomprime(v, rom, g, 0x04B0)                       # 0x49D3  G
    rellena(v, 0x1080, 0x170, 0xF1)                      # 0x49D6
    descomprime(v, rom, e(0x6517, 0x650D), 0x13D0)       # 0x49DB  F
    descomprime(v, rom, e(0x657B, 0x6521), 0x2B98)       # 0x49E1  D
    descomprime(v, rom, e(0x65CB, 0x6566), 0x33E8)       # 0x49E7  E
    patrones_de_sprite(v, rom)
    return v


def refleja_una_franja(v, ori, des):
    """0x443F: un sprite de 16x16 del reves. Lee los 32 bytes de ORI, le da la
    vuelta a cada uno (0x445E) y los escribe en el sprite que acaba en DES:
    la mitad izquierda del original va a la derecha (DES..) y la derecha a la
    izquierda (DES-0x10..). DES llega apuntando a la mitad derecha."""
    for mitad in (des, des - 0x10):
        for k in range(16):
            x = v.b[ori & 0x3FFF]
            v.b[(mitad + k) & 0x3FFF] = int("{:08b}".format(x)[::-1], 2)
            ori += 1
    return ori


def copia_franjas(v, ori, des, c):
    """0x441D: C sprites seguidos, cada uno reflejado en el siguiente hueco."""
    for _ in range(c):
        ori = refleja_una_franja(v, ori, des)
        des += 0x20


def copia_franjas_alternas(v, ori, des, c):
    """0x4429: C parejas. Cada pareja se refleja CRUZADA -el primero en el
    segundo hueco y el segundo en el primero-, que es como se le da la vuelta
    a una figura de dos sprites de ancho."""
    for _ in range(c):
        ori = refleja_una_franja(v, ori, des)
        ori = refleja_una_franja(v, ori, des - 0x20)
        des += 0x40


def patrones_de_sprite(v, rom):
    """0x70D6: los tres bloques de patrones de sprite y sus reflejos."""
    descomprime(v, rom, 0x715C, 0x1800)          # 0x70D6
    descomprime(v, rom, 0x71D1, 0x18A0)          # 0x70DF
    descomprime(v, rom, 0x72F3)                  # 0x70E8, con su destino
    copia_franjas(v, 0x1860, 0x1890, 1)          # 0x70EE
    copia_franjas(v, 0x18C0, 0x1A50, 12)         # 0x70F9
    copia_franjas_alternas(v, 0x1BC0, 0x1DD0, 5)  # 0x7104
    copia_franjas(v, 0x1D00, 0x1EF0, 4)          # 0x710F
    return v


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


def pinta_rotulo(v, rom, ini, mascara=0xFF):
    """El interprete de rotulos de 0x40AE, el mismo de tools/guiones.py.

    OJO CON EL BORRADO, que en este cartucho no es como en sus dos hermanos:
    con la mascara a 0x00 no escribe ceros, escribe el patron **1** (0x40BF),
    porque aqui la celda vacia es la 1 y no la 0.
    """
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    from guiones import ejecuta
    fin, tramos = ejecuta(rom, ORG, ini)
    for destino, cuerpo in tramos:
        v.sitúa(destino)
        for b in cuerpo:
            c = b & mascara
            v.escribe(c if c else 0x01)
    return fin


def baja_el_logotipo(v, pasos=0x11):
    """0x4892: el logotipo de KONAMI, subiendo por la pantalla.

    Las mismas tres franjas de 3, 11 y 12 celdas de patrones CORRELATIVOS que
    en Circus Charlie y Magical Tree, y en la misma direccion: escribe en el
    REFLEJO de la cuenta respecto de 0x3AAA, y con los diecisiete pasos de
    0x4143 acaba en 0x388A -fila 4, columna 10-. Lo unico que cambia entre los
    tres cartuchos es el patron por el que empieza: 0x40 aqui, 0x41 en Circus
    y 0x60 en Magical Tree.

    Aqui las tres franjas salen de UN bucle con BC=0x0303, donde la cuenta de
    la siguiente se calcula como 14 menos lo que lleva (`ld a,00eh / sub c`):
    3, 11 y 12.
    """
    for paso in range(1, pasos + 1):
        de = (0x3AAA - paso * 0x20) & 0x3FFF
        a = 0x40
        for n in (3, 11, 12):
            v.sitúa(de)
            for _ in range(n):
                v.escribe(a)
                a = (a + 1) & 0xFF
            de = (de + 0x20) & 0x3FFF
        rellena(v, de, 12, 0x00)                     # 0x48C0
    return v


def barre_la_franja(v, pasos=0x13):
    """0x46ED: la cortina que tapa el logotipo, columna a columna.

    DE arranca en 0x3888 -fila 4, columna 8- y le suma el numero de pasada;
    luego baja de fila en fila. La de arriba se deja vacia y las dos de abajo
    llevan los patrones 0xDA+2n y 0xDB+2n. Son DIECINUEVE pasadas, no quince
    como en Magical Tree ni diecisiete como en Circus.
    """
    for paso in range(pasos):
        de = 0x3888 + paso
        for valor in (0x00, 0xDA + paso * 2, 0xDB + paso * 2):
            v.sitúa(de)
            v.escribe(valor & 0xFF)
            de += 0x20


def donde_va_el_cursor(opcion):
    """Con ROTACIONES, no con divisiones: `add a,014h / rrca / rrca`."""
    a = (0x14 + opcion) & 0xFF
    for _ in range(2):
        a = ((a >> 1) | ((a & 1) << 7)) & 0xFF
    return (0x7A00 | a) & 0x3FFF


def vram_de_la_presentacion(rom):
    """LA PANTALLA DE LA CASA: el logotipo de KONAMI y el rotulo de 0x5E42.

    OJO: esta NO es la pantalla de titulo del juego, que es la del menu.

        0x4140  monta_la_pantalla_entera (0x6051)
        0x4156  baja_el_logotipo, diecisiete pasos
        0x415D  pinta_rotulo 0x5E42
    """
    v = vram_de_la_escena(rom)
    baja_el_logotipo(v)
    pinta_rotulo(v, rom, 0x5E42)
    return v


def vram_de_la_seleccion(rom, cursor=True, opcion=0):
    """LA PANTALLA DE TITULO DE VERDAD: la del menu, con "PLAY SELECT".

        0x416C  borra_rotulo 0x5E42   con la mascara a 0x00, que aqui escribe
                                      el patron 1
        0x46ED  barre_la_franja       la cortina, diecinueve columnas
        0x4716  pinta_rotulo 0x5DB1   "PLAY SELECT", las cuatro opciones y el
                                      ":KONAMI 1984"
    """
    v = vram_de_la_presentacion(rom)
    pinta_rotulo(v, rom, 0x5E42, mascara=0x00)
    barre_la_franja(v)
    pinta_rotulo(v, rom, 0x5DB1)
    if cursor:
        de = donde_va_el_cursor(opcion)
        v.sitúa(de)
        v.escribe(0x3E)
        v.escribe(0x3F)
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


# La fila de pantalla en la que empieza la panaderia: el bufer de 0xE1A0 va
# a 0x39A0, que es la fila 13. Medido en los volcados de openMSX
# (work/partida): la ventana de 32 columnas casa con el mapa ahi y no en otra.
FILA_DE_LA_PANADERIA = 13


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
            pa, co = celda(v, t, (y + FILA_DE_LA_PANADERIA) // 8)
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


def pantalla_entera(v, fn, esc=2, con_sprites=False):
    """Los 256x192 puntos, con EL MISMO renderizador que se coteja.

    No se dibuja aqui a mano: se llama a tools/vram.py, que esta medido contra
    la pantalla de openMSX punto por punto -las siete pantallas de la
    demostracion, 49.152 de 49.152 cada una-.
    """
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import vram as V
    px = V.pantalla(bytes(v.b), VDP, con_sprites=con_sprites)
    if esc == 1:
        png(256, 192, px, fn)
        return
    w, h = 256 * esc, 192 * esc
    g = bytearray(w * h * 3)
    for y in range(h):
        fy = y // esc
        for x in range(w):
            i, j = (y * w + x) * 3, (fy * 256 + x // esc) * 3
            g[i:i + 3] = px[j:j + 3]
    png(w, h, g, fn)


def main():
    global ORG
    rom = open(sys.argv[1], "rb").read()
    ORG = int(sys.argv[2], 0)
    sal = sys.argv[3]
    os.makedirs(sal, exist_ok=True)

    v = vram_de_la_escena(rom)
    # LAS DOS PANTALLAS ENTERAS, cotejadas contra el volcado del emulador a
    # CERO bytes de diferencia (tools/coteja_vram.py).
    pantalla_entera(vram_de_la_presentacion(rom),
                    os.path.join(sal, "pantalla-presentacion.png"))
    pantalla_entera(vram_de_la_seleccion(rom),
                    os.path.join(sal, "pantalla-titulo.png"))

    logotipo(v, os.path.join(sal, "logotipo-konami.png"))
    hoja(v, 0, os.path.join(sal, "tiles.png"))
    hoja(v, 2, os.path.join(sal, "tiles-tercio3.png"))
    rango(v, 0x10, 43, os.path.join(sal, "fuente.png"))
    # LA PANADERIA DE CADA FASE: la misma de 0x7604, pero el montaje de la
    # fase carga bloques distintos segun (0xE051) -ver vram_de_la_partida-.
    # Con el contador a 0, 1, 3, 5... sale una; con 2, 4, 6..., la otra.
    mapa(vram_de_la_partida(rom, 0), rom,
         os.path.join(sal, "panaderia-fases-1-2-4.png"))
    mapa(vram_de_la_partida(rom, 2), rom,
         os.path.join(sal, "panaderia-fases-3-5-7.png"))
    # los 64 patrones de sprite, que monta 0x70D6 y no la pantalla de la
    # escena: sin esto la hoja salia en negro
    sprites(vram_de_la_partida(rom, 0), SPRITES,
            os.path.join(sal, "sprites.png"), n=64)

    for f in sorted(os.listdir(sal)):
        print("  ", os.path.join(sal, f))


if __name__ == "__main__":
    main()
