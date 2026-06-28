GCCPATH=/home/connor/opt/cross/bin

DOIT=1

AS=$(GCCPATH)/aarch64-none-elf-as
LD=$(GCCPATH)/aarch64-none-elf-ld

default: tetris/tetris.s
	$(AS) main.s graphics.s api.s tetris/tetris.s -o tetris.o -mcpu=cortex-a72
	$(LD) tetris.o -o kernel.elf -T link.ld
	$(GCCPATH)/aarch64-none-elf-objcopy kernel.elf -O binary kernel8.img
	@echo "kernel8.img compiled"
