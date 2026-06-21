    .global initGame
    .global initZeropage
    .global gameLogic
    .global gameGraphics

.section "bss"

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
    .word 0xFFFF2121	//blue - wall
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
    .word 0xFF00FF00	//GREEN (UNUSED)

    .equ RANDOMENABLE, 	0x3F104000
    .equ RANDOMSTATUS, 	0x3F104004
    .equ RANDOMDATA, 	0x3F104008
    .equ RANDOMINTMASK,	0x3F104010

.section .text

initGame: // initialize game here
//  initPACASM(backgroundScreen, worldROM);
//  copy worldROM to backgroundScreen
	LDR X10, =backgroundScreen
	LDR X1, =worldROM
//  STARTUP RANDOM NUMBER GENERATOR
    MOV W4, #0
    LDR X5, =RANDOMENABLE
//  ENABLE RNG
    STR W4, [X5]
    LDR X5, =RANDOMSTATUS 
//  CLEAR ANY EXISTING STATUS/ERROR BITS
    MOV W4, #0
    STR W4, [X5]
    MOV W4, #0x40000
    LDR X5, =RANDOMINTMASK
//  WARM UP FOR THAT MANY CYCLES
    STR W4, [X5]
//  DATA MEMORY BARRIER TO ENSURE ORDER
    DMB ISH
    MOV W4, #1
    LDR X5, =RANDOMENABLE
    STR W4, [X5]  	// ENABLE RNG

//  quick loop to copy data to ZEROPAGE
    MOV X3, #64512
copyLoop:
	ldrb w2, [X1], #1
	strb w2, [X10], #1
	subs x3, x3, #1
	bne copyLoop

// end of initialization
    ret

initZeropage: // boring zeropage stuff here
    
    ret


random_bag: // hello world
    ret
