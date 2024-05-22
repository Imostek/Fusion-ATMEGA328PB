`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:20:55 08/04/2023 
// Design Name: 
// Module Name:    ADC_controller_1 
//////////////////////////////////////////////////////////////////////////////////
module ADC_controller_1(
	input clk,
	input rst,
	input [7:0] ADC_config,
	
	//adc fifo status signal
	input  ADC_read_en_0, 
	input  ADC_read_en_1,
	input  ADC_read_en_2,
	input  ADC_read_en_3,
	
	output ADC_fifo_empty_0,
	output ADC_fifo_empty_1,
	output ADC_fifo_empty_2,
	output ADC_fifo_empty_3,
	
	//adc data output signal
	output [7:0] ADC_data_0,
	output [7:0] ADC_data_1,
	output [7:0] ADC_data_2,
	output [7:0] ADC_data_3,
	
	//adc connection
	output cs,
	input  sdata,
	output sclk 
   );

//define internal wire and reg
wire [7:0] fifo_data_in,fifo_data_out;
wire [7:0] adc_data_out;

wire local_rst;
wire dtclk_re;

//enable clk
assign local_clk = (ADC_config[0])? clk : 1'b0;

//fifo instantiation
wire fifo_rd_en,fifo_wr_en,fifo_full,fifo_empty;

fifo ADC_fifo(
    .data_in(fifo_data_in),
    .clk(local_clk),
	 .rst(rst),
    .wr_en(fifo_wr_en),
    .rd_en(fifo_rd_en),
    .data_out(fifo_data_out),
    .fifo_full(fifo_full),
    .fifo_empty(fifo_empty)
); 

//data out mux
assign ADC_data_0 = (ADC_config[2:1] == 2'b00)? fifo_data_out : 8'd0;
assign ADC_data_1 = (ADC_config[2:1] == 2'b01)? fifo_data_out : 8'd0;
assign ADC_data_2 = (ADC_config[2:1] == 2'b10)? fifo_data_out : 8'd0;
assign ADC_data_3 = (ADC_config[2:1] == 2'b11)? fifo_data_out : 8'd0;

//ADC read enable mux
assign fifo_rd_en = (ADC_config[2:1] == 2'b00) ? ADC_read_en_0 :
						  (ADC_config[2:1] == 2'b01) ? ADC_read_en_1 :
						  (ADC_config[2:1] == 2'b10) ? ADC_read_en_2 :
						  (ADC_config[2:1] == 2'b11) ? ADC_read_en_3 : 1'b0;

//fifo_empty mux
assign ADC_fifo_empty_0 = (ADC_config[2:1] == 2'b00) ? fifo_empty : 1'b0;
assign ADC_fifo_empty_1 = (ADC_config[2:1] == 2'b01) ? fifo_empty : 1'b0;
assign ADC_fifo_empty_2 = (ADC_config[2:1] == 2'b10) ? fifo_empty : 1'b0;
assign ADC_fifo_empty_3 = (ADC_config[2:1] == 2'b11) ? fifo_empty : 1'b0;

//instantiate ADC interface block
adc_interface  ADC_(
	 .clk(local_clk),
	 .rst(rst),
	 .data_out(adc_data_out),
	 .clk_out(data_clk),
	 .start(soc),
	 //adc connection
    .cs_bar(cs),
    .sdata(sdata),
    .sclk(sclk)
);

//detecting poesge of data_clk
reg [1:0] edge_det;
always@(negedge clk )
edge_det <= {edge_det[0],data_clk};
assign dtclk_re = {edge_det[1:0] == 2'b01};

//define glue logic
assign fifo_data_in = adc_data_out;
assign soc = ~fifo_full;
assign fifo_wr_en = dtclk_re;

endmodule
