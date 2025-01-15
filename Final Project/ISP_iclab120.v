module ISP(
    // Input Signals
    input clk,
    input rst_n,
    input in_valid,
    input [3:0] in_pic_no,
    input [1:0] in_mode,
    input [1:0] in_ratio_mode,

    // Output Signals
    output reg out_valid,
    output reg [7:0] out_data,
    
    // DRAM Signals
    // axi write address channel
    // src master
    output [3:0]  awid_s_inf,
    output reg [31:0] awaddr_s_inf,
    output [2:0]  awsize_s_inf,
    output [1:0]  awburst_s_inf,
    output [7:0]  awlen_s_inf,
    output reg    awvalid_s_inf,
    // src slave
    input         awready_s_inf,
    // -----------------------------
  
    // axi write data channel 
    // src master
    output [127:0] wdata_s_inf,
    output reg    wlast_s_inf,
    output reg    wvalid_s_inf,
    // src slave
    input          wready_s_inf,
  
    // axi write response channel 
    // src slave
    input [3:0]    bid_s_inf,
    input [1:0]    bresp_s_inf,
    input          bvalid_s_inf,
    // src master 
    output reg     bready_s_inf,
    // -----------------------------
  
    // axi read address channel 
    // src master
    output [3:0]   arid_s_inf,
    output reg [31:0] araddr_s_inf,
    output [7:0]   arlen_s_inf,
    output [2:0]   arsize_s_inf,
    output [1:0]   arburst_s_inf,
    output reg     arvalid_s_inf,
    // src slave
    input          arready_s_inf,
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
reg [1:0] in_mode_reg; // 0 == auto focus, 1 == auto exposure
reg [1:0] in_ratio_mode_reg; //(0, 0.25),(1, 0.5),(2, 1),(3, 2)

reg valid_data, valid_out, valid_out_r, valid_out_rr;
reg valid_data_a, valid_out_a, valid_out_a2, valid_out_a_r, valid_out_a_rr;

reg axi_flag;

reg [7:0] gray_cell[0:11][0:2];
reg [7:0] gray_cell_add_a[0:2];
reg [6:0] gray_cell_add_b[0:2];
reg gray_cell_flag[0:11];
reg [3:0] gray_cell_cnt;
reg [4:0] diff_cell_cnt, diff_cell_cnt2;

reg [14:0] diff2;
reg [13:0] diff2_h;
reg [13:0] diff2_v;
reg diff2_flag, diff2_flag2;
reg [12:0] diff1_h;
reg [12:0] diff1_v;
reg [13:0] diff1;
reg diff1_flag, diff1_flag2;
reg [11:0] diff0;
reg [10:0] diff0_h;
reg [10:0] diff0_v;
reg diff0_flag, diff0_flag2;
reg [1:0] idx, idx_r;


reg [7:0] data_in_result_part[0:15];
reg [5:0] diff_cnt;
reg [7:0] diff2_h_out_reg[0:2];
reg [7:0] diff2_v_out_reg[0:2];
reg [9:0] diff0_n_reg;
reg [9:0] diff1_n_reg;
reg [7:0] sub[0:1], sub2[0:1];
reg [7:0] sub_1, sub_2, sub_21, sub_22;
reg [7:0] sub_result, sub_result2;
reg sub_flag, sub_flag2;
reg sub_sel_flag;
reg diff01_flag_0, diff01_flag_1;


reg [8:0] average_cnt;
reg average_shift;



reg [7:0] cell_max[0:15], cell_min[0:15];
reg [9:0] cell_max_tot, cell_min_tot;
reg [7:0] cell_max_div_reg, cell_min_div_reg;
reg [8:0] cell_tot;
reg cell_max_min_flag;


reg [7:0] addr_dram_reg;
reg rvalid_s_inf_r, rvalid_s_inf_rr;
reg [127:0] data_in_result_buff;
reg [7:0] average_tmp8[0:7];
reg [8:0] average_tmp4[0:3];
reg [9:0] average_tmp2[0:1];
reg [10:0] average_tmp1;
reg [17:0] average_cell_tot;
reg average_flag, average_reset_flag;


reg [127:0] zero_check;


reg [15:0] auto_flag;
reg [1:0] auto_auto_focus_idx[0:15];

reg [7:0] auto_auto_exposure_idx[0:15];

reg [7:0] auto_average_idx[0:15];

reg in_valid_r;
reg msb_left_reg;
reg [1:0] msb_right_reg;
reg [2:0] msb[15:0], msb_r;
reg in_pic_no_zero; //check whether the pic is whole zero pic


//==============================================//
//                 wire declaration             //
//==============================================//

wire zero_flag;
wire [7:0] msb_temp;

wire [15:0] addr_bus;



wire [127:0] data_in_result; //data in of SRAM
wire [127:0] data_out_result;

wire [1:0] gray_shift;
wire [7:0] diff2_h_out[0:2];
wire [7:0] diff2_v_out[0:2];


wire [9:0] diff0_n;
wire [9:0] diff1_n;
wire [9:0] diff2_n;

wire [7:0] cell_max_div, cell_min_div;

wire [9:0] cell_max_min;

wire mode0_zero, mode1_zero;

//==============================================//
//           AXI4 parameter declaration         //
//==============================================//
// 1. read address channel
// 1-1. one master and one slave, so read address ID = 0
assign arid_s_inf    = 0;
// 1-2. read address of picture
// 1-3. burst length = 140/focus/0, 192/exposure/1
assign arlen_s_inf   = 191;
// 1-4. burst size = Only support 3’b100 in this exercise
assign arsize_s_inf  = 3'b100;
// 1-5. brust type = 1 (incrementing burst)
assign arburst_s_inf = 1;
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
assign awlen_s_inf   = 191;
// 3-4. burst size = Only support 3’b100 in this exercise
assign awsize_s_inf  = 3'b100;
// 3-5. brust type = 1 (incrementing burst)
assign awburst_s_inf = 1;
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

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) in_valid_r <= 0;
	else in_valid_r <= in_valid;
