# El código

## Todo en la interrupción

INIT (`0x40C7`) pone el modo 1 de interrupción, engancha H.KEYI, deja la pila
en `0xE400`, pone a cero el kilobyte de RAM y se queda esperando. El gancho
(`0x405C`) guarda los doce registros, los dos juegos con IX e IY, antes de hacer
nada. Las dieciséis escenas están en la tabla de `0x4119`, pegada detrás del
`call` del despachador de `0x4096`.

El cuadro de la partida (`0x48CE`) son veintisiete llamadas seguidas, una por
cada cosa que se mueve o se pinta, y el reloj al final.

## La panadería

- `0x4D0C` pinta una columna: el índice por diez, sin multiplicar, y diez
  índices del mapa de `0x7604`, uno por fila.
- La ventana de 32 columnas vive en el búfer de `0xE1A0` y va a la tabla de
  nombres desde `0x39A0`, la fila 13.
- `0x49A6` monta la fase y `0x49BB..0x49E7` eligen sus bloques con
  `(0xE051)`. La pantalla de `0x6051` se monta una sola vez, al encender, con
  la fase a cero.

## Las figuras

- `0x70D6` carga los patrones de sprite: tres bloques comprimidos y sus
  reflejos (`0x443F`, que da la vuelta a cada byte y cambia las dos mitades).
- `0x4C51` pone la pose del panadero y `0x4C67` el salto, con el arco de
  `0x4CC3`.
- `0x5117` atiende a los tres mapaches, con sus diez estados en la tabla de
  `0x5138`; `0x51D9` los hace andar.

## El resto

- El reloj de la jornada, `0x4614`.
- La demostración: `0x4775` cambia la lectura del mando por los 80 bytes de
  `0x6001` mientras se está en el menú.
- El azar: el registro R, en `0x498E`.

## Las herramientas

- `tools/graficos.py`: la VRAM de la escena y de la partida, la panadería y
  las pantallas de menú.
- `tools/figuras.py`: el panadero y los mapaches.
- `tools/coteja_partida.py` y `tools/omsx_partida.tcl`: el cotejo contra
  openMSX.
