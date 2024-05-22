`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:13:41 06/23/2023 
// Design Name: 
// Module Name:    fifo 
//////////////////////////////////////////////////////////////////////////////////
module fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 4
)(
    input [WIDTH-1:0] data_in,
    input wire clk,
	 input wire rst,
	 
//	 output [1:0] wr_ptr,
//	 output [1:0] rd_ptr,
	 
    input wire wr_en,
    input wire rd_en,
    output reg [WIDTH-1:0] data_out,
    output wire fifo_full,
    output wire fifo_empty,
    output wire fifo_not_empty,
    output wire fifo_not_full
);

//define log2 function
function integer log2(input integer v); 
begin 
	log2=0; 
	while(v>>log2) log2=log2+1; 
end 
endfunction

// define internal wire and reg
integer i;
localparam bus_w = log2(DEPTH)-1;
localparam bus_w_1 = bus_w-1;

reg [WIDTH-1:0] memory [0:DEPTH-1];
reg [bus_w:0] write_ptr;
reg [bus_w:0] read_ptr;
wire write = wr_en;
wire read  = rd_en;

//update fifo status flags
wire [bus_w:0] stat = (write_ptr > read_ptr)? (write_ptr - read_ptr):
				          (write_ptr < read_ptr)? (read_ptr - write_ptr):0; 

assign fifo_empty = ( write_ptr == read_ptr ) ? 1'b1 : 1'b0;
assign fifo_full = (((write_ptr > read_ptr) & (stat == {(bus_w){1'b1}}))|((write_ptr < read_ptr) & (stat == {{(bus_w_1){1'b0}},1'b1}))) ? 1'b1 : 1'b0;

assign fifo_not_empty = ~fifo_empty;
assign fifo_not_full = ~fifo_full;

//fifo read and write operation
always @ (posedge clk) begin
	if(rst) begin
		for(i=0;i<DEPTH;i=i+1)begin
			memory[i] <= 0;end
		data_out <= 8'd0;
	end	
	else begin	
	  if ( write ) begin
			memory[write_ptr] <= data_in;
	  end
	  if ( read ) begin
			data_out <= memory[read_ptr];
	  end
	 end 
end

//update fifo read and write pointer 
always @ ( posedge clk ) begin
	if(rst) begin
		write_ptr <= 0;
		read_ptr  <= 0;
		end	
  else begin		
	  if ( write && fifo_not_full ) begin
			write_ptr <= write_ptr + 1;
	  end

	  if ( read && fifo_not_empty ) begin
			read_ptr <= read_ptr + 1;
	  end
  end
end

//assign rd_ptr = read_ptr;
//assign wr_ptr = write_ptr;

endmodule
