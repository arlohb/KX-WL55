# Function naming

Functions in modules outside of the main module (PanicOS.asm) will follow one of two patterns:
- API functions - these will be given a prefix appropriate to the module, e.g. `lcd_init` for a function to initialise the LCD
- Private functions - these will have an underscore prefix, e.g. `_my_function` - these should *never* be called from outside the module
- Initialisation functions - modules which need initialisation should have a `..._init` function

# Calling conventions

The following conventions are *mandatory* for all API functions

## Parameters

- Single 1-byte parameter - accumulator A
- Two 1-byte parameters - accumulators A, B
- Single 2-byte parameter (non-address) - accumulator D
- Single 2-byte parameter (address) - X register

## Return values

- Single 1-byte parameter - accumulator A
- Single 2-byte parameter - accumulator D

## Register-saving conventions

Any API function, or function within the main module, will preserve the values of all registers used by either itself, or any non-API functions it calls, other than those used as parameters or return addresses.

