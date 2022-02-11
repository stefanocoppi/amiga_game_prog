;***************************************************************************
; MAIN
;***************************************************************************

	include "hardware.i"

main:
    lea     CUSTOM,a5               ; indirizzo base dei chip custom
    bsr     take_system
    
mainloop:
    btst    #6,CIAAPRA              ; if left mouse button is pressed, exits
    bne.s   mainloop

    bsr     release_system
    rts
	
	include	"hw_takeover.s"