end

always @(*) begin
	case(current_state)
		IDLE: begin
			// when input is valid
			if(in_valid_r) next_state = (zero_flag || (((in_mode_reg == 0) || (in_mode_reg == 1 && in_ratio_mode_reg == 2) || (in_mode_reg == 2)) && auto_flag[in_pic_no_reg])) ? ZERO_OUTPUT : DRAM_READ;
			else next_state = current_state;
		end

		// read picture from DRAM to SRAM with AXI4 protocol
		DRAM_READ: begin
			// when last data of picture is read, start gray scale
			next_state = rready_s_inf ? EXPOSURE : current_state;
		end

		//do exposure
		EXPOSURE: begin
			if(out_valid) next_state = IDLE;
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
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) in_pic_no_reg <= 0;
	else if(in_valid) in_pic_no_reg <= in_pic_no;
end
// 0 == auto focus, 1 == auto exposure
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) in_mode_reg <= 0;
	else if(in_valid) in_mode_reg <= in_mode;
end
//(0, 0.25),(1, 0.5),(2, 1),(3, 2)
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) in_ratio_mode_reg <= 0;
	else if(in_valid) in_ratio_mode_reg <= (in_mode == 1) ? in_ratio_mode : 2;
end


assign addr_bus = (in_pic_no_reg << 11) + (in_pic_no_reg << 10);


//===============================================//
//        Read DRAM with AXI4 protocol 	         //
//===============================================//
// 1-2. read address of picture
// In brust mode, only need to give an initial address





always @(posedge clk or negedge rst_n) begin
	if(!rst_n) axi_flag <= 0;
	else if(current_state == IDLE && next_state == DRAM_READ) begin
		axi_flag <= 1;
	end
	else begin
		axi_flag <= 0;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		araddr_s_inf <= 0;
	end
	else if(axi_flag) begin
		araddr_s_inf <= {16'd1, addr_bus};
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
	else if(axi_flag) begin
		arvalid_s_inf <= 1;
	end
end

// 2-6. read ready
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		rvalid_s_inf_r <= 0;
	end
	// complete reading all the data from the DRAM in burst mode
	else begin
		rvalid_s_inf_r <= rvalid_s_inf;
	end
end
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		rvalid_s_inf_rr <= 0;
	end
	// complete reading all the data from the DRAM in burst mode
	else begin
		rvalid_s_inf_rr <= rvalid_s_inf_r;
	end
end
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		rready_s_inf <= 0;
	end
	// complete reading all the data from the DRAM in burst mode
	else begin
		rready_s_inf <= rvalid_s_inf_rr;
	end
end









//===============================================//
//         Write DRAM with AXI4 protocol         //
//===============================================//
// 3-2. write address of exposure picture
// In brust mode, only need to give an initial address

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		awaddr_s_inf <= 0;
	end
	else if(axi_flag) begin
		awaddr_s_inf <= {16'd1, addr_bus};
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
	else if(axi_flag && (in_mode_reg == 1)) begin
		awvalid_s_inf <= 1;
	end
end

// 4-1. write data
// write exposure picture from SRAM to DRAM
assign wdata_s_inf = data_in_result_buff;

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
	end 
	else begin
		wvalid_s_inf <= rvalid_s_inf && (in_mode_reg == 1);
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


wire [7:0] data_part[0:15];
assign data_part[0] = data_in_result_buff[127:120];
assign data_part[1] = data_in_result_buff[119:112];
assign data_part[2] = data_in_result_buff[111:104];
assign data_part[3] = data_in_result_buff[103:96];
assign data_part[4] = data_in_result_buff[95:88];
assign data_part[5] = data_in_result_buff[87:80];
assign data_part[6] = data_in_result_buff[79:72];
assign data_part[7] = data_in_result_buff[71:64];
assign data_part[8] = data_in_result_buff[63:56];
assign data_part[9] = data_in_result_buff[55:48];
assign data_part[10] = data_in_result_buff[47:40];
assign data_part[11] = data_in_result_buff[39:32];
assign data_part[12] = data_in_result_buff[31:24];
assign data_part[13] = data_in_result_buff[23:16];
assign data_part[14] = data_in_result_buff[15:8];
assign data_part[15] = data_in_result_buff[7:0];



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



always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0; i < 12; i = i + 1) begin
			gray_cell[i][0] <= 0;
			gray_cell[i][1] <= 0;
			gray_cell[i][2] <= 0;
		end
	end
	else if(current_state == IDLE) begin
		for(i = 0; i < 12; i = i + 1) begin
			gray_cell[i][0] <= 0;
			gray_cell[i][1] <= 0;
			gray_cell[i][2] <= 0;
		end
	end
	else begin
		for(i = 0; i < 12; i = i + 1) begin
			gray_cell[i][0] <= gray_cell_flag[i] ? (gray_cell_add_a[0] + gray_cell_add_b[0]) : gray_cell[i][0];
			gray_cell[i][1] <= gray_cell_flag[i] ? (gray_cell_add_a[1] + gray_cell_add_b[1]) : gray_cell[i][1];
			gray_cell[i][2] <= gray_cell_flag[i] ? (gray_cell_add_a[2] + gray_cell_add_b[2]) : gray_cell[i][2];
		end
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		gray_cell_cnt <= 0;
	end
	else if(current_state == IDLE) begin
		gray_cell_cnt <= 0;
	end
	else if(average_cnt[5:0] == 26) begin
		gray_cell_cnt <= 0;
	end
	else if(gray_cell_cnt != 15) begin
		gray_cell_cnt <= gray_cell_cnt + 1;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0; i < 12; i = i + 1) begin
			gray_cell_flag[i] <= 0;
		end
	end
	else if(current_state == IDLE) begin
		for(i = 0; i < 12; i = i + 1) begin
			gray_cell_flag[i] <= 0;
		end
	end
	else begin
		gray_cell_flag[0] <= gray_cell_cnt == 0;
		for(i = 1; i < 12; i = i + 1) begin
			gray_cell_flag[i] <= gray_cell_flag[i-1];
		end
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0; i < 3; i = i + 1) begin
			gray_cell_add_a[i] <= 0;
		end
	end
	else if(current_state == IDLE) begin
		for(i = 0; i < 3; i = i + 1) begin
			gray_cell_add_a[i] <= 0;
		end
	end
	else begin
		case(gray_cell_cnt)
			0: begin
				gray_cell_add_a[0] <= gray_cell[0][0];
				gray_cell_add_a[1] <= gray_cell[0][1];
				gray_cell_add_a[2] <= gray_cell[0][2];
			end
			1: begin
				gray_cell_add_a[0] <= gray_cell[1][0];
				gray_cell_add_a[1] <= gray_cell[1][1];
				gray_cell_add_a[2] <= gray_cell[1][2];
			end
			2: begin
				gray_cell_add_a[0] <= gray_cell[2][0];
				gray_cell_add_a[1] <= gray_cell[2][1];
				gray_cell_add_a[2] <= gray_cell[2][2];
			end
			3: begin
				gray_cell_add_a[0] <= gray_cell[3][0];
				gray_cell_add_a[1] <= gray_cell[3][1];
				gray_cell_add_a[2] <= gray_cell[3][2];
			end
			4: begin
				gray_cell_add_a[0] <= gray_cell[4][0];
				gray_cell_add_a[1] <= gray_cell[4][1];
				gray_cell_add_a[2] <= gray_cell[4][2];
			end
			5: begin
				gray_cell_add_a[0] <= gray_cell[5][0];
				gray_cell_add_a[1] <= gray_cell[5][1];
				gray_cell_add_a[2] <= gray_cell[5][2];
			end
			6: begin
				gray_cell_add_a[0] <= gray_cell[6][0];
				gray_cell_add_a[1] <= gray_cell[6][1];
				gray_cell_add_a[2] <= gray_cell[6][2];
			end
			7: begin
				gray_cell_add_a[0] <= gray_cell[7][0];
				gray_cell_add_a[1] <= gray_cell[7][1];
				gray_cell_add_a[2] <= gray_cell[7][2];
			end
			8: begin
				gray_cell_add_a[0] <= gray_cell[8][0];
				gray_cell_add_a[1] <= gray_cell[8][1];
				gray_cell_add_a[2] <= gray_cell[8][2];
			end
			9: begin
				gray_cell_add_a[0] <= gray_cell[9][0];
				gray_cell_add_a[1] <= gray_cell[9][1];
				gray_cell_add_a[2] <= gray_cell[9][2];
			end
			10: begin
				gray_cell_add_a[0] <= gray_cell[10][0];
				gray_cell_add_a[1] <= gray_cell[10][1];
				gray_cell_add_a[2] <= gray_cell[10][2];
			end
			11: begin
				gray_cell_add_a[0] <= gray_cell[11][0];
				gray_cell_add_a[1] <= gray_cell[11][1];
				gray_cell_add_a[2] <= gray_cell[11][2];
			end
		endcase
	end
