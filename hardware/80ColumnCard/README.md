# 80ColumnCard

## Construction notes

## RAM (U10)
U10 is designed to use a 6116 Static RAM chip, however there are multiple overlapping footprints available on the board in order for you to just use whatever 2K or larger SRAM is easiest for you to obtain. Consult the interactive BOM if you're not sure how to place the chip. Many larger chips however have the A11 pin where the 6116 has the /WE pin, so you'll have to cut and then re-solder the X21 jumper accordingly.

## Firmware ROM (U3)
U3 holds the 1K of firmware (e.g. "Videx Videoterm ROM 2.4.bin") and can be any EPROM from a 2758A up to a 27(C)512, depending on whatever you have available. A10 will be permanently tied low, and A11-A15 are all permanently tied high, so the code needs to go in the lower 1K of a 2716, or the lower half of the top 2K of any larger EPROM. (Or just repeat it enough times to fill up the whole thing)

## Character ROM (U20)
Any size from 2732 to 27C080 is pin-compatible, however the character generator subcircuit appears to be very sensitive to the speed of this EPROM. Character corruption occurs with EPROMs that are too fast, so 200ns or slower (higher number) is recommended.
Confirmed working are: M27C64-20, AM2732A-2.

This EPROM can hold one or two of the 2K [character sets](../../character_roms). A12-A15 are all permanently tied high, so only the top 4K of the EPROM is usable. The standard character set (e.g. "videx std 7x9 - top right.bin") goes in the lower 2K of that space, and any desired alternative character set (e.g. "videx inverse - top left.bin") goes in the upper 2K of that space.

## Other
Although many of the TTL LS chips can be substituted with members of newer logic families (ACT, for example), U2 (74LS02) U4 (74LS04) U6 (74LS00) U23 (74LS161) must be LS or other TTL (non-CMOS) families.
