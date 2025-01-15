module Program(input clk, INF.Program_inf inf);
import usertype::*;

//==============================================//
//             Parameter and Integer            //
//==============================================//
enum logic [2:0] {
    IDLE =    3'd0,
    DATA_READ =   3'd1,
	DRAM_READ =  3'd2,
	INDEX_CEHCK = 3'd3,
	DRAM_WRITE = 3'd4,
    DATE_CHECK = 3'd5,
	OUTPUT = 3'd6
    } current_state, next_state;

integer i, j;

//==============================================//
//               logic declaration              //
//==============================================//

logic [15:0] addr_bus;
logic [63:0] rdata;
logic [2:0] cnt_idx;

logic [2:0] cnt_idx_check;
logic idx_check_control;
logic idx_check_complete;
Warn_Msg idx_check_warn_msg;
logic [13:0] formula_A, formula_F, formula_H, formula_case, formula_F_tmp;
Index formula_B, formula_C, formula_G, idx_DRAM;
logic [2:0] formula_D, formula_E;
Index minus0, minus1, minus0_reg, minus1_reg;
Index G;
Index G_tmp[0:3];
Index G_sort[0:3];
logic [1:0] G_shift, G_shift_reg;
logic [2:0] cnt_G_sort;
Index G_sort_tmp;
Index max_wire, min_wire, max_reg;



logic [2:0] cnt_update;
Index idx_tmp;
Index idx_tmp_comp;
Index idx_update;
logic [12:0] large_idx;
Index sum, diff;
logic update_control;
logic update_complete_tmp[0:3];
logic update_complete;
Warn_Msg update_warn_msg;
logic B_VALID_buff;
logic flag;


threshold_type threshold_table[0:7];


Action act;
Formula_Type formula;
Mode mode;
Month month;
Day day;
Data_No data_no;
Index index[0:3];

logic date_check_control;
logic date_check_complete;
Warn_Msg date_check_warn_msg;

Data_Dir DRAM_data;





logic [7:0] rdata_wire[0:7];


always_ff @(posedge clk ) begin
    if(inf.sel_action_valid) act <= inf.D.d_act[0];
end

always_ff @(posedge clk ) begin
    if(inf.formula_valid) formula <= inf.D.d_formula[0];
end

always_ff @(posedge clk ) begin
    if(inf.mode_valid) mode <= inf.D.d_mode[0];
end

always_ff @(posedge clk ) begin
    if(inf.date_valid) month <= inf.D.d_date[0].M;
end

always_ff @(posedge clk ) begin
    if(inf.date_valid) day <= inf.D.d_date[0].D;
end

always_ff @(posedge clk ) begin
    if(inf.data_no_valid) data_no <= inf.D.d_data_no[0];
end


always_ff @(posedge clk ) begin
    if(current_state == IDLE) cnt_idx <= 0;
	else if(inf.index_valid) cnt_idx <= cnt_idx + 1;
end

always_ff @(posedge clk ) begin
	for(i = 0; i < 4; i = i + 1) begin
    	if(inf.index_valid) index[i] <= (cnt_idx == i) ? inf.D.d_index : index[i];
	end
end



always_ff @(posedge clk ) begin
    if(inf.R_VALID && inf.R_READY) begin
        DRAM_data.M <= inf.R_DATA[39:32];
    end
	else if(act == Update) begin
		DRAM_data.M <= month;
	end
end
always_ff @(posedge clk ) begin
    if(inf.R_VALID && inf.R_READY) begin
        DRAM_data.D <= inf.R_DATA[7:0];
    end
	else if(act == Update) begin
		DRAM_data.D <= day;
	end
end


assign addr_bus = data_no << 3;//(in_pic_no_reg << 11) + (in_pic_no_reg << 10) + ((in_mode_reg) ? 0 : 416);
assign rdata = inf.R_DATA;
assign rdata_wire[0] = inf.R_DATA[63:56];
assign rdata_wire[1] = inf.R_DATA[55:48];
assign rdata_wire[2] = inf.R_DATA[47:40];
assign rdata_wire[3] = inf.R_DATA[39:32];
assign rdata_wire[4] = inf.R_DATA[31:24];
assign rdata_wire[5] = inf.R_DATA[23:16];
assign rdata_wire[6] = inf.R_DATA[15:8];
assign rdata_wire[7] = inf.R_DATA[7:0];


