# In the emulator

With openMSX and the `Philips_VG_8020` machine:

    echo 2 > work/fase.txt
    openmsx -machine Philips_VG_8020 -cart comicbakery.rom -script tools/omsx_partida.tcl

`tools/omsx_partida.tcl`:

- presses space in the menu and, when scene 5 sets the stage counter to zero
  (`0x4193`), writes the one in `work/fase.txt` into `0xE051`, before the stage
  is set up;
- counts game frames with a breakpoint at `0x48CE` and dumps RAM and VRAM on
  frames 1, 50, 200, 400, 800, 1200, 1600 and 2400, into `work/partida/`.

The demo goes through `0x48CE` too, so the first dumps are of the demo, with
the counter at 1.

A warning: if a breakpoint's command fails, openMSX freezes the emulation. The
script wraps its commands in `catch` and logs the error in
`work/partida/log.txt`.