end


always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0; i < 3; i = i + 1) begin
			gray_cell_add_b[i] <= 0;
		end
	end
	else if(current_state == IDLE) begin
		for(i = 0; i < 3; i = i + 1) begin
			gray_cell_add_b[i] <= 0;
		end
	end
	else begin
		gray_cell_add_b[0] <= (average_cnt[0] ? (average_shift ? data_in_result_buff[111:105] : data_in_result_buff[111:106]) : (average_shift ? data_in_result_buff[7:1] : data_in_result_buff[7:2]));
		gray_cell_add_b[1] <= (average_cnt[0] ? (average_shift ? data_in_result_buff[119:113] : data_in_result_buff[119:114]) : (average_shift ? data_in_result_buff[15:9] : data_in_result_buff[15:10]));
		gray_cell_add_b[2] <= (average_cnt[0] ? (average_shift ? data_in_result_buff[127:121] : data_in_result_buff[127:122]) : (average_shift ? data_in_result_buff[23:17] : data_in_result_buff[23:18]));
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
	else if(average_cnt == 156) begin
		diff_cell_cnt <= 0;
	end
	else begin
		diff_cell_cnt <= diff_cell_cnt + 1;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) diff_cell_cnt2 <= 0;
	else if(current_state == IDLE) begin
		diff_cell_cnt2 <= 0;
	end
	else if(average_cnt == 158) begin
		diff_cell_cnt2 <= 0;
	end
	else begin
		diff_cell_cnt2 <= diff_cell_cnt2 + 1;
	end
end


