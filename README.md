# The Nerdy Nights ca65 Translation

[Nerdy Nights](https://nerdy-nights.nes.science/) is a series by Brian Parker (aka BunnyBoy) of tutorials on programming homebrew games from scratch for the NES using assmebly. It walks through basic concepts in 9 lessons such as 16-bit maths and controller inputs, and there are further resources on the site available for learning about sound on the NES as well as Bank Switching, however these have not been translated to ca65 yet in this repo.

## What is the point of this repo?

The original Nerdy Nights tutorials were all written using the NESASM assembler, however some people (me included) prefer using the ca65 macro assembler - part of the [cc65 compiler](https://cc65.github.io/). There aren't too many things different between the 2 assemblers, however there are definitely a few key syntatical differences, like having different directives (e.g. using `.byte` instead of `.db`), or different inbuilt functions and how they are written (e.g. `LDA #HIGH(background)` is perfectly fine in NESASM to get the high byte, but in ca65 it would be written as `LDA #>background`).

Primarily, the main difference is that ca65 uses a linker to place code at specific address, instead of th `.org` statements used in NESASM. The linker uses different **segments** to seprate code. the `ld65` command is run with `-t nes` to create polayable .nes files. The linker uses the `nes.cfg` config file bundled with cc65 to generate usable `.nes` files.
**TLDR: The original tutorial was written for a different assembler than what I used**

## Getting Started

I recommend watching [this video](https://www.youtube.com/watch?v=JgdcGcJga4w&list=PL29OkqO3wUxzOmjc0VKcdiNPqwliHEuEk) to get cc65/ca65 setup properly.

To generate a playable .nes file, you need to create a `.bat` file. The code for that file is:

```` batch
ca65 FILENAME.asm -o FILENAME.o --debug-info
ld65 FILENAME.o -o FILENAME.nes -t nes --dbgfile FILENAME.dbg
````

This will generate 3 files: a `.o` file for the linker to use, a `.nes` file which is the playable file with emulators, and a `.dbg` file.

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
