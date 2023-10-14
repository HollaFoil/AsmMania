# AsmMania
A Mania-type rhythm game made in assembly (WIP). AsmMania is built for Manjaro (free open-source Linux distribution), utilizing only the X Window System (X11) and ALSA (Advanced Linux Sound Architecture). In theory, it is likely that this code will also run on most other Linux systems.

To control, simply use the EFJI or DFJK keys for lanes 1, 2, 3, 4.

# Compile
To compile, simply use gcc and run the following command:

`gcc -no-pie AsmMania.s time.s window.s render.s -lasound -lX11 -o AsmMania`

This will create the executable named `AsmMania`

