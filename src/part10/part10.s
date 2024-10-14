;**************************************************************************************************************************************************************************
; Amiga Assembly Game Programming Tutorial series
; 
; Part 10 ‐ Blitter
;
; (c) 2024 Coppis
;**************************************************************************************************************************************************************************

         incdir     "include"
         include    "hw.i"
         include    "funcdef.i"
         include    "exec/exec_lib.i"
         include    "graphics/graphics_lib.i"
         


;**************************************************************************************************************************************************************************
; Constants
;**************************************************************************************************************************************************************************
ExecBase           EQU $4
NUM_COLORS         EQU 16
N_PLANES           equ 4
DISPLAY_WIDTH      equ 320
DISPLAY_HEIGHT     equ 256
DISPLAY_PLANE_SIZE equ DISPLAY_HEIGHT*(DISPLAY_WIDTH/8)
DISPLAY_ROW_SIZE   equ (DISPLAY_WIDTH/8)
IMAGE_WIDTH        equ 32
IMAGE_HEIGHT       equ 32
IMAGE_PLANE_SIZE   equ IMAGE_HEIGHT*(IMAGE_WIDTH/8)

                       ;5432109876543210
DMASET             EQU %1000001111000000                          ; enable only copper, bitplane, Blitter DMA




;**************************************************************************************************************************************************************************
; Main program
;**************************************************************************************************************************************************************************
main:
         bsr        init
         bsr        load_palette
         bsr        init_bplpointers
         move.w     #(320-32)/2,d0                                ; x position
         move.w     #(256-32)/2,d1                                ; y position
         mulu       #DISPLAY_ROW_SIZE,d1                          ; y_offset = y * DISPLAY_ROW_SIZE
         asr.w      #3,d0                                         ; x_offset = x/8
         add.w      d1,d0                                         ; sum the offsets
         ext.l      d0
         lea        screen,a1
         add.l      d0,a1                                         ; sum the offset to a1
         bsr        draw_tile

mainloop:

         btst       #6,$bfe001                                    ; left mouse button pressed?
         bne        mainloop                                                  

         bsr        shutdown
         rts


;**************************************************************************************************************************************************************************
; Subroutines
;**************************************************************************************************************************************************************************

;**************************************************************************************************************************************************************************
; Initialize the program
;**************************************************************************************************************************************************************************
init:
         move.l     ExecBase,a6
         jsr        _LVODisable(a6)                               ; stop multitasking
         lea        gfx_name,a1                                               
         jsr        _LVOOldOpenLibrary(a6)                        ; open graphics.library
         move.l     d0,gfx_base                                   ; save base address of graphics.library
         move.l     d0,a6
         move.l     $26(a6),sys_coplist                           ; save system copperlist address
         jsr        _LVOOwnBlitter(a6)                            ; takes the Blitter exclusive
         lea        CUSTOM,a5
          
         move.w     #DMASET,DMACON(a5)                            ; set dma channels

         move.l     #copperlist,COP1LC(a5)                        ; set our copperlist address into Copper
         move.w     d0,COPJMP1(a5)                                ; reset Copper PC to the beginning of our copperlist
         move.w     #0,$dff1fc                                    ; disable AGA
         move.w     #$c00,$dff106                                             
         move.w     #$11,$10c(a5)
         rts


;**************************************************************************************************************************************************************************
; Terminates the program by releasing resources to the operating system.
;**************************************************************************************************************************************************************************
shutdown:
         move.l     sys_coplist,COP1LC(a5)                        ; set the system copperlist
         move.w     d0,COPJMP1(a5)                                ; start the system copperlist
         
         move.l     gfx_base,a6
         jsr        _LVODisownBlitter(a6)                         ; release Blitter ownership
         move.l     ExecBase,a6
         jsr        _LVOEnable(a6)                                ; enable multitasking
         move.l     gfx_base,a1                                               
         jsr        _LVOCloseLibrary(a6)                          ; close graphics.library
         rts


;**************************************************************************************************************************************************************************
; Load palette into copperlist
;**************************************************************************************************************************************************************************
load_palette:
         lea        palette,a0                                    ; pointer to palette data in memory
         lea        cop_palette+2,a1                              ; pointer to palette data in copperlist
         moveq      #NUM_COLORS-1,d7                              ; number of loop iterations
.loop:   move.w     (a0)+,(a1)                                    ; copy color value from memory to copperlist
         add.w      #4,a1                                         ; point to the next value in the copperlist
         dbra       d7,.loop                                      ; repeats the loop (NUM_COLORS-1) times

         rts


;**************************************************************************************************************************************************************************
; Initializes bitplane pointers
;**************************************************************************************************************************************************************************
init_bplpointers:
         move.l     #screen,d0                                    ; address of image in d0
         lea        bplpointers,a1                                ; bitplane pointers in a1
         move.l     #(N_PLANES-1),d1                              ; number of loop iterations in d1
