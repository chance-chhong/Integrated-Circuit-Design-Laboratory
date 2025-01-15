module ISP(
    // Input Signals
    input clk,
    input rst_n,
    input in_valid,
    input [3:0] in_pic_no,
    input       in_mode,
    input [1:0] in_ratio_mode,

    // Output Signals
    output reg out_valid,
    output reg [7:0] out_data,
    
    // DRAM Signals
    // axi write address channel
    // src master
    output [3:0]        awid_s_inf,
    output reg [31:0] awaddr_s_inf, // change to pseudo-reg
    output [2:0]      awsize_s_inf,
    output [1:0]     awburst_s_inf,
    output [7:0]       awlen_s_inf,
    output reg       awvalid_s_inf, // change to reg
    // src slave
    input            awready_s_inf,
    // -----------------------------
  
    // axi write data channel 
    // src master
    output [127:0] wdata_s_inf,
    output reg     wlast_s_inf, // change to reg
    output reg    wvalid_s_inf, // change to reg
    // src slave
    input          wready_s_inf,
  
    // axi write response channel 
    // src slave
    input [3:0]    bid_s_inf,
    input [1:0]    bresp_s_inf,
    input          bvalid_s_inf,
    // src master 
    output reg     bready_s_inf, // change to reg
    // -----------------------------
  
    // axi read address channel 
    // src master
    output [3:0]        arid_s_inf,
    output reg [31:0] araddr_s_inf, // change to pseudo-reg
    output [7:0]       arlen_s_inf,
    output [2:0]      arsize_s_inf,
    output [1:0]     arburst_s_inf,
    output reg       arvalid_s_inf, // change to reg
    // src slave
    input            arready_s_inf,
    // -----------------------------
  
    // axi read data channel 
    // slave
    input [3:0]    rid_s_inf,
    input [127:0]  rdata_s_inf,
    input [1:0]    rresp_s_inf,
    input          rlast_s_inf,
    input          rvalid_s_inf,
    // master
    output reg     rready_s_inf
    
);

//==============================================//
//             Parameter and Integer            //
//==============================================//
enum logic [1:0] {
    IDLE =    2'd0,
    DRAM_READ =   2'd1,
	EXPOSURE =  2'd2,
	ZERO_OUTPUT = 2'd3
    } current_state, next_state;

integer i, j;

//==============================================//
//                 reg declaration              //
//==============================================//

reg [3:0] in_pic_no_reg; // 4-bit in_pic_no from 0 to 15
reg in_mode_reg; // 0 == auto focus, 1 == auto exposure
reg [1:0] in_ratio_mode_reg; //(0, 0.25),(1, 0.5),(2, 1),(3, 2)

reg valid_data, valid_out, valid_out_r;

reg [23:0] gray_cell_[0:11];  //0,1,2,3,4,5,6,7,8,9,10,11,64,65,66,67,68,69,70,71,72,73,74,75,128,129,130,131,132,133,134,135,136,137,138,139
reg [7:0] gray_cell_cnt_;
reg [3:0] diff_cell_cnt;
reg [1:0] gray_shift_;
reg [23:0] gray_cell_buff[0:1];
reg [14:0] diff2_v;
reg [9:0] diff2_v_tmp, diff2_h;
reg [14:0] diff2;
reg [13:0] diff1_v, diff1_h;
reg [13:0] diff1;
reg [11:0] diff0;
reg [1:0] idx_, idx;
reg rvalid_s_inf_reg;


reg [7:0] data_in_result_part[0:15];
reg [5:0] diff_cnt;
reg flag;
reg [7:0] diff2_h_out_reg[0:2];
reg [7:0] diff2_v_out_reg[0:2];
reg [9:0] diff0_n_reg;
reg [9:0] diff1_n_reg;
reg [9:0] diff2_n_reg;
reg [7:0] sub1[0:5], sub2[0:5];


reg [15:0] average_cell[0:15];
reg [15:0] average_cell_shift;
reg [8:0] average_cnt;
reg flag_average_output, flag_average_output_r;
reg [3:0] average_cell_cnt;
reg [1:0] average_shift[0:15];

reg [7:0] addr_dram_reg;
reg [127:0] data_in_result_buff[0:15];
reg [17:0] average_cell_tot;

reg [15:0] in_pic_no_zero; //check whether the pic is whole zero pic
reg [127:0] zero_check;

reg [15:0]auto_flag;
reg [1:0] auto_auto_focus_idx[0:15];

reg [7:0] auto_auto_exposure_idx[0:15];



//==============================================//
//                 wire declaration             //
//==============================================//

wire [15:0] addr_bus;



wire [127:0] data_in_result; //data in of SRAM
wire [127:0] data_out_result;

wire [1:0] gray_shift;
wire [7:0] diff2_h_out[0:2];
wire [7:0] diff2_v_out[0:2];


wire [9:0] diff0_n;
wire [9:0] diff1_n;
wire [9:0] diff2_n;


//wire [7:0] addr_dram_wire;
//wire [127:0] data_in_dram;
//wire [127:0] data_out_dram;


