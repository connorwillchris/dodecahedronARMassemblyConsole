.global _start

.equ GPIO_BASE, 0x7e200000
.equ GPFSEL2, 0x8
.equ GPIO_21_OUTPUT, 0x8 // 1 << 3
.equ GPFSET0, 0x1c
.equ GPFCLR0, 0x28
.equ GPIOVAL, 0x200000 // 1 << 21

//.text
_start:
//	base of our GPIO structure
	ldr r0, =GPIO_BASE

//	set the GPIO 21 function as output
	ldr r1, =GPIO_21_OUTPUT
	str r1, [r0, #GPFSEL2]


// 	NOTE: Keep at 64 bit version
	ldr r2, =0x80000

loop:
//	turn on the LED
	ldr r1, =GPIOVAL
	str r1, [r0, #GPFSET0]

//	wait for some time delay
	eor r10, r10, r10
delay1:
	add r10, r10, #1
	cmp r10, r2
	bne delay1

	ldr r1, =GPIOVAL
	str r1, [r0, #GPFCLR0]
	eor r10, r10, r10
delay2:
	add r10, r10, #1
	cmp r10, r2
	bne delay2

	b loop