//===============================================//
//        Read DRAM with AXI4-Lite protocol      //
//===============================================//
// read address of picture
always_comb begin
	// If read valid is high, give read address
	if(inf.AR_VALID) begin
		if(current_state == DRAM_READ) begin
			inf.AR_ADDR = {1'b1, addr_bus};
        end
		else inf.AR_ADDR = 0;
	end
	else begin
		inf.AR_ADDR = 0;
	end 
end
// read valid
always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		inf.AR_VALID <= 0;
	end
	else if(inf.AR_VALID && inf.AR_READY) begin
		inf.AR_VALID <= 0;
	end
	else if(current_state != next_state && next_state == DRAM_READ) begin
		inf.AR_VALID <= 1;
	end
end

// read ready
always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		inf.R_READY <= 0;
	end
	else if(inf.AR_VALID && inf.AR_READY) begin
		inf.R_READY <= 1;
	end
	else if(inf.R_VALID) begin
		inf.R_READY <= 0;
	end
end









//===============================================//
//       Write DRAM with AXI4-Lite protocol      //
//===============================================//
// write address of exposure picture
always_comb begin
	// If write valid is high, give read address
	if(inf.AW_VALID) begin
		inf.AW_ADDR = {16'd1, addr_bus};
	end
    else begin
		inf.AW_ADDR = 0;
	end 
end

// write valid
always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		inf.AW_VALID <= 0;
	end
    else if(inf.AW_VALID && inf.AW_READY) begin
		inf.AW_VALID <= 0;
	end
	else if(act == Update && cnt_update > 0 && cnt_update < 2) begin
		inf.AW_VALID <= 1;
	end
end

// write data
// write to DRAM
assign inf.W_DATA = (current_state == IDLE) ? 0 : {DRAM_data.Index_A[11:4],DRAM_data.Index_A[3:0],DRAM_data.Index_B[11:8],DRAM_data.Index_B[7:0],4'b0,DRAM_data.M,DRAM_data.Index_C[11:4],DRAM_data.Index_C[3:0],DRAM_data.Index_D[11:8],DRAM_data.Index_D[7:0],3'b0,DRAM_data.D};

// write valid
always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		inf.W_VALID <= 0;
	end
    else if(inf.W_READY) begin
		inf.W_VALID <= 0;
	end
    else if(inf.AW_VALID && inf.AW_READY) begin
		inf.W_VALID <= 1;
	end
end
// response ready
always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		inf.B_READY <= 0;
	end
    else if(inf.B_VALID) begin
		inf.B_READY <= 0;
	end
	else if(inf.AW_VALID && inf.AW_READY) begin
		inf.B_READY <= 1;
    end
end




//==============================================//
//             Current State Block              //
//==============================================//
always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) current_state <= IDLE;
	else current_state <= next_state;
end

//==============================================//
//              Next State Block                //
//==============================================//
always_comb begin
	case(current_state)
		IDLE: begin
			// when input is valid
			if(inf.sel_action_valid) next_state = DATA_READ;
			else next_state = current_state;
		end
        DATA_READ: begin
			if(inf.data_no_valid) next_state = DRAM_READ;
            else next_state = current_state;
        end
        DRAM_READ: begin
            if(inf.R_VALID) begin
				case(act)
					Index_Check: next_state = INDEX_CEHCK;
					Update: next_state = DRAM_WRITE;
					Check_Valid_Date: next_state = DATE_CHECK;
					default: next_state = current_state;
				endcase
			end
            else next_state = current_state;
        end
		INDEX_CEHCK: begin
			next_state = ((!date_check_control && cnt_idx == 4) || (cnt_G_sort == 6)) ? IDLE : INDEX_CEHCK;
		end
        DRAM_WRITE: begin
			next_state = (cnt_update == 6 && B_VALID_buff) ? IDLE : DRAM_WRITE;
        end
		DATE_CHECK: begin
            next_state = OUTPUT;
        end
        OUTPUT: begin
            next_state = IDLE;
        end
		default: next_state = IDLE; // illegal state
	endcase
end


//==============================================//
//                 Index check                  //
//==============================================//
parameter threshold_type threshold_t[0:7] = '{
    '{2047,1023,0,511},
    '{800,400,0,200},
    '{2047,1023,0,511},
    '{3,2,0,1},
    '{3,2,0,1},
    '{800,400,0,200},
    '{800,400,0,200},
    '{800,400,0,200}
};
assign threshold_table[0][0] = 2047;
assign threshold_table[0][1] = 1023;
assign threshold_table[0][3] = 511;
assign threshold_table[1][0] = 800;
assign threshold_table[1][1] = 400;
assign threshold_table[1][3] = 200;
assign threshold_table[2][0] = 2047;
assign threshold_table[2][1] = 1023;
assign threshold_table[2][3] = 511;
assign threshold_table[3][0] = 3;
assign threshold_table[3][1] = 2;
assign threshold_table[3][3] = 1;
assign threshold_table[4][0] = 3;
assign threshold_table[4][1] = 2;
assign threshold_table[4][3] = 1;
assign threshold_table[5][0] = 800;
assign threshold_table[5][1] = 400;
assign threshold_table[5][3] = 200;
assign threshold_table[6][0] = 800;
assign threshold_table[6][1] = 400;
assign threshold_table[6][3] = 200;
assign threshold_table[7][0] = 800;
assign threshold_table[7][1] = 400;
assign threshold_table[7][3] = 200;

