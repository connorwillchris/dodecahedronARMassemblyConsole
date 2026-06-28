//.define DOIT, 1

.ifdef DOIT

code_test:
    ldr x1, x2
    ret

init_randomization:
    mov w4, #0
    ldr x5, =RANDOMENABLE
//  enable rng
    STR w4, [x5]
    ldr x5, =RANDOMSTATUS
//  clear any existing status/error bits
    mov w4, #0
    STR w4, [x5]
    mov w4, #0x40000
    ldr x5, =RANDOMINTMASK
//  warm up for that many cycles
    STR w4, [x5]
//  data memory barrier to ensure order
    dmb ish
    mov w4, #1
//  enable rng
    ldr x5, =RANDOMENABLE
    str w4, [x5]
    ret

.endif
