;***************************************************************************
; Amiga Hardware takeover routines
;***************************************************************************


; uncomment to allow execution from Workbench
; comment to run form AsmOne / AsmPro
;fromWB      set 1


;***************************************************************************
; VARIABLES
;***************************************************************************

gfx_name        dc.b    "graphics.library",0    ; name of graphics.library of Amiga O.S.
                even
gfx_base        dc.l    0                       ; indirizzo base della graphics.library
old_dma         dc.w    0                       ; saved state of DMACON
old_intena      dc.w    0                       ; saved value of INTENA
old_intreq      dc.w    0                       ; saved value of INTREQ
old_adkcon      dc.w    0                       ; saved value of ADKCON
return_msg      dc.l    0
wb_view         dc.l    0


;***************************************************************************
; Takes full control of Amiga hardware, disabling the O.S.
;***************************************************************************
take_system:
    move.l  EXEC_BASE,a6            ; base address of Exec library
    IFD     fromWB
    sub.l   a1,a1                   ; a1 = 0
    jsr     FindTask(a6)            ; find current task
    move.l  d0,a4                   
    tst.l   pr_CLI(a4)              ; if pr_CLI <> 0, then the process was
    bne     .fromCLI                ; executed from CLI
                                    ; else was executed from Workbench
    lea     pr_MsgPort(a4),a0       ; a0 = Workbench MsgPort
    jsr     WaitPort(a6)            ; wait for Workbench message
    lea     pr_MsgPort(a4),a0       
    jsr     GetMsg(a6)              ; get Workbench message
    move.l  d0,return_msg           ; store message pointer
    ENDC
.fromCLI:
    lea     gfx_name(PC),a1         ; name of the library to open
    jsr     OldOpenLibrary(a6)      ; opens graphics.library of O.S.
    move.l  d0,gfx_base             ; saves base address of graphics.library
    move.l  gfx_base(PC),a6         ; base address of graphics.library in a6
    move.l  $22(a6),wb_view         ; saves current view
    sub.l   a1,a1                   ; null view to reset video mode
    jsr     LoadView(a6)            ; resets video mode
    jsr     WaitOf(a6)              ; waits a vertical blank
    jsr     WaitOf(a6)
    move.l  EXEC_BASE,a6            ; base address of Exec library
    jsr     ExecForbid(a6)          ; disable O.S. multitasking
    jsr     Disable(a6)             ; disable O.S. interrupts
    lea     CUSTOM,a5               ; base address of custom chips registers
    move.w  INTENAR(a5),old_intena  ; save interrupts state
    move.w  INTREQR(a5),old_intreq
    move.w  ADKCONR(a5),old_adkcon  ; save ADKCON
    move.w  #$7fff,INTENA(a5)       ; disable all interrupts
    move.w  #$7fff,INTREQ(a5)
    move.w  DMACONR(a5),old_dma     ; saves state of DMA channels
    move.w  #$7fff,DMACON(a5)       ; disables all DMA channels
    rts


;***************************************************************************
; Releases the hardware control to the O.S.
;***************************************************************************
release_system:
    lea     CUSTOM,a5               ; base address of custom chips registers
    or.w    #$8000,old_dma          ; sets bit 15
    move.w  old_dma,DMACON(a5)      ; restores saved DMA state
    move.w  #$7fff,INTENA(a5)       ; disable all interrupts
    move.w  #$7fff,INTREQ(a5)
    move.w  #$7fff,ADKCON(a5)       ; clears ADKCON
    or.w    #$8000,old_intena       ; sets bit 15
    or.w    #$8000,old_intreq
    or.w    #$8000,old_adkcon
    move.w  old_intena,INTENA(a5)   ; restores saved interrupts state
    move.w  old_intreq,INTREQ(a5)
    move.w  old_adkcon,ADKCON(a5)   ; restores old value of ADKCON
    
    move.l  EXEC_BASE,a6
    tst.l   return_msg              ; was there a message from Workbench?
    beq     .nowbmsg                ; no. nothing to do
    move.l  return_msg,a1           ; pointer to Workbench message
    jsr     ReplyMsg(a6)            ; reply message to Workbench

.nowbmsg:
    jsr     ExecPermit(a6)          ; enables O.S. multitasking
    jsr     Enable(a6)              ; enables O.S. interrupts
    move.l  gfx_base,a6             ; base address of graphics.library
    move.l  wb_view,a1              ; saved workbench view
    jsr     LoadView(a6)            ; restores the workbench view
    move.l  gfx_base,a1             ; base address of graphics.library
    move.l  sys_cop1(a1),COP1LC(a5) ; restores the system copperlist 1
    move.l  sys_cop2(a1),COP2LC(a5) ; restores the system copperlist 2
    jsr     CloseLibrary(a6)        ; closes graphics.library
    rts