//==============================================//
//           AXI4 parameter declaration         //
//==============================================//
// 1. read address channel
// 1-1. one master and one slave, so read address ID = 0
assign arid_s_inf    = 0;
// 1-2. read address of picture
// 1-3. burst length = 140/focus/0, 192/exposure/1
assign arlen_s_inf   = (current_state == IDLE) ? 0 : 191;
// 1-4. burst size = Only support 3’b100 in this exercise
assign arsize_s_inf  = (current_state == IDLE) ? 0 : 3'b100;
// 1-5. brust type = 1 (incrementing burst)
assign arburst_s_inf = (current_state == IDLE) ? 0 : 1;
// 1-6. read valid
// 1-7. read ready (from DRAM slave)

// 2. read data channel
// 2-1. one master and one slave, so read ID tag = 0 (from DRAM slave)
// 2-2. read data (from DRAM slave)
// 2-3. read response (from DRAM slave)
// 2-4. read last (from DRAM slave)
// 2-5. read valid (from DRAM slave)
// 2-6. read ready

//==============================================//
// 3. write address channel
// 3-1. one master and one slave, so write address ID = 0
assign awid_s_inf    = 0;
// 3-2. write address of exposure picture
// 3-3. burst length = 191, whole picture
assign awlen_s_inf   = (current_state == IDLE) ? 0 : 191;
// 3-4. burst size = Only support 3’b100 in this exercise
assign awsize_s_inf  = (current_state == IDLE) ? 0 : 3'b100;
// 3-5. brust type = 1 (incrementing burst)
assign awburst_s_inf = (current_state == IDLE) ? 0 : 1;
// 3-6. write valid
// 3-7. write ready (from DRAM slave)

// 4. write data channel
// 4-1. write data
// 4-2. write last
// 4-3. write valid
// 4-4. write ready (from DRAM slave)

// 5. write response channel
// 5-1. write ID tag (from DRAM slave)
// 5-2. write response (from DRAM slave)
// 5-3. write valid (from DRAM slave)
// 5-4. write ready



//==============================================//
//             Current State Block              //
//==============================================//
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) current_state <= IDLE;
	else current_state <= next_state;
end

//==============================================//
//              Next State Block                //
//==============================================//
always @(*) begin
	case(current_state)
		IDLE: begin
			// when input is valid
			if(in_valid) next_state = (in_pic_no_zero[in_pic_no] || (((in_mode == 0) || (in_mode == 1 && in_ratio_mode == 2)) && auto_flag[in_pic_no])) ? ZERO_OUTPUT : DRAM_READ;
			else next_state = current_state;
		end

		// read picture from DRAM to SRAM with AXI4 protocol
		DRAM_READ: begin
			// when last data of picture is read, start gray scale
			if(in_mode_reg == 0 || in_mode_reg == 1) next_state = rvalid_s_inf ? EXPOSURE : current_state;
			//else if(rlast_s_inf) next_state = GRAY_SCALE;
			else next_state = current_state;
		end

		//do exposure
		EXPOSURE: begin
			if(average_cnt == 211) next_state = IDLE;
			else next_state = EXPOSURE;
		end

		//output zero
		ZERO_OUTPUT: begin
			next_state = IDLE;
		end
		
		default: next_state = IDLE; // illegal state
	endcase
end




// 4-bit in_pic_no from 0 to 15
always @(posedge clk ) begin
	if(in_valid) in_pic_no_reg <= in_pic_no;
end
// 0 == auto focus, 1 == auto exposure
always @(posedge clk ) begin
	if(in_valid) in_mode_reg <= in_mode;
end
//(0, 0.25),(1, 0.5),(2, 1),(3, 2)
always @(posedge clk ) begin
	if(in_valid) in_ratio_mode_reg <= in_mode ? in_ratio_mode : 2;
end

assign addr_bus = (in_pic_no_reg << 11) + (in_pic_no_reg << 10);

