;**************************************************************************************************************************************************************************
; Amiga Assembly Game Programming Tutorial series
; 
; Part 11 ‐ Tiles and tilemaps
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
TILESET_WIDTH      EQU 320
TILESET_HEIGHT     EQU 304
TILESET_ROW_SIZE   EQU (TILESET_WIDTH/8)
TILESET_PLANE_SIZE EQU (TILESET_HEIGHT*TILESET_ROW_SIZE)
TILESET_COLS       EQU 20
TILEMAP_ROW_SIZE   EQU 268*2
TILE_WIDTH         EQU 16
TILE_HEIGHT        EQU 16

                       ;5432109876543210
DMASET             EQU %1000001111000000                         ; enable only copper, bitplane, Blitter DMA




;**************************************************************************************************************************************************************************
; Main program
;**************************************************************************************************************************************************************************
main:
         bsr        init
         bsr        load_palette
         bsr        init_bplpointers
        ;  move.w     #0,d2                                        ; x position
        ;  move.w     #256-16,d3                                   ; y position
        ;  move.w     #7,d0                                        ; tile index
        ;  bsr        draw_tile
        ;  add.w      #16,d2
        ;  move.w     #8,d0
        ;  bsr        draw_tile

        ;  move.w     #107,d0                                      ; map column to draw
        ;  move.w     #16,d2                                       ; x position (multiple of 16)
        ;  bsr        draw_tile_column

         move.w     #196,d0                                      ; map column to start drawing from
         bsr        fill_screen_with_tiles

mainloop:

         btst       #6,$bfe001                                   ; left mouse button pressed?
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
         jsr        _LVODisable(a6)                              ; stop multitasking
         lea        gfx_name,a1                                               
         jsr        _LVOOldOpenLibrary(a6)                       ; open graphics.library
         move.l     d0,gfx_base                                  ; save base address of graphics.library
         move.l     d0,a6
         move.l     $26(a6),sys_coplist                          ; save system copperlist address
         jsr        _LVOOwnBlitter(a6)                           ; takes the Blitter exclusive
         lea        CUSTOM,a5
          
         move.w     #DMASET,DMACON(a5)                           ; set dma channels

         move.l     #copperlist,COP1LC(a5)                       ; set our copperlist address into Copper
         move.w     d0,COPJMP1(a5)                               ; reset Copper PC to the beginning of our copperlist
         move.w     #0,$dff1fc                                   ; disable AGA
         move.w     #$c00,$dff106                                             
         move.w     #$11,$10c(a5)
         rts


;**************************************************************************************************************************************************************************
; Terminates the program by releasing resources to the operating system.
;**************************************************************************************************************************************************************************
shutdown:
         move.l     sys_coplist,COP1LC(a5)                       ; set the system copperlist
         move.w     d0,COPJMP1(a5)                               ; start the system copperlist
         
         move.l     gfx_base,a6
         jsr        _LVODisownBlitter(a6)                        ; release Blitter ownership
         move.l     ExecBase,a6
         jsr        _LVOEnable(a6)                               ; enable multitasking
         move.l     gfx_base,a1                                               
         jsr        _LVOCloseLibrary(a6)                         ; close graphics.library
         rts


;**************************************************************************************************************************************************************************
; Load palette into copperlist
;**************************************************************************************************************************************************************************
load_palette:
         lea        palette,a0                                   ; pointer to palette data in memory
         lea        cop_palette+2,a1                             ; pointer to palette data in copperlist
         moveq      #NUM_COLORS-1,d7                             ; number of loop iterations
.loop:   move.w     (a0)+,(a1)                                   ; copy color value from memory to copperlist
         add.w      #4,a1                                        ; point to the next value in the copperlist
         dbra       d7,.loop                                     ; repeats the loop (NUM_COLORS-1) times

         rts


;**************************************************************************************************************************************************************************
; Initializes bitplane pointers
;**************************************************************************************************************************************************************************
init_bplpointers:
         move.l     #screen,d0                                   ; address of image in d0
         lea        bplpointers,a1                               ; bitplane pointers in a1
         move.l     #(N_PLANES-1),d1                             ; number of loop iterations in d1
.loop:
         move.w     d0,6(a1)                                     ; copy low word of image address into BPLxPTL (low word of BPLxPT)
         swap       d0                                           ; swap high and low word of image address
         move.w     d0,2(a1)                                     ; copy high word of image address into BPLxPTH (high word of BPLxPT)
         swap       d0                                           ; resets d0 to the initial condition
         add.l      #DISPLAY_PLANE_SIZE,d0                       ; point to the next bitplane
         add.l      #8,a1                                        ; point to next bplpointer
         dbra       d1,.loop                                     ; repeats the loop for all planes
         rts 


;**************************************************************************************************************************************************************************
; Wait for the blitter to finish
;**************************************************************************************************************************************************************************
wait_blitter:
.loop:
         btst.b     #6,DMACONR(a5)                               ; if bit 6 is 1, the blitter is busy
         bne        .loop                                        ; and then wait until it's zero
         rts 


