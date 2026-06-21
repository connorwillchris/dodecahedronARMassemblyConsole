.section "bss"
.p2align 12		//align 4096 bytes
	MBOX:	.FILL 40, 4, 0   //REPEAT N TIMES, SIZE M BYTES, VALUE X

.align 4
WIDTH: 	.WORD 0
.align 4	
HEIGHT: .WORD 0
.align 4	
PITCH: 	.WORD 0
.align 4	
ISRGB: 	.WORD 0
.align 4	
FB:		.QUAD 0
	
.section .rodata	//READ ONLY DATA
.ALIGN 4
	PILOGO:	.INCBIN "resource/piLogo.bin"
	
.section ".text.text"
.align 4
.EQU VIDEOCORE_MBOX, (0x3F000000 + 0x0000B880)
.EQU MBOX_READ, 	(VIDEOCORE_MBOX + 0x0)
.EQU MBOX_POLL, 	(VIDEOCORE_MBOX + 0x10)
.EQU MBOX_SENDER, 	(VIDEOCORE_MBOX + 0x14)
.EQU MBOX_STATUS, 	(VIDEOCORE_MBOX + 0x18)
.EQU MBOX_CONFIG, 	(VIDEOCORE_MBOX + 0x1C)
.EQU MBOX_WRITE, 	(VIDEOCORE_MBOX + 0x20)
.EQU MBOX_RESPONSE, 0x80000000
.EQU MBOX_FULL, 	0x80000000
.EQU MBOX_EMPTY, 	0x40000000
.EQU MBOX_REQUEST, 	0
.EQU MBOX_CH_PROP, 	8 // Request from ARM for response by VideoCore
.EQU MBOX_TAG_SETPOWER, 	0x28001
.EQU MBOX_TAG_SETCLKRATE, 	0x38002

.EQU MBOX_TAG_SETPHYWH,   0x48003
.EQU MBOX_TAG_SETVIRTWH,  0x48004
.EQU MBOX_TAG_SETVIRTOFF, 0x48009
.EQU MBOX_TAG_SETDEPTH,   0x48005
.EQU MBOX_TAG_SETPXLORDR, 0x48006
.EQU MBOX_TAG_GETFB,      0x40001
.EQU MBOX_TAG_GETPITCH,   0x40008
.EQU MBOX_TAG_LAST,       0


MAILBOX_CALL:
#[
    // 1. Prepare message r (Address | Channel)
    AND W10, W10, #0xF
    LDR X1, =MBOX
    BIC X1, X1, #0xF
	//ORR X1, X1, #0xC0000000  // Tell GPU to look at the alias addres
    ORR W10, W10, W1

    // 2. Wait until NOT FULL
    LDR X2, =MBOX_STATUS
    LDR W1, =MBOX_FULL

READMAILBOX:
    LDR W3, [X2]
    TST W3, W1
    BNE READMAILBOX

    // 3. Write r
    LDR X2, =MBOX_WRITE
    STR W10, [X2]

    // 4. Wait for and verify reply
    LDR X2, =MBOX_STATUS
    LDR W3, =MBOX_EMPTY

