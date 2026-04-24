/*--------------------------------------------------------------------*/
/* bigintadd.s                                                        */
/* ARM64: BigInt_larger and BigInt_add (Part 2d: params/locals on     */
/* stack; .equ for constants and offsets).                            */
/*--------------------------------------------------------------------*/

/* In lieu of a boolean data type. */

/* enum {FALSE, TRUE} */
.equ FALSE, 0
.equ TRUE, 1
.equ MAX_DIGITS, 32768

/* struct BigInt field offsets (bytes) */
.equ LLENGTH, 0
.equ AAULDIGITS, 8

/* BigInt_larger stack frame */
.equ L_FRAME, 32
.equ L_LENGTH1, 0
.equ L_LENGTH2, 8
.equ L_LLARGER, 16

/* BigInt_add frame (all C locals + saved x30) */
.equ ADD_FRAME, 64
.equ ADD_X30, 0
.equ O_ADDEND1, 8
.equ O_ADDEND2, 16
.equ O_SUM, 24
.equ ULCARRY, 32
.equ ULSUM, 40
.equ LINDEX, 48
.equ LSUMLENGTH, 56

/*--------------------------------------------------------------------*/
/* Return the larger of lLength1 and lLength2. */

.text
BigInt_larger:
    sub sp, sp, L_FRAME

    str x0, [sp, L_LENGTH1]
    str x1, [sp, L_LENGTH2]

    /* if (lLength1 > lLength2) */
    ldr x0, [sp, L_LENGTH1]
    ldr x1, [sp, L_LENGTH2]
    cmp x0, x1
    ble larger_else

    /* lLarger = lLength1 */
    str x0, [sp, L_LLARGER]
    b larger_endif

larger_else:
    /* lLarger = lLength2 */
    str x1, [sp, L_LLARGER]

larger_endif:
    ldr x0, [sp, L_LLARGER]
    add sp, sp, L_FRAME
    ret

/*--------------------------------------------------------------------*/
/* Assign the sum of oAddend1 and oAddend2 to oSum.  oSum should be
   distinct from oAddend1 and oAddend2.  Return 0 (FALSE) if an
   overflow occurred, and 1 (TRUE) otherwise. */ 
   
.global BigInt_add
BigInt_add:
    sub sp, sp, ADD_FRAME
    str x30, [sp, ADD_X30]

    str x0, [sp, O_ADDEND1]
    str x1, [sp, O_ADDEND2]
    str x2, [sp, O_SUM]

    /* lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength) */
    ldr x0, [sp, O_ADDEND1]
    ldr x0, [x0, LLENGTH]
    ldr x1, [sp, O_ADDEND2]
    ldr x1, [x1, LLENGTH]
    bl BigInt_larger
    str x0, [sp, LSUMLENGTH]

    /* if (oSum->lLength > lSumLength) memset(...) */
    ldr x0, [sp, O_SUM]
    ldr x4, [x0, LLENGTH]
    ldr x3, [sp, LSUMLENGTH]
    cmp x4, x3
    ble add_skip_memset

    ldr x0, [sp, O_SUM]
    add x0, x0, AAULDIGITS
    mov x1, 0
    mov x2, #(MAX_DIGITS * 8)
    bl memset

add_skip_memset:
    /* ulCarry = 0; lIndex = 0; */
    mov x8, 0
    str x8, [sp, ULCARRY]
    str x8, [sp, LINDEX]

add_loop:
    ldr x6, [sp, LINDEX]
    ldr x3, [sp, LSUMLENGTH]
    cmp x6, x3
    bge add_endloop

    /* ulSum = ulCarry; ulCarry = 0 */
    ldr x7, [sp, ULCARRY]
    str x7, [sp, ULSUM]
    mov x8, 0
    str x8, [sp, ULCARRY]

    /* ulSum += oAddend1->aulDigits[lIndex] */
    ldr x0, [sp, O_ADDEND1]
    add x0, x0, AAULDIGITS
    ldr x9, [sp, LINDEX]
    ldr x10, [x0, x9, lsl 3]
    ldr x7, [sp, ULSUM]
    add x7, x7, x10
    str x7, [sp, ULSUM]
    cmp x7, x10
    bhs add_after_carry1
    mov x8, 1
    str x8, [sp, ULCARRY]
add_after_carry1:

    /* ulSum += oAddend2->aulDigits[lIndex] */
    ldr x0, [sp, O_ADDEND2]
    add x0, x0, AAULDIGITS
    ldr x9, [sp, LINDEX]
    ldr x10, [x0, x9, lsl 3]
    ldr x7, [sp, ULSUM]
    add x7, x7, x10
    str x7, [sp, ULSUM]
    cmp x7, x10
    bhs add_after_carry2
    mov x8, 1
    str x8, [sp, ULCARRY]
add_after_carry2:

    /* oSum->aulDigits[lIndex] = ulSum */
    ldr x0, [sp, O_SUM]
    add x0, x0, AAULDIGITS
    ldr x9, [sp, LINDEX]
    ldr x7, [sp, ULSUM]
    str x7, [x0, x9, lsl 3]

    ldr x9, [sp, LINDEX]
    add x9, x9, 1
    str x9, [sp, LINDEX]
    b add_loop

add_endloop:
    ldr x5, [sp, ULCARRY]
    cmp x5, 1
    bne add_write_length

    /* lSumLength == MAX_DIGITS (32768 == 8 << 12) */
    ldr x3, [sp, LSUMLENGTH]
    cmp x3, #8, lsl #12
    bne add_carry_digit

    mov w0, FALSE
    ldr x30, [sp, ADD_X30]
    add sp, sp, ADD_FRAME
    ret

add_carry_digit:
    ldr x0, [sp, O_SUM]
    add x0, x0, AAULDIGITS
    ldr x3, [sp, LSUMLENGTH]
    mov x11, 1
    str x11, [x0, x3, lsl 3]
    add x3, x3, 1
    str x3, [sp, LSUMLENGTH]

add_write_length:
    ldr x0, [sp, O_SUM]
    ldr x3, [sp, LSUMLENGTH]
    str x3, [x0, LLENGTH]

    mov w0, TRUE
    ldr x30, [sp, ADD_X30]
    add sp, sp, ADD_FRAME
    ret
