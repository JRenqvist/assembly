/* This file contains memory addresses for various parts of the code */

#define PRIVATE_TIMER_CONTROL 0xf8f00608
#define PRIVATE_TIMER_COUNTER 0xf8f00604
#define PRIVATE_TIMER_LOADVAL 0xf8f00600

#define FUNCTION_TABLE_MAGIC    0xffff0000
#define FUNCTION_TABLE_VERSION  0xffff0004
#define FUNCTION_TABLE_FLUSHCACHE 0xffff0008
#define FUNCTION_TABLE_SETPAGETABLE 0xffff001c


/* MMIO registers for UART */
#define UART_STATUS 0xe000102c
#define UART_RXTX 0xe0001030

/* MMIO registers for VGA */
#define VGA_FRAMECOUNT 0x40000004
#define VGA_BASEADDR   0x40000000

