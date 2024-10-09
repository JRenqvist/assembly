/* When this macro is inserted into assembler code, it will print out
   all registers as they exist just before the DUMP_REGISTERS
   call. (Exception: PC, which will correspond to the branch and
   link.)  Note that it will push data to the stack, so ensure that
   you don't store anything valuable in unallocated stack space (which
   you shouldn't do anyway).  */


#define DUMP_REGISTERS \
  push {r0-r12,r14};   \
  mov r0,r13;					\
  bl  dump_registers;				\
  pop {r0-r12,r14};				


