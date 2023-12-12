##Dana Maloney
    
/* Including xc.h for hardware specific masks, etc */
#include <xc.h>

    
/* TIMER INTERRUPT CONFIG AND VECTOR */
    
    .globl  __vector_dispatch_11    ## Timer 1 interrupt = vector 11
    .section .vector_11, code, keep
    .align 2
    .set nomips16
    .ent __vector_dispatch_11
__vector_dispatch_11:
    j  isrvector11	    ## on interrupt, jump to timer ISR.
    nop
    .end __vector_dispatch_11
    .size __vector_dispatch_11, .-__vector_dispatch_11
    
/* MAIN SECTION */
    
    .text			## Text section contains code
    .set noreorder		## Disable instruction reordering
    .globl main		## Define main label as a global entity
    .ent main		## and an entry point  
    
main:
    /* Configure IO.
       Need RB7/RB1 as input.
       Need RB12, RA2, RA3 as outputs (R, G, B lights)
       Start with config PORTA */
    sw	    zero, TRISA		    ## TRISA = 0  --> all PORTA bits = output
    sw	    zero, ANSELA	    ## ANSELA = 0 --> all PORTA bits digital
    
    /* Config PORTB */
    li	    t0, _PORTB_RB7_MASK	    ## Set RB7 in mask to 1
    sw	    t0, TRISB		    ## write TRISB. RB7 is now in, rest is out
    sw	    zero, ANSELB	    ## All of PORTB is digital
   
    
    
    /* Configure Timer 1. */
    sw	    zero, T1CON		    ## Clear T1Con -- including ON=0
    
    //period
    ori	    t1, zero, 15625         ## 65535 (0xFFFF) = 2.097 sec, 15625 = .25s
    sw	    t1, PR1		    ## write to PR1 (period) 
    
    //interrupt flag
    li	    t2, _IFS0_T1IF_MASK	    ## t2 = bit mask for checking T1IF 
    sw	    t2, IFS0CLR		    ## Clear T1IF 
    
    lui	    t3, 0x0001			## Want INTCON bit 16 (VS<0>) = 1
					##   so vectors 8 bytes apart
    ori	    t3, t3, _INTCON_MVEC_MASK   ## Enable multivectored interrupt mode
    sw	    t3, INTCON
    
    li	    t3, _IPC2_T1IP_MASK	    ## Set T1 interrupt priority level to 7
    sw	    t3, IPC2		    ## Implicitly sets subpriority level to 0
    
    //prescaler
    li	    t3, _T1CON_TCKPS_MASK   ## Prescaler: Factor of 256 (TCKPS=11) 
    sw	    t3, T1CONSET
    
    
    //enable interrupts
    ei
    
    //enable timer
    li	    t5, _T1CON_TON_MASK	    ## enable timer 1 by setting ON=1
    sw	    t5, T1CONSET
    
    //calculate clicks per period
    
    //LED update logic
    
    loop:
    //set all LEDs off
    ##sw	    zero, LATASET
    ##sw	    zero, LATBSET
    
    j loop
    nop
    
       
.end main

/* ISR CODE FROM intTest2.S */
    
isrvector11:  ##TIMER INTERRUPT
    /* Clear interrupt flag */
    li	    t2, _IFS0_T1IF_MASK    
    sw	    t2, IFS0CLR		    ## Clear T1IF in software 
    /* LED update */
    li	    t2, _PORTA_RA3_MASK
    sw	    t2, LATAINV
    li	    t3, _PORTA_RA2_MASK
    sw	    t3, LATAINV
    li	    t4, _PORTB_RB12_MASK
    sw	    t4, LATBINV
    
    /* Reset Timer */
    
    
int11done:
    eret		    ## Return from interrupt
    .end isrvector11
