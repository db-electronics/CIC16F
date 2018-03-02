
;************************************************************************
#include <p16f15313.inc>
;************************************************************************
; CONFIG1
; __config 0xD7FE
 __CONFIG _CONFIG1, _FEXTOSC_ECM & _RSTOSC_EXT1X & _CLKOUTEN_OFF & _CSWEN_OFF & _FCMEN_OFF
; CONFIG2
; __config 0xEF3E
 __CONFIG _CONFIG2, _MCLRE_OFF & _PWRTE_OFF & _LPBOREN_OFF & _BOREN_OFF & _BORV_LO & _ZCD_OFF & _PPS1WAY_ON & _STVREN_OFF
; CONFIG3
; __config 0xFF9F
 __CONFIG _CONFIG3, _WDTCPS_WDTCPS_31 & _WDTE_OFF & _WDTCWS_WDTCWS_7 & _WDTCCS_SC
; CONFIG4
; __config 0xFFEF
 __CONFIG _CONFIG4, _BBSIZE_BB512 & _BBEN_OFF & _SAFEN_ON & _WRTAPP_OFF & _WRTB_OFF & _WRTC_OFF & _WRTSAF_OFF & _LVP_ON
; CONFIG5
; __config 0xFFFF
 __CONFIG _CONFIG5, _CP_OFF 
;************************************************************************
 
mem	    udata   0x20
lock	    res	    0x10
key	    res	    0x10
x	    res	    1
swait	    res	    1
lwait	    res	    1

dout	    equ	    0		; data out is bit0 of GPIO
din	    equ	    1		; data in is bit1 of GPIO
led	    equ	    4
	
;************************************************************************
; macros
loadlock    macro L1,L2,L3,L4,L5,L6,L7,L8,L9,LA,LB,LC,LD,LE,LF
	movlw	L1
	movwf	lock+0x1
	movlw	L2
	movwf	lock+0x2
	movlw	L3
	movwf	lock+0x3
	movlw	L4
	movwf	lock+0x4
	movlw	L5
	movwf 	lock+0x5
	movlw	L6
	movwf 	lock+0x6
	movlw	L7
	movwf 	lock+0x7
	movlw	L8
	movwf 	lock+0x8
	movlw	L9
	movwf 	lock+0x9
	movlw	LA
	movwf 	lock+0xA
	movlw	LB
	movwf 	lock+0xB
	movlw	LC
	movwf 	lock+0xC
	movlw	LD
	movwf 	lock+0xD
	movlw	LE
	movwf 	lock+0xE
	movlw	LF
	movwf 	lock+0xF
    endm

loadkey	    macro K2,K3,K4,K5,K6,K7,K8,K9,KA,KB,KC,KD,KE,KF
	movlw	K2
	movwf	key+0x2
	movlw	K3
	movwf	key+0x3
	movlw	K4
	movwf	key+0x4
	movlw	K5
	movwf 	key+0x5
	movlw	K6
	movwf 	key+0x6
	movlw	K7
	movwf 	key+0x7
	movlw	K8
	movwf 	key+0x8
	movlw	K9
	movwf 	key+0x9
	movlw	KA
	movwf 	key+0xA
	movlw	KB
	movwf 	key+0xB
	movlw	KC
	movwf 	key+0xC
	movlw	KD
	movwf 	key+0xD
	movlw	KE
	movwf 	key+0xE
	movlw	KF
	movwf 	key+0xF
    endm
	
 ;***********************************************************************
; program start
	org	0x0000
	goto	main
isr
	org	0x0004
	bcf	PIE0, 0		; clear interrupt flag
	bsf	INTCON, 7	; re-enable interrupts
 
; 2 cycles to here from POR or ISR
main				
	banksel ANSELA
	clrf	ANSELA		; Digital I/O
	banksel TRISA
	movlw	B'00101110'	; 5 = in, 4 = out, 3 = in, 2 = in, 1 = in, 0 = out
	movwf	TRISA
	banksel	WPUA
	movlw	B'00100100'	; weak pull-up on 5 and 2
	movwf	WPUA
	banksel INTCON
	movlw	0x80		; global enable interrupts + GP2 falling edge int
	movwf	INTCON
	banksel PIE0
	movlw	0x01		; enable external interrupts
	movwf	PIE0
	banksel PORTA

; 17 from POR to cycles to here
; timing critical section here,
; lock sends stream ID. 15 cycles per bit--------
; stream id read at 34th, 49th, 64th and 79th cycles

