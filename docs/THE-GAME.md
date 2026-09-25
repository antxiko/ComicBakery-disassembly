# The game

![The title](imagenes/rotulo.png)

The baker guards the bakery from the **raccoons** during an **eight-minute**
working day by the clock (`0x4614`). The baker walks along the floor, jumps
with both buttons and shoots; a raccoon that touches the baker costs a life.
When the day is over, the cartridge counts the loaves (`0x5B5E`).

The pictures below **are neither captures nor the cartridge running**: they
are the ROM's tables put together the way the game does it —the screens and
the bakery with its set-up chain, the baker and the raccoons with their pose
and step tables—. Checked against openMSX in sixteen game dumps: **0 bytes
different** in the colour, pattern and sprite pattern tables.

## The baker

Four sprites (`0x4C51`), with the patterns of one of the fourteen poses at
`0x7124` and the row and colour of the template at `0x7096`: the second is
0x10 below the first, the third 8 and the fourth 0x20.

![The baker](imagenes/jugador.png)

## The raccoons

Two sprites in a row (`0x51D9`), the second sixteen pixels to the right and
with the pattern four further on. Walking left the patterns start at `0x78`,
and walking right 0x3C further on; the step is picked by the frame counter and
only ever gives 0, 8 or 16. There are three, told apart by the colour at
`0x51B2`: grey, yellow and red.

![The raccoons](imagenes/enemigos.png)

## Each stage's bakery

There is one bakery: the **92 columns of ten cells** at `0x7604`. The screen
shows 32 of them, from row 13 down. But the stage set-up (`0x49BB` to
`0x49E7`) picks its graphics blocks with the counter at `0xE051`, and the
bakery changes machines:

| stages | machines |
|---|---|
| 1, 2, 4, 6, 8... | green |
| 3, 5, 7, 9... | blue |

![The bakery on stages 1, 2, 4...](imagenes/panaderia-fases-1-2-4.png)

![The bakery on stages 3, 5, 7...](imagenes/panaderia-fases-3-5-7.png)

## The menu screens

Built from the ROM and checked against openMSX down to **0 bytes**.

![The company screen](imagenes/pantalla-presentacion.png)

![The title screen](imagenes/pantalla-titulo.png)
