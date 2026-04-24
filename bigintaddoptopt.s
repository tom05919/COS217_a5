/*--------------------------------------------------------------------*/
/* bigintaddopt.s                                                     */
/* Author: Ty Lipscomb and Tom Wang                                   */
/*--------------------------------------------------------------------*/

/* In lieu of a boolean data type. */

/* enum {FALSE, TRUE} */
.equ FALSE, 0
.equ TRUE, 1
.equ MAX_DIGITS, 32768


/*--------------------------------------------------------------------*/

/* Assign the sum of oAddend1 and oAddend2 to oSum.  oSum should be
   distinct from oAddend1 and oAddend2.  Return 0 (FALSE) if an
   overflow occurred, and 1 (TRUE) otherwise. */

.global BigInt_add
OADDEND1 .req x19
OADDEND2 .req x20
OSUM .req x21
LSUM_LENGTH .req x22
ULSUM       .req x25

BigInt_add:
	/* Prologue: Save the original callee-saved registers to the stack */
   stp x19, x20, [sp, -16]!
   stp x21, x22, [sp, -16]!
   stp x25, x30, [sp, -16]!

	/* Move the incoming parameters from volatile x0-x2 into your safe registers */
   mov OADDEND1, x0
   mov OADDEND2, x1
   mov OSUM, x2


   ldr x0, [OADDEND1] /* loads oAddend1->lLength since x is 8 byte and lLength is first 8 byte of struct*/
   ldr x1, [OADDEND2] /* oAddend2->lLength */

   /* lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength) */
   cmp x0, x1
   csel LSUM_LENGTH, x0, x1, gt

	/* if (oSum->lLength > lSumLength) */
	ldr x4, [OSUM]
	cmp x4, LSUM_LENGTH
	ble endif1

	/* memset(oSum->aulDigits, 0, MAX_DIGITS * sizeof(unsigned long)); */
   add x0, OSUM, 8 /* address of oSum->aulDigits (very start of array) */
   mov x1, 0
   mov x2, #(MAX_DIGITS * 8)

   bl memset

endif1:
   add x9,  OADDEND1, 8        /* pointer to oAddend1->aulDigits[0] */
   add x10, OADDEND2, 8        /* pointer to oAddend2->aulDigits[0] */
   add x11, OSUM, 8            /* pointer to oSum->aulDigits[0] */
   mov x12, LSUM_LENGTH        /* loop counter */

   /* clear carry flag before first adcs */
   adds xzr, xzr, xzr

   /* guarded loop: if lSumLength == 0, skip loop */
   cbz x12, no_final_carry

loop1:
   ldr x13, [x9], 8            /* x13 = oAddend1->aulDigits[i]; advance */
   ldr x14, [x10], 8           /* x14 = oAddend2->aulDigits[i]; advance */

   adcs ULSUM, x13, x14        /* ulSum = x13 + x14 + carry flag */

   str ULSUM, [x11], 8         /* oSum->aulDigits[i] = ulSum; advance */

   sub x12, x12, 1             /* decrement counter; does NOT change flags */
   cbnz x12, loop1             /* branch without changing carry flag */

endloop1:
   bcc no_final_carry          /* if carry clear, skip final digit */

   /* final carry exists */
   cmp LSUM_LENGTH, MAX_DIGITS
   bne room_for_carry

   mov x0, FALSE
   b finish

room_for_carry:
   mov x13, 1
   str x13, [x11]              /* x11 points to oSum->aulDigits[lSumLength] */
   add LSUM_LENGTH, LSUM_LENGTH, 1

no_final_carry:
   str LSUM_LENGTH, [OSUM]     /* oSum->lLength = lSumLength */
   mov x0, TRUE
   b finish

finish:
   ldp x25, x30, [sp], 16
   ldp x21, x22, [sp], 16
   ldp x19, x20, [sp], 16

   ret

   .unreq OADDEND1
   .unreq OADDEND2
   .unreq OSUM
   .unreq LSUM_LENGTH
   .unreq ULSUM