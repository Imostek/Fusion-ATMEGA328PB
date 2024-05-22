`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:33:57 05/17/2024  
// Module Name:    SPI_slave_10 
// Update     :    Rst from microcontroller code added  
//////////////////////////////////////////////////////////////////////////////////
module SPI_slave_10(
	input sys_clk,
	input rst_bar,
	
	//--for debug
//	output data_clk_de,
//	output [3:0] bit_cnt_reg_de,
//	output [7:0] data_reg_de, addr_reg_de,
//	output valid_de,
//	output adc_en_de,
//	output led_en_de,
//	output [7:0] adc_config_reg_de,
	
	input sclk,
	input cs,
	input mosi,
	output miso,
	
	//led connection
	output [3:0] LEDs,
	
	//ADC connection
	output A_CS,
	output A_CLK,
	input  A_DT,
	
	//DAC connection
	inout  D_DT,
	output D_CLK,
	
	//PWM connection
	output PWM_1,
	output PWM_2,
	output PWM_3,
	output PWM_4,
	
	//UART connection
	output UART_TX
    );
	 
//define internal wire and reg
wire rst = ~rst_bar;
wire clk = sys_clk;

reg cs_reg,mosi_reg;
reg [7:0] addr_reg, data_reg;
reg [7:0] addr,data;
wire [7:0] addr_sig, data_sig;
reg [7:0] miso_data_reg;
reg miso_reg;
reg rst_fp_from_uc_reg;

wire [7:0] ADC_uc_data;
wire [7:0] ADC_UART_data;
wire [7:0] ADC_filter_data;
wire [7:0] filter_UART_data;

wire ADC_filter_UART_empty;
wire UART_ADC_filter_done;

wire ADC_UART_empty;
wire UART_ADC_done;
wire FPGA_rst;

//sync input signal with system clk
always @(posedge clk) begin
	cs_reg <= cs;
	mosi_reg <= mosi;
end

wire cs_sig = cs_reg;
wire mosi_sig = mosi_reg; 

//edge detection
reg [2:0] edge_det = 0;
always @(posedge clk)
	edge_det <= {edge_det[1:0],sclk};

wire sclk_fe = (edge_det == 3'd100);
wire valid_fe = ~cs_sig & sclk_fe;	

//receive SPI data				
reg [3:0] bit_cnt_reg;
reg [7:0] data_reg_0, data_reg_1 = 0;


//implement SPI slave
always @(posedge clk) begin
	if(rst) begin
		data_reg_0 <= 8'd0;
		data_reg_1 <= 8'd0;
		bit_cnt_reg <= 4'd0;
		end
	 else if(~cs) begin
		if(sclk_fe & bit_cnt_reg < 4'd8) begin
			data_reg_0 <= {data_reg_0[6:0],mosi_sig};
			bit_cnt_reg <= bit_cnt_reg + 4'd1;
			end
		else if(bit_cnt_reg == 4'd8) begin
			data_reg_1  <= data_reg_0;
			bit_cnt_reg <= 4'd0;
			end
		else begin
			data_reg_0  <= data_reg_0;
			bit_cnt_reg <= bit_cnt_reg;
			end
	 end
	 else begin
		data_reg_0 <= 8'd0;
		bit_cnt_reg <= 4'd0;
	 end
end

//update MISO 
always @(*) begin
	case(bit_cnt_reg)
	4'b0001: begin miso_reg <= miso_data_reg[7]; end
	4'b0010: begin miso_reg <= miso_data_reg[6]; end
	4'b0011: begin miso_reg <= miso_data_reg[5]; end
	4'b0100: begin miso_reg <= miso_data_reg[4]; end
	4'b0101: begin miso_reg <= miso_data_reg[3]; end
	4'b0110: begin miso_reg <= miso_data_reg[2]; end
	4'b0111: begin miso_reg <= miso_data_reg[1]; end
	4'b1000: begin miso_reg <= miso_data_reg[0]; end
	endcase
end	

//update wr_en addr and data
reg d0,d1;
wire dt_clk = bit_cnt_reg[3];

//delay data clk for sync
always @(posedge clk) begin
	if(rst) begin
		d0 <= 0;
		d1 <= 0;
	end
	else begin 
		d0 <= dt_clk;
		d1 <= d0;
	end
end

wire wr_en = d1;

//state machine to update addr and data
localparam 	s0 = 1'b0,
			   s1 = 1'b1;

reg st;
reg valid;

always @(posedge clk or posedge rst) begin
	if(rst) begin
		st <= s0;
		data_reg <= 8'd0;
		addr_reg <= 8'd0;
		valid <= 0;
	end
	else begin
		case(st) 
		s0: begin
				 valid <= 0;
				 if(wr_en) begin
					addr_reg <= data_reg_1;
					st <= s1;end
			 end
		s1: begin
				 if(wr_en) begin
					data_reg <= data_reg_1;
					valid <= 1;
					st <= s0;end
			 end
		default: begin st <= s0; end
		endcase
	end
end

//register addr and data after receiving valid signal
reg valid_shift_1,valid_shift_2;
reg valid_shift_3,valid_shift_4;

always @(posedge clk) begin
	if(rst)begin
		valid_shift_1 <= 0;
		valid_shift_2 <= 0;
		valid_shift_3 <= 0;
		valid_shift_4 <= 0;
		end
	else begin
		valid_shift_1 <= valid;
		valid_shift_2 <= valid_shift_1;
		valid_shift_3 <= valid_shift_2;
		valid_shift_4 <= valid_shift_3;
		end
end

wire valid_sig = valid_shift_2;

always @(posedge clk)begin
	if(valid_sig) begin
		addr <= addr_reg;
		data <= data_reg;
	end
end

assign addr_sig = addr;
assign data_sig = data;

//multiplexer to select different controller en signal
reg LED_en_reg, ADC_en_reg, UART_en_reg, DAC_en_reg, PWM_en_reg;
reg toUART_en_reg;
reg toDAC_en_reg;
reg UC_FIFO_rst_en_reg;
reg toPWM_cmd_1_en_reg;
reg toPWM_cmd_2_en_reg;
reg toPWM_cmd_3_en_reg;
reg toPWM_cmd_4_en_reg;

reg coef_0_0_en_reg;
reg coef_0_1_en_reg;
reg coef_1_0_en_reg;
reg coef_1_1_en_reg;
reg coef_2_0_en_reg;
reg coef_2_1_en_reg;
reg coef_3_0_en_reg;
reg coef_3_1_en_reg;
reg coef_4_0_en_reg;
reg coef_4_1_en_reg;
reg coef_5_0_en_reg;
reg coef_5_1_en_reg;
reg coef_6_0_en_reg;
reg coef_6_1_en_reg;
reg coef_set_en_reg;

always @(*) begin
	rst_fp_from_uc_reg      = (addr_sig == 8'd250)  ? 1'b1 : 1'b0;
	LED_en_reg 					= (addr_sig == 8'd1)		? 1'b1 : 1'b0; //LED cntr en
	ADC_en_reg 					= (addr_sig == 8'd4)		? 1'b1 : 1'b0; //ADC cntr en
	UART_en_reg					= (addr_sig == 8'd8)		? 1'b1 : 1'b0;	//UART cntr en
	toUART_en_reg 				= (addr_sig == 8'd128) 	? 1'b1 : 1'b0; //UC_UART_FIFO wr en
	UC_FIFO_rst_en_reg 		= (addr_sig == 8'd129) 	? 1'b1 : 1'b0; //UC_UART_FIFO rst en
	DAC_en_reg     			= (addr_sig == 8'd16)	? 1'b1 : 1'b0; //DAC cntr en
	toDAC_en_reg            = (addr_sig == 8'd130) 	? 1'b1 : 1'b0; //UC_DAC_FIFO wr en
	PWM_en_reg              = (addr_sig == 8'd32) 	? 1'b1 : 1'b0; //PWM cntr en
	toPWM_cmd_1_en_reg      = (addr_sig == 8'd140) 	? 1'b1 : 1'b0; //PWM cmd1 en
	toPWM_cmd_2_en_reg      = (addr_sig == 8'd141) 	? 1'b1 : 1'b0; //PWM cmd2 en
	toPWM_cmd_3_en_reg      = (addr_sig == 8'd142) 	? 1'b1 : 1'b0; //PWM cmd3 en
	toPWM_cmd_4_en_reg      = (addr_sig == 8'd143) 	? 1'b1 : 1'b0; //PWM cmd4 en
	
	//--------------------------------------------------------------------------
	coef_0_0_en_reg         = (addr_sig == 8'd160) 	? 1'b1 : 1'b0;
	coef_0_1_en_reg			= (addr_sig == 8'd161) 	? 1'b1 : 1'b0;
	coef_1_0_en_reg			= (addr_sig == 8'd162) 	? 1'b1 : 1'b0;
	coef_1_1_en_reg			= (addr_sig == 8'd163) 	? 1'b1 : 1'b0;
	coef_2_0_en_reg			= (addr_sig == 8'd164) 	? 1'b1 : 1'b0;
	coef_2_1_en_reg			= (addr_sig == 8'd165) 	? 1'b1 : 1'b0;
	coef_3_0_en_reg			= (addr_sig == 8'd166) 	? 1'b1 : 1'b0;
	coef_3_1_en_reg			= (addr_sig == 8'd167) 	? 1'b1 : 1'b0;
	coef_4_0_en_reg			= (addr_sig == 8'd168) 	? 1'b1 : 1'b0;
	coef_4_1_en_reg			= (addr_sig == 8'd169) 	? 1'b1 : 1'b0;
	coef_5_0_en_reg			= (addr_sig == 8'd170) 	? 1'b1 : 1'b0;
	coef_5_1_en_reg			= (addr_sig == 8'd171) 	? 1'b1 : 1'b0;
	coef_6_0_en_reg			= (addr_sig == 8'd172) 	? 1'b1 : 1'b0;
	coef_6_1_en_reg			= (addr_sig == 8'd173) 	? 1'b1 : 1'b0;
	coef_set_en_reg         = (addr_sig == 8'd174)  ? 1'b1 : 1'b0;
end

//assign en signals
wire fp_rst = rst_fp_from_uc_reg;
or(FPGA_rst, rst, fp_rst);
wire LED_en 				= LED_en_reg;
wire ADC_en 				= ADC_en_reg;
wire UART_en				= UART_en_reg;
wire toUART_en 			= toUART_en_reg;
wire UC_FIFO_rst_en 		= UC_FIFO_rst_en_reg;
wire DAC_en  				= DAC_en_reg;
wire toDAC_en        	= toDAC_en_reg;
wire PWM_en          	= PWM_en_reg;
wire toPWM_cmd_1_en  	= toPWM_cmd_1_en_reg;
wire toPWM_cmd_2_en  	= toPWM_cmd_2_en_reg;
wire toPWM_cmd_3_en  	= toPWM_cmd_3_en_reg;
wire toPWM_cmd_4_en  	= toPWM_cmd_4_en_reg;

wire coef_0_0_en			= coef_0_0_en_reg;
wire coef_0_1_en			= coef_0_1_en_reg;
wire coef_1_0_en			= coef_1_0_en_reg;
wire coef_1_1_en			= coef_1_1_en_reg;
wire coef_2_0_en			= coef_2_0_en_reg;
wire coef_2_1_en			= coef_2_1_en_reg;
wire coef_3_0_en			= coef_3_0_en_reg;
wire coef_3_1_en			= coef_3_1_en_reg;
wire coef_4_0_en			= coef_4_0_en_reg;
wire coef_4_1_en			= coef_4_1_en_reg;
wire coef_5_0_en			= coef_5_0_en_reg;
wire coef_5_1_en			= coef_5_1_en_reg;
wire coef_6_0_en			= coef_6_0_en_reg;
wire coef_6_1_en			= coef_6_1_en_reg;
wire coef_set_en        = coef_set_en_reg;

//filter coeff reg update
reg [15:0] coeff[0:6];
integer i;

always @(posedge valid_sig or posedge FPGA_rst) begin
	if(FPGA_rst) begin
		for(i=0; i<7; i=i+1) 
			coeff[i] <= 16'd0;
	end	
	else begin
		coeff[0][7:0]  <= (coef_0_0_en) ? data_sig : coeff[0][7:0];
		coeff[0][15:8] <= (coef_0_1_en) ? data_sig : coeff[0][15:8];
		coeff[1][7:0]  <= (coef_1_0_en) ? data_sig : coeff[1][7:0];
		coeff[1][15:8] <= (coef_1_1_en) ? data_sig : coeff[1][15:8];
		coeff[2][7:0]  <= (coef_2_0_en) ? data_sig : coeff[2][7:0];
		coeff[2][15:8] <= (coef_2_1_en) ? data_sig : coeff[2][15:8];
		coeff[3][7:0]  <= (coef_3_0_en) ? data_sig : coeff[3][7:0];
		coeff[3][15:8] <= (coef_3_1_en) ? data_sig : coeff[3][15:8];
		coeff[4][7:0]  <= (coef_4_0_en) ? data_sig : coeff[4][7:0];
		coeff[4][15:8] <= (coef_4_1_en) ? data_sig : coeff[4][15:8];
		coeff[5][7:0]  <= (coef_5_0_en) ? data_sig : coeff[5][7:0];
		coeff[5][15:8] <= (coef_5_1_en) ? data_sig : coeff[5][15:8];
		coeff[6][7:0]  <= (coef_6_0_en) ? data_sig : coeff[6][7:0];
		coeff[6][15:8] <= (coef_6_1_en) ? data_sig : coeff[6][15:8];
	end		
end

//set filter coeff
reg [15:0] filter_coef[0:6];
integer j,k;
always @(posedge coef_set_en or posedge FPGA_rst) begin
	if(FPGA_rst) begin
		for(j=0; j<7; j=j+1) begin
		filter_coef[j] <= 16'd0;end
	end
	else begin
		for(k=0; k<7; k=k+1) begin
		filter_coef[k] <= coeff[k];end
	end
end

//-------------------- instantiate filter

//delay done sig
reg delay_done_reg;

always @(posedge clk) begin
	if(FPGA_rst) delay_done_reg <= 0;
	else delay_done_reg <= UART_ADC_filter_done;
end

wire filter_clk = delay_done_reg; 
wire [15:0] filter_out;

Generic_FIR_filter  TAP_filter(
	.clk(clk), 
	.rst(FPGA_rst),
	.vin({8'd0,ADC_filter_data}), 
	.coef_0(filter_coef[0]), 
	.coef_1(filter_coef[1]), 
	.coef_2(filter_coef[2]), 
	.coef_3(filter_coef[3]), 
	.coef_4(filter_coef[4]), 
	.coef_5(filter_coef[5]), 
	.coef_6(filter_coef[6]), 
	.filter_clk(filter_clk), //uart done as filter clk
	.vout(filter_out)
);

assign filter_UART_data = filter_out[7:0];

//generate UC_UART_FIFO_rst pulse
reg [2:0] rst_pulse_gen_reg = 0;
always @(posedge clk) begin
	rst_pulse_gen_reg <= {rst_pulse_gen_reg[1:0],UC_FIFO_rst_en};
end
wire UC_UART_FIFO_rst_sig = (rst_pulse_gen_reg == 3'b001 | rst_pulse_gen_reg == 3'b011);	

//UC UART FIFO signals
wire [7:0] UC_UART_fifo_data_in = data_sig;
wire [7:0] UC_UART_fifo_data_out;
wire UC_UART_fifo_rd_en;
wire UC_UART_fifo_empty;
wire UC_UART_fifo_full;
wire UC_UART_fifo_wr = (toUART_en)? valid_shift_4:0;

//-------------------- instantiate UC UART FIFO	
fifo #(8,8) UC_UART_fifo(
    .data_in(UC_UART_fifo_data_in),
    .clk(clk),
	 .rst(UC_UART_FIFO_rst_sig | rst),
    .wr_en(UC_UART_fifo_wr),
    .rd_en(UC_UART_fifo_rd_en),
    .data_out(UC_UART_fifo_data_out),
    .fifo_full(UC_UART_fifo_full),
    .fifo_empty(UC_UART_fifo_empty)
);

//-------------------- instantiate led controller
wire [3:0] led_sig;

LED_controller led_cntr(
	.clk(clk), 
	.rst(FPGA_rst),
	.LED_en(LED_en), 
	.data(data_sig), 
	.LEDs(led_sig)
);

//ADC config reg update
reg [7:0] ADC_config_reg = 0;
always @(posedge valid_sig or posedge FPGA_rst) begin
	if(FPGA_rst) ADC_config_reg <= 8'd0;
	else ADC_config_reg <= (ADC_en) ? data_sig : ADC_config_reg;
end

//-------------------- instantiate ADC controller
ADC_controller_1 ADC_(
	.clk(clk),
	.rst(FPGA_rst),
	.ADC_config(ADC_config_reg),
	
	//adc fifo status signal
	.ADC_read_en_0(wr_en),//uc 
	.ADC_read_en_1(UART_ADC_done),//UART
	.ADC_read_en_2(UART_ADC_filter_done),//tap_filter
	.ADC_read_en_3(),
	
	.ADC_fifo_empty_0(),
	.ADC_fifo_empty_1(ADC_UART_empty),//UART
	.ADC_fifo_empty_2(ADC_filter_UART_empty),//tap_filter
	.ADC_fifo_empty_3(),
	
	//adc data output signal
	.ADC_data_0(ADC_uc_data),//uc
	.ADC_data_1(ADC_UART_data),//UART
	.ADC_data_2(ADC_filter_data),//tap_filter
	.ADC_data_3(),
	
	//adc connection
	.cs(A_CS),
	.sdata(A_DT),
	.sclk(A_CLK) 
   );
	
//UART config reg update
reg [7:0] UART_config_reg = 0;
always @(posedge valid_sig or posedge FPGA_rst) begin
	if(FPGA_rst) UART_config_reg <= 8'd0;
	else UART_config_reg <= (UART_en) ? data_sig : UART_config_reg;
end	

//-------------------- instantiate UART controller
UART_controller_1 UART_(
	.clk(clk),
	.rst(FPGA_rst),
	.UART_config(UART_config_reg),
	
	//tx data in 
	.tx_data_0(UC_UART_fifo_data_out),//uc
	.tx_data_1(ADC_UART_data),//ADC filter data
	.tx_data_2(filter_UART_data),//tap_filter
	.tx_data_3(),
	
	//tx start signal
	.tx_start_0(~UC_UART_fifo_empty),//uc
	.tx_start_1(~ADC_UART_empty),//ADC
	.tx_start_2(~ADC_filter_UART_empty),//tap_filter
	.tx_start_3(),
	
	//tx done signal
	.tx_done_0(UC_UART_fifo_rd_en),//uc
	.tx_done_1(UART_ADC_done),//ADC
	.tx_done_2(UART_ADC_filter_done),//tap_filter
	.tx_done_3(),
		
	//uart connection
	.tx(UART_TX)
  );	


//DAC config reg update
reg [7:0] DAC_config_reg = 0;
always @(posedge valid_sig or posedge FPGA_rst) begin
	if(FPGA_rst) DAC_config_reg <= 8'd0;
	else DAC_config_reg <= (DAC_en) ? data_sig : DAC_config_reg;
end

//-------------------- instantiate DAC controller
wire [11:0] UC_DAC_data_sig = {data_sig[7:0],4'b1111};

DAC_controller_1 DAC_(
	.clk(clk),
	.rst(FPGA_rst),
	.DAC_config(DAC_config_reg),
	
	//DAC data in 
	.DAC_data_0(UC_DAC_data_sig),//from UC
	.DAC_data_1(),//from UART
	.DAC_data_2(),//from FILTER
	.DAC_data_3(),
	
	//DAC conversion start signal
	.cnv_start_0(toDAC_en),//from UC
	.cnv_start_1(),
	.cnv_start_2(),
	.cnv_start_3(),
	
	//DAC conversion done signal
	.cnv_done_0(),
	.cnv_done_1(),
	.cnv_done_2(),
	.cnv_done_3(),
		
	//DAC connection
	.ddata(D_DT),
	.dclk(D_CLK)	
	 );
	 
//PWM config reg update
reg [7:0] PWM_config_reg = 0;
reg [7:0] PWM_cmd_1_reg = 0;
reg [7:0] PWM_cmd_2_reg = 0;
reg [7:0] PWM_cmd_3_reg = 0;
reg [7:0] PWM_cmd_4_reg = 0;

always @(posedge valid_sig or posedge FPGA_rst) begin
	if(FPGA_rst) PWM_config_reg <= 8'd0;
	else    PWM_config_reg <= (PWM_en) ? data_sig : PWM_config_reg;
end	

//PWM cmd reg update
always @(posedge clk or posedge FPGA_rst) begin
	if(FPGA_rst) begin
		PWM_cmd_1_reg <= 8'd0;
		PWM_cmd_2_reg <= 8'd0;
		PWM_cmd_3_reg <= 8'd0;
		PWM_cmd_4_reg <= 8'd0;
		end
	else begin   
		PWM_cmd_1_reg <= (toPWM_cmd_1_en) ? data_sig : PWM_cmd_1_reg;
		PWM_cmd_2_reg <= (toPWM_cmd_2_en) ? data_sig : PWM_cmd_2_reg;
		PWM_cmd_3_reg <= (toPWM_cmd_3_en) ? data_sig : PWM_cmd_3_reg;
		PWM_cmd_4_reg <= (toPWM_cmd_4_en) ? data_sig : PWM_cmd_4_reg;
		end
end	

//-------------------- instantiate PWM controller
PWM_controller_1 PWM_(
	.clk(clk),
	.rst(FPGA_rst),
	.PWM_config(PWM_config_reg),
	
	.cmd_1(PWM_cmd_1_reg),
	.cmd_2(PWM_cmd_2_reg),
	.cmd_3(PWM_cmd_3_reg),
	.cmd_4(PWM_cmd_4_reg),
	
	.pwm_1(PWM_1),
	.pwm_2(PWM_2),
	.pwm_3(PWM_3),
	.pwm_4(PWM_4)
    ); 

//update data to miso reg
always @(posedge clk) begin
	miso_data_reg = (ADC_en) ? ADC_uc_data : miso_data_reg;
end
 

//final signal assignment
assign LEDs = ~led_sig;
assign miso = miso_reg;

//for debug
//assign data_clk_de    = wr_en; 
//assign bit_cnt_reg_de = bit_cnt_reg;
//assign data_reg_de    = data_sig;
//assign addr_reg_de    = addr_sig;
//assign valid_de       = valid_sig;
//assign adc_en_de      = ADC_en;
//assign led_en_de      = LED_en;
//assign adc_config_reg_de = config_reg_de;

endmodule
