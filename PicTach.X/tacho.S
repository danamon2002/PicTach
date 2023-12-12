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
    li	    t0, _PORTB_RB7_MASK	    ##Set RB7 in mask to 1
    sw	    t0, TRISB		    ##write TRISB. RB7 is now in, RBX is out
    sw	    zero, ANSELB	    ##All of PORTB is digital
    
    /* Configure timer-counter */
    ## timer config as counter.
    
    
    
.end main
