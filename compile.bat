cd ./output/console
nasm -D CONSOLE_SYBSYS -fobj ../../src/main.asm -o main.obj
nasm -D CONSOLE_SYBSYS -fobj ../../src/instructions.asm -o instructions.obj
nasm -D CONSOLE_SYBSYS -fobj ../../src/parser.asm -o parser.obj
alink main.obj instructions.obj parser.obj -oPE -subsys console -entry start