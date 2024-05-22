`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   12:33:02 07/16/2023
// Design Name:   LED_controller
// Module Name:   /home/ise/xilinx/mc_fpga_interface/LED_controller_tb.v
// Project Name:  mc_fpga_interface
////////////////////////////////////////////////////////////////////////////////

module LED_controller_tb;

	// Inputs
	reg clk;
	reg rst;
	reg [7:0] addr;
	reg [7:0] data;

	// Outputs
	wire [3:0] LEDs;
	wire en_sig;
	
	always #10 clk = ~clk;

	// Instantiate the Unit Under Test (UUT)
	LED_controller uut (
		.clk(clk), 
		.rst(rst),
      
		.en_sig(en_sig),
			
		.addr(addr), 
		.data(data), 
		.LEDs(LEDs)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 1;
		addr = 0;
		data = 0;

		// Wait 100 ns for global reset to finish
		#100;
		rst = 0;
		
		#1000 addr = 1; data = 4'd2; 
		#1000 addr = 5; #20 data = 4'd5;
		#1000 addr = 0; #20 data = 4'd10;
		#1000 $finish;
		
 	end
      
endmodule

