## Struttura dati

In questo tutorial creeremo la prima entità del nostro gioco, l'astronave del giocatore. Definiremo un'apposita struttura dati che ci consentirà di rappresentare lo ship.

Vediamo come definire le strutture dati in Assembler. Useremo due direttive: **rsreset** ed **rs**.

    rsreset
    Reset structure offset counter to zero.

    <label> rs.<size> <expression>
    Assigns the current value of the structure offset counter to <label>. Afterwards the counter is incremented by the instruction’s <size> multiplied by <expression>. Any valid M68k size extension is allowed for <size>: b, w, l.

Una tipica dichiarazione di struttura ha la seguente forma:

              rsreset                   ; resets structure offset counter to zero
    <label1>  rs.<size> <expression1>   ; first field declaration
    <label2>  rs.<size> <expression2>   ; second field declaration
              ...
    length    rs.b      0               ; defines structure length in bytes

Applichiamo adesso la sintassi appena vista alla definizione delle proprietà che caratterizzeranno il player's ship:

    ; player's ship
                        rsreset
    ship.x              rs.w       1    ; position
    ship.y              rs.w       1
    ship.vx             rs.w       1    ; x component of velocity
    ship.vy             rs.w       1    ; y component of velocity
    ship.bobdata        rs.l       1    ; address of graphic data
    ship.mask           rs.l       1    ; address of mask
    ship.current_frame  rs.w       1    ; current animation frame
    ship.state          rs.w       1    ; current state
    ship.anim_delay     rs.w       1    ; delay between two animation frames
    ship.ind_timer      rs.w       1    ; timer for indestructible state
    ship.flash_timer    rs.w       1    ; timer for flashing
    ship.visible        rs.w       1    ; visibility flag: 1 visible, 0 invisible
    ship.fire_timer     rs.w       1    ; timer to implement a delay between two shots
    ship.fire_delay     rs.w       1    ; delay between two shots (in frames)
    ship.fire_type      rs.w       1    ; type of fire
    ship.length         rs.b       0

## Inizializzazione

Per poter usare la struttura dati definita, dobbiamo creare un'istanza in memoria. Prima però definiamo alcune costanti che ci saranno utili per inizializzare la struttura dati.

    ;***************************************************************************************************************
    ; Constants
    ;***************************************************************************************************************

    ...

    ; ship
    SHIP_WIDTH                equ 32 ; width in pixel
    SHIP_WIDTH_B              equ (SHIP_WIDTH/8) ; width in byte
    SHIP_HEIGHT               equ 30 ; height in pixel
    SHIP_X0                   equ 16 ; starting position
    SHIP_Y0                   equ 81                                                        
    SHIP_VX0                  equ 2 ; default speed in px/frame
    SHIP_VY0                  equ 2
    SHIP_MIN_X                equ 32
    SHIP_MAX_X                equ (16+DISPLAY_WIDTH-SHIP_WIDTH)
    SHIP_MIN_Y                equ 0
    SHIP_MAX_Y                equ (VIEWPORT_HEIGHT-SHIP_HEIGHT)
    SHIP_ANIM_IDLE            equ 1 ; animation frame
    SHIP_ANIM_UP              equ 0
    SHIP_ANIM_DOWN            equ 2
    SHIP_ANIM_EXPL            equ 3
    SHIP_FRAME_SZ             equ (SHIP_WIDTH_B*SHIP_HEIGHT)*N_PLANES
    SHIP_MASK_SZ              equ (SHIP_WIDTH_B*SHIP_HEIGHT)
    SHIP_SPRITESHEET_WIDTH    equ 96
    SHIP_SPRITESHEET_HEIGHT   equ 30
    SHIP_STATE_ACTIVE         equ 0
    SHIP_STATE_HIT            equ 1
    SHIP_STATE_INDESTRUCTIBLE equ 2
    ; ship states:
    ; - active: the ship accepts player input, can collide with the background, aliens and bullets.
    ; - hit: the ship has been hit, plays the explosion animation. Collisions are disabled.
    ; - indestructible: the ship is reset to its initial position, is indestructible and flashes.
    ;
    ; ship state transitions:
    ; initial state and after losing a life: indestructible
    ; indestructible ---> active : the transition occurs after a time interval
    ; active ---> hit : when the ship collides with backgrounds, aliens and bullets
    ; hit ---> indestructible : when the ship's explosion ends

    SHIP_MAX_ANIM_DELAY       equ 4 ; delay between two animation frames (in frames)
    SHIP_IND_STATE_DURATION   equ (50*5) ; duration of the indestructible state (in frame)
    SHIP_FLASH_DURATION       equ 3 ; flashing duration (in frame)


    BASE_FIRE_INTERVAL        equ 7 ; delay between two shots for base bullets
    BULLET_TYPE_BASE          equ 0 ; types of bullets