always_ff @(posedge clk ) begin
	if(current_state == IDLE) cnt_idx_check <= 0;
    else if(cnt_idx == 3) cnt_idx_check <= 0;
	else if(current_state == INDEX_CEHCK && cnt_idx_check != 7) cnt_idx_check <= cnt_idx_check + 1;
end

always_comb begin
	case(cnt_idx_check)
		0: minus0 = DRAM_data.Index_A;
		1: minus0 = DRAM_data.Index_B;
		2: minus0 = DRAM_data.Index_C;
		3: minus0 = DRAM_data.Index_D;
		default: minus0 = 0;
	endcase
end

always_comb begin
	case(cnt_idx_check)
		0: minus1 = index[0];
		1: minus1 = index[1];
		2: minus1 = index[2];
		3: minus1 = index[3];
		default: minus1 = 0;
	endcase
end

always_ff @(posedge clk ) begin
    if(minus0 > minus1) minus0_reg <= minus0;
	else minus0_reg <= minus1;
end

always_ff @(posedge clk ) begin
    if(minus0 < minus1) minus1_reg <= minus0;
	else minus1_reg <= minus1;
end

always_ff @(posedge clk ) begin
    G <= minus0_reg - minus1_reg;
end

always_ff @(posedge clk ) begin
    if(cnt_idx == 4 && cnt_idx_check == 2) G_tmp[0] <= G;
end
always_ff @(posedge clk ) begin
    if(cnt_idx == 4 && cnt_idx_check == 3) G_tmp[1] <= G;
end
always_ff @(posedge clk ) begin
    if(cnt_idx == 4 && cnt_idx_check == 4) G_tmp[2] <= G;
end
always_ff @(posedge clk ) begin
    if(cnt_idx == 4 && cnt_idx_check == 5) G_tmp[3] <= G;
end

always_comb begin
	case(cnt_idx_check)
		0: idx_DRAM = DRAM_data.Index_A;
		1: idx_DRAM = DRAM_data.Index_B;
		2: idx_DRAM = DRAM_data.Index_C;
		3: idx_DRAM = DRAM_data.Index_D;
		default: idx_DRAM = 0;
	endcase
end


//formula_A
always_ff @(posedge clk ) begin
    if(current_state == IDLE) formula_A <= 0;
	else if(current_state == DRAM_READ) formula_A <= 0;
	else if(cnt_idx == 4 && (cnt_idx_check < 4)) formula_A <= formula_A + idx_DRAM;
	else if(cnt_idx == 4 && (cnt_idx_check == 4)) formula_A <= (formula_A >> 2); 
end


//formula_B

//max MAX(.a(index[0]), .b(index[1]), .c(index[2]), .d(index[3]), .out(max_wire));

