`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:09:12 08/11/2023 
// Design Name: 
// Module Name:    PWM_controller_1 
//////////////////////////////////////////////////////////////////////////////////
module PWM_controller_1(
	input clk,
	input rst,
	input [7:0] PWM_config,
	
	input [7:0] cmd_1,
	input [7:0] cmd_2,
	input [7:0] cmd_3,
	input [7:0] cmd_4,
	
	output pwm_1,
	output pwm_2,
	output pwm_3,
	output pwm_4
    );

//define internal wire and reg
wire local_clk_1,local_clk_2,local_clk_3,local_clk_4;

//enable clocks
assign local_clk_1 = (PWM_config[1])? clk : 1'b0;
assign local_clk_2 = (PWM_config[2])? clk : 1'b0;
assign local_clk_3 = (PWM_config[3])? clk : 1'b0;
assign local_clk_4 = (PWM_config[4])? clk : 1'b0;

//init pwm modules
pwm  pwm_module_1(
	.clk(local_clk_1),
	.rst(rst),
	.cmd(cmd_1),
	.pwm_out(pwm_1)
    );

pwm  pwm_module_2(
	.clk(local_clk_2),
	.rst(rst),
	.cmd(cmd_2),
	.pwm_out(pwm_2)
    );

pwm  pwm_module_3(
	.clk(local_clk_3),
	.rst(rst),
	.cmd(cmd_3),
	.pwm_out(pwm_3)
    );

pwm  pwm_module_4(
	.clk(local_clk_4),
	.rst(rst),
	.cmd(cmd_4),
	.pwm_out(pwm_4)
    );	 

endmodule
