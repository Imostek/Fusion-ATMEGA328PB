`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   21:00:56 09/05/2023
// Design Name:   Generic_FIR_filter
// Module Name:   /home/ise/xilinx/arduino/mc_fpga_interface/Generic_FIR_filter_tb.v
////////////////////////////////////////////////////////////////////////////////

module Generic_FIR_filter_tb;

	// Inputs
	reg [15:0] vin;
	reg [15:0] coef_0;
	reg [15:0] coef_1;
	reg [15:0] coef_2;
	reg [15:0] coef_3;
	reg [15:0] coef_4;
	reg [15:0] coef_5;
	reg [15:0] coef_6;
	reg rst;
	reg clk;
	reg filter_clk;

	// Outputs
	wire [15:0] vout;

	// Instantiate the Unit Under Test (UUT)
	Generic_FIR_filter uut (
		.vin(vin), 
		.coef_0(coef_0), 
		.coef_1(coef_1), 
		.coef_2(coef_2), 
		.coef_3(coef_3), 
		.coef_4(coef_4), 
		.coef_5(coef_5), 
		.coef_6(coef_6), 
		.rst(rst), 
		.clk(clk), 
		.filter_clk(filter_clk), 
		.vout(vout)
	);
	
	always #10 clk = ~clk;
	always #250 filter_clk = ~filter_clk;
	
	initial begin
		// Initialize Inputs
		vin = 127;
//		coef_0 = 16'd537;
//		coef_1 = 16'd1993;
//		coef_2 = 16'd3670;
//		coef_3 = 16'd4434;
//		coef_4 = 16'd3670;
//		coef_5 = 16'd1993;
//		coef_6 = 16'd537;
		
		coef_0 = 16'd1000;
		coef_1 = 16'd1000;
		coef_2 = 16'd1000;
		coef_3 = 16'd1000;
		coef_4 = 16'd1000;
		coef_5 = 16'd1000;
		coef_6 = 16'd1000;
		
		rst = 1;
		clk = 0;
		filter_clk = 0;

		// Wait 100 ns for global reset to finish
		#100 rst = 0;
		#100000 $finish;
        
		// Add stimulus here

	end
      
endmodule

