
#ifdef SDL_ROTATE
// Det här är inte ett särskilt snyggt hack, men det fungerar
// för tillfället...

#include <stdio.h>
typedef uint64_t memory_addr;
#define small_printf printf
void initialize_sdl_rotate(void);

#else
typedef uint32_t memory_addr;
#endif

// Direct memory access macros
#define REG8(add) *((volatile uint8_t *)(add))
#define REG16(add) *((volatile uint16_t *)(add))
#define REG32(add) *((volatile uint32_t *)(add))


// Inline functions for reading memory
static inline uint32_t read_mem32(memory_addr addr)
{
  return REG32(addr);
}

static inline uint16_t read_mem16(memory_addr addr)
{
  return REG16(addr);
}

static inline uint8_t read_mem8(memory_addr addr)
{
  return REG8(addr);
}

static inline void write_mem32(memory_addr addr, uint32_t val)
{
  REG32(addr) = val;
}

static inline void write_mem16(memory_addr addr, uint16_t val)
{
  REG16(addr) = val;
}

static inline void write_mem8(memory_addr addr, uint8_t val)
{
  REG8(addr) = val;
}

#undef REG8
#undef REG16
#undef REG32


void uart_putc(int c);
int uart_getc(void);
int uart_has_data(void);

int framebuffer_swap(uint32_t new_framebuffer);


int small_printf(const char *format, ...);

void trigger_logic_analyzer(void);

void Flush_DCache(void);
void SetPageTableAttributes(uint32_t page, uint32_t flags);


uint32_t get_timer(void);
void start_timer(void);


int fixed_point_cos(int angle);
int fixed_point_sin(int angle);