; burn 17 cycles
	movlw	LOW region
	movwf	FSR1L
	movlw	HIGH region
	movwf	FSR1H
	movlw	0x01		; wait = (3*W) + 5
	call	wait		; burn 8 cycles
	nop
	nop
	nop
	nop

	btfsc	PORTA, din	; check stream ID bit
	bsf	0x31, 3		; copy to lock seed
	movlw	0x02		; wait=3*W+5
	call	wait		; burn 11 cycles
	nop
	nop

	btfsc	PORTA, din	; check stream ID bit
	bsf	0x31, 0		; copy to lock seed
	movlw	0x02		;
	call	wait		; burn 11 cycles
	nop
	nop

	btfsc	PORTA, din	; check stream ID bit
	bsf	0x31, 1		; copy to lock seed
	movlw	0x02		;
	call	wait		; burn 11 cycles
	nop
	nop

	btfsc	PORTA, din	; check stream ID bit
	bsf	0x31, 2		; copy to lock seed

; 80 cycles to here
; both seeds must be loaded within cycle 154
; 154 - 80 = 74 cycles to load
; curent region is stored in program flash, load and call proper loading subroutine
	
	moviw	0[FSR1]		; read lock/key offset for computed goto
	
; 85 cycles
; 0x00 = 3193 - USA/Canada
; 0x01 = 3195 - Europe
; 0x02 = 3196 - Asia 
; 0x03 = 3197 - UK/Italy/Australia
	
	brw			; add index in W to program counter
	goto	load3193	; 2 + 60 - load USA/Canada seeds
	goto	load3195	; 2 + 60 - load Europe seeds
	goto	load3196	; 2 + 60 - load Asia seeds
	goto	load3197	; 2 + 60 - load UK/Italy/Australia seeds
	
doneload	
	
; 147 cycles
;	clrf	FSR0H		; setup pointers
	movlw	LOW lock	; FSR0 points to lock/key region
	movwf	FSR0L
	clrf	FSR1H
	movlw	LOW x		; FSR1 points to X register emulator
	movwf	FSR1L
	banksel	PORTA		; just to be sure
	
;************************************************************************
; 154 cycles to main loop
	
mainloop
	movlw	0x01		; ldi 1
mainloop28
	movwf	x		; lxa - load x with a
mainloop54
	bcf	FSR0L, 4	; lbmi 0
			    ; ** 156 - in sync
	call	nextstreambit	; tml 147 - 10 cycles + 2 for call
			    ; ** 168 - in sync
	bsf	FSR0L, 4	; lbmi 1 - setting bit 4 changes 0x20 to 0x30
	call	nextstreambit	; tml 147 - 10 cycles + 2 for call
			    ; ** 181 - in sync
	movlw	LOW key		; tml 174 ; H := 1 in key mode, 10 cycles + 2 for call
	movwf	FSR0L
			    ; ** 183 - ahead by 10 cycles
	movlw	0x2		; burn 13 cycles
	call	wait		; need to skip over 3 useless instructions here
	nop			; tengen code tests din here (segher does not), maybe add this
	nop
			    ; ** 197 - in sync
	movlw	INDF0		; ldi 0, x
	clrf	INDF0		; ldi 0, x
			    ; ** 199 - in sync
	movwf	PORTA		; out	    // 200 ** key and lock both output here
	movfw	PORTA		; in	    // 201 ** lock is nop here, to permit read
	nop			; nop	    // 202 ** lock reads here
	bcf	PORTA, dout	; out0	    // 203 ** clear output bit
			    ; ** 203 - in sync
	movwf	INDF0		; s - store input bit
			    ; ** 204 - in sync

			    
; check if input bit matches what we output
	; din = 0x30.1 (keyseed)
	; calc = 0x20.0 (lockseed)
	; if ( 0x20.0 != 0x30.1 ) { die() }
	btfsc	key, 1		; if din == 0
	goto	rcvdOne	
rcvdZero
	btfsc	lock, 0		; if calc == 0
	goto	die		; din == 0, calc == 1 => die
	goto	endCheckDin		; 
rcvdOne
	btfss	lock, 0		; if calc == 1
	goto	die		; din == 1, calc == 0 => die
	nop			; 6 cycles for comparison either way
			    ; ** 210 - 20 cycles ahead
endCheckDin
		

			    
			    
			    
			    
			    
			    
	goto	mainloop

	
;************************************************************************
runhost
;	BL = 1, outputs = 0 - 7 cycles (CIC takes 16 cycles)
;************************************************************************			    
	clrf	PORTA	    ; 1 - clear outputs
	movlw	0xF0	    ; mask off nibble
	andwf	FSR0L, f    ; apply to BL
	movlw	0x01	    ; load BL with 1
	iorwf	FSR0L, f	
	return		    ; return, 7 cycles    
	
;************************************************************************
nextstreambit
;	tml 0x147
;	[H:0] := NEXT STREAM BIT - 10 cycles either pass, CIC takes 10 cycles
;************************************************************************
	movfw	x		; xax - not really exchanging but it's overwritten right after
	addwf	FSR0L		; add x (a really) 
	btfss	INDF0,0		; l, ska 0 - skip if bit0 = 0 
	goto	nsbskip		; t 11b
	movlw	0xF0		; lbli 0
	andwf	FSR0L		; lbli 0
	movlw	0x05		; ldi 5
	movwf	INDF0		; s
	return