//===============================================//
//        Read DRAM with AXI4 protocol 	         //
//===============================================//
// 1-2. read address of picture
// In brust mode, only need to give an initial address
always @(*) begin
	// If read valid is high, give read address
	if(arvalid_s_inf) begin
		// read picture from DRAM to SRAM
		if(current_state == DRAM_READ) begin
			// 32-bit read address
			// 16-bit 1, 16-bit addr_bus
			araddr_s_inf = {16'd1, addr_bus};
        end
		else araddr_s_inf = 0;
	end
	// If read address is not valid, give idle address
	else begin
		araddr_s_inf = 0;
	end 
end
// 1-6. read valid
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		arvalid_s_inf <= 0;
	end
	// after sending the read address to the DRAM, it's ready to receive the read data from the DRAM
	else if(arvalid_s_inf && arready_s_inf) begin
		arvalid_s_inf <= 0;
	end
	// start reading picture from DRAM to SRAM
	else if(current_state == IDLE && next_state == DRAM_READ) begin
		arvalid_s_inf <= 1;
	end
end

// 2-6. read ready
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		rready_s_inf <= 0;
	end
	// after sending the read address to the DRAM, it's ready to receive the read data from the DRAM
	else if(arvalid_s_inf && arready_s_inf) begin
		rready_s_inf <= 1;
	end
	// complete reading all the data from the DRAM in burst mode
	else if(rlast_s_inf) begin
		rready_s_inf <= 0;
	end
end









//===============================================//
//         Write DRAM with AXI4 protocol         //
//===============================================//
// 3-2. write address of exposure picture
// In brust mode, only need to give an initial address
always @(*) begin
	// If write valid is high, give read address
	if(awvalid_s_inf) begin
		// write picture from SRAM to DRAM
		// 32-bit read address
		// 16-bit 1, 16-bit addr_bus
		awaddr_s_inf = {16'd1, addr_bus};
	
	// If read address is not valid, give idle address
	end else begin
		awaddr_s_inf = 0;
	end 
end

// 3-6. write valid
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		awvalid_s_inf <= 0;
	// after sending the write address to the DRAM, it's ready to give write data from the DRAM
	end else if(awvalid_s_inf && awready_s_inf) begin
		awvalid_s_inf <= 0;
	end
	else if(rvalid_s_inf && (!wvalid_s_inf)) begin
		if(in_mode_reg == 1) awvalid_s_inf <= 1;
	end
end

// 4-1. write data
// write exposure picture from SRAM to DRAM
assign wdata_s_inf = (current_state == IDLE) ? 0 : data_in_result_buff[10];

// 4-2. write last
// wlast_m_inf
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		wlast_s_inf <= 0;
	// wlast_m_inf is high in one cycle
	end else if(wlast_s_inf && wready_s_inf) begin
		wlast_s_inf <= 0;
	// last data of exposure picture to be written to DRAM
	end else if(wvalid_s_inf && addr_dram_reg == 190) begin
		wlast_s_inf <= 1;
	end
end

// 4-3. write valid
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		wvalid_s_inf <= 0;
	// last data of exposure picture to be written to DRAM
	end else if(wready_s_inf && wlast_s_inf) begin
		wvalid_s_inf <= 0;
	// after sending the write address to the DRAM, it's ready to write data to the DRAM
	end else if(awvalid_s_inf && awready_s_inf) begin
		wvalid_s_inf <= 1;
	end
end
// 5-4. response ready
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		bready_s_inf <= 0;
	// last data of exposure picture to be written to DRAM
	end else if(awvalid_s_inf && awready_s_inf) begin
		bready_s_inf <= 1;
	// complete writing all the data to the DRAM in burst mode
	end else if(bvalid_s_inf) begin
		bready_s_inf <= 0;
	end
end

//================================================//
//   SRAM for outputing result and updating DRAM  //
//================================================//
// for the purpose of outputing result
// 64 * 3 blocks * 128 bits single-port SRAM
//sram_192x128_inst OUT_TO_RESULT(.A(addr_result_wire), .DO(data_out_result), .DI(data_in_result), .CK(clk), .WEB(web_result), .OE(1'b1), .CS(1'b1));

// for the purpose of updating DRAM
// 64 * 3 blocks * 128 bits single-port SRAM
//sram_192x128_inst UPDATE_DRAM(.A(addr_dram_wire), .DO(data_out_dram), .DI(data_in_dram), .CK(clk), .WEB(web_dram), .OE(1'b1), .CS(1'b1));


wire [7:0] data_part[0:15];
assign data_part[0] = data_in_result_buff[15][127:120];
assign data_part[1] = data_in_result_buff[15][119:112];
assign data_part[2] = data_in_result_buff[15][111:104];
assign data_part[3] = data_in_result_buff[15][103:96];
assign data_part[4] = data_in_result_buff[15][95:88];
assign data_part[5] = data_in_result_buff[15][87:80];
assign data_part[6] = data_in_result_buff[15][79:72];
assign data_part[7] = data_in_result_buff[15][71:64];
assign data_part[8] = data_in_result_buff[15][63:56];
assign data_part[9] = data_in_result_buff[15][55:48];
assign data_part[10] = data_in_result_buff[15][47:40];
assign data_part[11] = data_in_result_buff[15][39:32];
assign data_part[12] = data_in_result_buff[15][31:24];
assign data_part[13] = data_in_result_buff[15][23:16];
assign data_part[14] = data_in_result_buff[15][15:8];
assign data_part[15] = data_in_result_buff[15][7:0];



always @(*) begin
	case(in_ratio_mode_reg)
		1: data_in_result_part[0] = rdata_s_inf[7:0] >> 1;
		2: data_in_result_part[0] = rdata_s_inf[7:0];
		3: data_in_result_part[0] = rdata_s_inf[7] ? 255 : (rdata_s_inf[7:0] << 1);
		default: data_in_result_part[0] = rdata_s_inf[7:0] >> 2; //ratio 0
	endcase
end
always @(*) begin
	case(in_ratio_mode_reg)
		1: data_in_result_part[1] = rdata_s_inf[15:8] >> 1;
		2: data_in_result_part[1] = rdata_s_inf[15:8];
		3: data_in_result_part[1] = rdata_s_inf[15] ? 255 : (rdata_s_inf[15:8] << 1);
		default: data_in_result_part[1] = rdata_s_inf[15:8] >> 2; //ratio 0
	endcase
end
always @(*) begin
	case(in_ratio_mode_reg)
		1: data_in_result_part[2] = rdata_s_inf[23:16] >> 1;
		2: data_in_result_part[2] = rdata_s_inf[23:16];
		3: data_in_result_part[2] = rdata_s_inf[23] ? 255 : (rdata_s_inf[23:16] << 1);
		default: data_in_result_part[2] = rdata_s_inf[23:16] >> 2; //ratio 0
	endcase
end
always @(*) begin
	case(in_ratio_mode_reg)
		1: data_in_result_part[3] = rdata_s_inf[31:24] >> 1;
		2: data_in_result_part[3] = rdata_s_inf[31:24];
		3: data_in_result_part[3] = rdata_s_inf[31] ? 255 : (rdata_s_inf[31:24] << 1);
		default: data_in_result_part[3] = rdata_s_inf[31:24] >> 2; //ratio 0
	endcase
end
always @(*) begin
	case(in_ratio_mode_reg)
		1: data_in_result_part[4] = rdata_s_inf[39:32] >> 1;
		2: data_in_result_part[4] = rdata_s_inf[39:32];
		3: data_in_result_part[4] = rdata_s_inf[39] ? 255 : (rdata_s_inf[39:32] << 1);
		default: data_in_result_part[4] = rdata_s_inf[39:32] >> 2; //ratio 0
	endcase
end
always @(*) begin
	case(in_ratio_mode_reg)
		1: data_in_result_part[5] = rdata_s_inf[47:40] >> 1;
		2: data_in_result_part[5] = rdata_s_inf[47:40];
		3: data_in_result_part[5] = rdata_s_inf[47] ? 255 : (rdata_s_inf[47:40] << 1);
		default: data_in_result_part[5] = rdata_s_inf[47:40] >> 2; //ratio 0
	endcase
end
always @(*) begin
	case(in_ratio_mode_reg)
		1: data_in_result_part[6] = rdata_s_inf[55:48] >> 1;
		2: data_in_result_part[6] = rdata_s_inf[55:48];
		3: data_in_result_part[6] = rdata_s_inf[55] ? 255 : (rdata_s_inf[55:48] << 1);
		default: data_in_result_part[6] = rdata_s_inf[55:48] >> 2; //ratio 0
	endcase
end
always @(*) begin
	case(in_ratio_mode_reg)
		1: data_in_result_part[7] = rdata_s_inf[63:56] >> 1;
		2: data_in_result_part[7] = rdata_s_inf[63:56];
		3: data_in_result_part[7] = rdata_s_inf[63] ? 255 : (rdata_s_inf[63:56] << 1);
		default: data_in_result_part[7] = rdata_s_inf[63:56] >> 2; //ratio 0
	endcase
end
always @(*) begin
	case(in_ratio_mode_reg)
		1: data_in_result_part[8] = rdata_s_inf[71:64] >> 1;
		2: data_in_result_part[8] = rdata_s_inf[71:64];
		3: data_in_result_part[8] = rdata_s_inf[71] ? 255 : (rdata_s_inf[71:64] << 1);
		default: data_in_result_part[8] = rdata_s_inf[71:64] >> 2; //ratio 0
	endcase
end
always @(*) begin
	case(in_ratio_mode_reg)
		1: data_in_result_part[9] = rdata_s_inf[79:72] >> 1;
		2: data_in_result_part[9] = rdata_s_inf[79:72];
		3: data_in_result_part[9] = rdata_s_inf[79] ? 255 : (rdata_s_inf[79:72] << 1);
		default: data_in_result_part[9] = rdata_s_inf[79:72] >> 2; //ratio 0
	endcase
end
always @(*) begin
	case(in_ratio_mode_reg)
		1: data_in_result_part[10] = rdata_s_inf[87:80] >> 1;
		2: data_in_result_part[10] = rdata_s_inf[87:80];
		3: data_in_result_part[10] = rdata_s_inf[87] ? 255 : (rdata_s_inf[87:80] << 1);
		default: data_in_result_part[10] = rdata_s_inf[87:80] >> 2; //ratio 0
	endcase
end
always @(*) begin
	case(in_ratio_mode_reg)
		1: data_in_result_part[11] = rdata_s_inf[95:88] >> 1;
		2: data_in_result_part[11] = rdata_s_inf[95:88];
		3: data_in_result_part[11] = rdata_s_inf[95] ? 255 : (rdata_s_inf[95:88] << 1);
		default: data_in_result_part[11] = rdata_s_inf[95:88] >> 2; //ratio 0
	endcase
end
always @(*) begin
	case(in_ratio_mode_reg)
		1: data_in_result_part[12] = rdata_s_inf[103:96] >> 1;
		2: data_in_result_part[12] = rdata_s_inf[103:96];
		3: data_in_result_part[12] = rdata_s_inf[103] ? 255 : (rdata_s_inf[103:96] << 1);
		default: data_in_result_part[12] = rdata_s_inf[103:96] >> 2; //ratio 0
	endcase
end
always @(*) begin
	case(in_ratio_mode_reg)
		1: data_in_result_part[13] = rdata_s_inf[111:104] >> 1;
		2: data_in_result_part[13] = rdata_s_inf[111:104];
		3: data_in_result_part[13] = rdata_s_inf[111] ? 255 : (rdata_s_inf[111:104] << 1);
		default: data_in_result_part[13] = rdata_s_inf[111:104] >> 2; //ratio 0
	endcase
end
always @(*) begin
	case(in_ratio_mode_reg)
		1: data_in_result_part[14] = rdata_s_inf[119:112] >> 1;
		2: data_in_result_part[14] = rdata_s_inf[119:112];
		3: data_in_result_part[14] = rdata_s_inf[119] ? 255 : (rdata_s_inf[119:112] << 1);
		default: data_in_result_part[14] = rdata_s_inf[119:112] >> 2; //ratio 0
	endcase
end
always @(*) begin
	case(in_ratio_mode_reg)
		1: data_in_result_part[15] = rdata_s_inf[127:120] >> 1;
		2: data_in_result_part[15] = rdata_s_inf[127:120];
		3: data_in_result_part[15] = rdata_s_inf[127] ? 255 : (rdata_s_inf[127:120] << 1);
		default: data_in_result_part[15] = rdata_s_inf[127:120] >> 2; //ratio 0
	endcase
end


//================================================//
//                   GRAY_SCALE                   //
//================================================//

always @(posedge clk ) begin
	rvalid_s_inf_reg <= rvalid_s_inf;
end

reg [4:0] gray_exposure_cnt;

always @(posedge clk ) begin
	if(current_state == IDLE) begin
		for(i = 0; i < 12; i = i + 1)
			gray_cell_[i] <= 0;
	end
	else if(current_state == EXPOSURE && gray_exposure_cnt == 25) begin
		for(i = 0; i < 12; i = i + 1)
			gray_cell_[i] <= 0;
	end
	else if(((|gray_cell_cnt_[7:4]) == 0) || (gray_cell_cnt_[7:4] == 4'b0100) || (gray_cell_cnt_[7:4] == 4'b1000)) begin
		gray_cell_[gray_cell_cnt_[3:0]][23:16] <= gray_cell_[gray_cell_cnt_[3:0]][23:16] + ((gray_cell_cnt_[0] ? data_in_result_buff[15][7:0] : data_in_result_buff[15][111:104]) >> gray_shift_);
		gray_cell_[gray_cell_cnt_[3:0]][15:8] <= gray_cell_[gray_cell_cnt_[3:0]][15:8] + ((gray_cell_cnt_[0] ? data_in_result_buff[15][15:8] : data_in_result_buff[15][119:112]) >> gray_shift_);
		gray_cell_[gray_cell_cnt_[3:0]][7:0] <= gray_cell_[gray_cell_cnt_[3:0]][7:0] + ((gray_cell_cnt_[0] ? data_in_result_buff[15][23:16] : data_in_result_buff[15][127:120]) >> gray_shift_);
	end
end




always @(posedge clk or negedge rst_n) begin
	if(!rst_n) gray_exposure_cnt <= 0;
	else if(current_state == IDLE) gray_exposure_cnt <= 0;
	else if(rvalid_s_inf_reg && gray_exposure_cnt < 26) gray_exposure_cnt <= gray_exposure_cnt + 1;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) gray_cell_cnt_ <= 0;
	else if(current_state == IDLE) gray_cell_cnt_ <= 0;
	else if(gray_exposure_cnt == 25) gray_cell_cnt_ <= 0;
	else if(rvalid_s_inf_reg) gray_cell_cnt_ <= gray_cell_cnt_ + 1;
end
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) gray_shift_ <= 0;
	else if(current_state == IDLE) gray_shift_ <= 2;
	else if((&gray_cell_cnt_[6:0]) == 1) gray_shift_ <= 2;
	else if((&gray_cell_cnt_[5:0]) == 1) gray_shift_ <= 1;
