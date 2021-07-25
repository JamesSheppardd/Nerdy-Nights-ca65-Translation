ca65 controller.asm -o controller.o --debug-info
ld65 controller.o -o controller.nes -t nes --dbgfile controller.dbg