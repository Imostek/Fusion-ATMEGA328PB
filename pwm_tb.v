`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   13:56:10 08/11/2023
// Design Name:   pwm
// Module Name:   /home/ise/xilinx/arduino_code/mc_fpga_interface/mc_fpga_interface/mc_fpga_interface/pwm_tb.v
// Project Name:  mc_fpga_interface
////////////////////////////////////////////////////////////////////////////////

module pwm_tb;

	// Inputs
	reg clk;
	reg rst;
	reg [7:0] cmd;

	// Outputs
	wire pwm_out;

	// Instantiate the Unit Under Test (UUT)
	pwm uut (
		.clk(clk), 
		.rst(rst), 
		.cmd(cmd), 
		.pwm_out(pwm_out)
	);

	always #10 clk = ~clk;
	
	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 1;
		cmd = 0;

		// Wait 100 ns for global reset to finish
		#100; rst = 0 ;
		
		#1000000 cmd = 100;
		#1000000 cmd = 50;
		#1000000 cmd = 200;
		#1000000 cmd = 255;
		#1000000 $finish;
	end
      
endmodule