always_ff @(posedge clk ) begin
	if(cnt_idx == 4 && (cnt_idx_check == 0)) max_reg <= idx_DRAM;
	else if(cnt_idx == 4 && (cnt_idx_check > 0) && (cnt_idx_check < 4)) max_reg <= (max_reg < idx_DRAM) ? idx_DRAM : max_reg;
end

always_ff @(posedge clk ) begin
    formula_B <= max_reg - formula_C;
end

//formula_C

//min MIN(.a(index[0]), .b(index[1]), .c(index[2]), .d(index[3]), .out(min_wire));

always_ff @(posedge clk ) begin
	if(cnt_idx == 4 && (cnt_idx_check == 0)) formula_C <= idx_DRAM;
	else if(cnt_idx == 4 && (cnt_idx_check > 0) && (cnt_idx_check < 4)) formula_C <= (formula_C > idx_DRAM) ? idx_DRAM : formula_C;
end

//formula_D

always_ff @(posedge clk ) begin
	if(current_state == IDLE) formula_D <= 0;
	else if(current_state == DRAM_READ) formula_D <= 0;
	else if(cnt_idx == 4 && (cnt_idx_check < 4)) formula_D <= formula_D + (idx_DRAM > 2047);
end

//formula_E

always_ff @(posedge clk ) begin
	if(current_state == IDLE) formula_E <= 0;
	else if(current_state == DRAM_READ) formula_E <= 0;
	else if(cnt_idx == 4 && (cnt_idx_check < 4)) formula_E <= formula_E + (idx_DRAM > index[cnt_idx_check]);
end

//formula_F

sort SORT(.a(G_tmp[0]), .b(G_tmp[1]), .c(G_tmp[2]), .d(G_tmp[3]), .L1(G_sort[0]), .L2(G_sort[1]), .L3(G_sort[2]), .L4(G_sort[3]));
always_ff @(posedge clk ) begin
	if(cnt_idx == 3) cnt_G_sort <= 7;
    else if(cnt_idx == 4 && cnt_idx_check == 5) cnt_G_sort <= 0;
	else if(cnt_G_sort != 7) cnt_G_sort <= cnt_G_sort + 1;
end

always_ff @(posedge clk ) begin
	G_sort_tmp <= G_sort[cnt_G_sort];
end

always_ff @(posedge clk ) begin
	if(current_state == IDLE) formula_F_tmp <= 0;
    else if(cnt_idx == 4 && (cnt_G_sort > 0) && (cnt_G_sort < 4)) formula_F_tmp <= formula_F_tmp + G_sort_tmp;
end

always_ff @(posedge clk ) begin
	if(flag) formula_F <= formula_F_tmp / 3;
end

always_ff @(posedge clk ) begin
	if(current_state == IDLE) flag = 0;
	if(cnt_idx == 4 && (cnt_G_sort == 3)) flag = 1;
end

//formula_G

always_comb begin
	case(cnt_G_sort)
		0: G_shift = 1;
		1: G_shift = 2;
		2: G_shift = 2;
		default: G_shift = 0;
	endcase
end

always_ff @(posedge clk ) begin
	G_shift_reg <= G_shift;
end

always_ff @(posedge clk ) begin
	if(current_state == IDLE) formula_G <= 0;
    else if(cnt_idx == 4 && (cnt_G_sort > 0) && (cnt_G_sort < 4)) formula_G <= formula_G + (G_sort_tmp >> G_shift_reg);
end

//formula_H
always_ff @(posedge clk ) begin
    if(current_state == IDLE) formula_H <= 0;
	else if(cnt_idx == 4 && (cnt_idx_check > 1) && (cnt_idx_check < 6)) formula_H <= formula_H + G;
	else if(cnt_idx == 4 && (cnt_idx_check == 6)) formula_H <= (formula_H >> 2); 
end

always_ff @(posedge clk ) begin
	if(cnt_G_sort == 5) begin
		case(formula)
			Formula_A: formula_case = formula_A;
			Formula_B: formula_case = formula_B;
			Formula_C: formula_case = formula_C;
			Formula_D: formula_case = formula_D;
			Formula_E: formula_case = formula_E;
			Formula_F: formula_case = formula_F;
			Formula_G: formula_case = formula_G;
			Formula_H: formula_case = formula_H;
		endcase
	end
end


assign idx_check_control = !(formula_case >= threshold_table[formula][mode]);

