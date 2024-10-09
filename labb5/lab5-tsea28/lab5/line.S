#include "memorymap.h"
#include "config.h"
#include "asmutil.h"

        .text

        /* Set up register aliases to make the code easier to understand */
        lineinfoptr .req r0
        mapbase     .req r1
        xpos        .req r2
        ypos        .req r3
        dx          .req r4
        dy          .req r5
        fb          .req r6
        fb_offset   .req r7
        xcounter    .req r8
        ycounter    .req r9
        tmp         .req r10
        tmp2        .req r11

	
/***********************************************************************
 * This function is responsible for rendering a single line to the
 * specified framebuffer by incrementing the start coordinates
 * Inputs: r0: Contains a pointer to the lineinfo structure (see below)
 **********************************************************************/
render_line_asm:
	/* For simplicity reasons, save all relevant registers */
	push {r4-r11,r14}

        /* The pointer passed in register r0 points to a lineinfo
         * structure which contains the following information at the
	 * specified offsets:

         * At offset 0: Pointer to the map (reference image) we should rotate
         * At offset 4: X coordinate we should start fetching the line
         *                from in 24.8 fixed point format
         * At Offset 8: Y coordinate we should start fetching the line
         *                from in 24.8 fixed point format
         * At offset 12: Delta-X increment in the map for each pixel
         *               written to the framebuffer.
         * At offset 16: Delta-Y increment in the map for each pixel
         *               written to the framebuffer.
         * At offset 20: Pointer to the base address of the framebuffer
         * At offset 24: The first pixel in the framebuffer we should write to. (Note: One pixel is two bytes!) */ 
	
        /* Load registers from the lineinfo struct */
        ldr mapbase,[lineinfoptr,#0]
        ldr xpos,[lineinfoptr,#4]
        ldr ypos,[lineinfoptr,#8]
        ldr dx,[lineinfoptr,#12]
        ldr dy,[lineinfoptr,#16]
        ldr fb,[lineinfoptr,#20]
        ldr fb_offset,[lineinfoptr,#24]
        /* lineinfoptr is incremented further down */
        
        ldr xcounter,=FB_XSIZE

        add fb_offset,fb_offset /* Need to multiply fb_offset with two as a pixel is two bytes */
        add fb,fb_offset,fb     /* fb = fb+fb_offset */

        /* This loop is meant to implement the following piece of C code:
        	for (x=0; x<FB_XSIZE; x++) {
        		fb[fb_offset++] = map_addr[fixed_point_xy_to_linear(xpos,ypos)];
        		xpos += dx;
        		ypos += dy;
        	}
        */
pixelloop:
        /* First we convert xpos and ypos to a linear address in the reference image */
        
        /* Calculate (ypos/256)*MAP_XSIZE */
        asr tmp,ypos,#8
        lsl tmp,#MAP_XSIZE_LOG2

        /* Calculate x/256 */
        asr tmp2,xpos,#8

        add tmp,tmp2 /* tmp is now the linear position in the framebuffer */
        lsl tmp,#1   /* However, we need to take into account that we have two bytes per pixel */

        
        /* Lookup the correct pixel in the reference image */
        ldrh tmp,[mapbase,tmp]
        
        /* Store the pixel in the framebuffer and increment the framebuffer pointer*/
        strh tmp,[fb],#2

        add xpos,dx
        add ypos,dy
        
        add xcounter,xcounter,#-1
        cmp xcounter,#0
        bne pixelloop
	pop {r4-r11,r14}
	bx lr /* And return from the subroutine when done with the line */
        
        .global render_all_lines_asm
render_all_lines_asm:
        /* Push all regs except r12, sp, and pc
         (we are not using all regs at the moment, but you might need to do so
        when modifying this function...) */
        push {r4-r11,r14}



        ldr ycounter,=FB_YSIZE

	/* Note: The argument to render_lines_asm (r0, aka lineinfoptr)
	 * will be passed through directly to render_line_asm here without
	 * any need to do anything special */
rowloop:
	/* These two lines will ensure that the the logic anaylzer is triggered for each line*/
	ldr tmp,=0x9fff0000
	str tmp,[tmp]

	bl render_line_asm
        
        add lineinfoptr,#28 /* Make sure lineinfoptr point to the next line */
        
        /* Keep track on which line we are currently working and quit if we are done */
        add ycounter,ycounter,#-1
        cmp ycounter,#0

        bne rowloop

	
        pop {r4-r11,r14}
        bx   lr                 /* return */




	.global redraw_reference_image_asm

	/* This function is empty for the moment, but if you intend to modify
	   the reference image you should do so here. */
redraw_reference_image_asm:
	bx lr
        .end
