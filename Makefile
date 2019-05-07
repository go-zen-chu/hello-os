.PHONY: build run 

build:
	nasm boot.asm -f bin -o boot.bin

run:
	qemu-system-i386 -fda boot.bin
