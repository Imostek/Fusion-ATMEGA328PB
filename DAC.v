//Send Data on falling edge, read on clk high
//sdata High to Low when clock is High initiates Transfer
//sdata low to High when Clock is High ends Transfer
//inout port should go through the buffer

module dacMCP4725_interface(
		input clk,           // Clock input
		input rst,           // Reset input
		input start,		// Start ttransfer command
		input [11:0] data,  // dac value
		input sdata_in,
		output sdata_out,
		output sclk,     // Data Clock
		output tx_complete,
		output io_dir	
		//For Simulation 				
		/*output [7:0] count1_out, 		
		output [2:0] state_out, 		
		output sclk_negedge_out, 		
		output [7:0] data_out_out,		 		
		output sdata_in_out, 		
		output sdata_out_out*/
);
reg sclk_reg = 0;
reg sclk_out;
reg sclk_en; 
reg sdata_reg = 0;

reg tx_complete_reg = 1;
reg [7:0] count1 = 0;
reg [7:0] count_clk = 0;
reg [2:0] state,next_state;
reg [7:0] data_out;

reg io_dir_reg;  //T 1:Input ; 0:Output

//assign sdata_wire = sdata_in;

always @(posedge clk) begin
	if(rst) begin
		count_clk <= 0;
		sclk_reg <= 0;
	end
	else begin
		count_clk <= count_clk + 1;
		if(count_clk >= 120) begin
			count_clk <= 0;
			sclk_reg <= ~sclk_reg;
		end
	end	
end


//detecting poesge of sclk
reg [1:0] sclk_posedge_det;
wire sclk_posedge;
always@(posedge clk)
sclk_posedge_det <= {sclk_posedge_det[0],sclk_reg};
assign sclk_posedge = {sclk_posedge_det[1:0] == 2'b01};	

//detecting negege of sclk
reg [1:0] sclk_negedge_det;
wire sclk_negedge;
always@(posedge clk)
sclk_negedge_det <= {sclk_negedge_det[0],sclk_reg};
assign sclk_negedge = {sclk_negedge_det[1:0] == 2'b10};

//--------DAC Parameters--------------
localparam
DACADDRESS = 8'b11001100, //Address = 1100; A2,A1 = 11 (For A3 lot of PartID); A0 = 0 (GND); R/WBAR = 0 (Write)
FAST_MODE = 4'b0000;	//D7,D6 = 00 (Fast Mode); D5,D4 = PD1,PD0 (00 for DAC Mode)

//--------start of conversion generation--------------

localparam 	IDLE=3'd0,
				TRANSFER=3'd1,
				ACK=3'd2,
				TERMINATE=3'd3,
				ADDRESSTX = 3'd4,
				DATA1TX = 3'd5,
				DATA2TX = 3'd6,
				TRANS = 3'd7;
			  
always @(posedge clk) begin
	if(rst)begin
		sdata_reg <= 1;		
		state  <= IDLE;
		next_state <= IDLE;
		sclk_en <= 0;
		io_dir_reg <= 0;
		tx_complete_reg <= 1;
		count1 <= 0;
	end	
	else begin
		case(state)
			IDLE:	begin //wait for start
						io_dir_reg <= 0;
						if(start && sclk_posedge) begin							
							sdata_reg <= 0;	
							tx_complete_reg <= 0;
							data_out <= DACADDRESS;								
							state <= TRANSFER;
							next_state <= ADDRESSTX;
							sclk_en <= 1;
						end
						else begin
							state <= IDLE;
							sdata_reg <= 1;
						end
					end									
			TRANSFER:	begin //Transfer Byte available in data_out								
								if(sclk_negedge) begin		
									io_dir_reg <= 0;
									count1 <= count1 + 1;
									if (count1 >= 8) begin
										count1 <= 0;
										io_dir_reg <= 1;									
										state <= ACK;
										if(next_state == ADDRESSTX) begin
											next_state <= DATA1TX;
										end
										else if (next_state == DATA1TX) begin
											next_state <= DATA2TX;									
										end
										else if (next_state == DATA2TX) begin
											if(start) next_state <= DATA1TX;
											else begin
												next_state <= TERMINATE;												
											end
										end
									end
									else begin 
										state <= TRANSFER;
										sdata_reg <= data_out[7];
										data_out[7:0] <= {data_out[6:0], data_out[7]};
									end
								end
							end		
			ACK:	begin //wait for Tquite time
						if((sdata_in == 0) && sclk_posedge) begin													
							if(next_state == DATA1TX) begin
								data_out[7:4] <= FAST_MODE;
								data_out[3:0] <= data[11:8];
								state <= TRANSFER;
							end
							else if(next_state == DATA2TX) begin
								data_out[7:0] <= data[7:0];
								state <= TRANSFER;
							end
							else if (next_state == TERMINATE) begin
								sdata_reg <= 0;
								sclk_en <= 0;
								state <= TERMINATE;
							end
						end
						else	state <= ACK;
					end	
			TERMINATE:	begin
								io_dir_reg <= 0;
								count1 <= count1 + 1;
								if (count1 >= 60) begin
									count1 <= 0;
									sdata_reg <= 1;
									tx_complete_reg <= 1;
									state <= TRANS;
								end
							end
			TRANS: 	begin
							state <= IDLE;
						end
			default: state <= IDLE;
		endcase
	end	
end

always @(*) begin
	if(sclk_en) sclk_out <= sclk_reg;
	else sclk_out <= 1'b1;
	//sclk_out <= sclk_reg;
end

assign sclk = sclk_out;
assign sdata_out = sdata_reg;
assign tx_complete = tx_complete_reg;
assign io_dir = io_dir_reg;

//For Simulation 
/*assign  count1_out[7:0] =  count1[7:0]; 
assign state_out[2:0] = state[2:0]; 
assign sclk_negedge_out = sclk_negedge; 
assign data_out_out[7:0] = data_out[7:0]; 
 
assign sdata_out_out = sdata_out;*/
endmodule