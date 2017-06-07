`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Jeff Bulick
// 
// Create Date: 02/26/2017 02:54:33 PM
// Design Name: 
// Module Name: complex-logic.v
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

//Circuit that creates four modulo ten counters and displays them using four seven-segment LED displays 
//   on the Nexys-4 DDR board.  Counters are incremented using corresponding debounced pushbuttons.  
module num1(btnl, btnu, btnr, btnd, clock, reset, sevenSeg, segEnable, otherSegs);
    input btnl, btnu, btnr, btnd, clock, reset;
    output[7:0] sevenSeg;  //character display connections
    output[3:0] otherSegs; //anodes set to high to turn off certain 7seg displays
    output[3:0] segEnable;  //anodes 7seg displays to cycle through to show different numbers
    //setting other segment displays off
    assign otherSegs[3] = 1'b1;
    assign otherSegs[2] = 1'b1;
    assign otherSegs[1] = 1'b1;
    assign otherSegs[0] = 1'b1;
    wire delay_clock;
    wire clean0, clean1, clean2, clean3;
    wire[3:0] num0, num1, num2, num3, numOut;
    wire[1:0] counter;
        
    Debouncer d0(btnl, clock, clean0);
    Debouncer d1(btnu, clock, clean1);
    Debouncer d2(btnr, clock, clean2);
    Debouncer d3(btnd, clock, clean3);
    
    CounterMod10 c0(clean0, reset, num0);
    CounterMod10 c1(clean1, reset, num1);
    CounterMod10 c2(clean2, reset, num2);
    CounterMod10 c3(clean3, reset, num3);
    
    AnodeDelayClock a(clock, reset, delay_clock);
    CounterMod4 cntr(delay_clock, reset, counter);
    Mux m(num0, num1, num2, num3, counter, delay_clock, reset, numOut, segEnable);
    
    Segments s(numOut, sevenSeg);
endmodule

//Circuit that creates four modulo ten counters and displays them using four seven-segment LED displays 
//   on the Nexys-4 DDR board.  Counter "i" is incremented when a debounced push button is pressed and two 
//   switches are high/low to binary number "i".
module num2(btnr, sw1, sw0, clock, reset, sevenSeg, segEnable, otherSegs);
    input btnr, sw1, sw0, clock, reset;
    output[7:0] sevenSeg;  //character display connections
    output[3:0] otherSegs; //anodes set to high to turn off certain 7seg displays
    output[3:0] segEnable;  //anodes 7seg displays to cycle through to show different numbers
    //setting other segment displays off
    assign otherSegs[3] = 1'b1;
    assign otherSegs[2] = 1'b1;
    assign otherSegs[1] = 1'b1;
    assign otherSegs[0] = 1'b1;
    wire delay_clock;
    wire clean;
    wire[3:0] cout;
    wire[3:0] num0, num1, num2, num3, numOut;
    wire[1:0] counter;
        
    Debouncer d(btnr, clock, clean);
    
    ReverseMux rm(clean, sw1, sw0, cout);
    
    CounterMod10 c0(cout[0], reset, num0);
    CounterMod10 c1(cout[1], reset, num1);
    CounterMod10 c2(cout[2], reset, num2);
    CounterMod10 c3(cout[3], reset, num3);
    
    AnodeDelayClock a(clock, reset, delay_clock);
    CounterMod4 cntr(delay_clock, reset, counter);
    Mux m(num0, num1, num2, num3, counter, delay_clock, reset, numOut, segEnable);
    
    Segments s(numOut, sevenSeg);
endmodule

//4 digit counter (0000 to 9999). Counter increments every time BTNR is pushed and decrements when 
//  BTNL is pushed.  Counter resets if Switch0 goes high.  
module num3(btnr, btnl, clock, reset, sevenSeg, segEnable, otherSegs);
    input btnr, btnl, clock, reset;
    output[7:0] sevenSeg;  //character display connections
    output[3:0] otherSegs; //anodes set to high to turn off certain 7seg displays
    output[3:0] segEnable;  //anodes 7seg displays to cycle through to show different numbers
    //setting other segment displays off
    assign otherSegs[3] = 1'b1;
    assign otherSegs[2] = 1'b1;
    assign otherSegs[1] = 1'b1;
    assign otherSegs[0] = 1'b1;
    wire delay_clock;
    wire cleanR, cleanL;
    wire[3:0] cout;
    wire[3:0] num0, num1, num2, num3, numOut;
    wire[13:0] counter;
        
    Debouncer d0(btnr, clock, cleanR);
    Debouncer d1(btnl, clock, cleanL);
    
    IncDec id(cleanR, cleanL, reset, counter);
    
    CustDecoder cd(counter, num0, num1, num2, num3);
    
    AnodeDelayClock a(clock, reset, delay_clock);
    CounterMod4 cntr(delay_clock, reset, counter);
    Mux m(num0, num1, num2, num3, counter, delay_clock, reset, numOut, segEnable);
    
    Segments s(numOut, sevenSeg);
endmodule

//Decoder seperates each weighted decimal place value of input number
module CustDecoder(number, num0, num1, num2, num3);
    input[13:0] number;
    output[3:0] num0, num1, num2, num3;
    
    assign num3 = number/(14'd1000);
    assign num2 = (number - (num3*14'd1000))/(14'd100);
    assign num1 = (number - (num3*14'd1000) - (num2*14'd100))/(14'd10);
    assign num0 = (number - (num3*14'd1000) - (num2*14'd100) - (num1*14'd10));
endmodule

//Subcircuit handles logic for choosing inc/dec action 
module IncDec(inc, dec, reset, counter);
    input inc, dec, reset;
    output[13:0] counter;
    reg[13:0] counter;
    always@(posedge inc or posedge dec or posedge reset)
    if(reset)
        counter <= 14'd0;
    else
    begin
        if(inc && dec)
            counter <= counter;
        else if(inc && counter == 14'd9999 )
            counter <= 14'd0;
        else if(inc)
            counter <= counter + 14'd1;
        else if(dec && counter == 14'd0 )
            counter <= 14'd9999;
        else if(dec)
            counter <= counter - 14'd1;          
    end
endmodule

//Reverse Mux to increment counters by choice (SW1, SW0)
module ReverseMux(x, sw1, sw0, cout);
    input x, sw1, sw0;
    output[3:0] cout;
    reg[3:0] cout;
    always@(posedge x)
    begin
        case({sw1,sw0})
            2'b00:
                cout <= 4'b0001;
            2'b01:
                cout <= 4'b0010;
            2'b10:
                cout <= 4'b0100;
            2'b11:
                cout <= 4'b1000;
        endcase
    end
endmodule


//Multiplexing to display different 7 seg displays
module Mux(in0, in1, in2, in3, counter, clock, reset, number, enabler);
    input[3:0] in0,in1,in2,in3;
    input clock, reset;
    input[1:0] counter;
    output[3:0] number, enabler;
    reg[3:0] number, enabler;    
    always@(posedge clock or posedge reset)
    begin
        case(counter) 
            2'b00:
            begin
                number <= in0;
                enabler <= 4'b1110;
            end
            2'b01:
            begin
                number <= in1;
                enabler <= 4'b1101;
            end
            2'b10:
            begin
                number <= in2;
                enabler <= 4'b1011;
            end
            2'b11:
            begin
                number <= in3;
                enabler <= 4'b0111;
            end
        endcase
    end
endmodule

//Modulo 4 counter logic
module CounterMod4(clock, reset, counter);
    input clock, reset;
    output[1:0] counter;
    reg[1:0] counter;
    
    always@(posedge clock or posedge reset)
        begin    
            if( (counter == 2'd3) | reset)
                counter <= 2'd0;
            else
                counter <= counter + 2'd1;
        end
endmodule

//changes 100MHz to 1kHz
module AnodeDelayClock(clock, reset, delay_clock);
    input clock, reset;
    output delay_clock;
    reg[16:0] counter;  //counter to delay input clock
    reg delay_clock;   
    always@(posedge clock or posedge reset)
    begin
        if(reset)
            begin
            counter <= 17'd0;
            delay_clock <= 1'b0;
            end
        else
            begin
            counter <= counter + 17'd1;
                if(counter == 17'd100000) 
                    begin
                    delay_clock <= 1'b1;
                    counter <= 17'd0;
                    end
                else
                    delay_clock <= 1'b0;
            end
    end
endmodule

module Debouncer(raw, clock, clean);
    input raw, clock;
    output clean;
    reg clean;
    reg[17:0] counter;
    //debouncing circuit
   always@(posedge clock) begin
   if(~raw)
        begin
        counter <= 18'd0;
        clean <= 1'b0;
        end
   else
        begin
        counter <= counter + 18'd1;
        if(counter == 18'h3ffff)
            begin
            clean <= 1'd1;
            end
        else
            clean = clean;
        end     
  end
endmodule

//Modulo ten counter logic
module CounterMod10(clock, reset, count);
    input clock, reset;
    output[3:0] count;
    reg[3:0] count;
    always@(posedge reset or posedge clock)
    begin    
        if( (count == 4'd9) | reset)
            count <= 4'd0;
        else
            count <= count + 4'd1;
    end
endmodule

//Handles transistor state for LED 7seg display
module Segments(number, sevenSeg);
    input[3:0] number;
    output[7:0] sevenSeg;
    assign sevenSeg[7] = (number == 4'd1) | (number == 4'd4);
    assign sevenSeg[6] = (number == 4'd5) | (number == 4'd6);
    assign sevenSeg[5] = (number == 4'd2);
    assign sevenSeg[4] = (number == 4'd1) | (number == 4'd4) | (number == 4'd7);
    assign sevenSeg[3] = (number == 4'd1) | (number == 4'd3) | (number == 4'd4) |
                         (number == 4'd5) | (number == 4'd7) | (number == 4'd9);
    assign sevenSeg[2] = (number == 4'd1) | (number == 4'd2) | (number == 4'd3) |
                         (number == 4'd7);
    assign sevenSeg[1] = (number == 4'd0) | (number == 4'd1) | (number == 4'd7);
    assign sevenSeg[0] = 1'd1;  //always have decimal point off
endmodule