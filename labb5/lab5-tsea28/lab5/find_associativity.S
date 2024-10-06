#include "asmutil.h"
	
	.text
	.global find_associativity_asm

	/* Set up register aliases */

	/* Called with nr in register r0
	 * and step in register r1 */
find_associativity_asm:
	push {r4-r6}
	ldr r6,=2
	ldr r3,=0 /* j */

loop1:	
	cmp r3,r6
	bcs done_loop1

	ldr r2,=0 /* i */
	ldr r4,=0x82000000 /* Keeps track of the current address  */
loop2:
	cmp r2,r0
	bcs done_loop2

	ldr r5,[r4]
	add r4,r1 /* r4 += r1 */
	add r2,#1
	b   loop2

done_loop2:
	add r3,#1
	b   loop1

done_loop1:
	pop {r4-r6}
	bx  lr
