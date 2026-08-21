# Some notes on use of Forth

There is more detail in the official manuals etc., but these guides are handy reminders of what to do when.

## Using Screens

### Required definitions

If you don't have them already, you'll need to define the required words.

Select the forth vocab and set hex mode:
`FORTH HEX`

Then define a constant:
`40 CONSTANT C/L` ( 64 chars per line )

Now you'll need to enter definitions for some Forth words from the installation guide first, these are:
TEXT, LINE

Then switch to the EDITOR vocabulary:
`VOCABULARY EDITOR IMMEDIATE HEX`

and define some more words:
-MOVE, E, R, P, CLEAR, FLUSH, COPY

### Before Use

Before using screens, *always* execute `EMPTY-BUFFERS` first.

Before using a particular screen for the first time, execute `n CLEAR` where `n` is the screen number.
If not, then even reading the screen may cause crashes.

### Initialising a screen

Now you can `n CLEAR` which will clear the current screen.

Running `n LIST` will confirm this.  (You can hold SHIFT to pause the listing, thanks to `?TERMINAL`).

Note that both `CLEAR` and `LIST` also initialise `SCR`, the "current screen" variable.

### Adding text

Use the `P` word to add text to the current screen.

`n P <text here>` will add text to line `n` of the current screen.

### Copying to the RAM disks

Note that data is cached in volatile RAM.  After making changes, run `FLUSH` to ensure these are copied to RAM disk.



