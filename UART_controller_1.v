`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:55:00 08/04/2023 
// Design Name: 
// Module Name:    UART_controller_1 
//////////////////////////////////////////////////////////////////////////////////
module UART_controller_1(
	input clk,
	input rst,
	input [7:0] UART_config,
	
	//tx data in 
	input [7:0] tx_data_0,
	input [7:0] tx_data_1,
	input [7:0] tx_data_2,
	input [7:0] tx_data_3,
	
	//tx start signal
	input tx_start_0,
	input tx_start_1,
	input tx_start_2,
	input tx_start_3,
	
	//tx done signal
	output tx_done_0,
	output tx_done_1,
	output tx_done_2,
	output tx_done_3,
		
	//uart connection
	output tx
	//input  rx
    );
	 
//define internal reg and wire
wire [7:0] tx_data_in;	
wire tx_done;
wire tx_start;
wire tx_done_re; 

wire local_clk;
wire tx_tick;
wire rx_tick;

//enable clk
assign local_clk = (UART_config[3])? clk : 1'b0;

//define tx data in mux
assign tx_data_in = (UART_config[5:4] == 2'b00) ? tx_data_0 :
						  (UART_config[5:4] == 2'b01) ? tx_data_1 :
						  (UART_config[5:4] == 2'b10) ? tx_data_2 :
						  (UART_config[5:4] == 2'b11) ? tx_data_3 : 8'd0;

//define tx start sig mux
assign tx_start = (UART_config[5:4] == 2'b00)? tx_start_0 : 
						(UART_config[5:4] == 2'b01)? tx_start_1 :
						(UART_config[5:4] == 2'b10)? tx_start_2 :
						(UART_config[5:4] == 2'b11)? tx_start_3 : 1'b0;	

//define tx done signal mux
assign tx_done_0 = (UART_config[5:4] == 2'b00) ? tx_done_re : 1'b0;						
assign tx_done_1 = (UART_config[5:4] == 2'b01) ? tx_done_re : 1'b0;
assign tx_done_2 = (UART_config[5:4] == 2'b10) ? tx_done_re : 1'b0;
assign tx_done_3 = (UART_config[5:4] == 2'b11) ? tx_done_re : 1'b0;							

//instantiate modules
BaudTickGen  baud_gen(
	.clk(local_clk), 
	.enable(1'b1), 
	.tx_tick(tx_tick),
	.rx_tick(rx_tick)
);

//instantiate transmit module
tx_module transmit(
	.clk(tx_tick), 
	.rst(rst), 
	.start(tx_start), 
	.data(tx_data_in), 
	.stop_bit_config(1'b0), 
	.tx_done(tx_done), 
	.tx(tx)
);

//detecting poesge of done
reg [1:0] edge_det_;
always@(negedge clk)
edge_det_ <= {edge_det_[0],tx_done};
assign tx_done_re = {edge_det_[1:0] == 2'b01};

endmodule
