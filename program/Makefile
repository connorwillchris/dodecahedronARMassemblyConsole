MAKEFLAGS += --silent

#-verbose on 2nd compilation line to see default linker
GCCPATH = /mnt/c/ARCHIVE/inkboxSoftware/projects/rpiConsole/program/ARMGNU/gcc-arm/bin

default:
	$(GCCPATH)/aarch64-none-elf-as main.s graphics.s pac.s -o pacman.o -mcpu=cortex-a53 
	$(GCCPATH)/aarch64-none-elf-ld pacman.o -o kernel.elf -T link.ld
	$(GCCPATH)/aarch64-none-elf-objcopy kernel.elf -O binary kernel8.img
	@echo "\tkernel8.img compiled"
	$(MAKE) clean
	
clean:
	rm pacman.o
	rm kernel.elf
	