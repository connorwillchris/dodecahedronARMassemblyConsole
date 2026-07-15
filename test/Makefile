
GCCPATH=/home/connor/opt/cross/bin

default:
	$(GCCPATH)/aarch64-none-elf-as main.s -o testing.o -mcpu=cortex-a72 -mfpu=neon-fp-armv8 -march=armv7ve 
	$(GCCPATH)/aarch64-none-elf-ld testing.o -o kernel.elf
	$(GCCPATH)/aarch64-none-elf-objcopy kernel.elf -O binary kernel7.img
	@echo "kernel7.img compiled"

clean:
	rm testing.o
	rm kernel.elf
