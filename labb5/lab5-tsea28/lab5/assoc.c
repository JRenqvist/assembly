#include <stdint.h>
#include "util.h"

void find_associativity(int nr, int step)
{
  int c=0, i, j;

  j = 0;                   /* Kommentar: starta med j satt till 0 */
  do {                     /* Loop över alla värden hos j (dvs 0,1,2,3)   */
    i = 0;                 /* För varje j starta med i=0 */
    do {                   /* Loop över alla värden 0 till (nr-1) */
      c = read_mem32(0x82000000 + i * step);    /* läs från minnet */
      i = i + 1;
    } while (i < nr);      /* Kör loop för i = 0,1 ... nr-1 */
    j = j + 1;        
  } while (j < 4);         /* Kör loop för j = 0,1,2,3 */

  small_printf("\nc= 0x%08x\n",c);
}

/* Prototype for assembler version of find_associativity() */
void find_associativity_asm(int nr, int step);

int main(void)
{
  Flush_DCache();
  trigger_logic_analyzer();
  /* Byt ut ANTAL och STEGLANGD nedan mot siffervärden */
  find_associativity(ANTAL,STEGLANGD);

  return 0;
}
