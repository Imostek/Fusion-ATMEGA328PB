`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:51:21 09/05/2023 
// Design Name: 
// Module Name:    Generic_FIR_filter(sequential design with limited resource) 
//////////////////////////////////////////////////////////////////////////////////
module Generic_FIR_filter(
	input signed [15:0] vin,
	input signed [15:0] coef_0,
	input signed [15:0] coef_1,
	input signed [15:0] coef_2,
	input signed [15:0] coef_3,
	input signed [15:0] coef_4,
	input signed [15:0] coef_5,
	input signed [15:0] coef_6,
	input rst,
	input clk,
	input filter_clk,
	output [15:0] vout 
);

//----------internal reg and wire   
integer i,j,k,l;	 
wire signed [15:0] coef[6:0];
reg  signed [15:0] delay [6:0];
reg  [15:0] X,Y;
reg  [35:0] W;
wire [35:0] Z;	
reg  [15:0] out_reg,out_reg_1;

//-----filter coefficient assignment
assign	coef[0] = coef_0, 
			coef[1] = coef_1,
			coef[2] = coef_2,
			coef[3] = coef_3,
			coef[4] = coef_4,
			coef[5] = coef_5,
			coef[6] = coef_6;
	
//------------- edge detect -------------------
//reg [1:0] edge_det = 2'b00;
//always @(posedge clk)
//	edge_det <= {edge_det[0], filter_clk};
//	
//wire filter_tick = (edge_det == 2'b01);

wire filter_tick = filter_clk;

//-------- state machine for FIR filter --------
localparam 	s0 = 3'd0,
				s1 = 3'd1,
				s2 = 3'd2,
				s3 = 3'd4,
				s4 = 3'd5,
				s5 = 3'd6;
				
//define state variable 
reg [2:0] state = s0;
reg [2:0] index;		

always @(posedge clk) begin
	if(rst) begin
		for(i=0; i<=6; i=i+1) begin
			delay[i] <= 0;end
		X         <= 0;
      Y         <= 0;
      out_reg   <= 0;
		out_reg_1 <= 0;	
		state     <= s0;
	end
	else begin
		case(state)
			s0: begin
				  if(filter_tick)	state <= s1;
				  else 				state <= s0; 	
				 end
			s1: begin
				  delay[0] <= vin;
				  for(k=1;k<7;k=k+1) begin
				    delay[k] <= delay[k-1];end
				  index   <= 0;
				  out_reg <= 0;
              state   <= s2; 				  
             end
			s2: begin
				  X <= coef[index];
				  Y <= delay[index];
				  state <= s3;
				 end
			s3: begin
				  W <= Z >>> 14;
				  state <= s4;
				 end
			s4: begin
				  out_reg <= out_reg + W[15:0];
              if(index < 3'd6) begin
						index <= index + 3'd1;
						state <= s2;end
				  else state <= s5; 	
			    end
			s5: begin
					out_reg_1 <= out_reg;
					state <= s0;
				 end
			default: begin 
							state <= s0; 
						end	 
		endcase
	end

end

//------------- multiplier unit -------------------
MULT18X18 MULT18X18_inst (
	.P(Z),            // 36-bit multiplier output
	.A({2'b00,X}),    // 18-bit multiplier input
	.B({2'b00,Y})     // 18-bit multiplier input
);


assign vout = out_reg_1;
endmodule




