##Dana Maloney
    
/* Including xc.h for hardware specific masks, etc */
    #include <xc.h>

main:
    /* Configure IO.
       Need RB7/RB1 as input.
       Need RB12, RA2, RA3 as outputs (R, G, B lights)
       Start with config PORTA */
    sw	    zero, TRISA		    ## TRISA = 0  --> all PORTA bits = output
    sw	    zero, ANSELA	    ## ANSELA = 0 --> all PORTA bits digital
    /* Config PORTB */
    li	    t0, _PORTB_RB7_MASK	    ## Set RB7 in mask to 1
    sw	    t0, TRISB		    ## write TRISB. RB7 is now in, RBX is out
    sw	    zero, ANSELB	    ## All of PORTB is digital
   
    
    
    /* Configure Timer 1. */
    sw	    zero, T1CON		    ## Clear T1Con -- including ON=0
    
    //period
    ori	    t1, zero, 15625         ## 65535 (0xFFFF) = 2.097 sec, 15625 = .25s
    sw	    t1, PR1		    ## write to PR1 (period) 
    
    //interrupt flag
    li	    t2, _IFS0_T1IF_MASK	    ## t2 = bit mask for checking T1IF 
    sw	    t2, IFS0CLR		    ## Clear T1IF 
    
    //prescaler
    li	    t3, _T1CON_TCKPS_MASK   ## Prescaler: Factor of 256 (TCKPS=11) 
    sw	    t3, T1CONSET
    
    //enable timer
    li	    t5, _T1CON_TON_MASK	    ## enable timer 1 by setting ON=1
    sw	    t5, T1CONSET	    
    
    
    
    
.end main