Adesso, nella sezione "Variables", definiamo l'istanza della struttura dati ship, rispettando la dimensione dei vari campi che abbiamo definito prima.

    ;***************************************************************************************************************
    ; Variables
    ;***************************************************************************************************************

    ...

    ; player ship
    pl_ship  dc.w    SHIP_X0,SHIP_Y0            ; position
             dc.w    SHIP_VX0,SHIP_VY0          ; velocity
             dc.l    ship_gfx                   ; address of graphic data
             dc.l    ship_mask                  ; address of mask
             dc.w    SHIP_ANIM_IDLE             ; current animation frame
             dc.w    SHIP_STATE_ACTIVE          ; current state             
             dc.w    SHIP_MAX_ANIM_DELAY        ; delay between two animation  frames
             dc.w    SHIP_IND_STATE_DURATION    ; timer for indestructible state
             dc.w    SHIP_FLASH_DURATION        ; timer for flashing
             dc.w    1                          ; visibility flag: 1 visible, 0  invisible
             dc.w    0                          ; timer to implement a delay between two shots
             dc.w    BASE_FIRE_INTERVAL         ; delay between two shots (in frames)
             dc.w    BULLET_TYPE_BASE           ; type of fire

## Disegno

Dopo aver definito la struttura dati del player's ship, iniziamo a definire le routine che operano su di essa. Se vogliamo fare un'analogia con la programmazione Object Oriented, la struttura dati rappresenta la classe, mentre le routine i metodi della classe. Per i nomi delle routine che operano su una struttura dati, definiamo la convenzione che devono iniziare con "<nome_struttura_dati>_". Quindi per il player's ship i nomi delle routine devono iniziare con ship\_.

La prima routine che creiamo è quella per disegnare lo ship, che chiameremo ship_draw. Questa routine riuserà la routine draw_bob creata nella parte 13.

    ;***********************************************************************************************
    ; Draws the player's ship.
    ;***********************************************************************************************
    movem.l    d0-a6,-(sp)

    lea        pl_ship,a6                     ; ship's instance base address

    tst.w      ship.visible(a6)               ; ship is visible?
    beq        .return                        ; if is not, returns immediately
    move.l     ship.bobdata(a6),a0            ; Bob's image address
    move.l     ship.mask(a6),a1               ; Bob's mask address
    move.l     draw_buffer,a2                 ; destination video buffer address
    move.w     ship.x(a6),d0                  ; x-coordinate of Bob in px
    move.w     ship.y(a6),d1                  ; y-coordinate of Bob in px
    move.w     #SHIP_WIDTH,d2                 ; bob width in px
    move.w     #SHIP_HEIGHT,d3                ; bob height in px
    move.w     ship.current_frame(a6),d4      ; spritesheet column of the bob
    move.w     #0,d5                          ; spritesheet row of the bob
    move.w     #SHIP_SPRITESHEET_WIDTH,a3     ; spritesheet width
    move.w     #SHIP_SPRITESHEET_HEIGHT,a4    ; spritesheet height
    bsr        draw_bob

    .return:
    movem.l    (sp)+,d0-a6
    rts

Questa routine deve essere richiamata nel mainloop, subito dopo scroll_background:

	mainloop	bsr     wait_vblank
						bsr     swap_buffers

						bsr     scroll_background

						bsr     ship_draw

						btst    #6,$bfe001           ; left mouse button pressed?
						bne     mainloop   

## Lettura del joystick

## Update
movimento con joystick
animazione 