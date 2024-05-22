`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:59:14 07/20/2023 
// Design Name: 
// Module Name:    adc_interface 
//////////////////////////////////////////////////////////////////////////////////
module adc_interface(
	 input  clk,
	 input  rst,
	 input  start,
    output cs_bar,
    input  sdata,
    output sclk,
	 output clk_out,
	 //for debug
	 //output [14:0] dt,
	 output [7:0] data_out
    );
	 
//define wire and reg
reg cs_reg;
reg sclk_reg;
reg clk_out_reg;
reg [14:0]data_reg;
reg [7:0] data_out_reg;
reg [4:0] edge_cnt;
reg [2:0] delay_reg;

//----------- sclk generation--------------
reg [3:0] delay;
always @(posedge clk or posedge rst) begin
	if(rst)
		delay <= 4'd0;
	else if(delay <= 4'd15) 
		delay <= delay +1; 
	else 
		delay <= delay; 
	end

//for 50% duly cycle sclk	
always @(posedge clk) begin
   sclk_reg <= delay[3];end

//detecting poesge of sclk
reg [1:0] sclk_edge_det;
wire sclk_posedge;
always@(negedge clk )
sclk_edge_det <= {sclk_edge_det[0],sclk_reg};
assign sclk_posedge = {sclk_edge_det[1:0] == 2'b01};	

//detecting negege of sclk
reg [1:0] sclk_edge_det_;
wire sclk_negedge;
always@(negedge clk )
sclk_edge_det_ <= {sclk_edge_det_[0],sclk_reg};
assign sclk_negedge = {sclk_edge_det_[1:0] == 2'b10};
	
//--------start of conversion generation--------------
reg [2:0] state;
localparam st0=3'd0,
			  st1=3'd1,
			  st2=3'd2,
			  st3=3'd3,
		     st4=3'd4;

always @(posedge clk) begin
	if(rst)begin
		cs_reg      <= 1'b1;
		clk_out_reg <= 1'b0;
		data_reg    <= 15'd0;
		data_out_reg<= 10'd0;
		edge_cnt    <= 5'd0;
		state       <= st0;
	end
	
	else begin
		case(state)
		st0: 	begin //wait for start
				if(start) begin
					cs_reg      <= 1'b1;
					clk_out_reg <= 1'b0;
					edge_cnt    <= 5'd0;
					data_reg    <= 15'd0;
					state       <= st1;end
				else state <= st0;
				end
				
		st1:	begin //down cs to start conversion
				if(sclk_negedge) begin
					cs_reg <= 1'b0;
					state  <= st2;end
				else state <= st1;	
				end
				
		st2:	begin //reading data from adc
				if(edge_cnt == 5'd15) begin
					//cs_reg <= 1'b1;
					state  <= st3;end 
				else if(sclk_posedge)begin
					data_reg <= {data_reg[13:0],sdata};
					edge_cnt <= edge_cnt + 1;
					cs_reg   <= 1'b0;
					state    <= st2;end
				else state  <= st2;	
				end
		
		st3:	begin //wait for Tquite time
				if(edge_cnt == 5'd20)begin
					cs_reg      <= 1'b1;
					clk_out_reg <= 1'b1;
					data_out_reg<= data_reg[11:4]; 
					state       <= st4;end
				else if(sclk_posedge)begin
					cs_reg <= 1'b1;
					edge_cnt <= edge_cnt + 1;
					state    <= st3;end
				else state <= st3;	
				end
				
		st4:	begin
				state <= st0;
				end
				
		default: state <= st0;
		endcase
	end	
end

//generate delayed clk_signal
always @(posedge clk) begin
	delay_reg[0] <= clk_out_reg;
	delay_reg[1] <= delay_reg[0];
	delay_reg[2] <= delay_reg[1];
end	

reg s_reg;
always @(*) begin
	if(cs_reg)
		s_reg <= 1'b1;
	else if(~cs_reg)	
		s_reg <= sclk_reg;
	else s_reg <= s_reg;
end	
	
//assigning output signal
assign cs_bar  = cs_reg;
assign clk_out = delay_reg[2];
assign data_out= data_out_reg;
assign sclk    = s_reg;//sclk_reg;


//for debug
//assign dt = data_reg;

endmodule