end
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		gray_cell_buff[0] <= 0;
		gray_cell_buff[1] <= 0;
	end
	else if(current_state == IDLE) begin
		gray_cell_buff[0] <= 0;
		gray_cell_buff[1] <= 1;
	end
	else if(gray_cell_cnt_[7] && (|gray_cell_cnt_[6:0])) begin
		gray_cell_buff[0] <= gray_cell_buff[1];
		gray_cell_buff[1] <= gray_cell_[diff_cell_cnt];
	end
end



//================================================//
//                   DIFFERENCE                   //
//================================================//

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) diff_cell_cnt <= 0;
	else if(current_state == IDLE) begin
		diff_cell_cnt <= 0;
	end
	else if(gray_cell_cnt_ == 128) begin
		diff_cell_cnt <= 0;
	end
	else begin
		diff_cell_cnt <= diff_cell_cnt + 1;
	end
end

always @(posedge clk ) begin
	for(i = 0; i < 3; i = i + 1) begin
		diff2_h_out_reg[i] <= diff2_h_out[i];
	end
end
always @(posedge clk ) begin
	for(i = 0; i < 3; i = i + 1) begin
		diff2_v_out_reg[i] <= diff2_v_out[i];
	end
end

always @(posedge clk ) begin
	sub1[0] <= (gray_cell_buff[1][23:16] > gray_cell_buff[1][15:8]) ? gray_cell_buff[1][23:16] : gray_cell_buff[1][15:8];
