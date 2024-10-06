CROSS_COMPILER=C:\Xilinx\14.7\ISE_DS\EDK\gnu\arm\nt\bin\arm-xilinx-eabi-


all: rotate hello assoc insnfetch

rotate: rotate.dis rotate.hex 
	@true

hello: hello.hex hello.dis
	@true

assoc: assoc.hex assoc.dis
	@true

insnfetch: insnfetch.hex insnfetch.dis
	@true

# #include dependencies
helloworld.o: helloworld.c util.h
util.o: util.c util.h memorymap.h
rotate.o: rotate.c util.h memorymap.h config.h
insnfetch.o: insnfetch.c util.h
fetchtest.o: fetchtest.c util.h
assoc.o: assoc.c util.h

# Some generic rules
%.o: %.c
	$(CROSS_COMPILER)gcc -Wall -O2 -g3 -c $<  -o $@

%.o: %.S
	$(CROSS_COMPILER)gcc -Wall -O2 -g3 -c $<  -o $@

%.hex: %.elf
	$(CROSS_COMPILER)objcopy $< -O ihex $@

%.dis: %.elf
	$(CROSS_COMPILER)objdump -d $< > $@	


hello.elf: helloworld.o util.o
	$(CROSS_COMPILER)gcc -Wl,-T -Wl,lscript.ld  -o hello.elf  helloworld.o util.o 

rotate.elf: rotate.o util.o sintable.o
	$(CROSS_COMPILER)gcc -Wl,-T -Wl,lscript.ld  -o rotate.elf  rotate.o util.o sintable.o

assoc.elf: util.o assoc.o 
	$(CROSS_COMPILER)gcc -Wl,-T -Wl,lscript.ld  -o assoc.elf  assoc.o  util.o 

insnfetch.elf: insnfetch.o util.o fetchtest.o
	$(CROSS_COMPILER)gcc -Wl,-T -Wl,lscript.ld  -o insnfetch.elf  insnfetch.o util.o fetchtest.o

clean:
	rm -f *.o *.elf *.hex *~ *.dis



rotate_sdl: 
	gcc -O2 -g $$(sdl-config --cflags) rotate.c sintable.c util_sdl.c -o rotate-sdl  -DSDL_ROTATE -Wall $$(sdl-config --libs) -lrt -pg
	@echo Interested in trying out profiling?: Try to run gprof -p -b rotate-sdl after running rotate-sdl
	@echo Other interesting profiling options: gprof -p -b -l rotate-sdl

