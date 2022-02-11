;***************************************************************************
; COSTANTS used in bare metal hardware programming of Amiga
;***************************************************************************

                IFND	HARDWARE_I
HARDWARE_I      SET	1

;***************************************************************************
; O.S. routines
;***************************************************************************
EXEC_BASE       equ  4
OldOpenLibrary  equ -$198
CloseLibrary    equ -$19e
Disable         equ -$78
Enable          equ -$7e
OwnBlitter	equ -$1c8
DisOwnBlitter	equ -$1ce
ExecForbid	equ -132
ExecPermit	equ -138
FindTask        equ -$126
WaitPort        equ -$180
GetMsg          equ -$174
ReplyMsg        equ -$17a
LoadView        equ -$de
WaitOf          equ -$10e

pr_CLI          equ $ac
pr_MsgPort      equ $5c

sys_cop1        equ $26
sys_cop2        equ $32

;***************************************************************************
; Custom chips
;***************************************************************************
CIAAPRA         equ $bfe001
CUSTOM          equ $dff000

BLTDDAT		equ	$000
DMACONR		equ	$002
VPOSR		equ	$004
VHPOSR		equ	$006
DSKDATR		equ	$008
JOY0DAT		equ	$00a
JOY1DAT		equ	$00c
CLXDAT		equ	$00e
ADKCONR		equ	$010
POT0DAT		equ	$012
POT1DAT		equ	$014
POTGOR		equ	$016
SERDATR		equ	$018
DSKBYTR		equ	$01a
INTENAR		equ	$01c
INTREQR		equ	$01e
DSKPT		equ	$020
DSKPTH		equ	$020
DSKPTL		equ	$022
DSKLEN		equ	$024
DSKDAT		equ	$026
REFPTR		equ	$028
VPOSW		equ	$02a
VHPOSW		equ	$02c
COPCON		equ	$02e
SERDAT		equ	$030
SERPER		equ	$032
POTGO		equ	$034
JOYTEST		equ	$036
STREQU		equ	$038
STRVBL		equ	$03a
STRHOR		equ	$03c
STRLONG		equ	$03e
BLTCON0		equ	$040
BLTCON1		equ	$042
BLTAFWM		equ	$044
BLTALWM		equ	$046
BLTCPT		equ	$048
BLTCPTH		equ	$048
BLTCPTL		equ	$04a
BLTBPT		equ	$04c
BLTBPTH		equ	$04c
BLTBPTL		equ	$04e
BLTAPT		equ	$050
BLTAPTH		equ	$050
BLTAPTL		equ	$052
BLTDPT		equ	$054
BLTDPTH		equ	$054
BLTDPTL		equ	$056
BLTSIZE		equ	$058
BLTCMOD		equ	$060
BLTBMOD		equ	$062
BLTAMOD		equ	$064
BLTDMOD		equ	$066
BLTCDAT		equ	$070
BLTBDAT		equ	$072
BLTADAT		equ	$074
DSKSYNC		equ	$07e
COP1LC		equ	$080
COP1LCH		equ	$080
COP1LCL		equ	$082
COP2LC		equ	$084
COP2LCH		equ	$084
COP2LCL		equ	$086
COPJMP1		equ	$088
COPJMP2		equ	$08a
COPINS		equ	$08c
DIWSTRT		equ	$08e
DIWSTOP		equ	$090
DDFSTRT		equ	$092
DDFSTOP		equ	$094
DMACON		equ	$096
CLXCON		equ	$098
INTENA		equ	$09a
INTREQ		equ	$09c
ADKCON		equ	$09e
AUD0LC		equ	$0a0
AUD0LCH		equ	$0a0
AUD0LCL		equ	$0a2
AUD0LEN		equ	$0a4
AUD0PER		equ	$0a6
AUD0VOL		equ	$0a8
AUD0DAT		equ	$0aa
AUD1LC		equ	$0b0
AUD1LCH		equ	$0b0
AUD1LCL		equ	$0b2
AUD1LEN		equ	$0b4
AUD1PER		equ	$0b6
AUD1VOL		equ	$0b8
AUD1DAT		equ	$0ba
AUD2LC		equ	$0c0
AUD2LCH		equ	$0c0
AUD2LCL		equ	$0c2
AUD2LEN		equ	$0c4
AUD2PER		equ	$0c6
AUD2VOL		equ	$0c8
AUD2DAT		equ	$0ca
AUD3LC		equ	$0d0
AUD3LCH		equ	$0d0
AUD3LCL		equ	$0d2
AUD3LEN		equ	$0d4
AUD3PER		equ	$0d6
AUD3VOL		equ	$0d8
AUD3DAT		equ	$0da
BPL1PT		equ	$0e0
BPL1PTH		equ	$0e0
BPL1PTL		equ	$0e2
BPL2PT		equ	$0e4
BPL2PTH		equ	$0e4
BPL2PTL		equ	$0e6
BPL3PT		equ	$0e8
BPL3PTH		equ	$0e8
BPL3PTL		equ	$0ea
BPL4PT		equ	$0ec
BPL4PTH		equ	$0ec
BPL4PTL		equ	$0ee
BPL5PT		equ	$0f0
BPL5PTH		equ	$0f0
BPL5PTL		equ	$0f2
BPL6PT		equ	$0f4
BPL6PTH		equ	$0f4
BPL6PTL		equ	$0f6
BPL7PT          equ     $0f8
BPL8PT          equ     $0fc
BPLCON0		equ	$100
BPLCON1		equ	$102
BPLCON2		equ	$104
BPLCON3		equ	$106
BPL1MOD		equ	$108
BPL2MOD		equ	$10a
BPLCON4		equ	$10c
BPL1DAT		equ	$110
BPL2DAT		equ	$112
BPL3DAT		equ	$114
BPL4DAT		equ	$116
BPL5DAT		equ	$118
BPL6DAT		equ	$11a
SPR0PT		equ	$120
SPR0PTH		equ	$120
SPR0PTL		equ	$122
SPR1PT		equ	$124
SPR1PTH		equ	$124
SPR1PTL		equ	$126
SPR2PT		equ	$128
SPR2PTH		equ	$128
SPR2PTL		equ	$12a
SPR3PT		equ	$12c
SPR3PTH		equ	$12c
SPR3PTL		equ	$12e
SPR4PT		equ	$130
SPR4PTH		equ	$130
SPR4PTL		equ	$132
SPR5PT		equ	$134
SPR5PTH		equ	$134
SPR5PTL		equ	$136
SPR6PT		equ	$138
SPR6PTH		equ	$138
SPR6PTL		equ	$13a
SPR7PT		equ	$13c
SPR7PTH		equ	$13c
SPR7PTL		equ	$13e
SPR0POS		equ	$140
SPR0CTL		equ	$142
SPR0DATA	equ	$144
SPR0DATB	equ	$146
SPR1POS		equ	$148
SPR1CTL		equ	$14a
SPR1DATA	equ	$14c
SPR1DATB	equ	$14e
SPR2POS		equ	$150
SPR2CTL		equ	$152
SPR2DATA	equ	$154
SPR2DATB	equ	$156
SPR3POS		equ	$158
SPR3CTL		equ	$15a
SPR3DATA	equ	$15c
SPR3DATB	equ	$15e
SPR4POS		equ	$160
SPR4CTL		equ	$162
SPR4DATA	equ	$164
SPR4DATB	equ	$166
SPR5POS		equ	$168
SPR5CTL		equ	$16a
SPR5DATA	equ	$16c
SPR5DATB	equ	$16e
SPR6POS		equ	$170
SPR6CTL		equ	$172
SPR6DATA	equ	$174
SPR6DATB	equ	$176
SPR7POS		equ	$178
SPR7CTL		equ	$17a
SPR7DATA	equ	$17c
SPR7DATB	equ	$17e
COLOR00		equ	$180
COLOR01		equ	$182
COLOR02		equ	$184
COLOR03		equ	$186
COLOR04		equ	$188
COLOR05		equ	$18a
COLOR06		equ	$18c
COLOR07		equ	$18e
COLOR08		equ	$190
COLOR09		equ	$192
COLOR10		equ	$194
COLOR11		equ	$196
COLOR12		equ	$198
COLOR13		equ	$19a
COLOR14		equ	$19c
COLOR15		equ	$19e
COLOR16		equ	$1a0
COLOR17		equ	$1a2
COLOR18		equ	$1a4
COLOR19		equ	$1a6
COLOR20		equ	$1a8
COLOR21		equ	$1aa
COLOR22		equ	$1ac
COLOR23		equ	$1ae
COLOR24		equ	$1b0
COLOR25		equ	$1b2
COLOR26		equ	$1b4
COLOR27		equ	$1b6
COLOR28		equ	$1b8
COLOR29		equ	$1ba
COLOR30		equ	$1bc
COLOR31		equ	$1be
HTOTAL		equ	$1c0
HSSTOP		equ	$1c2
HBSTRT		equ	$1c4
HBSTOP		equ	$1c6
VTOTAL		equ	$1c8
VSSTOP		equ	$1ca
VBSTRT		equ	$1cc
VBSTOP		equ	$1ce
SPRHSTRT	equ	$1d0
SPRHSTOP	equ	$1d2
BPLHSTRT	equ	$1d4
BPLHSTOP	equ	$1d6
HHPOSW		equ	$1d8
HHPOSR		equ	$1da
BEAMCON0	equ	$1dc
HSSTRT		equ	$1de
VSSTRT		equ	$1e0
HCENTER		equ	$1e2
DIWHIGH		equ	$1e4
BPLHMOD		equ	$1e6
SPRHPT		equ	$1e8
SPRHPTH		equ	$1e8
SPRHPTL		equ	$1ea
BPLHPT		equ	$1ec
BPLHPTH		equ	$1ec
BPLHPTL		equ	$1ee
FMODE		equ	$1fc


;***************************************************************************
; CIA hardware registers
;***************************************************************************

CIAA		equ	$bfe001
CIAB		equ	$bfd000

; registers
CIAPRA		equ	$000
CIAPRB		equ	$100
CIADDRA		equ	$200
CIADDRB		equ	$300
CIATALO		equ	$400
CIATAHI		equ	$500
CIATBLO		equ	$600
CIATBHI		equ	$700
CIATODLO	equ	$800
CIATODMID	equ	$900
CIATODHI	equ	$a00
CIASDR		equ	$c00
CIAICR		equ	$d00
CIACRA		equ	$e00
CIACRB		equ	$f00

;***************************************************************************
; MACROS
;***************************************************************************

BREAK   MACRO
        ; instruction added to allow a memory watch with WinUAE debugger,
        ; using w 0 100 2
        clr.w   $100 
        ENDM

	ENDC	; HARDWARE_I