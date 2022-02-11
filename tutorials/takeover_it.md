# Prendere il controllo dell'hardware di Amiga
Amiga dispone di un sistema operativo abbastanza sofisticato che fornisce al programmatore tutti gli strumenti per utilizzare le capacità grafiche e sonore. Tuttavia, storicamente, pochissimi giochi hanno fatto uso del sistema operativo. Praticamente tutti i giochi commerciali che furono sviluppati per Amiga bypassavano il sistema operativo e prendevano il controllo diretto dell'hardware ed erano scritti in linguaggio Assembly. Il motivo è semplice: in questo modo è possibile ottenere le massime performance dall'hardware. Lo svantaggio è dato dalla maggior quantità di codice da dover scrivere, dato che non si possono usare le librerie del sistema operativo e che si usa un linguaggio di basso livello come l'Assembly. Inoltre il debug è più difficoltoso ed è possibile anche bloccare la macchina in caso di errori di programmazione. Queste criticità sono mitigate dal fatto che tutto sommato Amiga fornisce già molte funzionalità grafiche implementate nei chip custom e che quindi la quantità di codice necessaria ad un videogioco non è eccessiva. Inoltre i videogiochi per Amiga erano prevalentemente 2D e quindi con una complessità molto inferiore a quelli 3D attuali. Infatti un tipico videogioco poteva richiedere da 5000 a 10000 linee di codice Assembly, che sono pochissime se paragonate ai giochi moderni. Normalmente veniva sviluppato da un solo
programmatore, che spesso era anche il game designer e il grafico. Per questo motivo, ricreare al giorno d'oggi videogiochi per Amiga è fattibile per un programmatore che lo faccia per hobby. Dato che vogliamo creare un videogioco in assembly, programmando direttamente l'hardware di Amiga, dobbiamo prendere il controllo dell'hardware di Amiga, bypassando il S.O. Innanzitutto vedremo i concetti teorici necessari, poi scriveremo il codice necessario.

## Operazioni necessarie a prendere il controllo dell'hardware
Adesso scriveremo una routine che consente al nostro programma di prendere il controllo completo dell'hardware di Amiga, disabilitando il sistema operativo. E' la prima routine da richiamare in un videogioco, la chiameremo **take_system**. Cosa deve fare questa routine? L'obiettivo principale è quello di consentire l'utilizzo esclusivo delle risorse hardware al nostro programma, in particolare la cpu. Passiamo in rassegna in dettaglio le operazioni da effettuare per raggiungere questo obiettivo. Innanzitutto resettare il modo video, in modo da avere uno stato "pulito" dei registri dei chip custom. Poi disabilitare il multitasking del sistema operativo, che è una tecnica che suddivide il tempo di cpu tra più processi. Una componente del sistema operativo, chiamata Scheduler, assegna la cpu ai processi per un quanto di tempo predefinito. In questo modo l'utente ha l'impressione che sia possibile eseguire più processi simultaneamente. Dato che stiamo realizzando un videogioco, vogliamo evitare di cedere la cpu ad altri processi, per questo motivo disabilitiamo la funzionalità multitasking del sistema operativo. Ma non è ancora sufficiente, infatti la cpu potrebbe essere sottratta al nostro gioco anche dall'esecuzione degli interrupt del sistema operativo. Vedremo in un paragrafo successivo cosa sono gli interrupt. Per ora basta sapere che sono dei segnali che interrompono l'esecuzione di un processo e passano l'esecuzione ad una routine di gestione dell'interrupt. Per evitare ciò, disabilitamo gli interrupt generati dal sistema operativo. Ma ancora non è sufficiente per assicurare l'uso esclusivo della cpu al nostro gioco: occorre disabilitare tutti gli interrupt del sistema agendo direttamente sul registro che li abilita o disabilita. L'ultima operazione che farà la nostra routine è quella di disabilitare tutti i canali DMA, in modo da consentire al gioco di abilitare solo quelli che effettivamente utilizzerà. Vedremo in un paragrafo successivo il concetto di DMA, per ora basta sapere che è un dispositivo hardware che consente l'accesso diretto alla memoria ad un particolare sottosistema, ad esempio al Blitter o al processore audio Paula. Prima di disabilitare gli interrupt ed il DMA, sarà necessario salvare i valori attuali, per poterli poi ripristinare al termine del programma.

