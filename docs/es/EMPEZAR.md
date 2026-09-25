# Empezar

Este repositorio contiene el desensamblado comentado de **Comic Bakery** de
Konami para MSX (RC-714, 1984). No contiene el cartucho: la imagen de la ROM no
se distribuye.

## Lo que hace falta

- `pasmo` — el ensamblador que reproduce la ROM
- `python3` — las herramientas de `tools/`
- `make`
- Tu propia copia del cartucho, en la raíz y con el nombre `comicbakery.rom`

Son **16.384 bytes exactos** y su huella es:

    sha256  089e6cd7ff074c5c162325b3ac00e36e5787034bffe349b6e33db51a2e591ed8

Para comprobarla:

    make comprueba

## Reproducirlo entero

| orden | qué hace | qué demuestra |
|---|---|---|
| `make listado` | traza el flujo y genera `src/comicbakery.asm` con las notas | que el listado sale del cartucho y de `src/comicbakery.notes`, no se edita a mano |
| `make verify` | reensambla con `pasmo` y compara | que el listado ES la ROM, byte a byte |
| `make sanity` | reparte los 16.384 bytes entre código y datos | que no queda ni un byte sin asignar |
| `make test` | 33 tests | que las cifras de esta web son las del listado |
| `make imagenes` | dibuja todo lo de `docs/imagenes/` desde la ROM | que los formatos están bien leídos |
| `make coteja_partida` | compara con dieciséis volcados de openMSX | cero bytes de diferencia en las tablas |

El cotejo necesita antes los volcados: `tools/omsx_partida.tcl`, con el
contador de fase en `work/fase.txt`. Ver [En el emulador](EN-EL-EMULADOR.html).
