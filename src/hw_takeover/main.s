;***************************************************************************
; MAIN
;***************************************************************************

    incdir  "dh1:game_prog_tutorials/src/hw_takeover/"
	include "hardware.i"

main:
    lea     CUSTOM,a5               ; base address of custom chips registers
    bsr     take_system
    
mainloop:
    btst    #6,CIAAPRA              ; if left mouse button is pressed, exits
    bne.s   mainloop

    bsr     release_system
    rts
	
	include	"hw_takeover.s"