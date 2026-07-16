
![Annotated photo of the KX-WL55 internals](./images/AnnotatedPhoto.png)

# Components

## CPU - HD63B03XP

[datasheet](https://rocelec.widen.net/view/pdf/bz4q6bm06r/RNCCS10700-1.pdf)

- Compatible with HD6301V1
- 192 bytes of RAM

## ROM 1 + 2 - TMS 27C010A-10/15

[datasheet](https://www.alldatasheet.com/datasheet-pdf/download/87796/TI/TMS27C010A.html)

- ROM 1 is `-10` meaning 100ns access time
- ROM 2 is `-15` meaning 100ns access time
- Each is 131,072 by 8 bits, meaning 1,048,576 bits

## ROM 3 - KM23C4000P-15

[similar MX23C4000 datasheet](https://datasheet4u.com/download/80205/23C4000.html)
[similar KM23C4000D datasheet](https://www.digchip.com/datasheets/parts/datasheet/409/KM23C4000D-pdf.php)

## Gate Arrays - μPD65000CW

[general μPD65000 datasheet](https://www.alldatasheet.com/datasheet-pdf/download/115557/NEC/UPD65000.html)

## RAM

[datasheet](https://www.alldatasheet.com/datasheet-pdf/download/1462411/TOSHIBA/TC51832ASPL-85.html)

- 256K each pseudo-static RAM

# Address state on boot

- JM1 is not fitted, so VECT is low, so C000-FFFF is IC6.
- We're currently *assuming* the first 16K of IC6 because that appears to have a sensible vector table at the end.
- That would suggest RESET code at 0x851C
- No other pages of IC6 appear to have RESET code at 0x051C.
- Guess the RESET code is, therefore, in IC7.

# Links

- [a bored programmer's blog on the KX-WL55 and the printer](https://aboredprogrammer.com/panasonic-wl55-kx-wl55/)
- [KX-WL55 manual](https://aboredprogrammer.com/wp-content/uploads/2017/02/84e3d34c3587fbafc73c919987b91b25.pdf)
- [KX-W1000 service manual](https://archive.org/details/kx-w1000-service-manual/KX-W1000%20Service%20Manual_600dpi/page/n1/mode/2up)
- [KX-W1500 service manual](https://www.manualslib.com/manual/3353446/Panasonic-Kx-W1500.html)
- [panasonic_typewriter_interface](https://github.com/xunker/panasonic_typewriter_interface)

