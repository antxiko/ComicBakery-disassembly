# The code

## Everything in the interrupt

INIT (`0x40C7`) sets interrupt mode 1, hooks H.KEYI, puts the stack at
`0xE400`, clears the kilobyte of RAM and waits. The hook (`0x405C`) saves the
twelve registers, both sets with IX and IY, before doing anything. The sixteen
scenes are in the table at `0x4119`, stuck right behind the `call` of the
dispatcher at `0x4096`.

The game frame (`0x48CE`) is twenty-seven calls in a row, one for each thing
that moves or is drawn, and the clock at the end.

## The bakery

- `0x4D0C` draws a column: the index times ten, without multiplying, and ten
  indices from the map at `0x7604`, one per row.
- The 32-column window lives in the buffer at `0xE1A0` and goes to the name
  table from `0x39A0`, row 13.
- `0x49A6` sets up the stage and `0x49BB..0x49E7` pick its blocks with
  `(0xE051)`. The screen at `0x6051` is set up only once, at power-on, with the
  stage at zero.

## The figures

- `0x70D6` loads the sprite patterns: three compressed blocks and their mirror
  images (`0x443F`, which reverses each byte and swaps the two halves).
- `0x4C51` sets the baker's pose and `0x4C67` the jump, with the arc at
  `0x4CC3`.
- `0x5117` runs the three raccoons, with their ten states in the table at
  `0x5138`; `0x51D9` makes them walk.

## The rest

- The working-day clock, `0x4614`.
- The demo: `0x4775` swaps the controller reading for the 80 bytes at
  `0x6001` while in the menu.
- Randomness: the R register, at `0x498E`.

## The tools

- `tools/graficos.py`: the scene and game VRAM, the bakery and the menu
  screens.
- `tools/figuras.py`: the baker and the raccoons.
- `tools/coteja_partida.py` and `tools/omsx_partida.tcl`: the check against
  openMSX.

## Code shared with other Konami cartridges

This disassembly has been compared, instruction by instruction, with
every other Konami one in the series. A block counts when the same
instructions, at least six of them from a label to its `ret` or its
unconditional jump, are in both cartridges; the addresses are left
aside, because they change from one cartridge to the next. Of the
other 57, **49** have at least one block in common with this one;
these are the ones that share the most:

| Cartridge | Blocks | Instructions | For example (here = there) |
|---|---:|---:|---|
| [Circus Charlie](https://antxiko.github.io/CircusCharlie-disassembly/) | 27 | 392 | `atiende_el_menu` (0x4831) |
| [Magical Tree](https://antxiko.github.io/MagicalTree-disassembly/) | 21 | 351 | `atiende_el_menu` (0x4831) |
| [Cabbage Patch Kids](https://antxiko.github.io/CabbagePatchKids-disassembly/) | 20 | 206 | `lee_el_teclado` (0x47E8) = `LEE_EL_TECLADO` |
| [Konami’s Mahjong Dojo](https://antxiko.github.io/KonamisMahjongDojo-disassembly/) | 14 | 141 | `arranca_la_voz` (0x79E2) = `carga_los_canales` |
| [Hyper Sports 1](https://antxiko.github.io/HyperSports1-disassembly/) | 12 | 174 | `atiende_el_menu` (0x4831) = `MANEJADOR_DEMO` |
| [Yie Ar Kung-Fu](https://antxiko.github.io/YieArKungFu-disassembly/) | 12 | 125 | `lee_el_teclado` (0x47E8) |
| [Konami’s Game Master 2](https://antxiko.github.io/GameMaster2-disassembly/) | 9 | 78 | `refleja_una_franja` (0x443F) = `espejo_16` |
| [Super Cobra](https://antxiko.github.io/SuperCobra-disassembly/) | 8 | 97 | `parpadea_el_turno` (0x46A3) = `PARPADEA_EL_JUGADOR` |
| [Sky Jaguar](https://antxiko.github.io/SkyJaguar-disassembly/) | 7 | 85 | `lee_el_teclado` (0x47E8) = `LEE_TECLADO` |
| [Hyper Rally](https://antxiko.github.io/HyperRally-disassembly/) | 6 | 52 | `mira_si_es_record` (0x4599) = `ACTUALIZA_TOPE` |

The whole matrix, the 58 cartridges against each other, is on
[The routines](https://antxiko.github.io/MSX-disassembly-database/THE-ROUTINES.html) in the series database, along
with the method and the program that measures it.