end
always @(posedge clk ) begin
	sub1[1] <= (gray_cell_buff[1][15:8] > gray_cell_buff[1][7:0]) ? gray_cell_buff[1][15:8] : gray_cell_buff[1][7:0];
end
always @(posedge clk ) begin
	sub1[2] <= (gray_cell_buff[1][23:16] > gray_cell_buff[0][7:0]) ? gray_cell_buff[1][23:16] : gray_cell_buff[0][7:0];
end
always @(posedge clk ) begin
	sub1[3] <= (gray_cell_[diff_cell_cnt][23:16] > gray_cell_buff[0][23:16]) ? gray_cell_[diff_cell_cnt][23:16] : gray_cell_buff[0][23:16];
end
always @(posedge clk ) begin
	sub1[4] <= (gray_cell_[diff_cell_cnt][15:8] > gray_cell_buff[0][15:8]) ? gray_cell_[diff_cell_cnt][15:8] : gray_cell_buff[0][15:8];
end
always @(posedge clk ) begin
	sub1[5] <= (gray_cell_[diff_cell_cnt][7:0] > gray_cell_buff[0][7:0]) ? gray_cell_[diff_cell_cnt][7:0] : gray_cell_buff[0][7:0];
end

always @(posedge clk ) begin
	sub2[0] <= (gray_cell_buff[1][23:16] < gray_cell_buff[1][15:8]) ? gray_cell_buff[1][23:16] : gray_cell_buff[1][15:8];
