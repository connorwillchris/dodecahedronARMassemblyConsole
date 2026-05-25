//export functions:
.global initPACASM
.global initZEROPAGE
.global PACGRAPHICS
.global PACLOGIC

.section "bss"
#[	DATA
.ALIGN 4
	BUTTONSTATUS:	.FILL 16, 1, 0   //REPEAT 4 TIMES, SIZE 1 BYTE, VALUE 0
	LASTBUTTONSTATUS:	.FILL 16, 1, 0
	//.FILL 4, 1, 0   //REPEAT 4 TIMES, SIZE 1 BYTE, VALUE 0
	backgroundScreen: 	.FILL 64512, 1, 0
	gameExportScreen: 	.FILL 64512, 1, 0	//final screen delivered to renderer
	zeroPage:			.FILL 1024, 1, 0	//256*4
	LIFE: .fill 1, 4, 0
	//ZERO PAGE MAP (HEX):
	//0-13:		SPRITE DATA
	//14-377:	MAP AND DOT DATA
	//378-379: 	sprite counter timer, and sprite counter
	//37A-37F: 	sprite animation order
	//380-38F:	whoops, I missed this row
	//390-393: 	random values for ghost movement
	//394:		ghost speed counter
	//395:		ghost eating mode (timer, sets to 255, if 0 is false)
	//396-399:	ghost dead timers
	//39A-39D:	ghost speeds (actually I don't use this)
	//39E:		score

#]

.section .rodata	//READ ONLY DATA
.ALIGN 4
	//BUTTONDOWNSPRITE:	.INCBIN "resource/buttonDown.bin"
	charROM:	.INCBIN "resource/charROM.bin"		//20480B
	worldROM:	.INCBIN "resource/worldROM.bin"		//224*288=64512B
	worldMapROM:.INCBIN "resource/worldMapROM.bin"	//[28*31]=868B
	COLORPAL:
		.WORD 0xFF000000	//black
		.WORD 0xFFFF2121	//blue - wall
		.WORD 0xFF00FFFF	//yellow
		.WORD 0xFF0000FF	//red
		.WORD 0xFF00FF00	//green
		.WORD 0xFF51B7FF	//orange
		.WORD 0xFF5197DE	//dark orange
		.WORD 0xFFFFFF00	//teal
		.WORD 0xFFAEB747	//dark teal
		.WORD 0xFFFFB7FF	//pink
		.WORD 0xFFAEB7FF	//dark pink
		.WORD 0xFFFFDEDE	//gray
		.WORD 0xFFFFFFFF	//white
		.WORD 0xFF444444	//INKBOX GRAY
		.WORD 0xFF00d2ff	//INKBOX YELLOW
		.WORD 0xFF00FF00	//GREEN (UNUSED)
		


.section .text

.EQU RANDOMENABLE, 	0x3F104000
.EQU RANDOMSTATUS, 	0x3F104004
.EQU RANDOMDATA, 	0x3F104008
.EQU RANDOMINTMASK,	0x3F104010

initPACASM:
#[	
	//initPACASM(backgroundScreen, worldROM);
	//copy worldROM to backgroundScreen
	LDR X10, =backgroundScreen
	LDR X1, =worldROM
	
	
	
//STARTUP RANDOM NUMBER GENERATOR
MOV W4, #0
LDR X5, =RANDOMENABLE
STR W4, [X5]	//ENABLE RNG	
LDR X5, =RANDOMSTATUS 
MOV W4, #0		//CLEAR ANY EXISTING STATUS/ERROR BITS
STR W4, [X5]
MOV W4, #0x40000
LDR X5, =RANDOMINTMASK
STR W4, [X5] 	//WARM UP FOR THAT MANY CYCLES
DMB ISH		  	//DATA MEMORY BARRIER TO ENSURE ORDER
MOV W4, #1	
LDR X5, =RANDOMENABLE
STR W4, [X5]  	//ENABLE RNG	
	
	
	
	MOV X3, #64512
	
	copyLoop:
		LDRB w2, [X1], #1
		STRB w2, [X10], #1
		SUBS x3, x3, #1
		BNE copyLoop
	
    RET
#]

