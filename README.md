# Comic Bakery (Konami, MSX) — a commented disassembly

*(También [en castellano](README.es.md).)*

An **RC-714** 16 KB cartridge from 1984. The listing in `src/comicbakery.asm`
reassembles the ROM **byte for byte** with `pasmo`, and every one of its
16,384 bytes is accounted for: **8,097 of code and 8,287 of data**. That is
**535 routines, none below 10% commented**, and the density is **46.9%**.

The baker, the raccoons and each stage's bakery are drawn from the ROM and
checked against openMSX in sixteen game dumps: **zero bytes different** in the
colour, pattern and sprite tables.

The ROM is not distributed.

- Website: https://antxiko.github.io/ComicBakery-disassembly/
- Getting started: [docs/GETTING-STARTED.md](docs/GETTING-STARTED.md)
- Legal notice: [LEGAL-NOTICE.md](LEGAL-NOTICE.md)
