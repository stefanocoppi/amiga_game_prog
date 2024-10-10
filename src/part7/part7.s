;**************************************************************************************************************************************************************************
; Amiga Assembly Game Programming Tutorial series
; 
; Part 7 ‐ The Copper and the copperlist
;
; (c) 2024 Coppis
;**************************************************************************************************************************************************************************

  incdir     "include"
  include    "hw.i"


;**************************************************************************************************************************************************************************
; Constants
;**************************************************************************************************************************************************************************
ExecBase     EQU $4
Disable      EQU -$78
Enable       EQU -$7e
OpenLibrary  EQU -$198
CloseLibrary EQU -$19e

                 ;5432109876543210
DMASET       EQU %1000001010000000     ; enable only copper DMA




;**************************************************************************************************************************************************************************
; Main program
;**************************************************************************************************************************************************************************
main:
  bsr        init

mainloop:

  btst       #6,$bfe001                ; left mouse button pressed?
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
  jsr        Disable(a6)               ; stop multitasking
  lea        gfx_name,a1                                               
  jsr        OpenLibrary(a6)           ; open graphics.library
  move.l     d0,gfx_base               ; save base address of graphics.library
  move.l     d0,a6
  move.l     $26(a6),sys_coplist       ; save system copperlist address
  lea        CUSTOM,a5
          
  move.w     #DMASET,DMACON(a5)        ; set dma channels

  move.l     #copperlist,COP1LC(a5)    ; set our copperlist address into Copper
  move.w     d0,COPJMP1(a5)            ; reset Copper PC to the beginning of our copperlist
  move.w     #0,$dff1fc                ; disable AGA
  move.w     #$c00,$dff106                                             
  move.w     #$11,$10c(a5)
  rts


;**************************************************************************************************************************************************************************
; Terminates the program by releasing resources to the operating system.
;**************************************************************************************************************************************************************************
shutdown:
  move.l     sys_coplist,COP1LC(a5)    ; set the system copperlist
  move.w     d0,COPJMP1(a5)            ; start the system copperlist

  move.l     ExecBase,a6
  jsr        Enable(a6)                ; enable multitasking
  move.l     gfx_base,a1                                               
  jsr        CloseLibrary(a6)          ; close graphics.library
  rts


;**************************************************************************************************************************************************************************
; Variables
;**************************************************************************************************************************************************************************
gfx_name:
  dc.b       "graphics.library",0,0
gfx_base:
  dc.l       0                         ; base address of graphics.library
sys_coplist:
  dc.l       0                         ; address of system copperlist


;**************************************************************************************************************************************************************************
; Graphics data
;**************************************************************************************************************************************************************************

  SECTION    graphics_data,DATA_C      ; segment loaded in CHIP RAM

copperlist:  
  dc.w       $100,$0200                ; BPLCON0 lowres video mode
  dc.w       $0180,$000f               ; puts blue value into COLOR0 register
  dc.w       $9601,$fffe               ; WAIT line 150 ($96)
  dc.w       $0180,$0000               ; puts black value into COLOR0 register
  dc.w       $ffff,$fffe               ; end of copperlist

  END 