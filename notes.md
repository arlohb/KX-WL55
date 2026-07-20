
![Annotated photo of the KX-WL55 internals](./assets/AnnotatedPhoto.png)

# Components

## CPU - HD63B03XP

[datasheet](./assets/HD63B03XP.pdf)

- Compatible with HD6301V1
- 192 bytes of RAM

## ROM 1 + 2 - TMS 27C010A-10/15

[datasheet](./assets/TMS27C010A.pdf)

- ROM 1 is `-10` meaning 100ns access time
- ROM 2 is `-15` meaning 100ns access time
- Each is 131,072 by 8 bits, meaning 1,048,576 bits

## ROM 3 - KM23C4000P-15

[similar MX23C4000 datasheet](./assets/MX23C4000.pdf)
[similar KM23C4000D datasheet](./assets/KM23C4000D.pdf)

## Gate Arrays - μPD65000CW

[general μPD65000 datasheet](./assets/UPD65000.pdf)

## RAM

[datasheet](./assets/TC51732AP.pdf)

- 256K each pseudo-static RAM

## LCD Controller - SED1330

[datasheet](./assets/SED1330-datasheet.pdf)
[technial manual](./assets/SED1330-technical-manual.pdf)

# Address state on boot

- JM1 is not fitted, so VECT is low, so C000-FFFF is IC6.
- Apparently page 0x1C000 of IC6 is loaded in to C000 of the memory map
- Sensible vector table appears at FFEA, with reset vector at D296
- Apparently sensible reset code at 1D296 in this chip, so D296 in memory map

# Pins

## BA - Bus Available

- Normally low
- Goes high when CPU accepts $\overline{\text{HALT}}$ and releases the buses

## Ports

| Port   | Address | Data Direction Register |
|--------|---------|-------------------------|
| Port 2 | $0003   | $0001, 2 bits           |
| Port 5 | $0015   | -                       |
| Port 6 | $0017   | $0016                   |

### Port 2

- 8-bit I/O port
- DDR made up of 2 bits
    - Bit 0 decides the I/O direction of $P_{20}$
    - Bit 1 decides the I/O direction of $P_{21}$ to $P_{27}$
    - 0 for input and 1 for output
- Port 2 is also used as an I/O pin for the timers and SCI
    - When used like this, port 2 except $P_{20}$ becomes an input or output
        automatically depending on their function regardless of the DDR

### Port 5

- 8-bit input only port
- Data direction register ($0016)
    - 0: $\overline{\text{IRQ}_1}$ Enable Bit
    - 1: $\overline{\text{IRQ}_2}$ Enable Bit
    - 2: MRE - Memory Ready Enable Bit
    - 3: HLTE - $\overline{\text{HALT}}$ Enable Bit
    - 4: unused
    - 5: unused
    - 6: RAME - RAM Enable
    - 7: STBY PWR - Standby Power Bit

# Computation Model

- Program is started from $FFFE-F
- Double accumulator D is made up of byte accumulators A and B
- X: index register
- SP: stack pointer
- PC: program counter
- CCR: condition code register
    - 0 C: Carry / borrow from MSB
    - 1 V: Overflow, 2's complement
    - 2 Z: Zero ()
    - 3 N: Negative (sign bit)
    - 4 I: Interrupt mask
    - 5 H: Half carry from bit 3 to bit 4
    - 6, 7: Unused

# Keyboard Matrix

| Row | 7 | 6 | 5         | 4     | 3   | 2     | 1           | 0    |
|-----|---|---|-----------|-------|-----|-------|-------------|------|
| 1   | M |   | ↑         | space | R󰘶  | code  | quick erase | <->  |
| 2   | - | B | print     | →     | ←   | reloc | ↓           | tab  |
| 3   | N | V | next page | ,     | .   | alt   | /           | caps |
| 4   | J | G | help      | 󰌑     | ÷   |       | @           | L󰘶   |
| 5   | H | F | menu      | K     | L   |       | ;           | 1    |
| 6   | U | T | C         | 󰁮     | 󱦒   | X     | []          | Z    |
| 7   | Y | R | D         | I     | O   | S     | P           | A    |
| 8   | 7 | 5 | E         | =     | <-- | W     | -->         | Q    |
| 9   | 6 | 4 | 3         | 8     | 9   | 2     | 0           |      |

# Links

- [a bored programmer's blog on the KX-WL55 and the printer](https://aboredprogrammer.com/panasonic-wl55-kx-wl55/)
- [KX-WL55 manual](./assets/kx-wl55-manual.pdf)
- [KX-W1000 service manual](./assets/kx-w1000-service-manual.pdf)
- [KX-W1500 service manual](https://www.manualslib.com/manual/3353446/Panasonic-Kx-W1500.html)
- [panasonic_typewriter_interface](https://github.com/xunker/panasonic_typewriter_interface)
- [emulator](https://pypi.org/project/m68hc11/)

