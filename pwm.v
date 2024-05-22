`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:41:14 08/11/2023 
// Design Name: 
// Module Name:    pwm 
//////////////////////////////////////////////////////////////////////////////////
module pwm(
	input clk,
	input rst,
	
	input [7:0] cmd,
	output pwm_out
    );

//define internal wire and reg
reg [9:0] counter;
reg [9:0] cmd_reg;

//update cmd reg
always @(posedge clk) begin
	if(rst) cmd_reg <= 10'd0;
	else
		cmd_reg <= {cmd[7:0], 2'b10};
end

//counter implement
always @(posedge clk) begin
	if(rst)
		counter <= 10'd0;
	else
		counter <= counter + 10'd1;
end

//pwm gen
assign pwm_out = (cmd_reg > counter) ? 1 : 0;

endmodule