initZEROPAGE:
#[
	//initZEROPAGE(zeroPage, worldMapROM)
	LDR X10, =zeroPage
	LDR X1, =worldMapROM
	//INITIALIZE SPRITES AREA AND OTHER DATA
	MOV x7, X10	//keep a fresh copy
	//RESET ALL TO ZERO
	MOV w3, #1024
	mov w2, #0
	zeroloop:
	STRB w2, [X10], #1
	SUBS w3, w3, #1
	BNE zeroloop
	
	mov X10, x7	//get back address
	
	//set sprites:
	#[
	MOV w2, #0x03	//pac-man sprite#
		STRB w2, [X10], #1
	MOV w2, #104	//pac-man X
		STRB w2, [X10], #1
	MOV w2, #204	//pac-man Y
		STRB w2, [X10], #1
	MOV w2, #00	//pac-man attributes
		STRB w2, [X10], #1
		
	MOV w2, #0x22	//red ghost sprite#
		STRB w2, [X10], #1
	MOV w2, #104	//red ghost X
		STRB w2, [X10], #1
	MOV w2, #108	//red ghost Y
		STRB w2, [X10], #1
	MOV w2, #00	//red ghost attributes
		STRB w2, [X10], #1
		MOV w2, #0x2C	//blue ghost sprite#
		STRB w2, [X10], #1
	MOV w2, #88	//blue ghost X
		STRB w2, [X10], #1
	MOV w2, #132	//blue ghost Y
		STRB w2, [X10], #1
	MOV w2, #00	//blue ghost attributes
		STRB w2, [X10], #1
		MOV w2, #0x37	//pink ghost sprite#
		STRB w2, [X10], #1
	MOV w2, #104	//pink ghost X
		STRB w2, [X10], #1
	MOV w2, #132	//pink ghost Y
		STRB w2, [X10], #1
	MOV w2, #00	//pink ghost attributes
		STRB w2, [X10], #1
		MOV w2, #0x3C	//orange ghost sprite#
		STRB w2, [X10], #1
	MOV w2, #120	//orange ghost X
		STRB w2, [X10], #1
	MOV w2, #132	//orange ghost Y
		STRB w2, [X10], #1
	MOV w2, #00	//orange ghost attributes
		STRB w2, [X10], #1
	#]	
	
	
	//copy dots and walls to zeroPage[20-887]:
	MOV w2, #868
	copydots:
		LDRB w3, [x1], #1
		STRB w3, [X10], #1
		SUBS w2, w2, #1
		BNE copydots
		

	MOV w2, WZR	
	STRB w2, [X10], #1	//sprite frame counter counter
	STRB w2, [X10], #1	//sprite frame counter
	//left
	MOV w2, #0x11
	STRB w2, [X10], #1
	MOV w2, #0x04
	STRB w2, [X10], #1
	MOV w2, #0x11
	STRB w2, [X10], #1
	MOV w2, #0x10
	STRB w2, [X10], #1
	//right
	MOV w2, #0x03
	STRB w2, [X10], #1
	MOV w2, #0x04
	STRB w2, [X10], #1
	MOV w2, #0x03
	STRB w2, [X10], #1
	MOV w2, #0x02
	STRB w2, [X10], #1
	//up
	MOV w2, #0x13
	STRB w2, [X10], #1
	MOV w2, #0x04
	STRB w2, [X10], #1
	MOV w2, #0x13
	STRB w2, [X10], #1
	MOV w2, #0x12
	STRB w2, [X10], #1
	//down
	MOV w2, #0x15
	STRB w2, [X10], #1
	MOV w2, #0x04
	STRB w2, [X10], #1
	MOV w2, #0x15
	STRB w2, [X10], #1
	MOV w2, #0x14
	STRB w2, [X10], #1
	
	RET
#]