always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0; i < 2; i = i + 1) begin
			sub[i] <= 0;
		end
	end
	else begin
		case(diff_cell_cnt)
			0: begin
				sub[0] <= gray_cell[0][0];
				sub[1] <= gray_cell[0][1];
			end
			1: begin
				sub[0] <= gray_cell[0][1];
				sub[1] <= gray_cell[0][2];
			end
			2: begin
				sub[0] <= gray_cell[0][2];
				sub[1] <= gray_cell[1][0];
			end
			3: begin
				sub[0] <= gray_cell[1][0];
				sub[1] <= gray_cell[1][1];
			end
			4: begin
				sub[0] <= gray_cell[1][1];
				sub[1] <= gray_cell[1][2];
			end
			5: begin
				sub[0] <= gray_cell[2][0];
				sub[1] <= gray_cell[2][1];
			end
			6: begin
				sub[0] <= gray_cell[2][1];
				sub[1] <= gray_cell[2][2];
			end
			7: begin
				sub[0] <= gray_cell[2][2];
				sub[1] <= gray_cell[3][0];
			end
			8: begin
				sub[0] <= gray_cell[3][0];
				sub[1] <= gray_cell[3][1];
			end
			9: begin
				sub[0] <= gray_cell[3][1];
				sub[1] <= gray_cell[3][2];
			end
			10: begin
				sub[0] <= gray_cell[4][0];
				sub[1] <= gray_cell[4][1];
			end
			11: begin
				sub[0] <= gray_cell[4][1];
				sub[1] <= gray_cell[4][2];
			end
			12: begin
				sub[0] <= gray_cell[4][2];
				sub[1] <= gray_cell[5][0];
			end
			13: begin
				sub[0] <= gray_cell[5][0];
				sub[1] <= gray_cell[5][1];
			end
			14: begin
				sub[0] <= gray_cell[5][1];
				sub[1] <= gray_cell[5][2];
			end
			15: begin
				sub[0] <= gray_cell[6][0];
				sub[1] <= gray_cell[6][1];
			end
			16: begin
				sub[0] <= gray_cell[6][1];
				sub[1] <= gray_cell[6][2];
			end
			17: begin
				sub[0] <= gray_cell[6][2];
				sub[1] <= gray_cell[7][0];
			end
			18: begin
				sub[0] <= gray_cell[7][0];
				sub[1] <= gray_cell[7][1];
			end
			19: begin
				sub[0] <= gray_cell[7][1];
				sub[1] <= gray_cell[7][2];
			end
			20: begin
				sub[0] <= gray_cell[8][0];
				sub[1] <= gray_cell[8][1];
			end
			21: begin
				sub[0] <= gray_cell[8][1];
				sub[1] <= gray_cell[8][2];
			end
			22: begin
				sub[0] <= gray_cell[8][2];
				sub[1] <= gray_cell[9][0];
			end
			23: begin
				sub[0] <= gray_cell[9][0];
				sub[1] <= gray_cell[9][1];
			end
			24: begin
				sub[0] <= gray_cell[9][1];
				sub[1] <= gray_cell[9][2];
			end
			25: begin
				sub[0] <= gray_cell[10][0];
				sub[1] <= gray_cell[10][1];
			end
			26: begin
				sub[0] <= gray_cell[10][1];
				sub[1] <= gray_cell[10][2];
			end
			27: begin
				sub[0] <= gray_cell[10][2];
				sub[1] <= gray_cell[11][0];
			end
			28: begin
				sub[0] <= gray_cell[11][0];
				sub[1] <= gray_cell[11][1];
			end
			29: begin
				sub[0] <= gray_cell[11][1];
				sub[1] <= gray_cell[11][2];
			end
		endcase
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0; i < 2; i = i + 1) begin
			sub2[i] <= 0;
		end
	end
	else begin
		case(diff_cell_cnt2)
			0: begin
				sub2[0] <= gray_cell[0][0];
				sub2[1] <= gray_cell[2][0];
			end
			1: begin
				sub2[0] <= gray_cell[0][1];
				sub2[1] <= gray_cell[2][1];
			end
			2: begin
				sub2[0] <= gray_cell[0][2];
				sub2[1] <= gray_cell[2][2];
			end
			3: begin
				sub2[0] <= gray_cell[1][0];
				sub2[1] <= gray_cell[3][0];
			end
			4: begin
				sub2[0] <= gray_cell[1][1];
				sub2[1] <= gray_cell[3][1];
			end
			5: begin
				sub2[0] <= gray_cell[1][2];
				sub2[1] <= gray_cell[3][2];
			end
			6: begin
				sub2[0] <= gray_cell[2][0];
				sub2[1] <= gray_cell[4][0];
			end
			7: begin
				sub2[0] <= gray_cell[2][1];
				sub2[1] <= gray_cell[4][1];
			end
			8: begin
				sub2[0] <= gray_cell[2][2];
				sub2[1] <= gray_cell[4][2];
			end
			9: begin
				sub2[0] <= gray_cell[3][0];
				sub2[1] <= gray_cell[5][0];
			end
			10: begin
				sub2[0] <= gray_cell[3][1];
				sub2[1] <= gray_cell[5][1];
			end
			11: begin
				sub2[0] <= gray_cell[3][2];
				sub2[1] <= gray_cell[5][2];
			end
			12: begin
				sub2[0] <= gray_cell[4][0];
				sub2[1] <= gray_cell[6][0];
			end
			13: begin
				sub2[0] <= gray_cell[4][1];
				sub2[1] <= gray_cell[6][1];
			end
			14: begin
				sub2[0] <= gray_cell[4][2];
				sub2[1] <= gray_cell[6][2];
			end
			15: begin
				sub2[0] <= gray_cell[5][0];
				sub2[1] <= gray_cell[7][0];
			end
			16: begin
				sub2[0] <= gray_cell[5][1];
				sub2[1] <= gray_cell[7][1];
			end
			17: begin
				sub2[0] <= gray_cell[5][2];
				sub2[1] <= gray_cell[7][2];
			end
			18: begin
				sub2[0] <= gray_cell[6][0];
				sub2[1] <= gray_cell[8][0];
			end
			19: begin
				sub2[0] <= gray_cell[6][1];
				sub2[1] <= gray_cell[8][1];
			end
			20: begin
				sub2[0] <= gray_cell[6][2];
				sub2[1] <= gray_cell[8][2];
			end
			21: begin
				sub2[0] <= gray_cell[7][0];
				sub2[1] <= gray_cell[9][0];
			end
			22: begin
				sub2[0] <= gray_cell[7][1];
				sub2[1] <= gray_cell[9][1];
			end
			23: begin
				sub2[0] <= gray_cell[7][2];
				sub2[1] <= gray_cell[9][2];
			end
			24: begin
				sub2[0] <= gray_cell[8][0];
				sub2[1] <= gray_cell[10][0];
			end
			25: begin
				sub2[0] <= gray_cell[8][1];
				sub2[1] <= gray_cell[10][1];
			end
			26: begin
				sub2[0] <= gray_cell[8][2];
				sub2[1] <= gray_cell[10][2];
			end
			27: begin
				sub2[0] <= gray_cell[9][0];
				sub2[1] <= gray_cell[11][0];
			end
			28: begin
				sub2[0] <= gray_cell[9][1];
				sub2[1] <= gray_cell[11][1];
			end
			29: begin
				sub2[0] <= gray_cell[9][2];
				sub2[1] <= gray_cell[11][2];
			end
		endcase
	end
