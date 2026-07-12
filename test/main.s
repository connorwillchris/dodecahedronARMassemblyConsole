.global _start

.equ GPIO_BASE, 0x3f200000
.equ GPFSEL2, 0x8
.equ GPIO_21_OUTPUT, 0x8 // 1 << 3
.equ GPFSET0, 0x1c
.equ GPFCLR0, 0x28
.equ GPIOVAL, 0x200000 // 1 << 21


//.text
_start:
//	base of our GPIO structure
	ldr x0, =GPIO_BASE

//	set the GPIO 21 function as output
	ldr x1, =GPIO_21_OUTPUT
	str x1, [x0, #GPFSEL2]

//	set counter
	ldr x2, =0x800000

loop:
//	turn on the LED
	ldr x1, =GPIOVAL
	str x1, [x0, #GPFSET0]

//	wait for some time delay
	eor x10, x10, x10
delay1:
	add x10, x10, #1
	cmp x10, x2
	bne delay1

	ldr x1, =GPIOVAL
	str x1, [x0, #GPFCLR0]
	eor x10, x10, x10
delay2:
	add x10, x10, #1
	cmp x10, x2
	bne delay2

	b loop
