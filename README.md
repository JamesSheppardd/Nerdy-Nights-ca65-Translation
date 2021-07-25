# The Nerdy Nights ca65 Translation

[Nerdy Nights](https://nerdy-nights.nes.science/) is a series by Brian Parker (aka BunnyBoy) of tutorials on programming homebrew games from scratch for the NES using assmebly. It walks through basic concepts in 9 lessons such as 16-bit maths and controller inputs, and there are further resources on the site available for learning about sound on the NES as well as Bank Switching, however these have not been translated to ca65 yet in this repo.

## What is the point of this repo?

The original Nerdy Nights tutorials were all written using the NESASM assembler, however some people (me included) prefer using the ca65 macro assembler - part of the [cc65 compiler](https://cc65.github.io/). There aren't too many things different between the 2 assemblers, however there are definitely a few key syntatical differences, like having different directives (e.g. using `.byte` instead of `.db`), or different inbuilt functions and how they are written (e.g. `LDA #HIGH(background)` is perfectly fine in NESASM to get the high byte, but in ca65 it would be written as `LDA #>background`).

Primarily, the main difference is that ca65 uses a linker to place code at specific address, instead of th `.org` statements used in NESASM. The linker uses different **segments** to seprate code. the `ld65` command is run with `-t nes` to create polayable .nes files. The linker uses the `nes.cfg` config file. This file can be found at the bottom of the document.
**TLDR: The original tutorial was written for a different assembler than what I used**

## Additional Resources

These are some additional resources that helped me when I was starting out:

* [Nerdy Nights tutorial](https://nerdy-nights.nes.science/)
* [Setting up cc65 and ca65](https://www.youtube.com/watch?v=JgdcGcJga4w&list=PL29OkqO3wUxzOmjc0VKcdiNPqwliHEuEk&index=1)
* [6502 Reference](http://www.obelisk.me.uk/6502/reference.html)
* [Nerdy Nights ca65 Remix](https://github.com/ddribin/nerdy-nights) - what I used to help me, however it does not cover the final 3 lessons, which is why I felt the need to post this repo
* [NESdev Wiki](https://wiki.nesdev.com/w/index.php/Nesdev_Wiki)
* [NES Development Discord](https://discord.gg/JKCbuycpEx)
* [Zeropages](https://www.youtube.com/playlist?list=PL29OkqO3wUxzOmjc0VKcdiNPqwliHEuEk) series by Michael Chiaramonte
* [NES RAM Maps](https://docs.google.com/spreadsheets/d/13Y_h6-3DQwdK-3Dvleg-Glk0jn43_As8jPKa08O__bU/edit#gid=0)
* [Easy 6502](http://skilldrick.github.io/easy6502/)
* [How ca65 works](https://nesdoug.com/2020/05/12/how-ca65-works/)

## The nes.cfg File

````
MEMORY {

    ZP:  start = $02, size = $1A, type = rw, define = yes;

    # INES Cartridge Header
    HEADER: start = $0, size = $10, file = %O ,fill = yes;

    # 2 16K ROM Banks
    # - startup
    # - code
    # - rodata
    # - data (load)
    ROM0: start = $8000, size = $7ff4, file = %O ,fill = yes, define = yes;

    # Hardware Vectors at End of 2nd 8K ROM
    ROMV: start = $fff6, size = $c, file = %O, fill = yes;

    # 1 8k CHR Bank
    ROM2: start = $0000, size = $2000, file = %O, fill = yes;

    # standard 2k SRAM (-zeropage)
    # $0100-$0200 cpu stack
    # $0200-$0500 3 pages for ppu memory write buffer
    # $0500-$0800 3 pages for cc65 parameter stack
    SRAM: start = $0500, size = $0300, define = yes;

    # additional 8K SRAM Bank
    # - data (run)
    # - bss
    # - heap
    RAM: start = $6000, size = $2000, define = yes;

}

SEGMENTS {
    HEADER:   load = HEADER,          type = ro;
    STARTUP:  load = ROM0,            type = ro,  define = yes;
    LOWCODE:  load = ROM0,            type = ro,                optional = yes;
    INIT:     load = ROM0,            type = ro,  define = yes, optional = yes;
    CODE:     load = ROM0,            type = ro,  define = yes;
    RODATA:   load = ROM0,            type = ro,  define = yes;
    DATA:     load = ROM0, run = RAM, type = rw,  define = yes;
    VECTORS:  load = ROMV,            type = rw;
    CHARS:    load = ROM2,            type = rw;
    BSS:      load = RAM,             type = bss, define = yes;
    HEAP:     load = RAM,             type = bss, optional = yes;
    ZEROPAGE: load = ZP,              type = zp;
}

FEATURES {
    CONDES: segment = INIT,
	    type = constructor,
	    label = __CONSTRUCTOR_TABLE__,
	    count = __CONSTRUCTOR_COUNT__;
    CONDES: segment = RODATA,
	    type = destructor,
	    label = __DESTRUCTOR_TABLE__,
	    count = __DESTRUCTOR_COUNT__;
    CONDES: type = interruptor,
	    segment = RODATA,
	    label = __INTERRUPTOR_TABLE__,
	    count = __INTERRUPTOR_COUNT__;
}

SYMBOLS {
    __STACKSIZE__ = $0300;  	# 3 pages stack
}
````