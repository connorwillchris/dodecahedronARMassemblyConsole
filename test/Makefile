
#GCCPATH=/home/connor/opt/cross/bin
GCC_PATH=/bin

default:
	arm-none-eabi-as main.s -o testing.o -march=armv7ve -mcpu=cortex-a72 -mfpu=neon-fp-armv8
	arm-none-eabi-ld testing.o -o kernel.elf
	arm-none-eabi-objcopy kernel.elf -O binary kernel7.img
	@echo "kernel7.img compiled"

clean:
	rm testing.o
	rm kernel.elf
