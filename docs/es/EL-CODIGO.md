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

## Código compartido con otros cartuchos de Konami

Este desensamblado se ha comparado, instrucción por instrucción, con
todos los demás de Konami de la serie. Cuenta un bloque cuando las
mismas instrucciones, al menos seis desde una etiqueta hasta su `ret`
o su salto sin condición, están en los dos cartuchos; las direcciones
no se miran, porque cambian de un cartucho a otro. De los otros 57,
**49** tienen al menos un bloque en común con este; estos son los
que más comparten:

| Cartucho | Bloques | Instrucciones | Por ejemplo (aquí = allí) |
|---|---:|---:|---|
| [Circus Charlie](https://antxiko.github.io/CircusCharlie-disassembly/es/) | 27 | 392 | `atiende_el_menu` (0x4831) |
| [Magical Tree](https://antxiko.github.io/MagicalTree-disassembly/es/) | 21 | 351 | `atiende_el_menu` (0x4831) |
| [Cabbage Patch Kids](https://antxiko.github.io/CabbagePatchKids-disassembly/es/) | 20 | 206 | `lee_el_teclado` (0x47E8) = `LEE_EL_TECLADO` |
| [Konami’s Mahjong Dojo](https://antxiko.github.io/KonamisMahjongDojo-disassembly/es/) | 14 | 141 | `arranca_la_voz` (0x79E2) = `carga_los_canales` |
| [Hyper Sports 1](https://antxiko.github.io/HyperSports1-disassembly/es/) | 12 | 174 | `atiende_el_menu` (0x4831) = `MANEJADOR_DEMO` |
| [Yie Ar Kung-Fu](https://antxiko.github.io/YieArKungFu-disassembly/es/) | 12 | 125 | `lee_el_teclado` (0x47E8) |
| [Konami’s Game Master 2](https://antxiko.github.io/GameMaster2-disassembly/es/) | 9 | 78 | `refleja_una_franja` (0x443F) = `espejo_16` |
| [Super Cobra](https://antxiko.github.io/SuperCobra-disassembly/es/) | 8 | 97 | `parpadea_el_turno` (0x46A3) = `PARPADEA_EL_JUGADOR` |
| [Sky Jaguar](https://antxiko.github.io/SkyJaguar-disassembly/es/) | 7 | 85 | `lee_el_teclado` (0x47E8) = `LEE_TECLADO` |
| [Hyper Rally](https://antxiko.github.io/HyperRally-disassembly/es/) | 6 | 52 | `mira_si_es_record` (0x4599) = `ACTUALIZA_TOPE` |

La matriz entera, los 58 cartuchos entre sí, está en
[Las rutinas](https://antxiko.github.io/MSX-disassembly-database/es/LAS-RUTINAS.html) de la base de datos de la
serie, con el método y el programa que la mide.