end
always @(posedge clk ) begin
	sub2[1] <= (gray_cell_buff[1][15:8] < gray_cell_buff[1][7:0]) ? gray_cell_buff[1][15:8] : gray_cell_buff[1][7:0];
end
always @(posedge clk ) begin
	sub2[2] <= (gray_cell_buff[1][23:16] < gray_cell_buff[0][7:0]) ? gray_cell_buff[1][23:16] : gray_cell_buff[0][7:0];
end
always @(posedge clk ) begin
	sub2[3] <= (gray_cell_[diff_cell_cnt][23:16] < gray_cell_buff[0][23:16]) ? gray_cell_[diff_cell_cnt][23:16] : gray_cell_buff[0][23:16];
end
always @(posedge clk ) begin
	sub2[4] <= (gray_cell_[diff_cell_cnt][15:8] < gray_cell_buff[0][15:8]) ? gray_cell_[diff_cell_cnt][15:8] : gray_cell_buff[0][15:8];
end
always @(posedge clk ) begin
	sub2[5] <= (gray_cell_[diff_cell_cnt][7:0] < gray_cell_buff[0][7:0]) ? gray_cell_[diff_cell_cnt][7:0] : gray_cell_buff[0][7:0];
end

assign diff2_h_out[0] = sub1[0] - sub2[0];
assign diff2_h_out[1] = sub1[1] - sub2[1];
assign diff2_h_out[2] = sub1[2] - sub2[2];

assign diff2_v_out[0] = sub1[3] - sub2[3];
assign diff2_v_out[1] = sub1[4] - sub2[4];
assign diff2_v_out[2] = sub1[5] - sub2[5];

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) diff2_h <= 0;
	else if(current_state == IDLE) begin
		diff2_h <= 0;
	end
	else begin
		diff2_h <= diff2_h_out_reg[0] + diff2_h_out_reg[1] + ((diff_cell_cnt[0]) ? 0 : diff2_h_out_reg[2]);
	end
end
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) diff2_v_tmp <= 0;
	else if(current_state == IDLE) begin
		diff2_v_tmp <= 0;
	end
	else begin
		diff2_v_tmp <= diff2_v_out_reg[0] + diff2_v_out_reg[1] + diff2_v_out_reg[2];
	end
end
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) diff2_v <= 0;
	else if(current_state == IDLE) begin
		diff2_v <= 0;
	end
	else if(diff_cell_cnt == 4) begin
		diff2_v <= 0;
	end
	else if((diff_cell_cnt > 4) && (diff_cell_cnt < 15)) begin
		diff2_v <= diff2_v + diff2_v_tmp;
	end
end
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) diff2 <= 0;
	else if(current_state == IDLE) begin
		diff2 <= 0;
	end
	else if(diff_cell_cnt == 3) diff2 <= 0;
	else if(diff_cell_cnt > 3) begin
		diff2 <= diff2 + diff2_h + ((diff_cell_cnt == 15) ? diff2_v : 0);
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) diff1_h <= 0;
	else if(current_state == IDLE) begin
		diff1_h <= 0;
	end
	else if(diff_cell_cnt == 4) diff1_h <= 0;
	else if((diff_cell_cnt > 4) && (diff_cell_cnt < 13)) begin
		diff1_h <= diff1_h + ((diff_cell_cnt[0]) ? diff2_h_out_reg[1] : diff2_h_out_reg[0]) + ((diff_cell_cnt[0]) ? 0 : diff2_h_out_reg[2]);
	end
end
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) diff1_v <= 0;
	else if(current_state == IDLE) begin
		diff1_v <= 0;
	end
	else if(diff_cell_cnt == 5) diff1_v <= 0;
	else if((diff_cell_cnt > 5) && (diff_cell_cnt < 12)) begin
		diff1_v <= diff1_v + diff2_v_out_reg[1] + ((diff_cell_cnt[0]) ? diff2_v_out_reg[0] : diff2_v_out_reg[2]);
	end
end
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) diff1 <= 0;
	else if(current_state == IDLE) begin
		diff1 <= 0;
	end
	else if(diff_cell_cnt == 13) begin
		diff1 <= diff1_h + diff1_v;
	end
end



always @(posedge clk or negedge rst_n) begin
	if(!rst_n) diff0 <= 0;
	else if(current_state == IDLE) begin
		diff0 <= 0;
	end
	else if(diff_cell_cnt == 8) begin
		diff0 <= diff2_h_out_reg[2] + diff2_v_out_reg[2];
	end
	else begin
		diff0 <= diff0 + ((diff_cell_cnt == 9) ? diff2_v_out_reg[0] : 0) + ((diff_cell_cnt == 10) ? diff2_h_out_reg[2] : 0);
	end
