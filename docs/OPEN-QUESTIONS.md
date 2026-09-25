# Open questions

- **The raccoon's other states.** Walking is drawn and checked; climbing to
  the oven, hit or knocked over (the table at `0x53CE`) shows up in ten of the
  dumps and is not drawn.
- **The cat** (`0x5088`): how long it waits depending on the stage is known;
  it has not been drawn.
- **The variant at `0xE19A`**, which comes from the R register and the stage
  number (`0x498A`): how it is worked out is known, not everything it changes.
- **What makes one stage harder than the last** —how long a shot lasts, how
  long the cat waits— is read from the code and not measured in the emulator.
