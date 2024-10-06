#include <stdint.h>
#include "util.h"

/* The section attribute ensures that chipscope_dummy, fetchtest, and
 * chipscope_dummy2 ends up in a special section which the linker
 * script will then place at location 0x82000000 */

extern int chipscope_dummy (void) __attribute__ ((section ("chipscope")));
int chipscope_dummy(void)
{
	return read_mem32(0x82000000)+1;
}

extern int fetchtest (uint8_t *, int) __attribute__ ((section ("chipscope")));
int fetchtest(uint8_t *test, int sum)
{
	int i;
	for(i=0; i < 15; i++){
		sum = sum + test[i];
	}
	return sum;
}

/* We put a function filled with NOPs behind fetchtest() so that it is easy
 * to identify when we have started to fetch cachelines after fetchtest() */
extern void chipscope_dummy2(void) __attribute__ ((section ("chipscope")));
void chipscope_dummy2(void)
{
#define NOP asm volatile("NOP")
	NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;
	NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;
	NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;
	NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;
	NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;
	NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;
	NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;
	NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;
	NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;
	NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;
	NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;
	NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;
	NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;
	NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;
  
}

