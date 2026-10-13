#!/usr/bin/env python3
"""La tienda del final de cada jornada, EJECUTANDO el cartucho.

Al acabar la jornada (0xE00D a uno, 0x4652) la escena 15 (0x4314) recorre su
tabla de ocho sub-estados (0x432B): el panadero se va (0x5A76, 0x5A96), se
monta la tienda (0x5AD6), el carro entra (0x5BA6), los panes pasan a los
ninos (0x5C1F, 0x5C5A, 0x5C6F) y se remata la fase (0x433B) o, si faltan
panes, se pierde una vida (0x5CEC -> escena 12).

Aqui no se redibuja nada a mano: se arranca el cartucho en frio con z80run
(0x40C7), se le da a cada cuadro lo mismo que la interrupcion (0x406E
suena_un_cuadro, 0x407A lee_los_mandos, 0x407D reparte_la_escena) y se
fotografia la VRAM con el renderizador de tools/vram.py, el cotejado contra
openMSX. Lo unico que se pone a mano es lo que hace el jugador: pulsar el
disparo en el menu, acabar la jornada (0xE00D) y cuantos panes ha hecho
(0xE060 y su copia en BCD 0xE07B, como los deja 0x5042-0x504B).

Uso: tienda.py <rom> <dir_salida>
  tienda.png       la tienda con los panes repartidos y el globo de FINE
  tienda.gif       la escena entera, cuadro a cuadro, con 10 panes
  tienda-falta.gif la misma con 3 panes: falta uno y se pierde una vida
  tienda-globos.png  el globo de cada cuenta de panes (4 a 9, y 3)
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from z80run import Z80, ParadaZ80  # noqa: E402
import vram as V  # noqa: E402

ORG = 0x4000
INIT, BUCLE = 0x40C7, 0x40F5            # init y su `jr` eterno
SUENA, MANDOS, ESCENA = 0x7A18, 0x4775, 0x40F7
FIN_DE_JORNADA = 0xE00D
PANES, PANES_BCD = 0xE060, 0xE07B


class Cartucho(Z80):
    """El cartucho con lo poco de la BIOS que usa: el VDP y el PSG."""

    def __init__(self, rom):
        super().__init__()
        self.carga(rom, ORG)
        self.fin = ORG + len(rom)
        self.psg = bytearray(16)
        self.psg[7] = 0xB8
        self.psg[14] = 0xFF               # el mando suelto
        self.mem[6] = self.mem[7] = 0x98  # los puertos del VDP (tabla de la BIOS)

    def _escribir(self, d, v):
        if ORG <= (d & 0xFFFF) < self.fin:
            return
        super()._escribir(d, v)

    def bios(self, pc):
        vdp = self.maq.vdp
        if pc == 0x0093:                                  # WRTPSG
            self.psg[self.a & 0x0F] = self.e
        elif pc == 0x0096:                                # RDPSG
            self.a = self.psg[self.a & 0x0F]
        elif pc == 0x013E:                                # RDVDP
            self.a = 0
        elif pc in (0x0050, 0x0053):                      # SETRD / SETWRT
            vdp.dir = self.hl & 0x3FFF
        elif pc == 0x004A:                                # RDVRM
            self.a = vdp.vram[self.hl & 0x3FFF]
        elif pc == 0x004D:                                # WRTVRM
            vdp.vram[self.hl & 0x3FFF] = self.a
        elif pc == 0x0047:                                # WRTVDP
            vdp.regs[self.c & 7] = self.b
        elif pc == 0x0141:                                # SNSMAT: nada pulsado
            self.a = 0xFF
        else:
            raise ParadaZ80("llamada a la BIOS 0x%04X" % pc)

    def llama(self, desde, tope=3_000_000, parada=0xFFFE):
        """Una rutina hasta su `ret`, o hasta `parada` (el `jr` eterno)."""
        centinela = 0xFFFE
        self.sp = (self.sp - 2) & 0xFFFF
        self._escribir16(self.sp, centinela)
        self.pc = desde
        n = 0
        while self.pc not in (centinela, parada):
            if self.pc < ORG:
                self.bios(self.pc)
                self.pc = self._pop()
                continue
            n += 1
            if n > tope:
                raise ParadaZ80("mas de %d instrucciones" % tope)
            self._una()

    def cuadro(self):
        """Lo que hace la interrupcion (0x405C), sin el cerrojo."""
        self.llama(SUENA)
        self.llama(MANDOS)
        self.llama(ESCENA)

    def escena(self):
        return self.mem[0xE000], self.mem[0xE001]

    def pantalla(self):
        return V.pantalla(bytes(self.maq.vdp.vram), bytes(self.maq.vdp.regs),
                          con_sprites=True)


def arranca(rom):
    z = Cartucho(rom)
    z.sp = 0xF000
    z.llama(INIT, parada=BUCLE)          # deja la pila en 0xE400 (0x40D5)
    return z


def a_la_tienda(rom, panes):
    """Del arranque hasta la escena 15 con `panes` panes hechos."""
    z = arranca(rom)
    for _ in range(3000):
        z.cuadro()
        if z.mem[0xE002] & 0x40:          # bit 6: ya no es la demostracion
            break
        # el menu es la escena 5 (0x417E): el disparo, un cuadro si y otro no
        z.psg[14] = 0xEF if z.escena()[0] == 5 and z.mem[0xE003] & 8 \
            else 0xFF
    z.psg[14] = 0xFF
    for _ in range(3000):                 # hasta la escena 11 (0x4240): se juega
        z.cuadro()
        if z.escena()[0] == 11:
            break
    else:
        raise ParadaZ80("la partida no arranca")
    z.mem[FIN_DE_JORNADA] = 1             # se acaba la jornada
    for _ in range(100):
        z.cuadro()
        if z.escena() == (15, 0):
            break
    z.mem[PANES] = panes
    z.mem[PANES_BCD] = int(str(panes), 16)
    return z


def graba_la_escena(rom, panes, hasta=2000):
    """Cuadros de la tienda: desde que se monta (15, 3) hasta que se deja.
    Con panes de sobra el globo sale en (15, 7), el remate de 0x433B; si
    faltan, 0x5D0E salta a la escena 12 con su plazo, y en (12, 3) se mira si
    quedan vidas."""
    z = a_la_tienda(rom, panes)
    cuadros = []
    for _ in range(hasta):
        z.cuadro()
        e = z.escena()
        if e[0] == 15 and e[1] < 3:
            continue
        if e[0] not in (12, 15) or e == (12, 3):
            break
        cuadros.append(z.pantalla())
    return z, cuadros


def imagen(px, esc=2):
    from PIL import Image
    im = Image.frombytes("RGB", (256, 192), bytes(px))
    return im.resize((256 * esc, 192 * esc), Image.NEAREST)


def gif(cuadros, fn, esc=2):
    """Un cuadro de GIF por cada cambio; la duracion, los cuadros de 1/60 s
    que dura, redondeada en centesimas sin perder el acumulado."""
    trozos = []
    for px in cuadros:
        if trozos and trozos[-1][0] == px:
            trozos[-1][1] += 1
        else:
            trozos.append([px, 1])
    trozos[-1][1] += 120                  # el final, dos segundos quieto
    ims, dur, t = [], [], 0
    for px, n in trozos:
        t0 = round(t * 100 / 60)
        t += n
        ims.append(imagen(px, esc))
        dur.append(max(2, round(t * 100 / 60) - t0) * 10)
    ims[0].save(fn, save_all=True, append_images=ims[1:], duration=dur,
                loop=0, optimize=True)
    return len(ims)


def main():
    rom = open(sys.argv[1], "rb").read()
    sal = sys.argv[2]
    os.makedirs(sal, exist_ok=True)
    _, c10 = graba_la_escena(rom, 10)
    imagen(c10[-1]).save(os.path.join(sal, "tienda.png"))
    print("tienda.gif", gif(c10, os.path.join(sal, "tienda.gif")), "cuadros")
    _, c3 = graba_la_escena(rom, 3)
    print("tienda-falta.gif", gif(c3, os.path.join(sal, "tienda-falta.gif")))
    from PIL import Image
    hoja = Image.new("RGB", (128 * 4, 32 * 2))
    for i, n in enumerate((3, 4, 5, 6, 7, 8, 9, 10)):
        _, c = graba_la_escena(rom, n)
        recorte = imagen(c[-1], 1).crop((40, 8, 168, 40))
        hoja.paste(recorte, ((i % 4) * 128, (i // 4) * 32))
    hoja.resize((hoja.width * 2, hoja.height * 2), Image.NEAREST).save(
        os.path.join(sal, "tienda-globos.png"))


if __name__ == "__main__":
    main()
