testrom.bin: testrom.asm
	dasm testrom.asm -f3 -ltestrom.lst -otestrom.bin

burn: testrom.bin
	sudo steam-run ../../onerom/onerom program --config-file onerom.json
clean:
	rm -f *.lst *.bin
