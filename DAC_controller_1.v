`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:52:26 08/11/2023 
// Design Name: 
// Module Name:    DAC_controller_1 
//////////////////////////////////////////////////////////////////////////////////
module DAC_controller_1(
	input clk,
	input rst,
	input [7:0] DAC_config,
	
	//DAC data in 
	input [11:0] DAC_data_0,//from UC
	input [11:0] DAC_data_1,//from UART
	input [11:0] DAC_data_2,//from FILTER
	input [11:0] DAC_data_3,
	
	//DAC conversion start signal
	input cnv_start_0,
	input cnv_start_1,
	input cnv_start_2,
	input cnv_start_3,
	
	//DAC conversion done signal
	output cnv_done_0,
	output cnv_done_1,
	output cnv_done_2,
	output cnv_done_3,
		
	//DAC connection
	inout  ddata,
	output dclk	
	 );

//define internal wire and reg
wire [11:0] DAC_data_in;	
wire cnv_done;
wire cnv_start;
wire cnv_done_re; 
wire local_clk;
wire io_dir;
wire sdata_in;
wire sdata_out;

//enable clk
assign local_clk = (DAC_config[3])? clk : 1'b0;

//define DAC data in mux
assign DAC_data_in = (DAC_config[5:4] == 2'b00) ? DAC_data_0 :
							(DAC_config[5:4] == 2'b01) ? DAC_data_1 :
							(DAC_config[5:4] == 2'b10) ? DAC_data_2 :
							(DAC_config[5:4] == 2'b11) ? DAC_data_3 : 12'd0;

//define DAC start sig mux
assign cnv_start = (DAC_config[5:4] == 2'b00)? cnv_start_0 : 
						 (DAC_config[5:4] == 2'b01)? cnv_start_1 :
						 (DAC_config[5:4] == 2'b10)? cnv_start_2 :
						 (DAC_config[5:4] == 2'b11)? cnv_start_3 : 1'b0;	

//define DAC done signal mux
assign cnv_done_0 = (DAC_config[5:4] == 2'b00) ? cnv_done_re : 1'b0;						
assign cnv_done_1 = (DAC_config[5:4] == 2'b01) ? cnv_done_re : 1'b0;
assign cnv_done_2 = (DAC_config[5:4] == 2'b10) ? cnv_done_re : 1'b0;
assign cnv_done_3 = (DAC_config[5:4] == 2'b11) ? cnv_done_re : 1'b0;							


//DAC interface
dacMCP4725_interface DAC_Unit(
		.clk(local_clk),           
		.rst(rst),           
		.start(cnv_start),		
		.data(DAC_data_in),  
		.sdata_in(sdata_in),
		.sdata_out(sdata_out),
		.sclk(dclk),     
		.tx_complete(cnv_done),
		.io_dir(io_dir)
		);


//detecting poesge of cnv_done
reg [1:0] edge_det;
always@(negedge clk)
	edge_det <= {edge_det[0],cnv_done};
assign cnv_done_re = (edge_det[1:0] == 2'b01) ? 1 : 0;


//IOBUF must stay in top module
IOBUF #(
   .DRIVE(12), 
   .IBUF_LOW_PWR("TRUE"),  
   .IOSTANDARD("DEFAULT"), 
   .SLEW("SLOW") 
) iobuf_inst (
   .O(sdata_in), // Buffer output		
   .IO(ddata),   // Buffer inout port (connect directly to top-level port)
   .I(sdata_out),// Buffer input
   .T(io_dir)    // 3-state enable input, high=input, low=output
);

endmodule
