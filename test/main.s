.global _start

.equ GPIO_BASE, 0xfe200000 // BCM2711 (Pi 4) GPIO base. 0xfe000000 is the peripheral base, NOT GPIO.... do not use it here
.equ GPFSEL2, 0x8
.equ GPIO_21_OUTPUT, 0x8 // FSEL21 = 001 (output), i.e. 1 << 3
.equ GPFSET0, 0x1c
.equ GPFCLR0, 0x28
.equ GPIOVAL, 0x200000 // 1 << 21

//.text
_start:
//	base of our GPIO structure
ldr x0, =GPIO_BASE

//	set the GPIO 21 function as output
// GPIO regs are 4 bytes; a 64-bit str faults on Device memory
ldr w1, =GPIO_21_OUTPUT
str w1, [x0, #GPFSEL2]

// delay counter x2 stays 64-bit. The GPIO register writes below MUST be 32-bit (w1), not x1
ldr x2, =0x100000 // delay count (bigger = slower blink)

loop:
//	turn on the LED
//	str w1 (32-bit). GPFSET0 is at 0x1c (not 8-byte aligned) so a 64-bit str x1 faults and pin never turns on
ldr w1, =GPIOVAL
str w1, [x0, #GPFSET0]

//	wait for some time delay
eor x10, x10, x10
delay1:
add x10, x10, #1
cmp x10, x2
bne delay1

//	turn off the LED
ldr w1, =GPIOVAL
str w1, [x0, #GPFCLR0]
eor x10, x10, x10
delay2:
add x10, x10, #1
cmp x10, x2
bne delay2


b loop
