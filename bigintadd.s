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
BigInt_add:
   sub sp, sp, 64
   str x30, [sp] 

   str x0, [sp, 16] /* store oAddend1 */
   str x1, [sp, 24] /* store oAddend2 */
   str x2, [sp, 32] /* store oSum */

   ldr x0, [x0] /* loads oAddend1->lLength since x is 8 byte and lLength is first 8 byte of struct*/
   ldr x1, [x1] /* oAddend2->lLength */

   bl BigInt_larger

   mov x3, x0 /* lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength) */

   str x3, [sp, 40]

   ldr x0, [sp, 32]
   ldr x4, [x0] /* oSum->lLength */

   cmp x4, x3
   ble endif1 /* if (oSum->lLength > lSumLength) */

   add x0, x0, 8 /* address of oSum->aulDigits (very start of array) */
   mov x1, 0
   mov x2, #(MAX_DIGITS * 8)

   bl memset

endif1:
   ldr x3, [sp, 40]
   mov x5, 0 /* ulCarry */
   mov x6, 0 /* lIndex */

loop1:
   cmp x6, x3
   bge endloop1

   mov x7, x5 /* ulSum */
   mov x5, 0 /* ulCarry */

   ldr x0, [sp, 16]
   add x0, x0, 8
   ldr x0, [x0, x6, lsl 3] /* oAddend1->aulDigits[lIndex] */
   add x7, x7, x0 /* ulSum += oAddend1->aulDigits[lIndex] */

   cmp x7, x0
   bhs endif2
   mov x5, 1

endif2:
   ldr x1, [sp, 24]
   add x1, x1, 8
   ldr x1, [x1, x6, lsl 3] /* oAddend2->aulDigits[lIndex] */
   add x7, x7, x1 /* ulSum += oAddend2->aulDigits[lIndex] */

   cmp x7, x1
   bhs endif3
   mov x5, 1

endif3:
   ldr x2, [sp, 32]
   add x2, x2, 8
   str x7, [x2, x6, lsl 3]

   add x6, x6, 1

   b loop1

endloop1:

   cmp x5, 1
   bne endif4

   cmp x3, MAX_DIGITS
   bne endif5

   mov x0, FALSE
   b finish

endif5:
   ldr x2, [sp, 32]
   add x2, x2, 8
   
   mov x4, 1
   str x4, [x2, x6, lsl 3] /* oSum->aulDigits[lSumLength] = 1 */
 
   add x3, x3, 1 /* lSumLength++ */
endif4:

   ldr x2, [sp, 32] /* oSum->lLength = lSumLength */
   str x3, [x2]

   mov x0, TRUE

finish:
   ldr x30, [sp]
   add sp, sp, 64
   ret
