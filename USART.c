/*
* Jeff Bulick
* ECE 138
* Lab 10
* 4/15/17
*/

#include <avr/io.h>
#include <avr/interrupt.h>
typedef int bool;
#define true 1
#define false 0

/* This program uses the ATmega8515 to exemplify USART.
* It has an internal buffer capable of storing 20 bytes.
* When this buffer is full, LED0 will turn on and additional bytes are ignored.
* When SW0 is pressed, all chars in buffer are sent to PC and LED0 is turned off.
* While transmitting, receiving is disabled.
* When SW1 is pressed and buffer is not full, a standard message is sent to PC.
*/

volatile char tbuffer[24];	//transmit buffer
volatile unsigned char tptr;	//pointer in transmit buffer
volatile int counter;			//counts received bytes
volatile char unsigned led;
volatile char tempbuff[24];	//temp buffer
volatile int tempCounter;	//temp counter
volatile bool clear;		//decide whether to clear the buffer

//transmit complete interrupt
ISR(USART_TX_vect){
	if(tptr == (counter+4)){	//if last char in buffer
		UCSRB = UCSRB & 0xf7;	//disable transmitting
		UCSRB = UCSRB | 0x10;	//allow receiving
		
		if(clear){	//clear the buffer
			counter = 0;
			tptr = 0;
		}
		else{	//restore the buffer
			counter = tempCounter;
			tptr = tempCounter;
			for(int i=0; i<24; i++){	//restore data in buffer
				tbuffer[i] = tempbuff[i];
			}
		}
		
	}
	else{
		UDR = tbuffer[tptr];	//send next char
		tptr++;					//increment pointer
	}
}

//receive complete interrupt
ISR(USART_RX_vect){
	if(tptr == 20){
		led  = led ^ 1;  //complement LED0
		PORTC = led;
		UCSRB = UCSRB & 0xef;	//disable receiving
	}
	else{
		tbuffer[tptr] = UDR;	//store byte from PC
		tptr++;					//increment index
		counter++;
	}
}

int main(void){
	//initialization
	bool send, sendStd, done0, done1;
	char Standard_Message[10] = "I am ready";
	cli();			//disable interrupts
	done0 = false;	 // handle switch length to handle one event
	done1 = false;
	DDRA = 0;      	//sets all pin A to input because connected to pushbuttons
	UBRRH = 0;
	UBRRL = 23;		//baud rate = 9600 using ATmega8515 clock rate
	UCSRB = 0xc0;	//allow transmit and receive complete interrupts
	UCSRB = UCSRB | 0x10;	//allow receiving
	tptr = 0;
	counter = 0;
	tempCounter = 0;
	DDRC = 0xff;  	//Port C set to output for LEDs
	led = 0xff;		//all LEDs off
	PORTC = led;
	sei();			//allow interrupts
	
	while(1){
	
		send = (PINA ^ 0xff) & 1;  //select bit 1 for SW0
		sendStd = (PINA ^ 0xff) & 2;	//select bit 2 for SW1
		
		//send standard message on SW1 press if buffer not full
		if(sendStd && (led == 0xff) && !done1){
			UCSRB = UCSRB & 0xef;	//disable receiving
			UCSRB = UCSRB | 0x08;	//allow transmission
			
			tempCounter = counter;
			for(int i=0; i<24; i++){	//store data in temp buffer
				tempbuff[i] = tbuffer[i];
			}
			
			tbuffer[0] = 0x0a;		//append LF character
			tbuffer[1] = 0x0d;		//append CR character
			for(int i=0; i<10; i++){	//load message into buffer
				tbuffer[i+2] = Standard_Message[i];
			}
			tbuffer[12] = 0x0a;		//append LF character
			tbuffer[13] = 0x0d;		//append CR character
			clear = false;			
			counter = 10;
			tptr = 1;				//index of next byte to send
			UDR = tbuffer[0];		//send LF
			done1 = true;			//react only once to press
		}
		
		
		//send message contained in buffer to PC and turn off LED0
		if(send && !done0){
			UCSRB = UCSRB & 0xef;	//disable receiving
			UCSRB = UCSRB | 0x08;	//allow transmission
			
			for(int i=counter; i>0; i--){
				tbuffer[i+1] = tbuffer[i-1];	//shift over bytes in buffer to make room for preceding LF,CR
			}
			
			//preceding buffer
			tbuffer[0] = 0x0a;		//append LF character
			tbuffer[1] = 0x0d;		//append CR character
			//anteceding buffer
			tbuffer[counter+2] = 0x0a;		//append LF character
			tbuffer[counter+3] = 0x0d;		//append CR character
			clear = true;
			tptr = 1;				//index of next byte to send
			UDR = tbuffer[0];		//send 0th byte
			led  = 0xff;  //complement LED0
			PORTC = led;
			done0 = true;			//react only once to press
		}
		
		if(!sendStd){				//switch1 is released
			done1 = false;
		}
		if(!send){				//switch0 is released
			done0 = false;
		}
		
	}
	return 0;
}