WAITREPLY:
    LDR W1, [X2]
    TST W1, W3      // Is it empty?
    BNE WAITREPLY   // Yes, wait until bit is 0

    // 5. Read message and check if it's ours
    LDR X4, =MBOX_READ
    LDR W1, [X4]
    CMP W10, W1      // Is this the message we sent?
    BNE WAITREPLY   // If not, it's for someone else, keep waiting

    // 6. Final success check (mbox[1])
    LDR X2, =MBOX
    LDR W3, [X2, #4]
    LDR W4, =MBOX_RESPONSE
    CMP W3, W4
    
    // Using CSET to replace the ENDTRUE/FALSE labels
    CSET W1, EQ     // W0 = 1 if W3 == W4, else 0
    RET
#]

FRAMEBUFFERINIT:
#[
	
	//ADRP X0, MBOX       // Get the 4KB page address of MBOX
	//ADD X0, X0, :lo12:MBOX  // Add the lower 12 bits (the offset within that page)
	LDR X10, =MBOX
	MOV X1, #140		//35*4, LENGTH OF MESSAGE IN BYTES 
	STR W1, [X10]		//mbox[0] = 35*4; // Length of message in bytes
	LDR X1, =MBOX_REQUEST
	STR W1, [X10, #4]	//mbox[1] = MBOX_REQUEST;

	LDR X1, =MBOX_TAG_SETPHYWH
	STR W1, [X10, #8]	//mbox[2] = MBOX_TAG_SETPHYWH; // Tag identifier
	MOV X1, #8
	STR W1, [X10, #12]	//mbox[3] = 8; // Value size in bytes
	MOV X1, #0
	STR W1, [X10, #16]	//mbox[4] = 0;
	MOV X1, #800
	STR W1, [X10, #20]	//mbox[5] = 1920; // Value(width)
	MOV X1, #480
	STR W1, [X10, #24]	//mbox[6] = 1080; // Value(height)    

	LDR X1, =MBOX_TAG_SETVIRTWH
	STR W1, [X10, #28]	// mbox[7] = MBOX_TAG_SETVIRTWH;
	MOV X1, #8
	STR W1, [X10, #32]	//mbox[8] = 8;
	MOV X1, #8
	STR W1, [X10, #36]	//mbox[9] = 8;
	MOV X1, #800
	STR W1, [X10, #40]	//mbox[10] = 1920;
	MOV X1, #480
	STR W1, [X10, #44]	//mbox[11] = 1080;
   
    LDR X1, =MBOX_TAG_SETVIRTOFF
	STR W1, [X10, #48]	//mbox[12] = MBOX_TAG_SETVIRTOFF;
	MOV X1, #8
	STR W1, [X10, #52]	//mbox[13] = 8;
	MOV X1, #8
	STR W1, [X10, #56]	//mbox[14] = 8;
	MOV X1, #0
	STR W1, [X10, #60]	//mbox[15] = 0; // Value(x)
	MOV X1, #0
	STR W1, [X10, #64]	//mbox[16] = 0; // Value(y)
	
    LDR X1, =MBOX_TAG_SETDEPTH
	STR W1, [X10, #68]	//mbox[17] = MBOX_TAG_SETDEPTH;
	MOV X1, #4
	STR W1, [X10, #72]	//mbox[18] = 4;
	MOV X1, #4
	STR W1, [X10, #76]	//mbox[19] = 4;
	MOV X1, #32
	STR W1, [X10, #80]	//mbox[20] = 32; // Bits per pixel

    LDR X1, =MBOX_TAG_SETPXLORDR
	STR W1, [X10, #84]	//mbox[21] = MBOX_TAG_SETPXLORDR;
	MOV X1, #4
	STR W1, [X10, #88]	//mbox[22] = 4;
	MOV X1, #4
	STR W1, [X10, #92]	//mbox[23] = 4;
	MOV X1, #1
	STR W1, [X10, #96]	//mbox[24] = 1; // RGB
    
    LDR X1, =MBOX_TAG_GETFB
	STR W1, [X10, #100]	//mbox[25] = MBOX_TAG_GETFB;
	MOV X1, #8
	STR W1, [X10, #104]	//mbox[26] = 8;
	MOV X1, #8
	STR W1, [X10, #108]	//mbox[27] = 8;
	MOV X1, #4096
	STR W1, [X10, #112]	//mbox[28] = 4096; // FrameBufferInfo.pointer
	MOV X1, #0
	STR W1, [X10, #116]	//mbox[29] = 0;    // FrameBufferInfo.size
    
	LDR X1, =MBOX_TAG_GETPITCH
	STR W1, [X10, #120]	//mbox[30] = MBOX_TAG_GETPITCH;
	MOV X1, #4
	STR W1, [X10, #124]	//mbox[31] = 4;
	MOV X1, #4
	STR W1, [X10, #128]	//mbox[32] = 4;
	MOV X1, #0
	STR W1, [X10, #132]	//mbox[33] = 0; // Bytes per line
    
	LDR X1, =MBOX_TAG_LAST
	STR W1, [X10, #136]	//mbox[34] = MBOX_TAG_LAST;

    /* Check call is successful and we have a pointer with depth 32	
    if (mbox_call(MBOX_CH_PROP) && mbox[20] == 32 && mbox[28] != 0) {
        mbox[28] &= 0x3FFFFFFF; // Convert GPU address to ARM address
        width = mbox[10];       // Actual physical width
        height = mbox[11];      // Actual physical height
        pitch = mbox[33];       // Number of bytes per line
        isrgb = mbox[24];       // Pixel order
        fb = (unsigned char *)((long)mbox[28]);
    }
	*/
	
	LDR X10, =MBOX_CH_PROP
	STP X29, X30, [SP, #-16]!	//RETURN ADDRESS
	BL MAILBOX_CALL
	LDP X29, X30, [SP], #16	
	
	CBZ X1, ENDFB
	LDR X10, =MBOX
	LDRB W1, [X10, #80]
	CMP W1, #32
	BNE ENDFB
	LDR W1, [X10, #112]
	CBZ W1, ENDFB
	//SUCESS, COPY ATTRIBUTES
	AND W1, W1, #0x3FFFFFFF
	STR X1, [X10, #112]
	
	LDR W1, [X10, #40]
	LDR X2, =WIDTH
	STR W1, [X2]
	
	LDR W1, [X10, #44]
	LDR X2, =HEIGHT
	STR W1, [X2]
	
	LDR W1, [X10, #132]
	LDR X2, =PITCH
	STR W1, [X2]
	
	LDR W1, [X10, #96]
	LDR X2, =ISRGB
	STR W1, [X2]
	
	LDR X1, [X10, #112]
	LDR X2, =FB
	STR X1, [X2]
	
ENDFB:
	RET
#]


DRAWPILOGO:
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

DRAWPIXEL://(int x, int y, unsigned char attr)
#[
  	LDR X10, =FB
	LDR X10, [X10]
	MOV W1, #0xFFFF00FF
	STR W1, [X10, #100]
	RET
#]

.align 4
DRAWPIXEL2://(int x, int y, unsigned char attr)
#[
	LDR X1, #0x80000    // If Core 0 is at 0x80000
    SUB X1, X1, #0x1000 // Core 1 gets the range 0x7F000 - 0x80000
    MOV SP, X1
	
	LDR X1, =LIFE
	MOV W2, #0x01
	STR W2, [X1]
	

  	LDR X10, =FB
	LDR X10, [X10]
	MOV W1, #0xFFFF00FF
	STR W1, [X10, #200]
ll:
	wfe
	b ll
#]