nsbskip
	movlw	0xF0		; lbli 0
	andwf	FSR0L		; lbli 0
	clrf	INDF0		; ldi 0, s
	return

	
;************************************************************************	
; --------wait: 3*(W-1)+7 cycles (including call+return). W=0 -> 256!--------
wait			    ; 2 for call
	movwf	swait	    ; 1
wait0	decfsz	swait, f    ; 1 / 2 last pass
	goto	wait0	    ; 2
	return		    ; 2

;************************************************************************
; --------wait long: 8+(3*(w-1))+(772*w). W=0 -> 256!--------
longwait
	movwf	lwait
	clrw
longwait0
	call	wait
	decfsz	lwait, f
	goto	longwait0
	return

	
;************************************************************************
;-- change region in eeprom and die
; 0x00 = 3193 - USA/Canada
; 0x01 = 3195 - Europe
; 0x02 = 3196 - Asia 
; 0x03 = 3197 - UK/Italy/Australia
die
	; get current region byte
	banksel NVMADRL		    
	movlw	HIGH region
	movwf	NVMADRH
	movlw	LOW region
	movwf	NVMADRL
	bcf	NVMCON1, NVMREGS
	bsf	NVMCON1, RD
	movf	NVMDATL, W
	movwf	INDF0		    ; store region in INDFO for now
	
	; erase row
	bsf	NVMCON1, FREE
	bsf	NVMCON1, WREN
	bcf	INTCON, GIE
	movlw	0x55
	movwf	NVMCON2
	movlw	0xAA
	movwf	NVMCON2
	bsf	NVMCON1, WR
	bsf	INTCON, GIE
	bcf	NVMCON1, WREN
	
	
	
; --------get caught up--------
	banksel PORTA
dietrap
	bsf	PORTA, led	; LED on
	nop
	nop
	bcf	PORTA, led	; LED on
	goto	dietrap	
	
	
;************************************************************************
; 3193 - USA/Canada 
; LOCK: 3952F20F9109997 - avrcic
; LOCK: $1952f8271981115 - segher
; LOAD LOCK SEED (30 cycles)
; 30 + 28 + 2 for final goto = 60
load3193
	loadlock    0x1,0x9,0x5,0x2,0xF,0x8,0x2,0x7,0x1,0x9,0x8,0x1,0x1,0x1,0x5
; 3193 - USA/Canada 
; KEY: x952129F910DF97 - avrcic
; KEY: $x95212171985715 - segher
	loadkey	    0x9,0x5,0x2,0x1,0x2,0x1,0x7,0x1,0x9,0x8,0x5,0x7,0x1,0x5
	goto	doneload

;************************************************************************
; 3195 - Europe 
; LOCK: $17BEF0AF5706617 
; LOAD LOCK SEED (30 cycles)
; 30 + 28 + 2 for final goto = 60
load3195
	loadlock    0x1,0x7,0xB,0xE,0xF,0x0,0xA,0xF,0x5,0x7,0x0,0x6,0x6,0x1,0x7
; 3195 - Europe 
; KEY: $x7BD309F6EF2F97 
	loadkey	    0x7,0xB,0xD,0x3,0x0,0x9,0xF,0x6,0xE,0xF,0x2,0xF,0x9,0x7	
	goto	doneload

;************************************************************************
; 3196 - Asia 
; LOCK: 06AD70AF6EF666C  
; LOAD LOCK SEED (30 cycles)
; 30 + 28 + 2 for final goto = 60
load3196
	loadlock    0x0,0x6,0xA,0xD,0x7,0x0,0xA,0xF,0x6,0xE,0xF,0x6,0x6,0x6,0xC
; 3196 - Asia
; KEY: x6ADCF606EF2F97 
	loadkey	    0x6,0xA,0xD,0xC,0xF,0x6,0x0,0x6,0xE,0xF,0x2,0xF,0x9,0x7	
	goto	doneload
	
;************************************************************************
; 3197 - UK/Italy/Australia  
; LOCK: 558937A00E0D66D   
; LOAD LOCK SEED (30 cycles)
; 30 + 28 + 2 for final goto = 60
load3197
	loadlock    0x5,0x5,0x8,0x9,0x3,0x7,0xA,0x0,0x0,0xE,0x0,0xD,0x6,0x6,0xD
; 3197 - UK/Italy/Australia
; KEY: x79AA1E0D019D99 
	loadkey	    0x7,0x9,0xA,0xA,0x1,0xE,0x0,0xD,0x0,0x1,0x9,0xD,0x9,0x9	
	goto	doneload

;************************************************************************
	org 0x780
region	db	0x01, 0x01  ; default to NA region because we're the center of the world
	
end