# En el emulador

Con openMSX y la máquina `Philips_VG_8020`:

    echo 2 > work/fase.txt
    openmsx -machine Philips_VG_8020 -cart comicbakery.rom -script tools/omsx_partida.tcl

`tools/omsx_partida.tcl`:

- pulsa espacio en el menú y, cuando la escena 5 pone el contador de fase a
  cero (`0x4193`), escribe en `0xE051` el de `work/fase.txt`, antes de que se
  monte la fase;
- cuenta los cuadros de partida con un punto de ruptura en `0x48CE` y vuelca
  RAM y VRAM en los cuadros 1, 50, 200, 400, 800, 1200, 1600 y 2400, en
  `work/partida/`.

La demostración también pasa por `0x48CE`, así que los primeros volcados son
de ella, con el contador a 1.

Un aviso: si la orden de un punto de ruptura falla, openMSX congela la
emulación. El guion envuelve las suyas en `catch` y apunta el error en
`work/partida/log.txt`.
