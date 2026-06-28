	.global initGame
    .global initZeropage
    .global gameLogic
    .global gameGraphics

.section "bss"
	BUTTONSTATUS:	.fill 16, 1, 0   //REPEAT 4 TIMES, SIZE 1 BYTE, VALUE 0
    LIFE:           .fill 1, 4, 0
    gameExportScreen: 	.FILL 64512, 1, 0	//final screen delivered to renderer
	zeroPage:			.FILL 1024, 1, 0	//256*4

.section .rodata // TODO: replace this code with my own map and CHR data
    .align 4
charROM:
    .INCBIN "resource/charROM.bin"		//20480B
worldROM:
    .INCBIN "resource/worldROM.bin"		//224*288=64512B
worldMapROM:
    .INCBIN "resource/worldMapROM.bin"	//[28*31]=868B
COLORPAL:
    .word 0xFF000000	//black
    /*.word 0xFFFF2121	//blue - wall
    .word 0xFF00FFFF	//yellow
    .word 0xFF0000FF	//red
    .word 0xFF00FF00	//green
    .word 0xFF51B7FF	//orange
    .word 0xFF5197DE	//dark orange
    .word 0xFFFFFF00	//teal
    .word 0xFFAEB747	//dark teal
    .word 0xFFFFB7FF	//pink
    .word 0xFFAEB7FF	//dark pink
    .word 0xFFFFDEDE	//gray
    .word 0xFFFFFFFF	//white
    .word 0xFF444444	//INKBOX GRAY
    .word 0xFF00d2ff	//INKBOX YELLOW
    .word 0xFF00FF00	//GREEN (UNUSED)*/

    .equ RANDOMENABLE, 	0x3F104000
    .equ RANDOMSTATUS, 	0x3F104004
    .equ RANDOMDATA, 	0x3F104008
    .equ RANDOMINTMASK,	0x3F104010

.section .text

// initialize game here
initGame:
//  initPACASM(backgroundScreen, worldrOM);
//  copy worldrOM to backgroundScreen
//  STARTUP RANDOM NUMBER GENERATOR
    mov w4, #0
    ldr x5, =RANDOMENABLE
//  ENABLE RNG
    STR w4, [x5]
    ldr x5, =RANDOMSTATUS
//  CLEAR ANY EXISTING STATUS/ERROR BITS
    mov w4, #0
    STR w4, [x5]
    mov w4, #0x40000
    ldr x5, =RANDOMINTMASK
//  WARM UP FOR THAT MANY CYCLES
    STR w4, [x5]
//  DATA MEMORY BARRIER TO ENSURE ORDER
    dmb ish
    mov w4, #1
    ldr x5, =RANDOMENABLE
    str w4, [x5]  	// ENABLE RNG

//  quick loop to copy data to ZEROPAGE
//  mov x3, #64512
/*
copyLoop:
	ldrb w2, [x1], #1
	strb w2, [x10], #1
	subs x3, x3, #1
	bne copyLoop
*/

// end of initialization
    ret

initZeropage: // boring zeropage stuff here
    ret

gameLogic:
    ret

gameGraphics:
    ret

// random bag algorithm
random_bag:
    ret
