# Getting started

This repository holds the commented disassembly of Konami's **Comic Bakery**
for the MSX (RC-714, 1984). It does not hold the cartridge: the ROM image is
not distributed.

## What you need

- `pasmo` — the assembler that reproduces the ROM
- `python3` — the tools in `tools/`
- `make`
- Your own copy of the cartridge, in the root and named `comicbakery.rom`

It is **exactly 16,384 bytes** and its fingerprint is:

    sha256  089e6cd7ff074c5c162325b3ac00e36e5787034bffe349b6e33db51a2e591ed8

To check it:

    make comprueba

## Reproducing all of it

| command | what it does | what it proves |
|---|---|---|
| `make listado` | traces the flow and generates `src/comicbakery.asm` with the notes | that the listing comes from the cartridge and `src/comicbakery.notes`, not hand-edited |
| `make verify` | reassembles with `pasmo` and compares | that the listing IS the ROM, byte for byte |
| `make sanity` | splits the 16,384 bytes into code and data | that not one byte is left unassigned |
| `make test` | 33 tests | that the numbers on this site are the listing's |
| `make imagenes` | draws everything in `docs/imagenes/` from the ROM | that the formats are read right |
| `make coteja_partida` | compares with sixteen openMSX dumps | zero bytes different in the tables |

The check needs the dumps first: `tools/omsx_partida.tcl`, with the stage
counter in `work/fase.txt`. See [In the emulator](IN-THE-EMULATOR.html).
