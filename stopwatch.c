/*
* Jeff Bulick
* ECE 138
* Lab 11
* 4/19/17
*/

#include <avr/io.h>
#include <avr/interrupt.h>
typedef int bool;
#define true 1
#define false 0

/* This program uses the ATmega8515 to simulate a stopwatch.
* The stop watch is controlled from the PC serial port.
* Commands s, S, r, and R will start, Stop, read, and Reset the stopwatch respectively.
* All other commands will be ignored.
*
* The start command begins counting up to a maximum of 59 mins and 59 secs.  When counting
* another start command will have no effect.  LED0 will blink complementing every half second
* while in counting mode.
*
* The stop command will stop the counting.
*
* The read command will send the time counted to the serial port in the form mm:ss.
* This will not effect the counting.
*
* The reset command will trigger stop event (if counting) and reset timer to 0.
*/

volatile unsigned char led;		//used for blinking led
volatile bool fullSec;			//used to double the timer overflow to one second
volatile bool counting;			//counting mode
volatile int seconds;			//counter for seconds
volatile char command;			//byte received from PC
volatile char tbuffer[7];		//transmit buffer
volatile unsigned char tptr;	//pointer in transmit buffer


//Timer overflows every half second
ISR(TIMER1_OVF_vect){
	TCNT1 = 58336;	//reset so timer can overflow again
	fullSec = !fullSec;
	if(counting){
		led  = led ^ 1;  //complement LED0
		PORTC = led;
	}
	if(fullSec && counting){	//delay timer to half the frequency (1 second)
		if(seconds < 3599){
			seconds++;			//stopwatch increments
		}
	}
}

//transmit complete interrupt
ISR(USART_TX_vect){
	if(tptr == 7){	//if index greater than buffer mem allocation
		UCSRB = UCSRB & 0xf7;	//disable transmitting
		UCSRB = UCSRB | 0x10;	//allow receiving
		tptr = 0;
	}
	else{
		UDR = tbuffer[tptr];	//send next char
		tptr++;					//increment pointer
	}
}

//receive complete interrupt
ISR(USART_RX_vect){
	command = UDR;		//store command from PC
}

int main(void){
	//initialization
	cli();			//disable interrupts
	TCCR1A = 0;  	//sets clock rate to 14.4kHz
	TCCR1B = 4;
	TCNT1 = 58336;  //initialize counter to overflow at one second
	DDRC = 0xff;  	//Port C set to output for LEDs
	led = 0xff;		//all LEDs off
	PORTC = led;
	TIMSK = 128;  	//allow only counter 1 overflow interrupt
	UBRRH = 0;
	UBRRL = 23;		//baud rate = 9600 using ATmega8515 clock rate
	UCSRB = 0xc0;	//allow transmit and receive complete interrupts
	UCSRB = UCSRB | 0x10;	//allow receiving
	tptr = 0;
	command = 0;
	seconds = 0;		//start at time = 0.
	counting = false;	//not in counting operation
	fullSec = true;	//start at whole number
	sei();			//allow interrupts
	
	while(1){
		
		if(command != 0){
			//start
			if(command == 's'){
				counting = true;	//enter counting operation
				command = 0;
			}
			//stop
			if(command == 'S'){
				counting = false;	//exit counting mode
				led = 0xff;		//all LEDs off
				PORTC = led;
				command = 0;
			}
			//read (transmit)
			if(command == 'r'){
				UCSRB = UCSRB & 0xef;	//disable receiving
				UCSRB = UCSRB | 0x08;	//allow transmission
				//prepare buffer for transmission
				int mins = seconds/60;	//number of minutes
				int minTensDigit = mins/10;
				tbuffer[0] = (char)(minTensDigit + '0');
				int minOnesDigit = (mins - (minTensDigit*10));
				tbuffer[1] = (char)(minOnesDigit + '0');
				tbuffer[2] = ':';
				int remainderSecs = seconds % 60;  //leftover seconds
				int secTensDigit = remainderSecs/10;
				tbuffer[3] = (char)(secTensDigit + '0');
				int secOnesDigit = (remainderSecs - (secTensDigit*10));
				tbuffer[4] = (char)(secOnesDigit + '0');
				tbuffer[5] = 0x0a;		//append LF character
				tbuffer[6] = 0x0d;		//append CR character
				tptr = 1;				//index of next byte to send
				UDR = tbuffer[0];		//send first byte
				command = 0;
			}
			//reset
			if(command == 'R'){
				counting = false;	//exit counting mode
				seconds = 0;		//reset counter
				led = 0xff;		//all LEDs off
				PORTC = led;
				command = 0;
			}
		}
		
	}
	return 0;
}