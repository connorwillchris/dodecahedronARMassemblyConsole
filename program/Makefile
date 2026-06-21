MAKEFLAGS += --silent

GCCPATH=/home/connor/opt/cross/bin

default:
	$(GCCPATH)/aarch64-none-elf-as main.s graphics.s pac.s -o pacman.o -mcpu=cortex-a72
	$(GCCPATH)/aarch64-none-elf-ld pacman.o -o kernel.elf -T link.ld
	$(GCCPATH)/aarch64-none-elf-objcopy kernel.elf -O binary kernel8.img
	@echo "kernel8.img compiled"
	$(MAKE) clean

clean:
	rm pacman.o
	rm kernel.elf
