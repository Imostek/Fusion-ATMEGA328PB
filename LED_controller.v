`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:01:19 07/16/2023 
// Design Name: 
// Module Name:    LED_controller 
//////////////////////////////////////////////////////////////////////////////////
module LED_controller(
		input clk,
		input rst,
		input LED_en,
		input [7:0] data,
		
		//for debug
		output en_sig,
		
		output [3:0] LEDs
    );

//define internal wire and reg
reg [3:0] led_reg;


//update leds
always @(posedge clk) begin
	if(rst) led_reg <= 4'b0000;
	else if(LED_en)
		led_reg <= data[3:0];
end

//assign outputs
assign LEDs = led_reg;	

//for debug
assign en_sig = LED_en;


endmodule