end



always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		sub_flag <= 0;
	end
	else if(average_cnt > 156) begin
		sub_flag <= 1;
	end
	else begin
		sub_flag <= 0;
	end
end


always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		sub_1 <= 0;
	end
	else if(sub_flag) begin
		sub_1 <= (sub[0] > sub[1]) ? sub[0] : sub[1];
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		sub_2 <= 0;
	end
	else if(sub_flag) begin
		sub_2 <= (sub[0] < sub[1]) ? sub[0] : sub[1];
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		sub_result <= 0;
	end
	else if(current_state == IDLE) begin
		sub_result <= 0;
	end
	else begin
		sub_result <= sub_1 - sub_2;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		sub_flag2 <= 0;
	end
	else if(average_cnt > 158) begin
		sub_flag2 <= 1;
	end
	else begin
		sub_flag2 <= 0;
	end
end


always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		sub_21 <= 0;
	end
	else if(sub_flag2) begin
		sub_21 <= (sub2[0] > sub2[1]) ? sub2[0] : sub2[1];
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		sub_22 <= 0;
	end
	else if(sub_flag2) begin
		sub_22 <= (sub2[0] < sub2[1]) ? sub2[0] : sub2[1];
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		sub_result2 <= 0;
	end
	else if(current_state == IDLE) begin
		sub_result2 <= 0;
	end
	else begin
		sub_result2 <= sub_21 - sub_22;
	end
end



always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		diff2 <= 0;
	end
	else if(current_state == IDLE) begin
		diff2 <= 0;
	end
	else if(diff2_flag && ~diff2_flag2) begin
		diff2 <= diff2_h + diff2_v;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		diff2_flag <= 0;
	end
	else if(current_state == IDLE) begin
		diff2_flag <= 0;
	end
	else if(average_cnt > 157 && diff_cell_cnt > 1) begin
		diff2_flag <= 1;
	end
	else begin
		diff2_flag <= 0;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		diff2_h <= 0;
	end
	else if(current_state == IDLE) begin
		diff2_h <= 0;
	end
	else if(diff2_flag) begin
		diff2_h <= diff2_h + sub_result;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		diff2_flag2 <= 0;
	end
	else if(current_state == IDLE) begin
		diff2_flag2 <= 0;
	end
	else if(average_cnt > 160 && diff_cell_cnt2 > 1) begin
		diff2_flag2 <= 1;
	end
	else begin
		diff2_flag2 <= 0;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		diff2_v <= 0;
	end
	else if(current_state == IDLE) begin
		diff2_v <= 0;
	end
	else if(diff2_flag2) begin
		diff2_v <= diff2_v + sub_result2;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		diff01_flag_0 <= 0;
	end
	else if(average_cnt > 157 && average_cnt < 186) begin
		diff01_flag_0 <= 1;
	end
	else begin
		diff01_flag_0 <= 0;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		diff01_flag_1 <= 0;
	end
	else if(current_state == IDLE) begin
		diff01_flag_1 <= 0;
	end
	else if(average_cnt > 188) begin
		diff01_flag_1 <= 1;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		diff1_flag <= 0;
	end
	else if(current_state == IDLE) begin
		diff1_flag <= 0;
	end
	else if(diff01_flag_0) begin
		case(diff_cell_cnt)
			8,9,10,13,14,15,18,19,20,23,24,25: diff1_flag <= 1;
			default: diff1_flag <= 0;
		endcase
	end
	else if(diff01_flag_1) begin
		case(diff_cell_cnt)
			9,10,11,12,15,16,17,18,21,22,23,24: diff1_flag <= 1;
			default: diff1_flag <= 0;
		endcase
	end
	else begin
		diff1_flag <= 0;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		diff1_flag2 <= 0;
	end
	else if(current_state == IDLE) begin
		diff1_flag2 <= 0;
	end
	else if(diff01_flag_0) begin
		case(diff_cell_cnt2)
			9,10,11,12,15,16,17,18,21,22,23,24: diff1_flag2 <= 1;
			default: diff1_flag2 <= 0;
		endcase
	end
	else begin
		diff1_flag2 <= 0;
	end
end


always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		diff1_h <= 0;
	end
	else if(current_state == IDLE) begin
		diff1_h <= 0;
	end
	else if(diff1_flag) begin
		diff1_h <= diff1_h + sub_result;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		diff1_v <= 0;
	end
	else if(current_state == IDLE) begin
		diff1_v <= 0;
	end
	else if(diff1_flag2) begin
		diff1_v <= diff1_v + sub_result2;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		diff1 <= 0;
	end
	else if(current_state == IDLE) begin
		diff1 <= 0;
	end
	else begin
		diff1 <= diff1_h + diff1_v;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		diff0_flag <= 0;
	end
	else if(current_state == IDLE) begin
		diff0_flag <= 0;
	end
	else if(diff01_flag_0) begin
		case(diff_cell_cnt)
			14,19: diff0_flag <= 1;
			default: diff0_flag <= 0;
		endcase
	end
	else begin
		diff0_flag <= 0;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		diff0_flag2 <= 0;
	end
	else if(current_state == IDLE) begin
		diff0_flag2 <= 0;
	end
	else if(diff01_flag_0) begin
		case(diff_cell_cnt2)
			16,17: diff0_flag2 <= 1;
			default: diff0_flag2 <= 0;
		endcase
	end
	else begin
		diff0_flag2 <= 0;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		diff0_h <= 0;
	end
	else if(current_state == IDLE) begin
		diff0_h <= 0;
	end
	else if(diff0_flag) begin
		diff0_h <= diff0_h + sub_result;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		diff0_v <= 0;
	end
	else if(current_state == IDLE) begin
		diff0_v <= 0;
	end
	else if(diff0_flag2) begin
		diff0_v <= diff0_v + sub_result2;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		diff0 <= 0;
	end
	else if(current_state == IDLE) begin
		diff0 <= 0;
	end
	else begin
		diff0 <= diff0_h + diff0_v;
	end
