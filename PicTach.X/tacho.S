## EECE.3170: Microprocessors I
## UMass Lowell
## Author: Dana Maloney
## Based on Example code by Professor M. Geiger
    
// Including xc.h allows use of SFR names, bit masks, etc.
#include <xc.h>

    // Interrupt vector setup
    
    //VECTOR 9 (INPUT) SETUP
    .globl  __vector_dispatch_9    ## Port B change notification = vector #9
    .section .vector_9, code, keep
    .align 2
    .set nomips16
    .ent __vector_dispatch_9
__vector_dispatch_9:
    j  isrvector9	    ## Jump to actual ISR code, which is in text section
    nop
    .end __vector_dispatch_9
    .size __vector_dispatch_9, .-__vector_dispatch_9
    
    
    //VECTOR 11 (TIMER) SETUP
    .globl  __vector_dispatch_11    ## Timer 1 interrupt = vector #11
    .section .vector_11, code, keep
    .align 2
    .set nomips16
    .ent __vector_dispatch_11
__vector_dispatch_11:
    j  isrvector11	    ## Jump to actual ISR code, which is in text section
    nop
    .end __vector_dispatch_11
    .size __vector_dispatch_11, .-__vector_dispatch_11
    
    // Start of data section
    .data
    countaddress: .word 
    // Start of text section       
    .text		## Text section contains code
    .set noreorder	## Disable instruction reordering
    .globl main		## Define main label as a global entity
    .ent main		##   and an entry point    

main:
    
    // Configure port A for output
    sw	    zero, TRISA		    ## TRISA = 0  --> all PORTA bits = output
    sw	    zero, ANSELA	    ## ANSELA = 0 --> all PORTA bits digital
    ## li	    t0, _PORTA_RA3_MASK	    ## Mask for red LED in RGB    
    ## sw	    t0, LATASET		    ## Set Port A, bit 0 (turn LED1 on)
    //Configure port B inputs and outputs
    li	    t0, _PORTB_RB7_MASK	    ## Set RB7 in mask to 1
    sw	    t0, TRISB		    ## write TRISB. RB7 is now in, rest is out
    sw	    zero, ANSELB	    ## All of PORTB is digital
    
    // Configure Timer 1
    sw	    zero, T1CON		    ## Clear T1CON--disables timer to allow setup
    
    ori	    t1, zero, 31250	    ## Set t1 = initial PR1 value
    sw	    t1, PR1		    ## Currently set to 0.5 sec
    
    li	    t2, _IFS0_T1IF_MASK	    ## t2 = bit mask for checking Timer 1 interrupt flag
    
    ## Prescale clock
    li	    t3, _T1CON_TCKPS1_MASK  ## Prescale by factor of 64 (TCKPS = 10) BITMASK = 0x00000020
    sw	    t3, T1CONSET
    
    // Configure interrupts
    lui	    t3, 0x0001			## Want INTCON bit 16 (VS<0>) = 1
					##   so vectors 8 bytes apart
    ori	    t3, t3, _INTCON_MVEC_MASK   ## Enable multivectored interrupt mode
    sw	    t3, INTCON
    
    li	    t3, _IPC2_T1IP_MASK	    ## Set T1 interrupt priority level to 7
    sw	    t3, IPC2		    ## Implicitly sets subpriority level to 0
    
    li	    t3, _IPC2_CNBIP_MASK    ## Port B interrupt, pri = 7 (max)
    sw	    t3, IPC2SET
    
    li	    t3, _IFS0_T1IF_MASK	    ## t1 interrupt mask in t3
    sw	    t3, IEC0		
    
    li	    t3, _IEC0_CNBIE_MASK    ## Enable Port B change 
    sw	    t3, IEC0SET		    ## notification interrupts

    add	    t3, t4, zero	    ## Set bits in CNEN1B = 1 and CNEN0B = 0
    or	    t3, t3, t6		    ##   corresponding to switch positions
    sw	    t3, CNEN1B		    ##   (t4 = S1 bit mask; t6 = S2 bit mask)
    sw	    zero, CNEN0B	    ## Will detect falling edges on these pins
    
    li	    t3, _CNCONB_ON_MASK		    ## Enables Port B change notification
    ori	    t3, t3, _CNCONB_CNSTYLE_MASK    ## Enables edge detection
    sw	    t3, CNCONB
				    
    ei				    ## Enable interrupts globally
				    
    li	    t3, _T1CON_TON_MASK	    ## Enable Timer 1 by setting "ON" bit in T1CON
    sw	    t3, T1CONSET
    
    //Initialize address for tracking input state changes per period
    li	    t0, 0		    
    sw	    t0, 0x80000000
    li	    t0, 0
    sw	    t0, 0x80000004
  
    // Main loop for outside of interrupts
