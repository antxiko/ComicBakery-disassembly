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
