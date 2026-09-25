# El cartucho

16 KB en la página 1 (`0x4000-0x7FFF`), cabecera `AB` con INIT en `0x40C7` y
sin BASIC. Pantalla en SCREEN 2.

## La VRAM

Los ocho registros salen de `0x474F`: `02 E2 0E 7F 07 76 03 E1`. En SCREEN 2,
R3 y R4 son base y máscara, así que **el color va en `0x0000` y los patrones en
`0x2000`**.

| zona | qué hay |
|---|---|
| `0x0000` | la tabla de color |
| `0x1800` | los 64 patrones de sprite |
| `0x2000` | los patrones |
| `0x3800` | la tabla de nombres; la panadería, desde `0x39A0` |
| `0x3B00` | los atributos de los sprites |

## La RAM

**Toda la RAM del juego es 1 KB**: `0xE000-0xE3FF`, puesta a cero por INIT. La
pila, en `0xE400`.

| zona | qué hay |
|---|---|
| `0xE000` / `0xE001` | la escena y el sub-estado |
| `0xE003` | el contador de cuadros |
| `0xE00B` | sus tres bits de abajo: el compás de ocho |
| `0xE00D` | la señal de fin de fase |
| `0xE038` | la copia de los ocho registros del VDP |
| `0xE050` | el jugador en turno, 48 bytes; el otro, en `0xE0C0` |
| `0xE051` | el contador de fase, desde cero |
| `0xE080` | el búfer de los sprites |
| `0xE110` | el estado de los tres mapaches |
| `0xE1A0` | la ventana de la panadería, 320 bytes |

## La BIOS

Usa siete rutinas: RDPSG, RDVDP, SETRD, SETWRT, SNSMAT, WRTPSG y WRTVDP. Para
leer la VRAM tiene la suya.

## Las dos pantallas de menú

Están dibujadas desde la ROM y cotejadas contra openMSX a **0 bytes**.

![La pantalla de la casa](../imagenes/pantalla-presentacion.png)

![La pantalla de título](../imagenes/pantalla-titulo.png)