end

assign diff0_n = diff0 >> 2;
assign diff1_n = diff1 >> 4;



always @(posedge clk ) begin
	if(average_cnt == 187) diff0_n_reg <= diff0_n;
end
always @(posedge clk ) begin
	if(average_cnt == 187) diff1_n_reg <= diff1_n;
end



always @(posedge clk or negedge rst_n) begin
	if(!rst_n) valid_data <= 0;
	else if(average_cnt == 191) valid_data <= 1;
	else valid_data <= 0;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) valid_out_r <= 0;
	else valid_out_r <= valid_out;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) valid_out_rr <= 0;
	else valid_out_rr <= valid_out_r;
end

Divider divider(.clk(clk), .rst_n(rst_n), .valid_data(valid_data), .data_in(diff2), .valid_out(valid_out), .data_out(diff2_n));




//================================================//
//                  MAX_CONTRAST                  //
//================================================//

always @(*) begin
	if((diff0_n_reg >= diff1_n_reg) && (diff0_n_reg >= diff2_n)) idx = 0;
	else if((diff1_n_reg > diff0_n_reg) && (diff1_n_reg >= diff2_n)) idx = 1;
	else idx = 2;
end

always @(posedge clk ) begin
	idx_r <= idx;
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
		data_in_result_buff <= 0;
	end
	else begin
		data_in_result_buff <= {data_in_result_part[15],data_in_result_part[14],data_in_result_part[13],data_in_result_part[12],data_in_result_part[11],data_in_result_part[10],data_in_result_part[9],data_in_result_part[8],data_in_result_part[7],data_in_result_part[6],data_in_result_part[5],data_in_result_part[4],data_in_result_part[3],data_in_result_part[2],data_in_result_part[1],data_in_result_part[0]};
	end
end





always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		average_shift <= 0;
	end
	else if(current_state == IDLE) begin
		average_shift <= 0;
	end
	else begin
		average_shift <= ((average_cnt > 63) && (average_cnt < 128));
	end
end



always @(posedge clk ) begin
	if(current_state == IDLE) begin
		for(i = 0; i < 8; i = i + 1) begin
			average_tmp8[i] <= 0;
		end
	end
	else if(current_state == EXPOSURE) begin
		average_tmp8[7] <= (average_shift ? data_in_result_buff[127:121] : data_in_result_buff[127:122]) + (average_shift ? data_in_result_buff[63:57] : data_in_result_buff[63:58]);
		average_tmp8[6] <= (average_shift ? data_in_result_buff[119:113] : data_in_result_buff[119:114]) + (average_shift ? data_in_result_buff[55:49] : data_in_result_buff[55:50]);
		average_tmp8[5] <= (average_shift ? data_in_result_buff[111:105] : data_in_result_buff[111:106]) + (average_shift ? data_in_result_buff[47:41] : data_in_result_buff[47:42]);
		average_tmp8[4] <= (average_shift ? data_in_result_buff[103:97] : data_in_result_buff[103:98])  + (average_shift ? data_in_result_buff[39:33] : data_in_result_buff[39:34]);
		average_tmp8[3] <= (average_shift ? data_in_result_buff[95:89] : data_in_result_buff[95:90]) + (average_shift ? data_in_result_buff[31:25] : data_in_result_buff[31:26]);
		average_tmp8[2] <= (average_shift ? data_in_result_buff[87:81] : data_in_result_buff[87:82]) + (average_shift ? data_in_result_buff[23:17] : data_in_result_buff[23:18]);
		average_tmp8[1] <= (average_shift ? data_in_result_buff[79:73] : data_in_result_buff[79:74]) + (average_shift ? data_in_result_buff[15:9] : data_in_result_buff[15:10]);
		average_tmp8[0] <= (average_shift ? data_in_result_buff[71:65] : data_in_result_buff[71:66]) + (average_shift ? data_in_result_buff[7:1] : data_in_result_buff[7:2]);
	end
end


always @(posedge clk ) begin
	if(current_state == IDLE) begin
		for(i = 0; i < 4; i = i + 1) begin
			average_tmp4[i] <= 0;
		end
	end
	else if(current_state == EXPOSURE) begin
		average_tmp4[3] <= average_tmp8[6] + average_tmp8[7];
		average_tmp4[2] <= average_tmp8[4] + average_tmp8[5];
		average_tmp4[1] <= average_tmp8[2] + average_tmp8[3];
		average_tmp4[0] <= average_tmp8[0] + average_tmp8[1];
	end
end

always @(posedge clk ) begin
	if(current_state == IDLE) begin
		for(i = 0; i < 2; i = i + 1) begin
			average_tmp2[i] <= 0;
		end
	end
	else if(current_state == EXPOSURE) begin
		average_tmp2[1] <= average_tmp4[2] + average_tmp4[3];
		average_tmp2[0] <= average_tmp4[0] + average_tmp4[1];
	end
end

always @(posedge clk ) begin
	if(current_state == IDLE) begin
		average_tmp1 <= 0;
	end
	else if(current_state == EXPOSURE) begin
		average_tmp1 <= average_tmp2[0] + average_tmp2[1];
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

always @(posedge clk ) begin
	if(current_state == IDLE) average_flag <= 0;
	else if(current_state == EXPOSURE) average_flag <= 1;
end

always @(posedge clk ) begin
	if(current_state == IDLE) average_reset_flag <= 1;
	else if(current_state == EXPOSURE) average_reset_flag <= 0;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		average_cell_tot <= 0;
	end
	else if(average_reset_flag) begin
		average_cell_tot <= 0;
	end
	else if(average_flag) begin
		average_cell_tot <= average_cell_tot + average_tmp1;
	end
end




//================================================//
//                     AVERAGE                    //
//================================================//