;**************************************************************************************************************************************************************************
; Draw a 16x16 pixel tile using Blitter.
;
; parameters:
; d0.w - tile index
; d2.w - x position of the screen where the tile will be drawn
; d3.w - y position of the screen where the tile will be drawn
;**************************************************************************************************************************************************************************
draw_tile:
         movem.l    d0-a6,-(sp)                                  ; copy registers into the stack

         ; calculates the screen address where to draw the tile
         mulu       #DISPLAY_ROW_SIZE,d3                         ; y_offset = y * DISPLAY_ROW_SIZE
         lsr.w      #3,d2                                        ; x_offset = x / 8
         ext.l      d2
         lea        screen,a1
         add.l      d3,a1                                        ; sums offsets to a1
         add.l      d2,a1

         ; calculates row and column of tile in tileset starting from index
         ext.l      d0                                           ; extend d0 to a longword because the destination operand if divu must be long
         divu       #TILESET_COLS,d0                              
         swap       d0
         move.w     d0,d1                                        ; the rest indicates the tile column
         swap       d0                                           ; the quotient indicates the tile row
         
         ; calculates the x,y coordinates of the tile in the tileset
         lsl.w      #4,d0                                        ; y = row * 16
         lsl.w      #4,d1                                        ; x = column * 16
         
         ; calculate the offset to add to a0 to get the address of the source image
         mulu       #TILESET_ROW_SIZE,d0                         ; offset_y = y * TILESET_ROW_SIZE
         lsr.w      #3,d1                                        ; offset_x = x / 8
         ext.l      d1

         lea        tileset,a0                                   ; source image address
         add.l      d0,a0                                        ; add y_offset
         add.l      d1,a0                                        ; add x_offset

         moveq      #N_PLANES-1,d7
         
         bsr        wait_blitter
         move.w     #$ffff,BLTAFWM(a5)                           ; don't use mask
         move.w     #$ffff,BLTALWM(a5)
         move.w     #$09f0,BLTCON0(a5)                           ; enable channels A,D
                                                                 ; logical function = $f0, D = A
         move.w     #0,BLTCON1(a5)
         move.w     #(TILESET_WIDTH-TILE_WIDTH)/8,BLTAMOD(a5)    ; A channel modulus
         move.w     #(DISPLAY_WIDTH-TILE_WIDTH)/8,BLTDMOD(a5)    ; D channel modulus
.loop:
         bsr        wait_blitter
         move.l     a0,BLTAPT(a5)                                ; source address
         move.l     a1,BLTDPT(a5)                                ; destination address
         move.w     #64*16+1,BLTSIZE(a5)                         ; blit size: 16 rows for 1 word
         add.l      #TILESET_PLANE_SIZE,a0                       ; advances to the next plane
         add.l      #DISPLAY_PLANE_SIZE,a1
         dbra       d7,.loop
         bsr        wait_blitter

         movem.l    (sp)+,d0-a6                                  ; restore registers values from the stack
         rts


;**************************************************************************************************************************************************************************
; Draw a column of 12 tiles.
;
; parameters:
; d0.w - map column
; d2.w - x position (multiple of 16)
;**************************************************************************************************************************************************************************
draw_tile_column: 
         movem.l    d0-a6,-(sp)
        
         ; calculates the tilemap address from which to read the tile index
         lea        tilemap,a0
         lsl.w      #1,d0                                        ; offset_x = map_column * 2
         ext.l      d0
         add.l      d0,a0
         
         moveq      #12-1,d7
         move.w     #0,d3                                        ; y position
.loop:
         move.w     (a0),d0                                      ; tile index
         bsr        draw_tile
         add.w      #TILE_HEIGHT,d3                              ; increment y position
         add.l      #TILEMAP_ROW_SIZE,a0                         ; move to the next row of the tilemap
         dbra       d7,.loop

         movem.l    (sp)+,d0-a6
         rts


;**************************************************************************************************************************************************************************
; Fills the screen with tiles.
;
; parameters:
; d0.w - map column from which to start drawing tiles
;**************************************************************************************************************************************************************************
fill_screen_with_tiles:
         movem.l    d0-a6,-(sp)

         moveq      #20-1,d7
         move.w     #0,d2                                        ; position x
.loop    bsr        draw_tile_column
         add.w      #1,d0                                        ; increment map column
         add.w      #16,d2                                       ; increase position x
         dbra       d7,.loop

         movem.l    (sp)+,d0-a6
         rts
        
        
        


;**************************************************************************************************************************************************************************
; Variables
;**************************************************************************************************************************************************************************
gfx_name:
         dc.b       "graphics.library",0,0
gfx_base:
         dc.l       0                                            ; base address of graphics.library
sys_coplist:
         dc.l       0                                            ; address of system copperlist

tilemap  include    "gfx/rtype_tilemap.i"


;**************************************************************************************************************************************************************************
; Graphics data
;**************************************************************************************************************************************************************************

         SECTION    graphics_data,DATA_C                         ; segment loaded in CHIP RAM

tileset  incbin     "gfx/rtype_tileset.raw"                      ; 320x304, 16 colors
palette  incbin     "gfx/rtype.pal"

copperlist:  
         dc.w       DIWSTRT,$2c81                                ; display window start at ($81,$2c)
         dc.w       DIWSTOP,$2cc1                                ; display window stop at ($1c1,$12c)
         dc.w       DDFSTRT,$38                                  ; display data fetch start at $38
         dc.w       DDFSTOP,$d0                                  ; display data fetch stop at $d0
         dc.w       BPLCON1,0                                          
         dc.w       BPLCON2,0                                             
         dc.w       BPL1MOD,0                                             
         dc.w       BPL2MOD,0                                             

         dc.w       BPLCON0,$4200                                ; 4 bitplane lowres video mode
 
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

         dc.w       $ffff,$fffe                                  ; end of copperlist


;**************************************************************************************************************************************************************************
; BSS DATA
;**************************************************************************************************************************************************************************

         SECTION    bss_data,BSS_C

screen   ds.b       (DISPLAY_PLANE_SIZE*N_PLANES)                ; visible screen

         END 