.loop:
         move.w     d0,6(a1)                                      ; copy low word of image address into BPLxPTL (low word of BPLxPT)
         swap       d0                                            ; swap high and low word of image address
         move.w     d0,2(a1)                                      ; copy high word of image address into BPLxPTH (high word of BPLxPT)
         swap       d0                                            ; resets d0 to the initial condition
         add.l      #DISPLAY_PLANE_SIZE,d0                        ; point to the next bitplane
         add.l      #8,a1                                         ; point to next bplpointer
         dbra       d1,.loop                                      ; repeats the loop for all planes
         rts 


;**************************************************************************************************************************************************************************
; Wait for the blitter to finish
;**************************************************************************************************************************************************************************
wait_blitter:
.loop:
         btst.b     #6,DMACONR(a5)                                ; if bit 6 is 1, the blitter is busy
         bne        .loop                                         ; and then wait until it's zero
         rts 


;**************************************************************************************************************************************************************************
; Draw a 32x32 pixel tile using blitter
;
; parameters:
; a1 - address where draw the tile
;**************************************************************************************************************************************************************************
draw_tile:
         movem.l    d0-d1/a0-a1,-(sp)                             ; copy registers into the stack

         moveq      #N_PLANES-1,d1
         lea        tile,a0                                       ; source image address
         bsr        wait_blitter
         move.w     #$ffff,BLTAFWM(a5)                            ; don't use mask
         move.w     #$ffff,BLTALWM(a5)
         move.w     #$09f0,BLTCON0(a5)                            ; enable channels A,D
                                                                  ; logical function = $f0, D = A
         move.w     #0,BLTCON1(a5)
         move.w     #0,BLTAMOD(a5)
         move.w     #(DISPLAY_WIDTH-IMAGE_WIDTH)/8,BLTDMOD(a5)    ; D channel modulus
.loop:
         bsr        wait_blitter
         move.l     a0,BLTAPT(a5)                                 ; source address
         move.l     a1,BLTDPT(a5)                                 ; destination address
         move.w     #64*32+2,BLTSIZE(a5)                          ; blit size: 32 rows for 2 words
         add.l      #IMAGE_PLANE_SIZE,a0                          ; advances to the next plane
         add.l      #DISPLAY_PLANE_SIZE,a1
         dbra       d1,.loop
         bsr        wait_blitter

         movem.l    (sp)+,d0-d1/a0-a1                             ; restore registers values from the stack
         rts


;**************************************************************************************************************************************************************************
; Variables
;**************************************************************************************************************************************************************************
gfx_name:
         dc.b       "graphics.library",0,0
gfx_base:
         dc.l       0                                             ; base address of graphics.library
sys_coplist:
         dc.l       0                                             ; address of system copperlist


;**************************************************************************************************************************************************************************
; Graphics data
;**************************************************************************************************************************************************************************

         SECTION    graphics_data,DATA_C                          ; segment loaded in CHIP RAM

tile     incbin     "tile.raw"
palette  incbin     "rtype.pal"

copperlist:  
         dc.w       DIWSTRT,$2c81                                 ; display window start at ($81,$2c)
         dc.w       DIWSTOP,$2cc1                                 ; display window stop at ($1c1,$12c)
         dc.w       DDFSTRT,$38                                   ; display data fetch start at $38
         dc.w       DDFSTOP,$d0                                   ; display data fetch stop at $d0
         dc.w       BPLCON1,0                                          
         dc.w       BPLCON2,0                                             
         dc.w       BPL1MOD,0                                             
         dc.w       BPL2MOD,0                                             

         dc.w       BPLCON0,$4200                                 ; 4 bitplane lowres video mode
 
cop_palette:
         dc.w       COLOR00,0,COLOR01,0,COLOR02,0,COLOR03,0
         dc.w       COLOR04,0,COLOR05,0,COLOR06,0,COLOR07,0
         dc.w       COLOR08,0,COLOR09,0,COLOR10,0,COLOR11,0
         dc.w       COLOR12,0,COLOR13,0,COLOR14,0,COLOR15,0
         
bplpointers:
         dc.w       BPL1PTH,$0000,BPL1PTL,$0000
         dc.w       BPL2PTH,$0000,BPL2PTL,$0000
         dc.w       BPL3PTH,$0000,BPL3PTL,$0000
         dc.w       BPL4PTH,$0000,BPL4PTL,$0000

         dc.w       $ffff,$fffe                                   ; end of copperlist


;**************************************************************************************************************************************************************************
; BSS DATA
;**************************************************************************************************************************************************************************

         SECTION    bss_data,BSS_C

screen   ds.b       (DISPLAY_PLANE_SIZE*N_PLANES)                 ; visible screen

         END 