## Restituire il controllo dell'hardware al S.O. di Amiga
Al termine del nostro programma, dovremo restituire il controllo dell'hardware al S.O. di Amiga, in modo da poter tornare al S.O. senza bloccare la macchina. Per fare ciò scriveremo una seconda routine, che chiameremo **release_system**. Vediamo cosa dovrà fare questa routine. In pratica dovrà effettuare l'inverso delle operazioni effettuate dalla take_system. Innanzitutto dovrà ripristinare lo stato dei canali DMA, salvato prima della disattivazione. Quindi dovrà ripristinare gli interrupt di sistema, sempre allo stato salvato prima della disattivazione. Dovrà quindi riabiitare il multitasking e gli interrupt del S.O. Dovrà rispristinare la view salvata prima del reset del modo video. Dovrà ripristinare le copperlist di sistema. Una copperlist altro non è che un programma per il coprocessore Copper, contenente le istruzioni per visualizzare lo schermo. Dato che il nostro gioco userà una propria copperlist, che definiremo in futuro, al termine dobbiamo ripristinare quelle di sistema. Infine chiuderà la libreria grafica. 

## Interrupts
Un interrupt è un segnale che dice alla cpu di interrompere l'esecuzione del programma corrente ed eseguire una routine di gestione dell'interrupt. Al termine di tale routine, il programma riprende dal punto in cui era stato interrotto. Gli interrupt solitamente vengono generati da dispositivi esterni alla cpu quali: chip custom, disco, porte seriali etc... E' un meccanismo utile per comunicare in maniera asincrona. In sua assenza, la cpu dovrebbe fare un ciclo in cui controlla lo stato delle periferiche esterne (polling). La cpu MC68000 ha 7 livelli di interrupt, che vanno da 1 (minima priorità) a 7 (massima priorità). Su Amiga, il livello 7 viene usato solo per interrupt generati da periferiche esterne connesse al bus di espansione. Una routine di interrupt può essere a sua volta interrotta da un interrupt di livello più alto (e di maggiore priorità). Come fa la cpu a sapere quale routine di gestione dell'interrupt chiamare? Esiste una tabella contenente i puntatori a tali routine, in base ai livelli di interrupt. I puntatori alle routine di gestione degli interrupt vengono chiamati autovettori (hanno un significato diverso da quello matematico). La struttura della tabella degli autovettori di interrupt è la seguente:

| Offset | Descrizione                |
|--------|----------------------------|
| $64    | Interrupt di livello 1     |
| ...    | ...                        |
| $7c    | Interrupt di livello 7     |


E' disponibile un registro, denominato INTENA, che consente di abilitare o disabilitare alcuni segnali di interrupt. INTENA ($dff09a) è a sola scrittura, mentre INTENAR($dff01c) è a sola lettura.

| BIT# | Nome      | Descrizione                                                                                   |
|------|-----------|-----------------------------------------------------------------------------------------------|
| 15   |SET/CLR    | Se vale 1 allora i bit ad 1 indicano abilitazione, se vale 0 allora indicano disabilitazione  |
| 14   |INTEN      | Interruttore generale di abilitazione di tutti gli interrupt                                  |
| 13   |EXTER      | Interrupt esterno                                                                             |
| 12   |DSKSYN     | Indica che il registro DSKSYN contiene i dati letti                                           |
| 11   |RBF        | Indica che il buffer della porta seriale è pieno di dati                                      |
| 10   |AUD3       | Lettura di un blocco di dati dal canale audio 3 terminata                                     |
|  9   |AUD2       | Lettura di un blocco di dati dal canale audio 2 terminata                                     |
|  8   |AUD1       | Lettura di un blocco di dati dal canale audio 1 terminata                                     |
|  7   |AUD0       | Lettura di un blocco di dati dal canale audio 0 terminata                                     |
|  6   |BLIT       | Indica che il Blitter ha terminato                                                            |
|  5   |VERTB      | Indica che il pennello elettronico ha raggiunto la linea 0                                    |
|  4   |COPER      | Interrupt generato dal Copper                                                                 |
|  3   |PORTS      | Interrupt generato dalle porte di I/O                                                         |
|  2   |SOFT       | Interrupt generati via software                                                               |
|  1   |DSKBLK     | Fine trasferimento di un blocco di dati da disco                                              |
|  0   |TBE        | Buffer della porta seriale vuoto                                                              |

