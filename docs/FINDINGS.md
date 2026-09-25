# Findings

1. **The carts were raccoons.** The listing called carts what the baker
   shoots and what costs the baker a life; drawn from the ROM they are the
   raccoons. And their second sprite goes sixteen pixels to the right, not
   below.
2. **Two bakeries.** The stage set-up picks graphics blocks with `(0xE051)`:
   green machines on stages 1, 2, 4, 6... and blue ones on 3, 5, 7... Stages 1
   and 2 look the same because stage 0 goes through the same block as the odd
   ones.
3. **The screen is set up once.** `0x6051` runs at power-on, with the stage at
   zero; at the start of each stage only its blocks are reloaded. Set up that
   way, the sixteen dumps give 0 bytes different.
4. **The sprites are not set up with the screen.** The 64 patterns are loaded
   by `0x70D6`, with their mirror images: every figure faces both ways without
   being stored twice.
5. **The demo plays from a script**: 80 bytes recorded at `0x6001` that stand
   in for the controller while in the menu.
6. **An eight-minute working day**, counted in BCD by `0x4614`. Neither of its
   two batch siblings has a clock.
7. **The viewer left inside.** `0x60B0` fills the 768 cells with indices 0, 1,
   2... and stays on a `jr $`. Nothing calls it.
8. **The interrupt saves all twelve registers**, where its two siblings trust
   the main thread not to use them.
9. **The extra life goes up in threes**, not in twos as in Circus Charlie and
   Magical Tree, its batch siblings.
10. **Switching players is 48 bytes**, not 32: this cartridge keeps more state
    per player.
11. **The game watches the music.** `0x5492` and `0x5BA6` decide on the byte
    a voice's score points to.
12. **The same decompression language as its siblings**, with a different
    routine signature (`0x43EE`).
