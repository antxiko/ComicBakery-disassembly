# La música

Todo lo que suena aquí sale de ejecutar el motor de sonido del cartucho (`suena_un_cuadro`, 0x7A18, y `pide_un_sonido`, 0x799C, que le reparte las voces; lo llama la interrupción en 0x406E) en un Z80 emulado, cuadro a cuadro y a 60 por segundo, igual que lo llama el juego. Lo que el motor escribe en el PSG pasa a sonido con un AY-3-8910 (`tools/musica.py`). Cada MP3 es la pieza entera hasta donde vuelve a empezar, más 8 segundos de la vuelta apagándose; las que no se repiten acaban donde acaba el motor.

## Cotejado con openMSX

Las escrituras al PSG se han comparado cuadro a cuadro con las de openMSX (C-BIOS MSX1 japonés). En todos los cuadros el PSG queda igual:

- la música de la fase 0x89, en dos tramos de la partida, de 163 y 222 cuadros, tal como el juego la pide;
- la 0x8B pedida al arrancar, sus primeros 314 cuadros;
- «se pierde una vida» (0x8D) entera, 385 cuadros.

El timbre no está cotejado: es el de un AY-3-8910 de manual, no una grabación del emulador. Las sondas están en `tools/omsx_psg.tcl` y `tools/coteja_psg.py`.

## Cómo se pide una pieza

`pide_un_sonido` recibe el número en A. Por debajo de 0x89 son efectos y del 0x89 en adelante la música usa más voces. La música de cada fase es la 0x89 o la 0x8B según el bit 0 del contador de fase. Las voces ocupan 11 bytes cada una desde 0xE010. El motor lee el registro 7 del PSG con RDPSG y conserva solo los bits del mezclador que le importan; el arranque del MSX lo deja en 0xB8 y aquí se parte de ese valor. Las pistas «de la tabla» están en la tabla de pistas pero ninguna rutina las pide con un `ld a`; se omiten otras más largas y sin repetición (0x9D, 0xA2 a 0xA4).

## Las músicas

**La música de la fase (una de las dos)** (0x89)

Lo pide la rutina de 0x4226: el bit 0 del contador de fase (0xE051) elige entre la 0x89 y la 0x8B; dura 25,6 s y vuelve a empezar en el segundo 0,0.

<audio controls preload="none" src="../audio/musica_89.mp3?v=e9daf2cf"></audio>

**La música de la fase (la otra)** (0x8B)

Lo pide la rutina de 0x4226, cuando el bit 0 del contador de fase es 0; dura 30,4 s y vuelve a empezar en el segundo 0,0.

<audio controls preload="none" src="../audio/musica_8B.mp3?v=90ce533a"></audio>

**Se pierde una vida** (0x8D)

Lo pide `pierde_una_vida`; dura 6,4 s.

<audio controls preload="none" src="../audio/musica_8D.mp3?v=ce4a9b21"></audio>

**Remate de la vida perdida** (0x90)

Lo pide `remata_la_vida_perdida`; dura 8,3 s.

<audio controls preload="none" src="../audio/musica_90.mp3?v=b29e887d"></audio>

**La pieza del 0x42A9** (0x93)

Lo pide `L_42A9`; dura 4,8 s.

<audio controls preload="none" src="../audio/musica_93.mp3?v=10dda31b"></audio>

**El fin de fase** (0x96)

Lo pide la rutina de 0x4250; dura 0,1 s y vuelve a empezar en el segundo 0,0.

<audio controls preload="none" src="../audio/musica_96.mp3?v=92a38341"></audio>

**Una pista de la tabla** (0x8A)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 25,6 s y vuelve a empezar en el segundo 12,8.

<audio controls preload="none" src="../audio/musica_8A.mp3?v=1dbf9e58"></audio>

**Otra pista de la tabla** (0x8C)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 21,6 s y vuelve a empezar en el segundo 6,4.

<audio controls preload="none" src="../audio/musica_8C.mp3?v=cd61f06a"></audio>

**Una tercera pista de la tabla** (0x8E)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 8,3 s.

<audio controls preload="none" src="../audio/musica_8E.mp3?v=4adb22cf"></audio>

**Una cuarta pista de la tabla** (0x8F)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 8,3 s.

<audio controls preload="none" src="../audio/musica_8F.mp3?v=fe71ec2a"></audio>

**Una quinta pista de la tabla** (0x91)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 8,3 s.

<audio controls preload="none" src="../audio/musica_91.mp3?v=da98c1ba"></audio>

**Una sexta pista de la tabla** (0x92)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 8,2 s.

<audio controls preload="none" src="../audio/musica_92.mp3?v=04e98919"></audio>

**Una séptima pista de la tabla** (0x94)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 38,4 s y vuelve a empezar en el segundo 0,0.

<audio controls preload="none" src="../audio/musica_94.mp3?v=cf8dd38b"></audio>

**Una octava pista de la tabla** (0x95)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 38,4 s y vuelve a empezar en el segundo 0,0.

<audio controls preload="none" src="../audio/musica_95.mp3?v=cba52f2c"></audio>

**Una novena pista de la tabla** (0x9F)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 9,2 s.

<audio controls preload="none" src="../audio/musica_9F.mp3?v=ee781b22"></audio>

**Una décima pista de la tabla** (0xA0)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 7,5 s y vuelve a empezar en el segundo 3,2.

<audio controls preload="none" src="../audio/musica_A0.mp3?v=06839425"></audio>