E' disponibile un registro, denominato INTREQ, per richiedere o cancellare un interrupt. Anche qui abbiamo, come per INTENA, una coppia di registri: INTREQ ($dff09c) a sola scrittura e INTREQR ($dff01e) a sola lettura. La struttura del registro è analoga a INTENA. Solitamente una routine di gestione di un interrupt, utilizza INTREQR per capire chi ha generato l'interrupt. Poi userà il registro INTREQ per cancellare il bit dell'interrupt generato, per indicare che tale interrupt è stato servito.

## DMA
DMA è un acronimo di "Direct Memory Access". Sappiamo che alla memoria Chip di Amiga possono avere accesso sia i chip custom che la cpu. Per aumentare il livello di parallelismo di Amiga, i progettisti hanno creato dei canali che consentono ai chip custom di accedere direttamente alla memoria, senza l'aiuto della cpu, lasciandola libera di fare altro. Questo è uno dei punti di forza dell'architettura di Amiga. L'accesso ai canali DMA viene regolamentato da un "DMA Controller" presente nel chip Agnus.
I canali DMA possono essere abilitati o disabilitati tramite il registro DMACON ($dff096) a sola scrittura. Esiste il registro a sola lettura DMACONR ($dff002) per leggere lo stato di tali canali. La seguente tabella mostra il significato dei bit di tali registri:

| BIT# | Nome      | Descrizione                                                                                   |
|------|-----------|-----------------------------------------------------------------------------------------------|
| 15   |SET/CLR    | Se vale 1 allora i bit ad 1 indicano abilitazione, se vale 0 allora indicano disabilitazione  |
| 14   |BlitBusy   | a sola lettura, indica che il Blitter è occupato                                              |
| 13   |BlitZero   |                                                                                               |
| 12   |X          | non usato                                                                                     |
| 11   |X          | non usato                                                                                     |
| 10   |BlitPri    | Priorità del Blitter                                                                          |
|  9   |Master     | Interruttore generale di abilitazione di tutti gli interrupt                                  |
|  8   |BPLEN      | Canale DMA per i bitplane                                                                     |
|  7   |COPEN      | Canale DMA del Copper                                                                         |
|  6   |BLTEN      | Canale DMA del Blitter                                                                        |
|  5   |SPREN      | Canale DMA degli Sprite                                                                       |
|  4   |DSKEN      | Canale DMA del disco                                                                          |
|  3   |AUD3EN     | Canale DMA per la voce 3 dell'audio                                                           |
|  2   |AUD2EN     | Canale DMA per la voce 2 dell'audio                                                           |
|  1   |AUD1EN     | Canale DMA per la voce 1 dell'audio                                                           |
|  0   |AUD0EN     | Canale DMA per la voce 0 dell'audio                                                           |


## Sistema Operativo di Amiga e librerie
Il S.O. di Amiga, denominato AmigaOS e contenuto in una memoria ROM denominata Kickstart, è composto da varie librerie, che non sono tutte presenti in memoria contemporaneamente, ma vengono caricate dinamicamente. La sua componente principale viene denominata Exec e svolge le funzionalità di task scheduler, memory management, gestione degli interrupt, comunicazione inter-processo tramite messaggi, caricamento delle librerie dinamiche. All'indirizzo $4, denominato ExecBase, c'è il puntatore alle funzioni della libreria. Per poter utilizzare una libreria dinamica, è necessario prima aprirla usando la funzione OpenLibrary dell'Exec. Questa funzione restituisce un puntatore all'indirizzo base della libreria, che va usato per chiamare tutte le funzioni della libreria stessa. Quando si smette di usare una libreria, è necessario chiuderla usando la funzione CloseLibrary.