always_comb begin
    idx_check_complete = idx_check_control;
end

always_comb begin
    idx_check_warn_msg = idx_check_control ? No_Warn : Risk_Warn;
end

//==============================================//
//                    Update                    //
//==============================================//

always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) cnt_update <= 0;
    else if(current_state == IDLE) cnt_update <= 0;
	else if(current_state == DRAM_WRITE && cnt_idx == 4 && cnt_update != 6) cnt_update <= cnt_update + 1;
end

assign diff = (idx_tmp_comp > idx_update) ? 0 : (idx_update - idx_tmp_comp);
assign sum = large_idx[12] ? 4095 : (idx_update + idx_tmp);

assign idx_tmp_comp = ~idx_tmp + 1;
assign large_idx = idx_update + idx_tmp;

always_comb begin
	case(cnt_update)
		1: idx_tmp = index[0];
		2: idx_tmp = index[1];
		3: idx_tmp = index[2];
		4: idx_tmp = index[3];
		default: idx_tmp = 0;
	endcase
end

always_comb begin
	case(cnt_update)
		1: idx_update = DRAM_data.Index_A;
		2: idx_update = DRAM_data.Index_B;
		3: idx_update = DRAM_data.Index_C;
		4: idx_update = DRAM_data.Index_D;
		default: idx_update = 0;
	endcase
end



always_ff @(posedge clk ) begin
    if(inf.R_VALID && inf.R_READY) begin
        DRAM_data.Index_A <= {inf.R_DATA[63:56],inf.R_DATA[55:52]};
    end
	else if(current_state == DRAM_WRITE && cnt_update == 1) begin
		if(index[0][11]) begin
			DRAM_data.Index_A <= diff;
		end
		else begin
			DRAM_data.Index_A <= sum;
		end
	end
end
always_ff @(posedge clk ) begin
    if(current_state == DRAM_WRITE && cnt_update == 1) begin
		if(index[0][11]) begin
			update_complete_tmp[0] <= !(idx_tmp_comp > idx_update);
		end
		else begin
			update_complete_tmp[0] <= ~large_idx[12];
		end
	end
end

always_ff @(posedge clk ) begin
    if(inf.R_VALID && inf.R_READY) begin
        DRAM_data.Index_B <= {inf.R_DATA[51:48],inf.R_DATA[47:40]};
    end
	else if(current_state == DRAM_WRITE && cnt_update == 2) begin
		if(index[1][11]) begin
			DRAM_data.Index_B <= diff;
		end
		else begin
			DRAM_data.Index_B <= sum;
		end
	end
end
always_ff @(posedge clk ) begin
    if(current_state == DRAM_WRITE && cnt_update == 2) begin
		if(index[1][11]) begin
			update_complete_tmp[1] <= !(idx_tmp_comp > idx_update);
		end
		else begin
			update_complete_tmp[1] <= ~large_idx[12];
		end
	end
end

always_ff @(posedge clk ) begin
    if(inf.R_VALID && inf.R_READY) begin
        DRAM_data.Index_C <= {inf.R_DATA[31:24],inf.R_DATA[23:20]};
    end
	else if(current_state == DRAM_WRITE && cnt_update == 3) begin
		if(index[2][11]) begin
			DRAM_data.Index_C <= diff;
		end
		else begin
			DRAM_data.Index_C <= sum;
		end
	end
end
always_ff @(posedge clk ) begin
    if(current_state == DRAM_WRITE && cnt_update == 3) begin
		if(index[2][11]) begin
			update_complete_tmp[2] <= !(idx_tmp_comp > idx_update);
		end
		else begin
			update_complete_tmp[2] <= ~large_idx[12];
		end
	end
end

always_ff @(posedge clk ) begin
    if(inf.R_VALID && inf.R_READY) begin
        DRAM_data.Index_D <= {inf.R_DATA[19:16],inf.R_DATA[15:8]};
    end
	else if(current_state == DRAM_WRITE && cnt_update == 4) begin
		if(index[3][11]) begin
			DRAM_data.Index_D <= diff;
		end
		else begin
			DRAM_data.Index_D <= sum;
		end
	end
