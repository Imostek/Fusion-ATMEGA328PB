`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:47:51 03/10/2023 
// Design Name: 
// Module Name:    baud_gen 
//////////////////////////////////////////////////////////////////////////////////
module BaudTickGen(
	input clk, enable,
	output tx_tick,rx_tick  // generate a tick at the specified baud rate * oversampling
);
parameter ClkFrequency = 50000000;
parameter Baud = 115200;
parameter Oversampling = 1;

//define log2 function
function integer log2(input integer v); 
begin 
	log2=0; 
	while(v>>log2) log2=log2+1; 
end 
endfunction

// +/- 2% max timing error over a byte
localparam AccWidth = log2(ClkFrequency/Baud)+8;  

reg [AccWidth:0] Acc = 0;
reg [AccWidth:0] Acc_ = 0;

// this makes sure Inc calculation doesn't overflow
localparam ShiftLimiter = log2(Baud*Oversampling >> (31-AccWidth));  
localparam Inc = ((Baud*Oversampling << (AccWidth-ShiftLimiter))+(ClkFrequency>>(ShiftLimiter+1)))/(ClkFrequency>>ShiftLimiter);

localparam ShiftLimiter_ = log2(Baud*8 >> (31-AccWidth));  
localparam Inc_ = ((Baud*8 << (AccWidth-ShiftLimiter_))+(ClkFrequency>>(ShiftLimiter_+1)))/(ClkFrequency>>ShiftLimiter_);

always @(posedge clk) 
	if(enable) 
		Acc <= Acc[AccWidth-1:0] + Inc[AccWidth:0]; 
	else Acc <= Inc[AccWidth:0];
	
always @(posedge clk) 
	if(enable) 
		Acc_   <= Acc_[AccWidth-1:0] + Inc_[AccWidth:0]; 
	else Acc_ <= Inc_[AccWidth:0];	

//assign tick	
assign tx_tick = Acc[AccWidth];
assign rx_tick = Acc_[AccWidth];

endmodule