## Organizzazione del codice
Prima di iniziare a scrivere un po' di codice, è necessario definire una struttura che sarà poi seguita per l'intera serie di tutorial.
Per favorire il riuso e la manutenibilità del codice, è opportuno suddividerlo in file distinti, che conterranno le routine per gestire una determinata funzionalità.
Poi avremo un file main che conterrà il main loop e richiamerà i vari moduli. Inoltre la definizione di costanti, macro viene raggruppata in file include con estensione ".i".


### Evitare inclusioni multiple
Quando si utilizzano file include per le costanti, potrebbe capitare di includere lo stesso file più volte. Per evitare inclusioni multiple, con conseguenti errori dell'Assemblaer, si usa la direttiva dell'assembler IFND che assembla il codice che segue soltanto se la costante specificata come parametro non è stata già definita. La seconda riga definisce tale costante HARDWARE_I in modo che,ad una seconda inclusione del file, il codice che segue IFND non venga incluso. Alla fine del file deve essere inserita l'istruzione ENDC che indica la fine del codice soggetto alla clausola IFND. Un esempio di file include è il seguente:

                    IFND    HARDWARE_I
    HARDWARE_I      SET	    1

    ; definizione di costanti e macro

    ENDC

### Struttura di un modulo

Un tipico modulo di libreria avrà la seguente struttura:

- inclusione di costanti, macro, strutture dati
- definizione di variabili
- routine esposte pubblicamente
- routine private, richiamate solo internamente al modulo

### Documentazione del codice
E' buona norma documentare correttamente il codice sorgente. Per fare ciò definiremo alcune convenzioni.
Ciascuna sezione sarà delimitata da un'intestazione fatta in questo modo:

    ;***************************************************************************
    ; SECTION NAME
    ;***************************************************************************

Ciascuna routine sarà preceduta dalla seguente intestazione:

    ;***************************************************************************
    ; Routine explanation
    ;
    ; Input:
    ; <register.size> = parameter description
    ;
    ; Output:
    ; <register.size> = value
    ;***************************************************************************
    routine_name:
        istructions     ; comment
        rts

I commenti che spiegano le operazioni svolte saranno inserite sulla stessa riga delle istruzioni, separate da una tabulazione.


## Implementazione di take_system

Sintetizziamo le operazioni che deve svolgere la routine che prende il controllo dell'hardware nel seguente pseudo-codice:

    take_system:
        reset video mode
        disable O.S. multitasking
        disable O.S. interrupts
        disable all system interrupts
        disable all DMA channels 

### Resettare il modo video
La prima operazione che vogliamo fare è resettare il modo video, in modo che tutti i registri dei chip custom siano reinizializzati. Per fare ciò utilizzeremo il sistema operativo di Amiga. La funzione che ci serve è denominata LoadView e serve a caricare una vista o modalità grafica. Come parametro prevede un puntatore ad una struttura che descrive la view in a1. Nel caso si voglia resettare il modo video, è necessario che a1 sia zero. Prima di resettare il modo video, è necessario salvare il valore corrente della view in una variabile, in modo da poterla poi ripristinare all'uscita del programma. Prima di poter usare una qualsiasi funzione è necessario caricare in memoria la libreria corrispondente, in questo caso la "graphics.library". Tale operazione si effettua con la funzione dell'Exec "OpenLibrary", che richiede in input una stringa con il nome della libreria in a1. In output ritorna un puntatore all'indirizzo base della libreria aperta in d0. Salveremo l'indirizzo base della graphics.library in una variabile. Le funzioni dell'Exec si richiamano specificando degli offset rispetto ad una base, che si trova all'indirizzo di memoria $4, denominato EXEC_BASE. Dopo aver resettato il modo video, aspettiamo un paio di vertical blank, usando la funzione WaitOf. Il vertical blank è il segnale generato quando il pennello elettronico ha terminato di disegnare lo schermo.

