cd ./output/windows
nasm -fwin32 ../../src/main.asm -o main.obj
nasm -fwin32 ../../src/instructions.asm -o instructions.obj
nasm -fwin32 ../../src/parser.asm -o parser.obj