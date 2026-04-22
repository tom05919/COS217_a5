/*#include <stdio.h>
 #include <ctype.h> */

/* DATA section*/
.section .data
    lLineCount: .quad 0
    lWordCount: .quad 0
    lCharCount: .quad 0
    iInWord:    .word 0

/*BSS section*/
.section .bss
    iChar: .skip 4

/*--------------------------------------------------------------------*/

/* Write to stdout counts of how many lines, words, and characters
   are in stdin. A word is a sequence of non-whitespace characters.
   Whitespace is defined by the isspace() function. Return 0. */

.section .rodata
    fmt: .asciz "%7ld %7ld %7ld\n"

.section ".text"
.global main

.equ FALSE, 0
.equ TRUE, 1
.equ EOF, -1

main:

    sub sp, sp, 16
    str x30, [sp]

loop1:
    bl getchar /* getchar() */

    mov w1, w0 
    adr x0, iChar
    str w1, [x0] /* iChar = getchar() */

    cmn w1, #1 /* !((iChar = getchar()) != EOF) */
    beq endloop1 /* goto endloop1 */

    adr x0, lCharCount
    ldr x2, [x0] /* lCharCount */
    add x2, x2, 1 
    str x2, [x0] /* lCharCount++ */

    mov w0, w1
    bl isspace /* isspace(iChar) */

    cbz w0, else1 /* if (!isspace(iChar)) goto else1 */

    adr x0, iInWord
    ldr w4, [x0]
    cmp w4, FALSE
    beq endif1 /* if (!iInWord) goto endif1 */

    adr x0, lWordCount
    ldr x5, [x0] /* lWordCount */
    add x5, x5, 1
    str x5, [x0] /* lWordCount++ */

    mov w4, FALSE 
    adr x0, iInWord
    str w4, [x0] /* iInWord = FALSE */

    b endif1

else1:
    adr x0, iInWord
    ldr w4, [x0]
    cmp w4, FALSE
    bne endif1 /* if (!iInWord) goto endif1; */

    mov w4, TRUE 
    adr x0, iInWord
    str w4, [x0] /* iInWord = TRUE */

endif1:

    adr x0, iChar
    ldr w1, [x0]
    cmp w1, '\n'
    bne endif2 /* if (!(iChar == '\n')) goto endif2 */

    adr x0, lLineCount
    ldr x3, [x0] /* lLineCount */
    add x3, x3, 1
    str x3, [x0] /* lLineCount++  */

endif2: 
    
    b loop1

endloop1:
    adr x0, iInWord
    ldr w4, [x0]
    cmp w4, TRUE
    bne endif3 /* if (iInWord) goto endif3 */

    adr x0, lWordCount
    ldr x5, [x0] /* lWordCount */
    add x5, x5, 1
    str x5, [x0] /* lWordCount++ */

endif3:

    adr x0, fmt

    adr x1, lLineCount
    ldr x1, [x1] /* load lLineCount */

    adr x2, lWordCount
    ldr x2, [x2] /* load lWordCount */

    adr x3, lCharCount
    ldr x3, [x3] /* load lCharCount */

    bl printf /* printf("%7ld %7ld %7ld\n", lLineCount, lWordCount, lCharCount) */

    mov w0, 0
    ldr x30, [sp]
    add sp, sp, 16
    ret
