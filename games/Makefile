
GCCPATH=/home/connor/opt/cross/bin

CC=$(GCCPATH)/aarch64-none-elf-as
LD=$(GCCPATH)/aarch64-none-elf-ld

tetris: tetris/tetris.s
	$(CC) main.s graphics.s tetris/tetris.s -o tetris.o -mcpu=cortex-a72
	$(LD) tetris.o -o kernel.elf -T link.ld
	$(GCCPATH)/aarch64-none-elf-objcopy kernel.elf -O binary kernel8.img
	@echo "kernel8.img compiled"
