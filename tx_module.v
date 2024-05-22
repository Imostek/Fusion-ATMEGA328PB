`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 		
// Engineer: 
// 
// Create Date:    11:07:53 05/02/2016 
// Design Name: 
// Module Name:    tx_module 
//////////////////////////////////////////////////////////////////////////////////
module tx_module(
	input clk,
	input rst,
	input start,
	input [7:0] data,
	input stop_bit_config,// 0 --> 1 stop bit, 1 --> 2 stop bit
	output tx_done,
	//for debug
//	output [3:0] cnt_de,
//	output [10:0] data_de,
//	output [1:0] state_de,
	//-------------//
	output tx
);

//--------internal wire and reg------//
	reg [10:0] data_in;
	reg stop_bit;
	reg done;
	reg tx_reg;
	reg [3:0] cnt;//to count the no of tx bit
   wire [3:0] cnt_val; 
	
//--------state machine parameters-----//
	
localparam  initialize	= 2'd0,
				st_tx			= 2'd1,
			// done_tx     = 2'd2,
				finish      = 2'd2;
reg [1:0] st_reg;				
	
//---------------state_machine--------//

assign cnt_val = (stop_bit)? 4'd11 : 4'd10; 

always @(posedge clk or posedge rst) begin
		if(rst) begin
			st_reg	<= initialize;
			data_in  <= 11'd0;
			stop_bit <= 1'b0;
			tx_reg   <= 1'b1;
			done     <= 1'b0;
			cnt      <= 3'd0;
			end
		else begin
			tx_reg	<= 1'b1;
			done     <= 1'b0;
			cnt		<= 3'd0;
			case(st_reg)
			initialize	:	begin
								if(start) begin
									data_in 	<= {1'b1, 1'b1, data, 1'b0};
									stop_bit <= stop_bit_config;
									done 		<= 1'b0;
									st_reg 	<= st_tx;
									end
								end
			st_tx			:	begin
								if(cnt < cnt_val) begin
									tx_reg	<= data_in[0];
									data_in 	<= {data_in[0], data_in[10:1]};
									cnt 		<= cnt + 1'b1;
									st_reg	<= st_tx;
									end
								else begin
									done		<= 1'b1;
									st_reg 	<= finish;
									end
								end
			finish    	:	begin
								st_reg	<= initialize;
								end									
			default		:	st_reg 	<= initialize;
			endcase
		end
end
				
//------------output assign--------------//

assign	 tx	 	= tx_reg,
			 tx_done	= done;
			 
//---for debug
//assign 	cnt_de		= cnt,
//			data_de		= data_in,
//			state_de		= st_reg;
			  
endmodule