end





assign diff0_n = diff0 >> 2;
assign diff1_n = diff1 >> 4;

always @(posedge clk ) begin
	if(valid_out) diff0_n_reg <= diff0_n;
end
always @(posedge clk ) begin
	if(valid_out) diff1_n_reg <= diff1_n;
end



always @(posedge clk or negedge rst_n) begin
	if(!rst_n) valid_data <= 0;
	else if(gray_cell_cnt_ == 145 && diff_cell_cnt == 0) valid_data <= 1;
	else valid_data <= 0;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) valid_out_r <= 0;
	else valid_out_r <= valid_out;
end

Divider divider(.clk(clk), .rst_n(rst_n), .valid_data(valid_data), .data_in(diff2), .valid_out(valid_out), .data_out(diff2_n));

always @(posedge clk ) begin
	if(valid_out) diff2_n_reg <= diff2_n;
end



//================================================//
//                  MAX_CONTRAST                  //
//================================================//

always @(*) begin
	if((diff0_n_reg >= diff1_n_reg) && (diff0_n_reg >= diff2_n_reg)) idx_ = 0;
	else if((diff1_n_reg > diff0_n_reg) && (diff1_n_reg >= diff2_n_reg)) idx_ = 1;
	else idx_ = 2;
end

always @(posedge clk ) begin
	if(valid_out_r) idx <= idx_;
end

//================================================//
//                    EXPOSURE                    //
//================================================//
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		addr_dram_reg <= 0;
	end
	// initialize to 0
	else if(current_state == IDLE) begin
		addr_dram_reg <= 0;
	end
	else if(addr_dram_reg == 191 || ~wready_s_inf) addr_dram_reg <= 0;
	// increment address when wready_s_inf is high
	else if(wready_s_inf) begin
		addr_dram_reg <= addr_dram_reg + 1;
	end
end
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0; i < 16; i = i + 1) begin
			data_in_result_buff[i] <= 0;
		end
	end
	else begin
		data_in_result_buff[15] <= {data_in_result_part[15],data_in_result_part[14],data_in_result_part[13],data_in_result_part[12],data_in_result_part[11],data_in_result_part[10],data_in_result_part[9],data_in_result_part[8],data_in_result_part[7],data_in_result_part[6],data_in_result_part[5],data_in_result_part[4],data_in_result_part[3],data_in_result_part[2],data_in_result_part[1],data_in_result_part[0]};
		for(i = 0; i < 15; i = i + 1) begin
			data_in_result_buff[i] <= data_in_result_buff[i + 1];
		end
	end
end
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0; i < 16; i = i + 1) begin
			average_shift[i] <= 0;
		end
	end
	else begin
	average_shift[15] <= ((average_cnt > 63) && (average_cnt < 128)) ? 1 : 2;
		for(i = 0; i < 15; i = i + 1) begin
			average_shift[i] <= average_shift[i + 1];
		end
	end
end

//================================================//
//                     AVERAGE                    //
//================================================//

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0; i < 16; i = i + 1) begin
			average_cell[i] <= 0;
		end
	end
	else if(current_state == IDLE) begin
		for(i = 0; i < 16; i = i + 1) begin
			average_cell[i] <= 0;
		end
	end
	else if(current_state == EXPOSURE) begin
		average_cell[15] <= average_cell[15] + (data_in_result_buff[0][127:120] >> average_shift[0]);
		average_cell[14] <= average_cell[14] + (data_in_result_buff[1][119:112] >> average_shift[1]);
		average_cell[13] <= average_cell[13] + (data_in_result_buff[2][111:104] >> average_shift[2]);
		average_cell[12] <= average_cell[12] + (data_in_result_buff[3][103:96] >> average_shift[3]);
		average_cell[11] <= average_cell[11] + (data_in_result_buff[4][95:88] >> average_shift[4]);
		average_cell[10] <= average_cell[10] + (data_in_result_buff[5][87:80] >> average_shift[5]);
		average_cell[9] <= average_cell[9] + (data_in_result_buff[6][79:72] >> average_shift[6]);
		average_cell[8] <= average_cell[8] + (data_in_result_buff[7][71:64] >> average_shift[7]);
		average_cell[7] <= average_cell[7] + (data_in_result_buff[8][63:56] >> average_shift[8]);
		average_cell[6] <= average_cell[6] + (data_in_result_buff[9][55:48] >> average_shift[9]);
		average_cell[5] <= average_cell[5] + (data_in_result_buff[10][47:40] >> average_shift[10]);
		average_cell[4] <= average_cell[4] + (data_in_result_buff[11][39:32] >> average_shift[11]);
		average_cell[3] <= average_cell[3] + (data_in_result_buff[12][31:24] >> average_shift[12]);
		average_cell[2] <= average_cell[2] + (data_in_result_buff[13][23:16] >> average_shift[13]);
		average_cell[1] <= average_cell[1] + (data_in_result_buff[14][15:8] >> average_shift[14]);
		average_cell[0] <= average_cell[0] + (data_in_result_buff[15][7:0] >> average_shift[15]);
	end
end


