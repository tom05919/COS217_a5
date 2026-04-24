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

/* Return the larger of lLength1 and lLength2. */
BigInt_larger:
   sub sp, sp, 32
   
   /* if (lLength1 > lLength2) */
   cmp x0, x1
   ble else1

   /* lLarger = lLength1 */
   str x0, [sp, 24]
   b endif0

else1:
   /* lLarger = lLength2 */
   str x1, [sp, 24]

endif0:
   ldr x0, [sp, 24] 
   add sp, sp, 32
   ret

/*--------------------------------------------------------------------*/

/* Assign the sum of oAddend1 and oAddend2 to oSum.  oSum should be
   distinct from oAddend1 and oAddend2.  Return 0 (FALSE) if an
   overflow occurred, and 1 (TRUE) otherwise. */

.global BigInt_add
OADDEND1 .req x19
OADDEND2 .req x20
OSUM .req x21
LSUM_LENGTH .req x22
LINDEX      .req x23
ULCARRY     .req x24
ULSUM       .req x25

BigInt_add:
	/* Prologue: Save the original callee-saved registers to the stack */
   stp x19, x20, [sp, -16]!
   stp x21, x22, [sp, -16]!
   stp x23, x24, [sp, -16]!
   stp x25, x30, [sp, -16]!

	/* Move the incoming parameters from volatile x0-x2 into your safe registers */
   mov OADDEND1, x0
   mov OADDEND2, x1
   mov OSUM, x2


   ldr x0, [OADDEND1] /* loads oAddend1->lLength since x is 8 byte and lLength is first 8 byte of struct*/
   ldr x1, [OADDEND2] /* oAddend2->lLength */

   bl BigInt_larger

   mov LSUM_LENGTH, x0 /* lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength) */

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
   mov ULCARRY, 0
   mov LINDEX, 0

loop1:
   cmp LINDEX, LSUM_LENGTH
   bge endloop1

   mov ULSUM, ULCARRY /* ulSum */
   mov ULCARRY, 0 /* ulCarry */

   add x0, OADDEND1, 8
   ldr x0, [x0, LINDEX, lsl 3] /* oAddend1->aulDigits[lIndex] */
   add ULSUM, ULSUM, x0 /* ulSum += oAddend1->aulDigits[lIndex] */

	/* overflow check */
   cmp ULSUM, x0
   bhs endif2
   mov ULCARRY, 1

endif2:

  /* ulSum += oAddend2->aulDigits[lIndex]; */
   add x1, OADDEND2, 8
   ldr x1, [x1, LINDEX, lsl 3]
   add ULSUM, ULSUM, x1

   cmp OADDEND2, x1
   bhs endif3
   mov ULCARRY, 1

endif3:
  /* oSum->aulDigits[lIndex] = ulSum; */
   add x2, OSUM, 8
	str ULSUM, [x2, LINDEX, lsl 3]

   add LINDEX, LINDEX, 1
   b loop1

endloop1:
	/* if (ulCarry == 1) */
   cmp ULCARRY, 1
   bne endif4

   /* if (lSumLength == MAX_DIGITS) return FALSE; */
   cmp LSUM_LENGTH, MAX_DIGITS
	bne endif5
   mov x0, FALSE

endif5:
   /* oSum->aulDigits[lSumLength] = 1; */
   add x2, OSUM, 8
   mov x4, 1
   str x4, [x2, LSUM_LENGTH, lsl 3]
    
   /* lSumLength++; */
   add LSUM_LENGTH, LSUM_LENGTH, 1

endif4:
	/* oSum->lLength = lSumLength; */
   str LSUM_LENGTH, [OSUM]

   /* return TRUE; */
   mov x0, TRUE

finish:

	ldp x25, x30, [sp], 16
   ldp x23, x24, [sp], 16
   ldp x21, x22, [sp], 16
   ldp x19, x20, [sp], 16

   ret

	.unreq OADDEND1
   .unreq OADDEND2
	.unreq OSUM
   .unreq LSUM_LENGTH
   .unreq LINDEX
   .unreq ULCARRY
   .unreq ULSUM