always @(posedge clk ) begin
    if(current_state == IDLE) begin
        for(i = 0; i < 16; i = i + 1) begin
            cell_max[i] <= 0;
        end
    end
    else if(current_state == EXPOSURE) begin
        cell_max[0] <= (data_in_result_buff[127:120] > data_in_result_buff[119:112]) ? data_in_result_buff[127:120] : data_in_result_buff[119:112];
        cell_max[1] <= (data_in_result_buff[111:104] > data_in_result_buff[103:96]) ? data_in_result_buff[111:104] : data_in_result_buff[103:96];
        cell_max[2] <= (data_in_result_buff[95:88] > data_in_result_buff[87:80]) ? data_in_result_buff[95:88] : data_in_result_buff[87:80];
        cell_max[3] <= (data_in_result_buff[79:72] > data_in_result_buff[71:64]) ? data_in_result_buff[79:72] : data_in_result_buff[71:64];
        cell_max[4] <= (data_in_result_buff[63:56] > data_in_result_buff[55:48]) ? data_in_result_buff[63:56] : data_in_result_buff[55:48];
        cell_max[5] <= (data_in_result_buff[47:40] > data_in_result_buff[39:32]) ? data_in_result_buff[47:40] : data_in_result_buff[39:32];
        cell_max[6] <= (data_in_result_buff[31:24] > data_in_result_buff[23:16]) ? data_in_result_buff[31:24] : data_in_result_buff[23:16];
        cell_max[7] <= (data_in_result_buff[15:8] > data_in_result_buff[7:0]) ? data_in_result_buff[15:8] : data_in_result_buff[7:0];
        cell_max[8] <= (cell_max[0] > cell_max[1]) ? cell_max[0] : cell_max[1];
        cell_max[9] <= (cell_max[2] > cell_max[3]) ? cell_max[2] : cell_max[3];
        cell_max[10] <= (cell_max[4] > cell_max[5]) ? cell_max[4] : cell_max[5];
        cell_max[11] <= (cell_max[6] > cell_max[7]) ? cell_max[6] : cell_max[7];
        cell_max[12] <= (cell_max[8] > cell_max[9]) ? cell_max[8] : cell_max[9];
        cell_max[13] <= (cell_max[10] > cell_max[11]) ? cell_max[10] : cell_max[11];
        cell_max[14] <= (cell_max[12] > cell_max[13]) ? cell_max[12] : cell_max[13];
        cell_max[15] <= ((cell_max[14] > cell_max[15]) || average_cnt == 69 || average_cnt == 133) ? cell_max[14] : cell_max[15];
    end
end

always @(posedge clk ) begin
	if(current_state == IDLE) begin
        for(i = 0; i < 15; i = i + 1) begin
            cell_min[i] <= 0;
        end
    end
    else if(current_state == EXPOSURE) begin
        cell_min[0] <= (data_in_result_buff[127:120] > data_in_result_buff[119:112]) ? data_in_result_buff[119:112] : data_in_result_buff[127:120];
        cell_min[1] <= (data_in_result_buff[111:104] > data_in_result_buff[103:96]) ? data_in_result_buff[103:96] : data_in_result_buff[111:104];
        cell_min[2] <= (data_in_result_buff[95:88] > data_in_result_buff[87:80]) ? data_in_result_buff[87:80] : data_in_result_buff[95:88];
        cell_min[3] <= (data_in_result_buff[79:72] > data_in_result_buff[71:64]) ? data_in_result_buff[71:64] : data_in_result_buff[79:72];
        cell_min[4] <= (data_in_result_buff[63:56] > data_in_result_buff[55:48]) ? data_in_result_buff[55:48] : data_in_result_buff[63:56];
        cell_min[5] <= (data_in_result_buff[47:40] > data_in_result_buff[39:32]) ? data_in_result_buff[39:32] : data_in_result_buff[47:40];
        cell_min[6] <= (data_in_result_buff[31:24] > data_in_result_buff[23:16]) ? data_in_result_buff[23:16] : data_in_result_buff[31:24];
        cell_min[7] <= (data_in_result_buff[15:8] > data_in_result_buff[7:0]) ? data_in_result_buff[7:0] : data_in_result_buff[15:8];
        cell_min[8] <= (cell_min[0] > cell_min[1]) ? cell_min[1] : cell_min[0];
        cell_min[9] <= (cell_min[2] > cell_min[3]) ? cell_min[3] : cell_min[2];
        cell_min[10] <= (cell_min[4] > cell_min[5]) ? cell_min[5] : cell_min[4];
        cell_min[11] <= (cell_min[6] > cell_min[7]) ? cell_min[7] : cell_min[6];
        cell_min[12] <= (cell_min[8] > cell_min[9]) ? cell_min[9] : cell_min[8];
        cell_min[13] <= (cell_min[10] > cell_min[11]) ? cell_min[11] : cell_min[10];
        cell_min[14] <= (cell_min[12] > cell_min[13]) ? cell_min[13] : cell_min[12];
    end
end

reg cell_min_flag;

always @(posedge clk ) begin
	if(average_cnt < 4) cell_min_flag <= 1;
	else cell_min_flag <= 0;
end

always @(posedge clk ) begin
    if(cell_min_flag) begin
        cell_min[15] <= 255;
    end
    else if(current_state == EXPOSURE) begin
        cell_min[15] <= (cell_min[14] < cell_min[15] || average_cnt == 69 || average_cnt == 133) ? cell_min[14] : cell_min[15];
    end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cell_max_min_flag <= 0;
	end
	else if(average_cnt == 68 || average_cnt == 132 || average_cnt == 196) begin
		cell_max_min_flag <= 1;
	end
	else begin
		cell_max_min_flag <= 0;
	end
end


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) cell_max_tot <= 0;
    else if(current_state == IDLE) cell_max_tot <= 0;
    else if(cell_max_min_flag) cell_max_tot <= cell_max_tot + cell_max[15];
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) cell_min_tot <= 0;
    else if(current_state == IDLE) cell_min_tot <= 0;
    else if(cell_max_min_flag) cell_min_tot <= cell_min_tot + cell_min[15];
