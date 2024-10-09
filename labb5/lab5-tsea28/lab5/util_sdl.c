// Warning: This file uses quite a few ugly hacks to ensure that
// rotate.c should work without changes, even though it is not running
// on an embedded system where addresses for the framebuffer are known
// beforehand, etc. In other words, don't look at this file as an
// example of proper C programming...

#include <stdio.h>
#include <stdlib.h>
#include <SDL.h>
#include <sys/mman.h>
#include <time.h>
#include <signal.h>
#include "config.h"


void uart_putc(int c)
{
	putchar(c);
}

static SDL_Event theevent;
int uart_getc(void)
{
	// This function assumes that uart_has_data has been called
	// previously to initialize theevent above.
	// (This is the case in rotate.c, so this shouldn't be an issue.)

	switch(theevent.key.keysym.sym){
	case SDLK_q:
		return 'q';
	case SDLK_a:
		return 'a';
	case SDLK_d:
		if(theevent.key.keysym.mod & KMOD_SHIFT){
			return 'D';
		}
		printf("the d\n");
		return 'd';
	case SDLK_s:
		return 's';
	case SDLK_w:
		return 'w';

	default:
		printf("Unknown key pressed\n");
	case SDLK_SPACE:
		return ' ';
	}
	
	return 0;
}
int uart_has_data(void)
{
	if(SDL_PollEvent(&theevent)){
		if(theevent.type == SDL_QUIT){
			SDL_Quit();
			exit(0);
		}
		
		if(theevent.type == SDL_KEYDOWN){
			return 1;
		}
	}
		
	return 0;
}

// Gör ingenting i denna version då det inte är möjligt att
// kontrollera cachen för ett vanligt program.
void Flush_DCache(void)
{
	return;
}

static struct timespec startts;
void start_timer(void)
{
	clock_gettime(CLOCK_MONOTONIC, &startts);
	return;
}

uint32_t get_timer(void)
{
	struct timespec ts;
	clock_gettime(CLOCK_MONOTONIC, &ts);

	uint64_t starttime, endtime; // Time in nanoseconds
	starttime = startts.tv_sec*1000000000 + startts.tv_nsec;
	endtime = ts.tv_sec*1000000000 + ts.tv_nsec;
	uint64_t tmp = (endtime - starttime)/1000;
	tmp =tmp * 533 / 2; // Convert to the same clock frequency as
			    // used in the Zynq PS7 system.
	return tmp;
}

// FIXME!
static SDL_Surface *thescreen;
// This function is far from 64 bit safe. But in this particular case
// we have hardcoded the framebuffer at 0x01000000 and 0x01400000 (by
// using the mmap calls below), so this is ok anyway (but not a very
// nice way of doing it...)
static struct timespec next_delaytime;
int framebuffer_swap(uint32_t new_framebuffer)
{
	if(SDL_MUSTLOCK(thescreen)){
		if(SDL_LockSurface(thescreen) < 0){
			fprintf(stderr,"Could not lock SDL Surface\n");
			SDL_Quit();
			exit(1);
		}
	}

	uint16_t *fb = (uint16_t *)new_framebuffer;
	uint32_t *surf = thescreen->pixels;
	int i;
	for(i=0; i < FB_XSIZE * FB_YSIZE; i++){
		unsigned int red, green, blue;
		red = fb[i] & 0xf800 >> 11;
		green = fb[i] & 0x07e0 >> 5;
		blue = fb[i] & 0x001f;
		red = red << 3;
		green = green << 2;
		blue = blue << 3;
		surf[i] = SDL_MapRGB(thescreen->format, red, green, blue);
	}

	if(SDL_MUSTLOCK(thescreen)) {
		SDL_UnlockSurface(thescreen);
	}

	// Cap the framerate to about 60 FPS
	clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME, &next_delaytime, 0);
	next_delaytime.tv_nsec += 1000000000/60;
	if(next_delaytime.tv_nsec >= 1000000000){
		next_delaytime.tv_nsec = 0;
	}
	
	SDL_Flip(thescreen);
	
	return 0;
}

void trigger_logic_analyzer(void)
{
	return;
}

void initialize_sdl_map(uint16_t *map_addr)
{
	uint16_t color_table[256];
	int i;
	for(i=0; i < 256; i++){
		color_table[i] = rand();
	}
	
	int x,y;
	for(x=0; x < MAP_XSIZE; x++){
		for(y=0; y < MAP_YSIZE; y++){
			// Create a grid like pattern
			uint16_t tmp = color_table[((y/16)*13) & 0xff];
			tmp = tmp ^ color_table[((x/16)*53) & 0xff];
			map_addr[x + MAP_XSIZE*y] = tmp;
		}
	}
}

// Use mmap in a fairly non portable way to map in memory in the same
// addresses as used in rotate.c in lab 5
void initialize_sdl_rotate(void)
{      
	
	if(mmap((void *)0x01000000, 0x01000000, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS,0,0) !=0x01000000){
		fprintf(stderr,"Could not allocate required memory mapping\n");
		fprintf(stderr,"This is most likely because Address space layout randomization is used\n");
		fprintf(stderr,"Please try again (it will most likely work after you try a few times).\n");
		exit(1);
	}
	if(mmap((void *)0x81000000, 0x08000000, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS,0,0) != 0x81000000){
		fprintf(stderr,"Could not allocate required memory mapping\n");
		fprintf(stderr,"This is most likely because Address space layout randomization is used\n");
		fprintf(stderr,"Please try again (it will most likely work after you try a few times).\n");
		exit(1);
	}

	if(SDL_Init(SDL_INIT_VIDEO) < 0) {
		fprintf(stderr,"Could not initialize SDL library\n");
		exit(1);
	}

	thescreen = SDL_SetVideoMode(FB_XSIZE, FB_YSIZE, 32, SDL_HWSURFACE);
	if(!thescreen){
		fprintf(stderr, "Could not initialize SDL Video mode\n");
		SDL_Quit();
		exit(1);
	}
	SDL_EnableKeyRepeat(150,50);


	clock_gettime(CLOCK_MONOTONIC, &next_delaytime);
	next_delaytime.tv_nsec = 0;


	initialize_sdl_map((uint16_t *) 0x81800000);
}
