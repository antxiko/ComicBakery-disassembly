#!/usr/bin/env python3
"""La musica del cartucho, ejecutando su motor de sonido (ver motor_musica.py).

Pide el sonido con `pide_un_sonido` (0x799C, A = numero) y corre
`suena_un_cuadro` (0x7A18), que la interrupcion llama cada cuadro (0x406E). Tres
voces de 11 bytes desde 0xE010; el mezclador lo lee del propio PSG (RDPSG).
Uso:  musica.py registros 0x89 [cuadros] | mp3 0x89 f.mp3 | todas docs/audio
      musica.py barrido 0x80 0xFF | emu
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import motor_musica  # noqa: E402
from motor_musica import P  # noqa: E402

TABLA = "ninguna llamada directa: está en la tabla de pistas"

PIEZAS = [
    P(0x89, "La música de la fase (una de las dos)",
      "The stage tune (one of the two)",
      "la rutina de 0x4226: el bit 0 del contador de fase (0xE051) elige "
      "entre la 0x89 y la 0x8B"),
    P(0x8B, "La música de la fase (la otra)", "The stage tune (the other)",
      "la rutina de 0x4226, cuando el bit 0 del contador de fase es 0"),
    P(0x8D, "Se pierde una vida", "A life is lost", "`pierde_una_vida`"),
    P(0x90, "Remate de la vida perdida", "The lost life, finished off",
      "`remata_la_vida_perdida`"),
    P(0x93, "La pieza del 0x42A9", "The tune at 0x42A9", "`L_42A9`"),
    P(0x96, "El fin de fase", "The end of the stage", "la rutina de 0x4250"),
    P(0x8A, "Una pista de la tabla", "A track in the table", TABLA),
    P(0x8C, "Otra pista de la tabla", "Another track in the table", TABLA),
    P(0x8E, "Una tercera pista de la tabla", "A third track in the table",
      TABLA),
    P(0x8F, "Una cuarta pista de la tabla", "A fourth track in the table",
      TABLA),
    P(0x91, "Una quinta pista de la tabla", "A fifth track in the table",
      TABLA),
    P(0x92, "Una sexta pista de la tabla", "A sixth track in the table",
      TABLA),
    P(0x94, "Una séptima pista de la tabla", "A seventh track in the table",
      TABLA),
    P(0x95, "Una octava pista de la tabla", "An eighth track in the table",
      TABLA),
    P(0x9F, "Una novena pista de la tabla", "A ninth track in the table",
      TABLA),
    P(0xA0, "Una décima pista de la tabla", "A tenth track in the table",
      TABLA),
]

PAGINA = motor_musica.pagina_basica(
    "`suena_un_cuadro`, 0x7A18, y `pide_un_sonido`, 0x799C, que le reparte "
    "las voces; lo llama la interrupción en 0x406E",
    "`suena_un_cuadro`, 0x7A18, and `pide_un_sonido`, 0x799C, which hands it "
    "the voices; the interrupt calls it at 0x406E",
    "C-BIOS MSX1 japonés",
    [("la música de la fase 0x89, en dos tramos de la partida, de 163 y 222 "
      "cuadros, tal como el juego la pide",
      "stage tune 0x89, in two stretches of the game, of 163 and 222 frames, "
      "just as the game asks for it"),
     ("la 0x8B pedida al arrancar, sus primeros 314 cuadros",
      "0x8B asked for at start-up, its first 314 frames"),
     ("«se pierde una vida» (0x8D) entera, 385 cuadros",
      "\"a life is lost\" (0x8D), whole, 385 frames")],
    [("Cómo se pide una pieza",
      "`pide_un_sonido` recibe el número en A. Por debajo de 0x89 son efectos "
      "y del 0x89 en adelante la música usa más voces. La música de cada "
      "fase es la 0x89 o la 0x8B según el bit 0 del contador de fase. Las "
      "voces ocupan 11 bytes cada una desde 0xE010. El motor lee el registro "
      "7 del PSG con RDPSG y conserva solo los bits del mezclador que le "
      "importan; el arranque del MSX lo deja en 0xB8 y aquí se parte de ese "
      "valor. Las pistas «de la tabla» están en la tabla de pistas pero "
      "ninguna rutina las pide con un `ld a`; se omiten otras más largas y "
      "sin repetición (0x9D, 0xA2 a 0xA4).",
      "How a piece is asked for",
      "`pide_un_sonido` takes the number in A. Below 0x89 are effects and "
      "from 0x89 up the music uses more voices. Each stage's tune is 0x89 or "
      "0x8B depending on bit 0 of the stage counter. The voices take 11 "
      "bytes each from 0xE010. The engine reads PSG register 7 with RDPSG "
      "and keeps only the mixer bits it cares about; the MSX start-up leaves "
      "it at 0xB8 and here it starts from that value. The tracks marked "
      "«in the table» are in the track table but no routine asks for them "
      "with an `ld a`; other, longer tracks with no repeat (0x9D, 0xA2 to "
      "0xA4) are left out.")])

CFG = dict(rom="comicbakery.rom", org=0x4000, frame=0x7A18, pide=0x799C,
           ram=(0xE010, 0xE034), excluye=[0xE019, 0xE024, 0xE02F], hz=60,
           psg0={7: 0xB8}, piezas=PIEZAS, pagina=PAGINA,
           cotejado=[(0x8D, 386, None), (0x89, 1538, 1)])

if __name__ == "__main__":
    sys.exit(motor_musica.main(CFG, sys.argv[1:]))