mainloop:
    
    //fast check
    lw	    t9, 0x80000004	## Load counter value
    move    t8, t9
    slti    t7, t8, 50			## 1 if t1 < 50 (50 * 2 * 60 = 6K RPM)
    bnez    t7, medspeed		## skip if < 50 clicks
    nop
    //set LED (RED)
    li	    t1, _PORTA_RA3_MASK		##red
    sw	    t1, LATASET
    j donechecking
    nop
    //medium speed check
    medspeed:
    move    t8, t9
    slti    t7, t8, 25			## 1 if t1 < 25 (3K RPM)
    bnez    t7, mainloopend		## skip if < 25 clicks
    nop
    //set LED (YELLOW)
    li	    t1, _PORTB_RB12_MASK	##green
    sw	    t1, LATBSET
    li	    t1, _PORTA_RA3_MASK		##red
    sw	    t1, LATASET
    j donechecking
    nop
    lowspeed:
    move    t8, t9
    slti    t7, t8, 4			## 1 if t1 < 4 (480 RPM)
    bnez    t7, mainloopend		## skip if < 4 clicks
    nop
    //set LED (GREEN)
    li	    t1, _PORTB_RB12_MASK	##green
    sw	    t1, LATBSET
    
    donechecking:
    
    li t6, 0x00060000		   ##loop counter value
    //delay loop
    delay:
    beqz t6, contmainloop
    nop
    addi t6, t6, -1
    j delay
    
    contmainloop:
   
    //	Reset Tach LED
    li	    t1, _PORTA_RA3_MASK
    sw	    t1 , LATACLR	    ##set port
    li	    t1, _PORTB_RB12_MASK
    sw	    t1 , LATBCLR	    ##set port
    
    
mainloopend:
    j	mainloop
    nop
    .end main
  
//==============================================================================
  
    // Handle Timer1 interrupt--clear interrupt flag and toggle LED
    .global isrvector11
    .ent isrvector11
isrvector11:			    ## TIMER INTERRUPT
    li	    t2, _IFS0_T1IF_MASK    
    sw	    t2, IFS0CLR		    ## Clear T1IF in software!
       
endvec11:
 
    //	Reset counter & store last value to new address
    lw	    t2, 0x80000000
    sw	    t2, 0x80000004 ## MAY BREAK PROGRAM
    li	    t0, 0
    sw	    t0, 0x80000000
    
    eret		    ## Return from interrupt
    .end isrvector11
    
//CODE FROM HW5 BELOW
    
    // Handle Port B change interrupt--check switches and toggle appropriate LEDs
    .global isrvector9
    .ent isrvector9
isrvector9:			    ##BUTTON INTERRUPT  
    //clear flag
    li	    t3, _IFS0_CNBIF_MASK    ## Clear Port B change notification flag
    sw	    t3, IFS0CLR		    ##    in IFS0
    li	    t3, _PORTB_RB7_MASK	    ## t4 = 0x00000080 --> mask for S1
    sw	    t3, CNFBCLR		    ## Clear flag input state change

    //debug code to show input change
    li	    t3, _PORTA_RA0_MASK	    ## Toggle input indicator LED
    sw	    t3, LATAINV 
    
    //code to up tick counter
    lw	    t3, 0x80000000		    ## load counter value
    addi    t3, 1		    ## add 1 to it
    sw	    t3, 0x80000000		    ## save it back to s0
    
    
    eret		    ## Return from interrupt
    .end isrvector9