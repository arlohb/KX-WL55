PanicOS.bin: *.asm drivers/*.asm
	dasm PanicOS.asm -f3 -lPanicOS.lst -oPanicOS.bin

burn: PanicOS.bin
	sudo steam-run ../../onerom/onerom program --config-file onerom.json
clean:
	rm -f *.lst *.bin