end


always @(posedge clk or negedge rst_n) begin
	if(!rst_n) valid_data_a <= 0;
	else if(average_cnt == 197) valid_data_a <= 1;
	else valid_data_a <= 0;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) valid_out_a_r <= 0;
	else valid_out_a_r <= valid_out_a;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) valid_out_a_rr <= 0;
	else valid_out_a_rr <= valid_out_a_r;
end



Divider2 divider_max(.clk(clk), .rst_n(rst_n), .valid_data(valid_data_a), .data_in(cell_max_tot), .valid_out(valid_out_a), .data_out(cell_max_div));
Divider2 divider_min(.clk(clk), .rst_n(rst_n), .valid_data(valid_data_a), .data_in(cell_min_tot), .valid_out(valid_out_a2), .data_out(cell_min_div));





always @(posedge clk or negedge rst_n) begin
	if(!rst_n) cell_tot <= 0;
	else if(current_state == IDLE) cell_tot <= 0;
	else if(valid_out_a) cell_tot <= (cell_max_div + cell_min_div) >> 1;
end


//================================================//
//                     OUTPUT                     //
//================================================//



always @(posedge clk or negedge rst_n) begin
	if(!rst_n) out_valid <= 0;
	else if(current_state == ZERO_OUTPUT || valid_out_rr) out_valid <= 1;
	else out_valid <= 0;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) out_data <= 0;
	else if(current_state == ZERO_OUTPUT || valid_out_rr) out_data <= (in_mode_reg == 0) ? auto_auto_focus_idx[in_pic_no_reg] : (in_mode_reg == 1 ? auto_auto_exposure_idx[in_pic_no_reg] : auto_average_idx[in_pic_no_reg]);
	else out_data <= 0;
end


//================================================//
//                  ZERO   OUTPUT                 //
//================================================//
assign msb_temp = data_in_result_part[15] | data_in_result_part[14] | data_in_result_part[13] | data_in_result_part[12] | data_in_result_part[11] | data_in_result_part[10] | data_in_result_part[9] | data_in_result_part[8] | data_in_result_part[7] | data_in_result_part[6] | data_in_result_part[5] | data_in_result_part[4] | data_in_result_part[3] | data_in_result_part[2] | data_in_result_part[1] | data_in_result_part[0];

always @(posedge clk) begin
    if(wvalid_s_inf) msb_left_reg <= msb_left_reg | (|msb_temp[7:2]);
    else msb_left_reg <= 0;
end

always @(posedge clk) begin
    if(wvalid_s_inf) msb_right_reg <= msb_right_reg | (msb_temp[1:0]);
    else msb_right_reg <= 0;
end


assign mode1_zero = (in_mode_reg[0]) && (in_ratio_mode_reg == 1) && (msb_r[2:1] == 2'b00);

assign mode0_zero = (in_mode_reg[0]) && (in_ratio_mode_reg == 0) && (msb_r[2] == 0);



assign zero_flag = (!(|msb_r) || mode0_zero || mode1_zero);

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
		for (i = 0; i < 16; i = i + 1) begin
			msb[i] <= 3'b111;
		end
	end
    else if(mode0_zero || mode1_zero) begin
        msb[in_pic_no_reg] <= 3'b000;
    end
    else if(wlast_s_inf) begin
        msb[in_pic_no_reg] <= {msb_left_reg, msb_right_reg};
	end
end

always @(posedge clk ) begin
	if(in_valid) msb_r <= msb[in_pic_no];
end







//================================================//
//                   AUTO ACTION                  //
//================================================//

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) auto_flag <= 0;
	else if(in_valid_r) auto_flag[in_pic_no_reg] <= 1;
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
	else if(zero_flag) auto_auto_focus_idx[in_pic_no_reg] <= 0;
	else if(valid_out_r) auto_auto_focus_idx[in_pic_no_reg] <= idx_r;
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
	else if(zero_flag) auto_auto_exposure_idx[in_pic_no_reg] <= 0;
	else if(average_cnt == 197) auto_auto_exposure_idx[in_pic_no_reg] <= average_cell_tot[17:10];
end


//================================================//
//                AUTO AUTO AVERAGE               //
//================================================//

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0; i < 16; i = i + 1) begin
			auto_average_idx[i] <= 0;
		end
	end
	else if(zero_flag) auto_average_idx[in_pic_no_reg] <= 0;
	else if(valid_out_a_rr) auto_average_idx[in_pic_no_reg] <= cell_tot;
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

	reg [29:0] temp_a;
	reg start_div;
	reg [4:0] cnt_div;


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
		end
		else if(start_div) begin
			if(cnt_div == 0) begin
				temp_a <= {15'b0,data_in};
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


 module Divider2(clk, rst_n, valid_data, data_in, valid_out, data_out);
	input clk, rst_n, valid_data;
	input [9:0] data_in;
	output reg valid_out;
	output reg [7:0] data_out;

	reg [19:0] temp_a;
	reg start_div;
	reg [4:0] cnt_div;

	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) start_div <= 0;
		else if(valid_data && start_div == 0) start_div <= 1;
		else if(cnt_div == 20) start_div <= 0;
	end
	
	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) cnt_div <= 0;
		else if(start_div) cnt_div <= cnt_div + 1;
		else cnt_div <= 0;
	end

	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			temp_a <= 0;
		end
		else if(start_div) begin
			if(cnt_div == 0) begin
				temp_a <= {10'b0,data_in};
			end
			else if(cnt_div[0]) begin
				temp_a <= {temp_a[18:0],1'b0};
			end
			else begin
				temp_a <= (temp_a[19:10] >= 3) ? (temp_a - 3071) : temp_a;
			end
		end
		else begin
			temp_a <= 0;
		end
	end

	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) valid_out <= 0;
		else if (cnt_div == 21) valid_out <= 1;
		else valid_out <= 0;
	end

	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) data_out <= 0;
		else data_out <= temp_a[7:0];
	end

endmodule



