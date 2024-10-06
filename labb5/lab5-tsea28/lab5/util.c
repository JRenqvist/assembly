/*
  The following copyright applies to the printf part of this file:
  Copyright 2001, 2002 Georges Menie (www.menie.org)

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU Lesser General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#include <stdint.h>
#include "util.h"
#include "memorymap.h"


static void printchar(char **str, int c)
{

  if (str) {
    **str = c;
    ++(*str);
  }
  else 
    uart_putc(c);
}

#define PAD_RIGHT 1
#define PAD_ZERO 2

static int prints(char **out, const char *string, int width, int pad)
{
  register int pc = 0, padchar = ' ';

  if (width > 0) {
    register int len = 0;
    register const char *ptr;
    for (ptr = string; *ptr; ++ptr) ++len;
    if (len >= width) width = 0;
    else width -= len;
    if (pad & PAD_ZERO) padchar = '0';
  }
  if (!(pad & PAD_RIGHT)) {
    for ( ; width > 0; --width) {
      printchar (out, padchar);
      ++pc;
    }
  }
  for ( ; *string ; ++string) {
    printchar (out, *string);
    ++pc;
  }
  for ( ; width > 0; --width) {
    printchar (out, padchar);
    ++pc;
  }

  return pc;
}

/* the following should be enough for 32 bit int */
#define PRINT_BUF_LEN 12

static int printi(char **out, int i, int b, int sg, int width, int pad, int letbase)
{
  char print_buf[PRINT_BUF_LEN];
  register char *s;
  register int t, neg = 0, pc = 0;
  register unsigned int u = i;

  if (i == 0) {
    print_buf[0] = '0';
    print_buf[1] = '\0';
    return prints (out, print_buf, width, pad);
  }

  if (sg && b == 10 && i < 0) {
    neg = 1;
    u = -i;
  }

  s = print_buf + PRINT_BUF_LEN-1;
  *s = '\0';

  while (u) {
    t = u % b;
    if( t >= 10 )
      t += letbase - '0' - 10;
    *--s = t + '0';
    u /= b;
  }

  if (neg) {
    if( width && (pad & PAD_ZERO) ) {
      printchar (out, '-');
      ++pc;
      --width;
    }
    else {
      *--s = '-';
    }
  }

  return pc + prints (out, s, width, pad);
}

static int print(char **out, int *varg)
{
  register int width, pad;
  register int pc = 0;
  register char *format = (char *)(*varg++);
  char scr[2];

  for (; *format != 0; ++format) {
    if (*format == '%') {
      ++format;
      width = pad = 0;
      if (*format == '\0') break;
      if (*format == '%') goto out;
      if (*format == '-') {
	++format;
	pad = PAD_RIGHT;
      }
      while (*format == '0') {
	++format;
	pad |= PAD_ZERO;
      }
      for ( ; *format >= '0' && *format <= '9'; ++format) {
	width *= 10;
	width += *format - '0';
      }
      if( *format == 's' ) {
	register char *s = *((char **)varg++);
	pc += prints (out, s?s:"(null)", width, pad);
	continue;
      }
      if( *format == 'd' ) {
	pc += printi (out, *varg++, 10, 1, width, pad, 'a');
	continue;
      }
      if( *format == 'x' ) {
	pc += printi (out, *varg++, 16, 0, width, pad, 'a');
	continue;
      }
      if( *format == 'X' ) {
	pc += printi (out, *varg++, 16, 0, width, pad, 'A');
	continue;
      }
      if( *format == 'u' ) {
	pc += printi (out, *varg++, 10, 0, width, pad, 'a');
	continue;
      }
      if( *format == 'c' ) {
	/* char are converted to int then pushed on the stack */
	scr[0] = *varg++;
	scr[1] = '\0';
	pc += prints (out, scr, width, pad);
	continue;
      }
    }
    else {
    out:
      printchar (out, *format);
      ++pc;
    }
  }
  if (out) **out = '\0';
  return pc;
}

/* assuming sizeof(void *) == sizeof(int) */

int small_printf(const char *format, ...)
{
  register int *varg = (int *)(&format);
  return print(0, varg);
}

int small_sprintf(char *out, const char *format, ...)
{
  register int *varg = (int *)(&format);
  return print(&out, varg);
}

#ifdef TEST_PRINTF
int main(void)
{
  char *ptr = "Hello world!";
  char *np = 0;
  int i = 5;
  unsigned int bs = sizeof(int)*8;
  int mi;
  char buf[80];

  mi = (1 << (bs-1)) + 1;
  printf("%s\n", ptr);
  printf("printf test\n");
  printf("%s is null pointer\n", np);
  printf("%d = 5\n", i);
  printf("%d = - max int\n", mi);
  printf("char %c = 'a'\n", 'a');
  printf("hex %x = ff\n", 0xff);
  printf("hex %02x = 00\n", 0);
  printf("signed %d = unsigned %u = hex %x\n", -3, -3, -3);
  printf("%d %s(s)%", 0, "message");
  printf("\n");
  printf("%d %s(s) with %%\n", 0, "message");
  sprintf(buf, "justif: \"%-10s\"\n", "left"); printf("%s", buf);
  sprintf(buf, "justif: \"%10s\"\n", "right"); printf("%s", buf);
  sprintf(buf, " 3: %04d zero padded\n", 3); printf("%s", buf);
  sprintf(buf, " 3: %-4d left justif.\n", 3); printf("%s", buf);
  sprintf(buf, " 3: %4d right justif.\n", 3); printf("%s", buf);
  sprintf(buf, "-3: %04d zero padded\n", -3); printf("%s", buf);
  sprintf(buf, "-3: %-4d left justif.\n", -3); printf("%s", buf);
  sprintf(buf, "-3: %4d right justif.\n", -3); printf("%s", buf);

  return 0;
}

