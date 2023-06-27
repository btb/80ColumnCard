# 80ColumnCard

## Construction notes

* the character generator subcircuit appears to be very sensitive to the speed of the character generator EPROM (U20).  Character corruption occurs with EPROMs that are too fast; an M27C64-20 appears to work.

* although many of the TTL LS chips can be substituted with members of newer logic families (ACT, for example), U2 (74LS02) and U6 (74LS00) must be LS.
