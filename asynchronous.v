`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Jeff Bulick
// 
// Create Date: 03/03/2017 12:26:29 AM
// Design Name: 
// Module Name: asynchronous.v
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: hierarchical implementation of FPGAs to design asycnhronous 
// 		sequential circuits. 
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

//function whose output (out) toggles when sequence P1,P1,P2 is keyed in.  P1 and P2 are implemented using 
//	BTNL and BTNR on the Nexys-4 DDR board and debounced with FPGAs in Verilog.  Repeats are allowed.
module num1(btnl, btnr, clock, out);
    input btnl, btnr, clock;
    output out;
    reg x1, x2, z;
    wire P1, P2, Q1, Q2;
    
    Debouncer d0(btnl, clock, P1);
    Debouncer d1(btnr, clock, P2);
    
    always@(posedge P1 or posedge P2)
    begin
        x1 <= (Q2*P1) + (Q1*Q2*P2);
        x2 <= (~Q1*P1) + ((Q2 + Q1*~Q2)*P2);
        z <= Q1*Q2;
    end    
    TFlop t1(x1, Q1);
    TFlop t2(x2, Q2);
    TFlop t3(z, out);
endmodule

//function with P1 and P2 implemented using BTNL and BTNR on the Nexys-4 DDR board and debounced with 
// 	FPGAs in Verilog.  There is no overlap between a valid pattern and the next pattern.  Output (out1)
//  becomes high with sequence P1,P2,P1,P1, and (out2) when P2,P1,P2,P1 is keyed in.
module num2(btnl, btnr, clock, out1, out2);
    input btnl, btnr, clock;
    output out1, out2;
    reg x1, x2, x3, x4, x5, x6, out1, out2;
    wire P1, P2, Q1, Q2, Q3, Q4, Q5, Q6;
    
    Debouncer d0(btnl, clock, P1);
    Debouncer d1(btnr, clock, P2);
    
    always@(posedge P1 or posedge P2)
    begin
        x1 <= (Q1*Q2*Q3 + ~Q1*Q2*Q3)*P1 + Q1*Q2*Q3*P2;
        x2 <= Q1*Q2*Q3*P1 + (Q1*Q2*Q3 + ~Q1*~Q2*Q3 + ~Q1*Q2*~Q3)*P2;
        x3 <= (~Q1*~Q2*~Q3 + ~Q1*Q2*~Q3)*P1 + (Q1*Q2*Q3 + ~Q1*Q3)*P2;
        x4 <= (Q4*Q5*Q6 + ~Q4*Q5*Q6)*P1 + Q4*Q5*Q6*P2;
        x5 <= (Q4*Q5*Q6 + ~Q4*~Q5*Q6 + ~Q4*Q5*~Q6)*P1 + (Q4*Q5*Q6 + ~Q4*Q5*Q6)*P2;
        x6 <= (Q4*Q5*Q6 + ~Q4*~Q5*Q6)*P1 + (~Q4*~Q5*~Q6 + ~Q4*Q5*~Q6)*P2;
        out1 <= Q1*Q2*Q3;
        out2 <= Q4*Q5*Q6;
    end    
    TFlop t1(x1, Q1);
    TFlop t2(x2, Q2);
    TFlop t3(x3, Q3);
    TFlop t4(x4, Q4);
    TFlop t5(x5, Q5);
    TFlop t6(x6, Q6);
endmodule


//basic implementation of a T-flip flop
module TFlop(clock, Q);
    input clock;
    output Q;
    reg Q;
    
    always@(negedge clock)
    begin
        Q <= ~Q;
    end
endmodule

//Debouncing circuit to make mechanical bouncing into a clean pulse
module Debouncer(raw, clock, clean);
    input raw, clock;
    output clean;
    reg clean;
    reg[17:0] counter;
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