/*
 * if you compile this file with
 *   gcc -Wall $(YOUR_C_OPTIONS) -DTEST_PRINTF -c printf.c
 * you will get a normal warning:
 *   printf.c:214: warning: spurious trailing `%' in format
 * this line is testing an invalid % at the end of the format string.
 *
 * this should display (on 32bit int machine) :
 *
 * Hello world!
 * printf test
 * (null) is null pointer
 * 5 = 5
 * -2147483647 = - max int
 * char a = 'a'
 * hex ff = ff
 * hex 00 = 00
 * signed -3 = unsigned 4294967293 = hex fffffffd
 * 0 message(s)
 * 0 message(s) with %
 * justif: "left      "
 * justif: "     right"
 *  3: 0003 zero padded
 *  3: 3    left justif.
 *  3:    3 right justif.
 * -3: -003 zero padded
 * -3: -3   left justif.
 * -3:   -3 right justif.
 */

#endif

/* Miscellaneous other functions */

/* Zedboard specific input/output to the UART */
void uart_putc(int c)
{
  while(read_mem8(UART_STATUS) & 0x10); // Wait for Tx FIFO to be non-full
  
  write_mem8(UART_RXTX,c);
}

int uart_has_data(void) // Check whether the UART has data for us.
{
  return !(read_mem8(UART_STATUS) & 0x02);
}

int uart_getc(void)
{
  while ( !uart_has_data() ); 
  return read_mem8(UART_RXTX);
}




/* This function is intended to trigger the logic analyzer (chipscope)
   connected to the AXI bus. (It of course requires the logic analyzer
   to be configured to look at AWADDR and AWVALID.) */

void trigger_logic_analyzer(void)
{
	write_mem32(0x9fff0000,0xdeadbeef);
}

/* The following wrapper functions are here so that we can call
   functions located in the monitor via a table located at 0xffff0000.
   
   These functions are simply too cumbersome to include in the lab
   files for various reasons (e.g., too many dependencies, etc). */
static int check_api_table_version(int version)
{
	if(read_mem32(FUNCTION_TABLE_MAGIC) != 0x534d4f4e){
		small_printf("ERROR: Did not find magic number in function table\r\n");
		return 0;
	}
	if(read_mem32(FUNCTION_TABLE_VERSION) < version){
		small_printf("ERROR: API Table version too small\r\n");
		return 0;
	}
	return 1;
	
}
void Flush_DCache(void)
{
	if(!check_api_table_version(1)){
		return;
	}
	void (*funcptr)(void);
	funcptr = (void (*)(void)) read_mem32(FUNCTION_TABLE_FLUSHCACHE);
	funcptr();
}

void SetPageTableAttributes(uint32_t page, uint32_t flags)
{
	if(!check_api_table_version(1)){
		return;
	}
	void (*funcptr)(uint32_t page, uint32_t flags);
	funcptr = (void (*)(uint32_t, uint32_t)) read_mem32(FUNCTION_TABLE_FLUSHCACHE);
	funcptr(page,flags);
}


/* This enables the private timer of the Cortex-A9 processor */
void start_timer(void)
{
	write_mem32(PRIVATE_TIMER_CONTROL,3); // Enable timer and enable auto reload.
	// Prescaler is 0, irq enable is 0
	write_mem32(PRIVATE_TIMER_LOADVAL, 0xffffffff);
}

uint32_t get_timer(void)
{
	// Note: Timer actually counts down, but to avoid possible
	// confusion we negate the value before we return it...
	return -read_mem32(PRIVATE_TIMER_COUNTER);
}

void stop_timer(void)
{
	write_mem32(PRIVATE_TIMER_CONTROL,0); // Disable timer

}


int framebuffer_swap(uint32_t new_framebuffer)
{

	int retval = 0;
	static int prevframe;
	int currentframe;

	// This write doesn't take effect immediately. It is however
	// saved by the VGA controller and acted upon at the start of
	// the next frame.
	write_mem32(VGA_BASEADDR, new_framebuffer| 0x80000000); // Bit 31: Enable DMA for framebuffer

	currentframe = read_mem32(VGA_FRAMECOUNT);
	if(currentframe != prevframe+1){
		retval = 1;
	}
	while(read_mem32(VGA_FRAMECOUNT) == currentframe);
	prevframe = currentframe;
	return retval;

}

/* This function is only intended to be called through the
   DUMP_REGISTERS call in asmutil.h as a debugging aid */
void dump_registers(uint32_t *regvals)
{
	small_printf("Register dump:\r\n");
	small_printf("r0: 0x%08x, r1: 0x%08x, r2: 0x%08x, r3: 0x%08x\r\n", regvals[0],regvals[1],regvals[2],regvals[3]);
	small_printf("r4: 0x%08x, r5: 0x%08x, r6: 0x%08x, r7: 0x%08x\r\n", regvals[4],regvals[5],regvals[6],regvals[7]);
	small_printf("r8: 0x%08x, r9: 0x%08x, r10: 0x%08x, r11: 0x%08x\r\n", regvals[8],regvals[9],regvals[10],regvals[11]);
	small_printf("r12: 0x%08x, sp: 0x%08x, lr: 0x%08x, pc: 0x%08x\r\n", regvals[12],regvals+14,regvals[13], __builtin_return_address(0));
}