end
always_ff @(posedge clk ) begin
    if(current_state == DRAM_WRITE && cnt_update == 4) begin
		if(index[3][11]) begin
			update_complete_tmp[3] <= !(idx_tmp_comp > idx_update);
		end
		else begin
			update_complete_tmp[3] <= ~large_idx[12];
		end
	end
end

always_ff @(posedge clk ) begin
	if(current_state == IDLE) B_VALID_buff <= 0;
    else if(inf.B_VALID) B_VALID_buff <= 1;
end

assign update_control = update_complete_tmp[0] && update_complete_tmp[1] && update_complete_tmp[2] && update_complete_tmp[3];

always_ff @(posedge clk ) begin
    update_complete <= update_control;
end

always_ff @(posedge clk ) begin
    update_warn_msg <= update_control ? No_Warn : Data_Warn;
end

//==============================================//
//               Check valid date               //
//==============================================//

assign date_check_control = !((month < DRAM_data.M) || (month == DRAM_data.M) && (day < DRAM_data.D));

always_comb begin
    date_check_complete = date_check_control;
end

always_comb begin
    date_check_warn_msg = date_check_control ? No_Warn : Date_Warn;
end

//==============================================//
//                    Ouput                     //
//==============================================//

always_ff @(posedge clk or negedge inf.rst_n ) begin
    if(!inf.rst_n) inf.out_valid <= 0;
    else if(current_state == IDLE) inf.out_valid <= 0;
    else if(current_state == OUTPUT) inf.out_valid <= 1;
	else if(next_state == IDLE && current_state == DRAM_WRITE) inf.out_valid <= 1;
	else if(next_state == IDLE && current_state == INDEX_CEHCK) inf.out_valid <= 1;
end

always_ff @(posedge clk or negedge inf.rst_n ) begin
    if(!inf.rst_n) inf.complete <= 0;
    else if(current_state == IDLE) inf.complete <= 0;
    else if(current_state == OUTPUT) inf.complete <= date_check_complete;
	else if(next_state == IDLE && current_state == DRAM_WRITE) inf.complete <= update_complete;
	else if(next_state == IDLE && current_state == INDEX_CEHCK) inf.complete <= date_check_control ? idx_check_complete : date_check_complete;
end
always_ff @(posedge clk or negedge inf.rst_n ) begin
    if(!inf.rst_n) inf.warn_msg <= No_Warn;
    else if(current_state == IDLE) inf.warn_msg <= No_Warn;
    else if(current_state == OUTPUT) inf.warn_msg <= date_check_warn_msg;
	else if(next_state == IDLE && current_state == DRAM_WRITE) inf.warn_msg <= update_warn_msg;
	else if(next_state == IDLE && current_state == INDEX_CEHCK) inf.warn_msg <= date_check_control ? idx_check_warn_msg : date_check_warn_msg;
end


endmodule


module max(
	input Index a, 
	input Index b, 
	input Index c, 
	input Index d, 
	output Index out
);
	Index max_val1, max_val2;
    assign max_val1 = (a > b) ? a : b;
	assign max_val2 = (c > d) ? c : d;
    assign out = (max_val1 > max_val2) ? max_val1 : max_val2;

endmodule


module min(
	input Index a, 
	input Index b, 
	input Index c, 
	input Index d, 
	output Index out
);
	Index min_val1, min_val2;
    assign min_val1 = (a < b) ? a : b;
	assign min_val2 = (c < d) ? c : d;
    assign out = (min_val1 < min_val2) ? min_val1 : min_val2;

endmodule

module sort(
	input Index a, 
	input Index b, 
	input Index c, 
	input Index d, 
	output Index L1,
	output Index L2,
	output Index L3,
	output Index L4
);
	Index min_val1, min_val2, min_val3, min_val4;
    assign min_val1 = (a < b) ? a : b;
	assign min_val3 = (a > b) ? a : b;
	assign min_val2 = (c < d) ? c : d;
	assign min_val4 = (c > d) ? c : d;
    assign L1 = (min_val1 < min_val2) ? min_val1 : min_val2;
	assign L2 = (min_val1 > min_val2) ? min_val1 : min_val2;
	assign L3 = (min_val3 < min_val4) ? min_val3 : min_val4;
	assign L4 = (min_val3 > min_val4) ? min_val3 : min_val4;

endmodule