### Definizione di variabili
Vediamo adesso come definire delle variabili in linguaggio assembly. Inizieremo definendo una variabile di tipo stringa contenente il nome della libreria che vogliamo caricare, ovvero la "graphics.library". Per fare ciò usiamo la direttiva dc.b dell'Assembler, che definisce un blocco di memoria contenente costanti di tipo byte, ovvero una stringa. Attenzione che una stringa in assembly deve essere sempre terminata dal byte 0. Inoltre la cpu MC68000 ha un bus indirizzi a 16 bit e quindi gli indirizzi delle variabili devono essere allineati a 16 bit. Per questo si usa la direttiva EVEN che aggiunge dei byte a zero per rendere pari l'indirizzo successivo alla stringa.
Per definire variabili di tipo word o long, è sufficiente usare la direttiva dc.w (per le word) oppure dc.l (per le long) dell'Assembler, che definisce una variabile di tipo word o long, a 16 o 32 bit, e permette di assegnarne il valore iniziale.
Il seguente frammento di codice mostra la definizione delle variabili:

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

### Disabilitare multitasking ed interrupts del S.O.
La seconda operazione da fare è quella di disabilitare il multitasking e gli interrupts del sistema operativo. Per fare ciò si usano le funzioni dell'Exec Forbid, che disabilita il multitasking e Disable che disabilita gli interrupts. In questo modo siamo sicuri che il nostro videogioco utilizzerà tutto il tempo di CPU a disposizione, evitando di cederlo ad altri processi o alle routine di gestione degli interrupts.

### Disabilitare interrupts di sistema e canali DMA
La terza operazione da fare è quella più delicata, infatti è quella che disabilita tutti gli interrupt di sistema e tutti i canali DMA. Disabilitare gli interrupt di sistema evita al videogioco qualsiasi interruzione che possa sottrargli cicli di CPU. Disabilitare i canali DMA consente di evitare sprechi di cicli di DMA per funzioni non desiderate.
Vedremo che in fase di inizializzazione del gioco dovremo riabilitare soltanto i canali DMA che utilizzeremo. Prima di disabilitare qualsiasi cosa, salviamo lo stato dei registri in opportune variabili: old_intena,old_intreq,old_adkcon,old_dma. Quindi disabilitiamo gli interrups scrivendo nel registro INTENA. E poi disabilitiamo i canali DMA scrivendo nel registro DMACON.
Il seguente frammento di codice implementa quanto descritto precedentemente:


    ;***************************************************************************
    ; Takes full control of Amiga hardware, disabling the O.S.
    ;***************************************************************************
    take_system:
        move.l  EXEC_BASE,a6            ; base address of Exec library
        lea     gfx_name(PC),a1         ; name of the library to open
        jsr     OpenLibrary(a6)         ; opens graphics.library of O.S.
        move.l  d0,gfx_base             ; saves base address of graphics.library
        move.l  gfx_base(PC),a6         ; base address of graphics.library in a6
        move.l  $22(a6),wb_view         ; saves current view
        sub.l   a1,a1                   ; null view to reset video mode
        jsr     LoadView(a6)            ; resets video mode
        jsr     WaitOf(a6)              ; waits a vertical blank
        jsr     WaitOf(a6)
        move.l  EXEC_BASE,a6            ; base address of Exec library
        jsr     Forbid(a6)          ; disable O.S. multitasking
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



## Implementazione di release_system

Sintetizziamo le operazioni che deve svolgere la nostra routine nel seguente pseudo-codice:

    release_system:
        restore saved DMA channels
        restore saved interrupts state
        enable O.S. multitasking
        enable O.S. interrupts
        restore saved view
        restore system copperlists
        close graphics.library