PACGRAPHICS:
#[
	//PACFRAME(gameExportScreen, backgroundScreen);
	LDR X10, =gameExportScreen
	LDR X1, =backgroundScreen
	
	MOV W5, #64512
	COPYBACKGROUNDLOOP:
		LDP X4, X6, [X1], #16   //LOAD 16 BYTES INTO X4 AND X6
		STP X4, X6, [X10], #16  //STORE 16 BYTES FROM X4 AND X6
		LDP X4, X6, [X1], #16   //REPEAT TO REDUCE BRANCHING CYCLES
		STP X4, X6, [X10], #16  
		LDP X4, X6, [X1], #16   //REPEAT TO REDUCE BRANCHING CYCLES
		STP X4, X6, [X10], #16  
		LDP X4, X6, [X1], #16   //REPEAT TO REDUCE BRANCHING CYCLES
		STP X4, X6, [X10], #16  
		SUBS W5, W5, #64
		BNE COPYBACKGROUNDLOOP

	
	//PACFRAMESPRITES(gameExportScreen, charROM, zeroPage);
	LDR X10, =gameExportScreen
	LDR X1, =charROM
	LDR X2, =zeroPage	
	MOV x12, x2
	ADD x12, x12, #0x395	//ghost eating mode
	//COPY SPRITES 0-5 TO BACKGROUND FROM ZEROPAGE [0-19]
	B DOTSFIRST
	SPRITESSECOND:
	MOV w8, #05		//total number of sprites
	spriteloop:
	//clear registers:
	EOR x3, x3, x3
	EOR x4, x4, x4
	EOR x5, x5, x5
	EOR x6, x6, x6
	//load:
	LDRB w3, [x2], #1	//char#
		CMP w8, #5
		BEQ loadrest
		//check ghost eyes:
		CHECKGHOSTEYES:
			SUB x12, x12, #0x395	//get start of zeroPage
			SUB x11, x2, x12	//get zero page index
			LSR x11, x11, #2	//divide by four to get ghost index
			ADD x12, x12, #0x395
			ADD x11, x11, x12
			LDRB w4, [x11]		//get ghost timer
		CMP w4, #0
		BEQ CHECKGHOSTEATINGMODE
			//else has ghost eyes
			SUB w4, w4, #1
			STRB w4, [x11]
			MOV w3, #0x40
			B loadrest
		//check if ghost eating mode:
	CHECKGHOSTEATINGMODE:
		LDRB w4, [x12]
		CMP w4, #0
		BEQ loadrest
			//change sprites of ghost to 1C + offset
			AND w3, w3, #1
			CMP w4, #40
			BGE setGhostBasicSprite
			ADD w3, w3, #0x1E
			B loadrest
			setGhostBasicSprite:
			ADD w3, w3, #0x1C
			B loadrest
	loadrest:
	LDRB w4, [x2], #1	//X
	LDRB w5, [x2], #1	//Y
	LDRB w6, [x2], #1	//ATTR
		CMP w8, #5
		BNE DRAWCHARFROMROM
		CMP w6, #8
		BLT DRAWCHARFROMROM
		MOV w8, #01	//only draw pacman if dead
	DRAWCHARFROMROM:	//gameExportScreen in X10, chrROM x1, zeroPage x2
						//chr#, X, Y, attr {x3-6}
					//[X10-x6]
	//;CALCUATE NEW POSITION IN CHARROM
	LSL x3, x3, #8	//multiply by CHAR size (256B per character)
	ADD x3, X3, x1	//sprite location stored in x3
	//;CALCULATE POSITION IN GRID
	MOV x7, #224	//tmp used
	MUL x5, x5, x7	//multipy Y by game width
	ADD x4, x4, x5	//add X value
	ADD x4, x4, X10	//location stored in x4
	//;WRITE 16 BYTES TO GRID, (SKIP BLACK)
	MOV w5, #16
	COPYCHARGREATERLOOP:
		MOV w6, #16
	COPYCHARACTER:
		LDRB w7, [x3], #1
		CMP w7, #0
		BEQ zeroskipChr
		STRB w7, [x4], #1
		B afterCHR
		zeroskipChr:
			ADD x4, x4, #1
		afterCHR:
		SUBS w6, w6, #1
		BNE COPYCHARACTER
	//;INCREASE LOCATION BY 208 (224-16)
		ADD x4, x4, #208
		SUBS w5, w5, #1
		BNE COPYCHARGREATERLOOP
	SUBS w8, w8, #1
	BNE spriteloop
	
	RET	//I WROTE THIS BACKWARDS, BUT OH WELL
	
	DOTSFIRST:
	ADD x2, x2, #20
	//add dots to screen:
		//walls and dots: zeroPage[20-947] (current index)
		//go through and if is 2, then add a dot sprite at that location
	EOR x3, x3, x3
	EOR x4, x4, x4
	EOR x5, x5, x5
	EOR x6, x6, x6
	//init X and Y:
	MOV w8, #868
		MOV w4, #0	//X
		MOV w5, #24	//Y
	drawdotloop:
		LDRB w6, [x2], #1
		CMP w6, #02	//is dot?
		BNE CHECKBIGDOT
			MOV x3,	#0x4400
			B ADDTOCHARROMLOCATION
		CHECKBIGDOT:
		CMP w6, #03	//is big dot?
		BNE NEXTDOTLOOP
			MOV x3,	#0x4500
	//get char rom location
		ADDTOCHARROMLOCATION:
		ADD x3, x3, x1	//char rom location in x3
	//CALCULATE POSITION IN GRID
	MOV x7, #224
	MUL x7, x5, x7	//multipy Y by game width
	ADD x7, x4, x7	//add X value
	ADD x7, x7, X10	//location stored in x7
	//WRITE 16 BYTES TO GRID, (SKIP BLACK)
	MOV W20, #16
	copydotLine:
		MOV w6, #16
	copydotPixel:
		LDRB w9, [x3], #1
		CMP w9, #0
		BEQ zeroskipdot
		STRB w9, [x7], #1
		B afterdot
		zeroskipdot:
			ADD x7, x7, #1
		afterdot:
		SUBS w6, w6, #1
		BNE copydotPixel
	//;INCREASE LOCATION BY 208 (224-16)
		ADD x7, x7, #208
		SUBS W20, W20, #1
		BNE copydotLine
	
	NEXTDOTLOOP:
		ADD w4, w4, #8
		CMP w4, #232
		BNE nextDOTLoopCheck
			MOV w4, #8
			ADD w5, w5, #8
		nextDOTLoopCheck:
		SUBS w8, w8, #1
		BNE drawdotloop
		
	SUB x2, x2, #888
	B SPRITESSECOND
