nasm -f win64 DimasPrintf.asm -o DimasPrintf.o
gcc -c main.cpp
gcc main.o DimasPrintf.o -static -o DimasPrintf.exe