La prima operazione è quella di ripristinare i canali DMA allo stato precedente. Per impostare i canali DMA, è necessario settare il bit 15 del registro DMACON. Questa operazione si effettua con l'istruzione OR. A questo punto è possibile scrivere il valore salvato precedentemente nel registro DMACON.
La seconda operazione è quella di ripristinare lo stato degli interrupts. Prima di modificare i registri di gestione degli interrupt, è necessario disabilitarli tutti. Quindi settiamo il bit 15 nei valori salvati, per poter impostare tali valori nei registri di scrittura. Quindi ripristiniamo i valori salvati nelle variabili neri registri INTENA, INTREQ e ADKCON.
A questo punto riabilitiamo il multitasking richiamando la funzionde dell'Exec Permit e successivamente gli interrupts del S.O. tramite la funzione Enable.
Non ci resta che ripristinare la view allo stato precedente al reset del modo video. Per fare ciò impostiamo il puntatore alla view salvata in a1 e chiamiamo la funzione LoadView della graphics.library. Attenzione a caricare in a6 il puntatore all'indirizzo base della graphics.library.
La successiva operazione è quella di ripristinare le copperlist di sistema. I valori di default si trovano nella struttura dati della graphics.library stessa, agli offset dati dalle costanti sys_cop1($26) e sys_cop2($32). Tali valori devono essere inseriti nei registri COP1LC e COP2LC dei custom chips, prestando attenzione a caricare a5 con l'indirizzo base dei custom registers CUSTOM ($dff000).
L'ultima operazione è la chiusura della graphics.library usando la funzione CloseLibrary dell'Exec.
Di seguito il codice sorgente della routine descritta:

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
        jsr     Permit(a6)              ; enables O.S. multitasking
        jsr     Enable(a6)              ; enables O.S. interrupts
        move.l  gfx_base,a6             ; base address of graphics.library
        move.l  wb_view,a1              ; saved workbench view
        jsr     LoadView(a6)            ; restores the workbench view
        move.l  gfx_base,a1             ; base address of graphics.library
        move.l  sys_cop1(a1),COP1LC(a5) ; restores the system copperlist 1
        move.l  sys_cop2(a1),COP2LC(a5) ; restores the system copperlist 2
        jsr     CloseLibrary(a6)        ; closes graphics.library
        rts


## Implementazione del main loop

Il flusso principale del nostro programma sarà implementato nel file "main.s". Inizialmente troveremo i file di inclusione.
Quindi ci sarà una sezione di inizializzazione in cui ci sarà la chiamata alla take_system per prendere il controllo dell'hardware.
A questo punto entreremo nel "main loop" ovvero il ciclo principale del programma.
Per il momento ci limiteremo a controllare se viene premuto il tasto sinistro del mouse, in tal caso si esce dal loop.
All'uscita del loop richiameremo la release_system per ridare il controllo dell'hardware al S.O. e termineremo il programma.
In coda troviamo l'inclusione dei vari moduli, per il momento soltanto il modulo "hw_takeover.s".
Di seguito il codice sorgente del modulo main.s:


    ;***************************************************************************
    ; MAIN
    ;***************************************************************************

        include "hardware.i"

    main:
        lea     CUSTOM,a5               ; base address of custom chips
        bsr     take_system
        
    mainloop:
        btst    #6,CIAAPRA              ; if left mouse button is pressed, exits
        bne.s   mainloop

        bsr     release_system
        rts
        
        include	"hw_takeover.s"

## Esecuzione e conclusioni

A questo punto è possibile provare ad assemblare il codice sorgente. Se stiamo usando AsmOne oppure AsmPro, è sufficiente digitare il comando "a".
Se non ci sono errori di compilazione, è possibile eseguire il codice. Per fare ciò, con AsmOne/AsmPro useremo il comando "j".
Vedremo soltanto uno schermo nero. Premendo il tasto sinistro del mouse, si tornerà allo schermo dell'assemblatore.
Il risultato di tanto sforzo di programmazione per il momento non è molto entusiasmante, ma  tutto funziona come previsto. Nelle prossime puntate inizieremo ad aggiungere codice per implementare il nostro videogioco e il risultato dell'esecuzione del codice inizierà ad essere più gratificante, perchè saranno visualizzate delle immagini e poi si potrà interagire con esse.

Il codice sorgente completo è disponible [qui](https://github.com/stefanocoppi/amiga_game_prog/tree/master/src/hw_takeover).