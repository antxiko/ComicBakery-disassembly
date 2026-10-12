# The music

Everything you hear here comes from running the cartridge's own sound engine (`suena_un_cuadro`, 0x7A18, and `pide_un_sonido`, 0x799C, which hands it the voices; the interrupt calls it at 0x406E) on an emulated Z80, frame by frame at 60 per second, just as the game calls it. What the engine writes to the PSG is turned into sound with an AY-3-8910 (`tools/musica.py`). Each MP3 is the whole piece up to where it starts again, plus 8 seconds of the repeat fading out; those that do not repeat end where the engine ends.

## Checked against openMSX

The PSG writes have been compared frame by frame with those of openMSX (C-BIOS MSX1 japonés). In every frame the PSG ends up the same:

- stage tune 0x89, in two stretches of the game, of 163 and 222 frames, just as the game asks for it;
- 0x8B asked for at start-up, its first 314 frames;
- "a life is lost" (0x8D), whole, 385 frames.

The timbre is not checked: it is a textbook AY-3-8910, not a recording of the emulator. The probes are `tools/omsx_psg.tcl` and `tools/coteja_psg.py`.

## How a piece is asked for

`pide_un_sonido` takes the number in A. Below 0x89 are effects and from 0x89 up the music uses more voices. Each stage's tune is 0x89 or 0x8B depending on bit 0 of the stage counter. The voices take 11 bytes each from 0xE010. The engine reads PSG register 7 with RDPSG and keeps only the mixer bits it cares about; the MSX start-up leaves it at 0xB8 and here it starts from that value. The tracks marked «in the table» are in the track table but no routine asks for them with an `ld a`; other, longer tracks with no repeat (0x9D, 0xA2 to 0xA4) are left out.

## The tunes

**The stage tune (one of the two)** (0x89)

Asked for by la rutina de 0x4226: el bit 0 del contador de fase (0xE051) elige entre la 0x89 y la 0x8B; lasts 25.6 s and starts again at second 0.0.

<audio controls preload="none" src="audio/musica_89.mp3?v=e9daf2cf"></audio>

**The stage tune (the other)** (0x8B)

Asked for by la rutina de 0x4226, cuando el bit 0 del contador de fase es 0; lasts 30.4 s and starts again at second 0.0.

<audio controls preload="none" src="audio/musica_8B.mp3?v=90ce533a"></audio>

**A life is lost** (0x8D)

Asked for by `pierde_una_vida`; lasts 6.4 s.

<audio controls preload="none" src="audio/musica_8D.mp3?v=ce4a9b21"></audio>

**The lost life, finished off** (0x90)

Asked for by `remata_la_vida_perdida`; lasts 8.3 s.

<audio controls preload="none" src="audio/musica_90.mp3?v=b29e887d"></audio>

**The tune at 0x42A9** (0x93)

Asked for by `L_42A9`; lasts 4.8 s.

<audio controls preload="none" src="audio/musica_93.mp3?v=10dda31b"></audio>

**The end of the stage** (0x96)

Asked for by la rutina de 0x4250; lasts 0.1 s and starts again at second 0.0.

<audio controls preload="none" src="audio/musica_96.mp3?v=92a38341"></audio>

**A track in the table** (0x8A)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 25.6 s and starts again at second 12.8.

<audio controls preload="none" src="audio/musica_8A.mp3?v=1dbf9e58"></audio>

**Another track in the table** (0x8C)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 21.6 s and starts again at second 6.4.

<audio controls preload="none" src="audio/musica_8C.mp3?v=cd61f06a"></audio>

**A third track in the table** (0x8E)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 8.3 s.

<audio controls preload="none" src="audio/musica_8E.mp3?v=4adb22cf"></audio>

**A fourth track in the table** (0x8F)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 8.3 s.

<audio controls preload="none" src="audio/musica_8F.mp3?v=fe71ec2a"></audio>

**A fifth track in the table** (0x91)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 8.3 s.

<audio controls preload="none" src="audio/musica_91.mp3?v=da98c1ba"></audio>

**A sixth track in the table** (0x92)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 8.2 s.

<audio controls preload="none" src="audio/musica_92.mp3?v=04e98919"></audio>

**A seventh track in the table** (0x94)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 38.4 s and starts again at second 0.0.

<audio controls preload="none" src="audio/musica_94.mp3?v=cf8dd38b"></audio>

**An eighth track in the table** (0x95)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 38.4 s and starts again at second 0.0.

<audio controls preload="none" src="audio/musica_95.mp3?v=cba52f2c"></audio>

**A ninth track in the table** (0x9F)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 9.2 s.

<audio controls preload="none" src="audio/musica_9F.mp3?v=ee781b22"></audio>

**A tenth track in the table** (0xA0)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 7.5 s and starts again at second 3.2.

<audio controls preload="none" src="audio/musica_A0.mp3?v=06839425"></audio>
