# Comic Bakery (Konami, MSX) — desensamblado comentado

*(Also available [in English](README.md).)*

Cartucho **RC-714** de 16 KB, 1984. El listado de `src/comicbakery.asm`
reensambla la ROM **byte a byte** con `pasmo`, y cada uno de sus 16.384 bytes
está asignado: **8.097 de código y 8.287 de datos**. Son **535 rutinas,
ninguna por debajo del 10 % comentado**, y una densidad del **46,9 %**.

El panadero, los mapaches y la panadería de cada fase están dibujados desde la
ROM y cotejados contra openMSX en dieciséis volcados de partida: **cero bytes
distintos** en las tablas de color, patrones y sprites.

La ROM no se distribuye.

- Web: https://antxiko.github.io/ComicBakery-disassembly/es/
- Para empezar: [docs/es/EMPEZAR.md](docs/es/EMPEZAR.md)
- Aviso legal: [AVISO-LEGAL.md](AVISO-LEGAL.md)