always @(posedge clk or negedge rst_n) begin
	if(!rst_n) average_cnt <= 0;
	else if(current_state == IDLE) begin
		average_cnt <= 0;
	end
	else if(next_state == EXPOSURE) begin
		average_cnt <= average_cnt + 1;
	end
end


always @(posedge clk or negedge rst_n) begin
	if(!rst_n) average_cell_cnt <= 0;
	else if(average_cnt == 192) average_cell_cnt <= 0;
	else average_cell_cnt <= average_cell_cnt + 1;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) flag_average_output <= 0;
	else if(current_state == IDLE) flag_average_output <= 0;
	else if(average_cnt == 192) flag_average_output <= 1;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) flag_average_output_r <= 0;
	else if(current_state == IDLE) flag_average_output_r <= 0;
	else flag_average_output_r <= flag_average_output;
end

always @(posedge clk ) begin
	if(flag_average_output) average_cell_shift <= average_cell[average_cell_cnt[3:0]];
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) average_cell_tot <= 0;
	else if(current_state == IDLE) average_cell_tot <= 0;
	else if(flag_average_output_r) average_cell_tot <= average_cell_tot + average_cell_shift;
end


//================================================//
//                     OUTPUT                     //
//================================================//



always @(posedge clk or negedge rst_n) begin
	if(!rst_n) out_valid <= 0;
	else if(current_state == ZERO_OUTPUT || (average_cnt == 210)) out_valid <= 1;
	else out_valid <= 0;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) out_data <= 0;
	else if(average_cnt == 210) out_data <= in_mode_reg == 0 ? idx : average_cell_tot[17:10];
	else if(current_state == ZERO_OUTPUT) out_data <= (in_mode_reg) ? auto_auto_exposure_idx[in_pic_no_reg] : auto_auto_focus_idx[in_pic_no_reg];
	else out_data <= 0;
end


//================================================//
//                  ZERO   OUTPUT                 //
//================================================//

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) zero_check <= 0;
	else if(current_state == IDLE) zero_check <= 0;
	else if(wready_s_inf) zero_check <= zero_check | data_in_result_buff[10];
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) flag <= 0;
	else if(current_state == IDLE) flag <= 1;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) in_pic_no_zero <= 0;
	else if(current_state == IDLE && ~flag) begin
		in_pic_no_zero <= 0;
	end
	else if(average_cnt == 198 && in_mode_reg == 1 && ((|zero_check) == 0)) begin
		in_pic_no_zero[in_pic_no_reg] <= 1;
	end
end




//================================================//
//                   AUTO ACTION                  //
//================================================//

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) auto_flag <= 0;
	else if(current_state == IDLE && ~flag) begin
		auto_flag <= 0;
	end
	else if(in_valid) auto_flag[in_pic_no] <= 1;
end


//================================================//
//                AUTO AUTO FOCUS                 //
//================================================//


always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0; i < 16; i = i + 1) begin
			auto_auto_focus_idx[i] <= 0;
		end
	end
	else if(current_state == IDLE && ~flag) begin
		for(i = 0; i < 16; i = i + 1) begin
			auto_auto_focus_idx[i] <= 0;
		end
	end
	else if(valid_out_r) auto_auto_focus_idx[in_pic_no_reg] <= idx_;
end

//================================================//
//                AUTO AUTO EXPOSURE              //
//================================================//


always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0; i < 16; i = i + 1) begin
			auto_auto_exposure_idx[i] <= 0;
		end
	end
	else if(current_state == IDLE && ~flag) begin
		for(i = 0; i < 16; i = i + 1) begin
			auto_auto_exposure_idx[i] <= 0;
		end
	end
	else if(average_cnt == 210) auto_auto_exposure_idx[in_pic_no_reg] <= average_cell_tot[17:10];
end

endmodule

//==========================================//
//                  Divider                 //
//==========================================//

 module Divider(clk, rst_n, valid_data, data_in, valid_out, data_out);
	input clk, rst_n, valid_data;
	input [14:0] data_in;
	output reg valid_out;
	output reg [9:0] data_out;

	reg [29:0] temp_a, temp_b;
	reg start_div;
	reg [4:0] cnt_div;
	wire [14:0] temp_a_;

	assign temp_a_ = temp_a[29:15];

	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) start_div <= 0;
		else if(valid_data && start_div == 0) start_div <= 1;
		else if(cnt_div == 30) start_div <= 0;
	end
	
	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) cnt_div <= 0;
		else if(start_div) cnt_div <= cnt_div + 1;
		else cnt_div <= 0;
	end

	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			temp_a <= 0;
			temp_b <= 0;
		end
		else if(start_div) begin
			if(cnt_div == 0) begin
				temp_a <= {15'b0,data_in};
				temp_b <= {15'd36,15'b0};
			end
			else if(cnt_div[0]) begin
				temp_a <= {temp_a[28:0],1'b0};
			end
			else begin
				temp_a <= (temp_a[29:15] >= 36) ? (temp_a - 1179647) : temp_a;
			end
		end
		else begin
			temp_a <= 0;
			temp_b <= 0;
		end
	end

	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) valid_out <= 0;
		else if (cnt_div == 31) valid_out <= 1;
		else valid_out <= 0;
	end

	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) data_out <= 0;
		else data_out <= temp_a[9:0];
	end

endmodule



