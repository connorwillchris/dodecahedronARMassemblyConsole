// boilerplate main file

.section ".text.boot"
.global _start
.global _bss_start
.global _bss_size

_start:
    // STARTUP SECTION - PARK OTHER CORES
    mrs x1, MPIDR_EL1
    and x1, x1, #0xff
    cbz x1, onMainCore
1: // the secondary core loop
    wfe
    b 1b // the secondary core loop
    mrs x1, MPIDR_EL1 // get core id
    and x1, x1, #0x03
    mov x5, #0x8
    mul x2, x1, x5
    add x2, x2, #0xe0
    ldr x3, [x2]
    dmb ish
    cbz x3, 1b
    //dmb ish
    cbz x2, 1b
    mov x4, xzr
    str x4, [x2]
    b 1b
runCore1:
    mov x1, 0x78000
    mov sp, x1
    bl drawPILogo
1:
    b 1b

// TODO: Later
onMainCore:

drawPILogo:
	//LOAD FRAME BUFFER ADDRESS
	LDR X10, =FB
	LDR X10, [X10]
	
	LDR X1, =PILOGO		//GET ADDRESS OF PILOGO DATA
	LDR X2, =0x5DC00	//800x480 (ENTIRE SCREEN BUFFER)
	MOV X4, XZR
DRAWLOGO:
	LDR W3, [X1, X4]
	STR W3, [X10, X4]
	ADD X4, X4, #04
	SUBS X2, X2, #01
	BGT DRAWLOGO
	RET