#]

PACLOGIC:
#[	PER FRAME LOGIC
	//PACLOGIC(zeroPage, joyStick)
	LDR X10, =zeroPage
	MOV x2, X10	//keep a fresh copy of pointer
	//MOVING PAC-MAN (direction stored in 4th attribute byte : 0l, 1r, 3u, 7d (1 minus joystick direction)
	
	//check score:
	MOV X10, x2		//reset zeroPage
	ADD X10, X10, #0x39E
	LDRB w3, [X10]
	CMP w3, #240
	BLT AFTERSCORECHECK
		//else game is over:
		B ENDPACLOGIC
	AFTERSCORECHECK:
	
	

	#[	MOVE PAC-MAN
	//reduce ghost eating mode:
	MOV X10, x2		//reset zeroPage
	ADD X10, X10, #0x395
	LDRB w3, [X10]
	CMP w3, #0
	BEQ PACMANMOVESECTION
		SUB w3, w3, #1
		STRB w3, [X10]
	PACMANMOVESECTION:
	MOV X10, x2
	ADD X10, X10, #3
	LDRB w3, [X10]
	CMP w3, #8
	BGE PACimation
	MOV X10, x2
	
	//check if exactly at square:
	ADD X10, X10, #1
	LDRB w3, [X10], #1	//getX
		ADD w3, w3, #4	//add X offset
	LDRB w4, [X10], #1	//getY
		SUB w4, w4, #20	//subtract Y offset
	LDRB w6, [X10]		//get direction (attr)
	MOV w8, w6
		//see if ends with 000
		AND w5, w3, #0x000000F8
		CMP w3, w5
		BNE MOVEPACMAN	//not on a perfect square
		AND w5, w4, #0x000000F8
		CMP w4, w5
		BNE MOVEPACMAN	//not a perfect square
	//if you got this far you can check movement now:
	//read joyStick to get new direction
	MOV w6, w1
		CMP w6, #0		//no new direction
		BEQ LOADJOYDIR
		SUB w6, w6, #1
		LDRB w8, [X10]	//load old direction
		STRB w6, [X10]	//store new direction
	LOADJOYDIR:
	LDRB w6, [X10]		//get direction (attr)
	//check if run into wall------------------
		//get currentPosition in Grid
		LSR w3, w3, #3
		LSR w4, w4, #3
		EOR x5, x5, x5		//clear x5
		MOV w5, #28
		MUL w5, w5, w4
		ADD w5, w5, w3	//grid index is now in w5
	MOV X10, x2		//restore zeroPage
	ADD X10, X10, #20	//get to map
	CMP w6, #0
	BNE CHECKRIGHTDIR
	CHECKLEFTDIR:
		//going left, check wall to left:
		SUB w5, w5, #1	//check wall to left
		B FINISHWALLCHECK
	CHECKRIGHTDIR:
	CMP w6, #1
	BNE CHECKUPDIR
		//going to right, check wall to right
		ADD w5, w5, #1
		B FINISHWALLCHECK
	CHECKUPDIR:
	CMP w6, #3
	BNE CHECKDOWNDIR
		//going up, check wall above
		SUB w5, w5, #28
		B FINISHWALLCHECK
	CHECKDOWNDIR:
	CMP w6, #7
	BNE ENDMOVEPACMAN
		//going down, check wall below
		ADD w5, w5, #28
	FINISHWALLCHECK:
		ADD X10, X10, x5	//get index
		LDRB w7, [X10]	//check
		CMP w7, #1		//is wall?
		BEQ REVERTDIRECTION//STOP MOVING
		CMP w7, #2		//is dot?
		BNE AFTERDOTCHECK
			//eat dot:
			MOV w7, #0
			STRB w7, [X10]
			//increase score
			MOV X20, x2		//get zeroPage
			ADD X20, X20, #0x39E
			LDRB w7, [X20]
			ADD w7, w7, #1
			STRB w7, [X20]
			B MOVEPACMAN
		AFTERDOTCHECK:
		CMP w7, #3		//is big dot?
		BNE AFTERBIGDOTCHECK
			//eat big dot:
			MOV w7, #0
			STRB w7, [X10]
			//set ghost eating mode
			MOV w7, #255
			MOV X10, x2
			ADD X10, X10, #0x395
			STRB w7, [X10]
		AFTERBIGDOTCHECK:
		B MOVEPACMAN
	REVERTDIRECTION:
		CMP w8, w6
		BEQ BLOCKED
		MOV X10, x2		//reset zeroPage
		ADD X10, X10, #1	//get X3
		LDRB w3, [X10], #1	//getX
			ADD w3, w3, #4	//add X offset
		LDRB w4, [X10], #1	//getY
			SUB w4, w4, #20	//subtract Y offset
		STRB w8, [X10]
		B LOADJOYDIR
	BLOCKED:
		//move animation to base 0
		MOV X10, x2
		LDRB w3, [X10]
		CMP w3, #04
		BEQ eBlocked
		ORR w3, w3, #1
		STRB w3, [X10]
		eBlocked:
		B ENDMOVEPACMAN

	MOVEPACMAN:
	MOV X10, x2			//reset zeroPage
	EOR x4, x4, x4
		CMP w6, #0
		BEQ MOVELEFT
		CMP w6, #01
		BEQ MOVERIGHT
		CMP w6, #03
		BEQ MOVEUP
		CMP w6, #07
		BEQ MOVEDOWN
		//else:
		B ENDMOVEPACMAN	//should never branch here but just in case
	MOVELEFT:
		ADD X10, X10, #1		//get X value of PAC-MAN
		LDRB w3, [X10]		//X in w3
		SUB w3, w3, #1
		AND w3, w3, #0xFF
		CMP w3, #255
		BNE leftLater
			MOV w3, #223
		leftLater:
		STRB w3, [X10]
		//SPRITE CYCLE:
		MOV w4, #0
		B PACimation
	MOVERIGHT:
		ADD X10, X10, #1		//get X value of PAC-MAN
		LDRB w3, [X10]		//X in w3
		ADD w3, w3, #1
		CMP w3, #212
		BNE rightLater
			MOV w3, #0
		rightLater:
		STRB w3, [X10]
		//SPRITE CYCLE:
		MOV w4, #4
		B PACimation
	MOVEUP:
		ADD X10, X10, #2		//get Y value of PAC-MAN
		LDRB w3, [X10]
		SUB w3, w3, #1
		STRB w3, [X10]
		//SPRITE CYCLE:
		MOV w4, #8
		B PACimation
	MOVEDOWN:
		ADD X10, X10, #2		//get Y value of PAC-MAN
		LDRB w3, [X10]
		ADD w3, w3, #1
		STRB w3, [X10]
		//SPRITE CYCLE:
		MOV w4, #12
	PACimation:
		MOV X10, x2		//reset zeroPage
		ADD X10, X10, #0x0378	//sprite counter counter
		EOR x3, x3, x3	//clear
		LDRB w3, [X10]
			ADD w3, w3, #1
			AND w3, w3, #3
			STRB w3, [X10], #1
			CMP w3, #0
			BNE endPacimation
				//check if dead:
				MOV x5, X10
				MOV X10, x2	//reset zeroPage
				ADD X10, X10, #3	//direction
				LDRB w3, [X10]
					CMP w3, #8
					BLT NORMALPACmation
					CMP w3, #20
					BEQ ENDMOVEPACMAN
					ADD w3, w3, #01
					STRB w3, [X10], #-3
					SUB w3, w3, #5
					STRB w3, [X10]
					ADD w3, w3, #5
					CMP w3, #20
					BEQ DEADPAC
					B ENDMOVEPACMAN
					
		NORMALPACmation:
		MOV X10, x5
		LDRB w3, [X10]
		ADD w3, w3, #1
		AND w3, w3, #3	//up to 3
		STRB w3, [X10], #1
		ADD X10, X10, x3
		ADD X10, X10, x4	//add track offset
		LDRB w3, [X10]
		MOV X10, x2
		STRB w3, [X10]
		endPacimation:
		B ENDMOVEPACMAN
		DEADPAC:
			//reset here later
	ENDMOVEPACMAN:
	#]
	
	//moving ghosts:
	//there are certain rules with ghosts, those are ignored for now
	//when ghost reaches perfect square change to random direction
	//with code below it doesn't matter if they can't go that direction
	//	they'll revert back to former direction
	GHOSTSECTION:
	#[
	MOV X10, x2			//reset zeroPage
	ADD X10, X10, #0x394	//ghost speed timer
	LDRB w3, [X10]
	ADD w3, w3, #1
	STRB w3, [X10], #1
		//check ghost eating mode:
		LDRB w4, [X10], #-1
		CMP w4, #0
		BEQ normalGhostSpeed
			//slow ghost speed
			CMP w3, #02
			BLT GOGOGHOSTS
			B GHOSTFRAMESKIP
	normalGhostSpeed:
	CMP w3, #04
	BNE GOGOGHOSTS
		GHOSTFRAMESKIP:
		//else skip this frame
		MOV w3, #0
		STRB w3, [X10]
		B AFTERGHOSTSECTION
	
	GOGOGHOSTS:
	
	//SET RANDOM GHOST DIRECTION
	MOV X10, X2		//RESET ZERO PAGE
	MOV X23, #04
	LDR X24, =RANDOMSTATUS
	LDR X25, =RANDOMDATA
	SETGHOSTRANDOMDIR:
		WAITRANDOMAVAILABLE:
		LDR W26, [X24]     			//READ STATUS
		LSR W26, W26, #24         	//CHECK COUNT > 0
		CBZ W26, WAITRANDOMAVAILABLE //NO DATA IF 0
		
		LDR W20, [X25]
		AND X20, X20, #0x03
		MOV X21, #1
		LSL X21, X21, X20
		STRB W21, [X10, #0x390]
		ADD X10, X10, #1
		SUBS X23, X23, #1
		BNE SETGHOSTRANDOMDIR
		
		
	EOR X20, X20, X20
	MOV W20, #4
	GHOSTLOOP:	
	MOV X10, x2			//reset zeroPage
	ADD X10, X10, X20		//get GHOST index
	//check if exactly at square:	
	ADD X10, X10, #1
	LDRB w3, [X10], #1	//getX
		ADD w3, w3, #4	//add X offset
	LDRB w4, [X10], #1	//getY
		SUB w4, w4, #20	//subtract Y offset
	LDRB w6, [X10]		//get direction (attr)
	MOV w8, w6		
		//see if ends with 000
		AND w5, w3, #0x000000F8
		CMP w3, w5
		BNE MOVEGHOST	//not on a perfect square
		AND w5, w4, #0x000000F8
		CMP w4, w5
		BNE MOVEGHOST	//not a perfect square
	//if you got this far you can get a new random direction now:
		MOV X10, x2			//reset zeroPage
		ADD X10, X10, #0x390
			EOR x6, x6, x6	//clear x6
			MOV w6, W20		//copy W20 (index)
			LSR w6, w6, #3	//divide by 8
			ADD X10, X10, x6	//add index offset of random
		LDRB w6, [X10]
		MOV X10, x2			//reset zeroPage
		ADD X10, X10, X20
		ADD X10, X10, #3
			CMP w6, #0		//no new direction
			BEQ GHOSTLOADJOYDIR
			CMP w6, #8
			//BGT GHOSTLOADJOYDIR
			SUB w6, w6, #1
			LDRB w8, [X10]	//load old direction
				//make sure is not opposite of old direction:
					EOR w9, w8, w6
					AND w9, w9, #02
					CMP w9, #02
					BNE GHOSTLOADJOYDIR	//not opposite left/right
					//EOR w9, w8, w6
					//CMP w9, #4
					//BEQ GHOSTLOADJOYDIR	//not opposite up/down (actually top formula should cover both)
			storeghost:
			STRB w6, [X10]	//store new direction
		GHOSTLOADJOYDIR:
		LDRB w6, [X10]		//get direction (attr)
		
	//check if run into wall------------------
		//get currentPosition in Grid
		LSR w3, w3, #3
		LSR w4, w4, #3
		EOR x5, x5, x5		//clear x5
		MOV w5, #28
		MUL w5, w5, w4
		ADD w5, w5, w3	//grid index is now in w5
		CMP w5, #393
		BNE GHOSTCHECKER2
			//set to go back right
			MOV w6, #1
			STRB w6, [X10]	//store new direction
			B MOVEGHOST
		GHOSTCHECKER2:
		CMP w5, #418
		BNE RUNGHOSTWALLCHECK
			//set to go back left
			MOV w6, #0
			STRB w6, [X10]	//store new direction
			B MOVEGHOST
	RUNGHOSTWALLCHECK:
	MOV X10, x2		//restore zeroPage
	ADD X10, X10, #20	//get to map
	CMP w6, #0
	BNE GHOSTCHECKRIGHTDIR
	GHOSTCHECKLEFTDIR:
		//going left, check wall to left:
		SUB w5, w5, #1	//check wall to left
		B GHOSTFINISHWALLCHECK
	GHOSTCHECKRIGHTDIR:
	CMP w6, #1
	BNE GHOSTCHECKUPDIR
		//going to right, check wall to right
		ADD w5, w5, #1
		B GHOSTFINISHWALLCHECK
	GHOSTCHECKUPDIR:
	CMP w6, #3
	BNE GHOSTCHECKDOWNDIR
		//going up, check wall above
		SUB w5, w5, #28
		B GHOSTFINISHWALLCHECK
	GHOSTCHECKDOWNDIR:
	CMP w6, #7
	BNE ENDMOVEGHOST
		//going down, check wall below
		ADD w5, w5, #28
	GHOSTFINISHWALLCHECK:
		ADD X10, X10, x5	//get index
		LDRB w7, [X10]	//check
		CMP w7, #1		//is wall?
		BEQ GHOSTREVERTDIRECTION//STOP MOVING
		B MOVEGHOST
	GHOSTREVERTDIRECTION:
		CMP w8, w6
		BEQ ENDMOVEGHOST
		MOV X10, x2		//reset zeroPage
		ADD X10, X10, X20		//get GHOST index
		ADD X10, X10, #1	//get X3
		LDRB w3, [X10], #1	//getX
			ADD w3, w3, #4	//add X offset
		LDRB w4, [X10], #1	//getY
			SUB w4, w4, #20	//subtract Y offset
		STRB w8, [X10]
		B GHOSTLOADJOYDIR

	MOVEGHOST:	
	MOV X10, x2			//reset zeroPage
	ADD X10, X10, X20		//get GHOST index
	EOR x4, x4, x4
		CMP w6, #0
		BEQ GHOSTMOVELEFT
		CMP w6, #01
		BEQ GHOSTMOVERIGHT
		CMP w6, #03
		BEQ GHOSTMOVEUP
		CMP w6, #07
		BEQ GHOSTMOVEDOWN
		//else:
		B ENDMOVEGHOST	//should never branch here but just in case
	GHOSTMOVELEFT:
		//set sprite
		LDRB w3, [X10]
		MOV w4, #0xF9
		AND w3, w3, w4
		MOV w4, #0x02
		ORR w3, w3, w4
		STRB w3, [X10]
		//move
		ADD X10, X10, #1		//get X value of PAC-MAN
		LDRB w3, [X10]		//X in w3
		SUB w3, w3, #1
		STRB w3, [X10]
		//SPRITE CYCLE:
		MOV w4, #0
		B GHOSTimation
	GHOSTMOVERIGHT:
		//set sprite
		LDRB w3, [X10]
		MOV w4, #0xF9
		AND w3, w3, w4
		STRB w3, [X10]
		//move
		ADD X10, X10, #1		//get X value of PAC-MAN
		LDRB w3, [X10]		//X in w3
		ADD w3, w3, #1
		STRB w3, [X10]
		//SPRITE CYCLE:
		MOV w4, #4
		B GHOSTimation
	GHOSTMOVEUP:
		//set sprite
		LDRB w3, [X10]
		MOV w4, #0xF9
		AND w3, w3, w4
		MOV w4, #0x04
		ORR w3, w3, w4
		STRB w3, [X10]
		//move
		ADD X10, X10, #2		//get Y value of PAC-MAN
		LDRB w3, [X10]
		SUB w3, w3, #1
		STRB w3, [X10]
		//SPRITE CYCLE:
		MOV w4, #8
		B GHOSTimation
	GHOSTMOVEDOWN:
		//set sprite
		LDRB w3, [X10]
		MOV w4, #0xF9
		AND w3, w3, w4
		MOV w4, #0x06
		ORR w3, w3, w4
		STRB w3, [X10]
		//move
		ADD X10, X10, #2		//get Y value of PAC-MAN
		LDRB w3, [X10]
		ADD w3, w3, #1
		STRB w3, [X10]
		//SPRITE CYCLE:
		MOV w4, #12
	GHOSTimation:
		MOV X10, x2		//reset zeroPage
		ADD X10, X10, #0x0378	//sprite counter counter
		LDRB w3, [X10]
		CMP w3, #1
		BNE enGHOSTimation
			//change ghost animation
			MOV X10, x2
			ADD X10, X10, X20
			LDRB w3, [X10]
			EOR w3, w3, #1
			STRB w3, [X10]
		enGHOSTimation:
	ENDMOVEGHOST:
		ADD W20, W20, #4
		CMP W20, #20
		BNE GHOSTLOOP
	#]
	AFTERGHOSTSECTION:
	
	//PAC-MAN GHOST COLLISION:
	#[
	MOV X10, x2			//reset zeroPage
	ADD X10, X10, #01		//get X of PAC-MAN
	LDRB w3, [X10], #1	//getX
		ADD w3, w3, #1
	LDRB w4, [X10], #1	//getY
		ADD w4, w4, #1
		//check if already dead お前はもう死んでいる
		LDRB w5, [X10]
		CMP w5, #8
		BGE AFTERGHOSTCOLLISION
	EOR X20, X20, X20	//clear X20
	MOV W20, #0			//loop counter
	
	GETGHOSTLOCATION:
		ADD X10, X10, #2	//get to ghost X
		LDRB w5, [X10], #1
			ADD w5, w5, #1
		LDRB w6, [X10], #1
			ADD w6, w6, #1
		//collision formula:
		ADD w7, w3, #13
		CMP w7, w5
		BLT AFTERCOMPAREGHOSTPACLOCATION
		ADD w7, w5, #14
		CMP w7, w3
		BLT AFTERCOMPAREGHOSTPACLOCATION
		ADD w7, w4, #13
		CMP w7, w6
		BLT AFTERCOMPAREGHOSTPACLOCATION
		ADD w7, w6, #14
		CMP w7, w4
		BLT AFTERCOMPAREGHOSTPACLOCATION
		
		B KILLPACMAN
		
		CHECKYDIFF:
		//IF X is the same, test for difference in Y <= 4
		CMP w3, w5
		BNE CHECKXDIFF
			SUB w6, w4, w6
			BPL	posY	//branch if positive
			SUB w6, w6, w4	//reverse subtract
			posY:
				CMP w6, #4
				BLE KILLPACMAN
			B AFTERCOMPAREGHOSTPACLOCATION
		CHECKXDIFF:
		//IF Y is the same, test for difference in X <= 4
		CMP w4, w6
		BNE AFTERCOMPAREGHOSTPACLOCATION
			SUB w5, w3, w5
			BPL posX
			SUB w5, w5, w3
			posX:
				CMP w5, #4
				BLE KILLPACMAN
			B AFTERCOMPAREGHOSTPACLOCATION			
		KILLPACMAN:
		//actually, first check the mode:
		MOV x8, x2
		ADD x8, x8, #0x395
			LDRB w7, [x8], #1	//check ghost eating mode:
			CMP w7, #0
			BEQ ACTUALLYKILLPACMAN
			//else kill ghost: (set sprite, flip direction, set ghost dead timer [0x396-0x399])
			//check if timer is started or not:
			LDRB w7, [x8]
			CMP w7, #0
			BNE AFTERCOMPAREGHOSTPACLOCATION
			//swap direction: 
			LDRB w4, [X10]	//luckily already at direction index
			CMP w4, #3
			BGE swaptop
				//swapbottom:
				EOR w4, w4, #1
				B aswap
			swaptop:
				EOR w4, w4, #4
			aswap:
				STRB w4, [X10]
			//set sprite: set above in sprite drawing section
			//set timer:
			MOV X10, x2		//reset zeroPage
			ADD X10, X10, #0x396
			ADD X10, X10, X20
			MOV w3, #128
			STRB w3, [X10]		
			
			B AFTERGHOSTCOLLISION
		ACTUALLYKILLPACMAN:
		MOV X10, x2		//reset zeroPage
		ADD X10, X10, #3	//get direction
		MOV w3, #8		//null direction
		STRB w3, [X10]	//no movement
		
	AFTERCOMPAREGHOSTPACLOCATION:
	ADD W20, W20, #1
	CMP W20, #4
	BNE GETGHOSTLOCATION
	AFTERGHOSTCOLLISION:
	#]
	
	ENDPACLOGIC:
	RET
#]

testing:

	;PRE-INDEX ADDRESSING
	LDR R0, [R1, #4]!
	;R1 += 4 BEFORE MEMEORY ACCESS
	
	LDR R0, [R1], #4
	;R1 += 4 AFTER MEMORY ACCESS