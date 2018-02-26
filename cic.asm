
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
 
mem	udata   0x20
lock	res	0x10
key	res	0x10
x	res	1
swait	res	1
lwait	res	1

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
	bcf	INTCON, 1	; clear interrupt flag
	bsf	INTCON, 7	; re-enable interrupts
 
main
	movlw	0x87
	movwf	FSR0H
	movlw	0x80
	movwf	FSR0L

doneload	
loop	
	moviw	FSR0++
	goto	loop


	
; -----------------------------------------------------------------------
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

; -----------------------------------------------------------------------
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

; -----------------------------------------------------------------------
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
	
; -----------------------------------------------------------------------
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

end