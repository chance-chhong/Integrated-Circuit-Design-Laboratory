module TMIP(
    // input signals
    clk,
    rst_n,
    in_valid, 
    in_valid2,
    
    image,
    template,
    image_size,
	action,
	
    // output signals
    out_valid,
    out_value
    );

input            clk, rst_n;
input            in_valid, in_valid2;

input      [7:0] image;
input      [7:0] template;
input      [1:0] image_size;
input      [2:0] action;

output reg       out_valid;
output reg       out_value;

//==================================================================
// parameter & integer
//==================================================================

enum logic[2:0] {
    IDLE =     3'd0,
    IN1 =      3'd1,
    IN2 =      3'd2,
    ACT_MAX =  3'd3,
    ACT_NEG =  3'd4,
    ACT_HOR =  3'd5,
    ACT_FILT = 3'd6,
    ACT_CONV = 3'd7
    } current_state, next_state;

//==================================================================
// reg & wire
//==================================================================
//wire [31:0] img;
//reg [31:0] img_reg;

reg flag_state;

reg [1:0] img_size, img_size_tmp;
reg [9:0] cnt_img;

reg [7:0] template_reg [0:8];

reg [7:0] img_read_kind;
reg [7:0] img_address;

reg [1:0] cnt_RGB;
reg [7:0] max;
reg [9:0] gray1;
reg [7:0] gray1_div;
reg [7:0] weight, weight_r, weight_rr;
reg [7:0] gray0_reg[0:2], gray1_reg[0:2], gray2_reg[0:2];
reg [1:0] addr_img;
reg [6:0] addr_img_;
reg [6:0] img_limit;

reg [2:0] action_reg [0:7];
reg [3:0] action_size;
reg [2:0] action_index;
reg [2:0] cnt_MP;

reg [2:0] cnt_mp;
reg [4:0] cnt_mp_times;
reg [7:0] cnt_mp_times_addr;
reg [5:0] addr_mp_offset;
reg [5:0] addr_mp_cnt1, addr_mp_cnt2, addr_mp_cnt3;
reg [7:0] ele_addr_mp_input;
wire [7:0] ele_addr_mp;
wire mp_stop;

reg [7:0] element_mp_0[0:3];
reg [7:0] element_mp_1[0:3];

wire [7:0] mp_out_1, mp_out_2;
reg [7:0] mp_out_1_reg, mp_out_2_reg, mp_out_1_reg_r, mp_out_2_reg_r;


reg [7:0] element_0[0:3];
reg [7:0] element_1[0:3];
reg [7:0] element_2[0:3];

reg [3:0] ele_addr_flip_input;


reg [7:0] ele_addr_input;
wire [7:0] ele_addr;

reg [3:0] cnt_flip_addr_8;
reg [5:0] cnt_flip_addr_16;


reg [7:0] filt_item_0[0:4];
reg [7:0] filt_item_1[0:4];
reg [7:0] filt_item_2[0:4];


reg [31:0] data_in_filt_case;
reg [7:0] data_in_filt_0[0:3];
reg [7:0] data_in_filt_1[0:3];
reg [7:0] data_in_filt_2[0:3];
reg [7:0] data_in_filt_3[0:3];

reg [1:0] shift_first, shift_second, shift_third, shift_fourth;
reg shift_big;


reg flag1, flag2, flag1_r, flag2_r, flag3, flag3_r, flag3_rr, flag3_rrr, flag3_rrrr;

reg [6:0] cnt_flag;
reg [2:0] trigger_flag1;
reg [2:0] trigger_flag1_;
reg [5:0] trigger_flag2;
reg [7:0] cnt_write_addr;

reg filt_flag;

reg [1:0] cnt_filt;
reg [5:0] cnt_filt_addr;
reg [3:0] cnt_filt_item;

reg [2:0] addr_filt_flag1_offset1;
reg [3:0] addr_filt_flag1_offset2;
reg [7:0] addr_filt_flag3_offset1, addr_filt_flag3_offset2, addr_filt_flag3_offset3, addr_filt_flag3_offset4;
reg [6:0] trigger_addr_filt_finalwrite; //flag3

reg [3:0] cnt_chg, cnt_chg_r;
wire flag_big_update, flag_small_update, flag_shift_update, padding_shift_update, zero_padding_update1, zero_padding_update2, zero_padding_shift_update;
reg control_big_update, control_small_update, control_padding_shift_update, control_zero_padding_shift_update;
reg control_zero_padding_update1, control_zero_padding_update2;

wire [7:0] filt_out;

reg [6:0] limit_filt_stop;
wire filt_stop;


reg [2:0] cnt_maxpool;
reg [3:0] cnt_maxpool_addr;

wire [31:0] data_out;
wire [15:0] data_out1, data_out2;
reg [31:0] data_in;
wire [15:0] data_in1, data_in2;


reg flag_neg, flag_flip;
reg occur_flip;
wire control_neg, control_flip;
reg control_neg_reg, control_flip_reg;

reg conv_flag;   //1,   1,6    1,5,9,14     *3    *0   3     *0   3   7   11   
reg trigger_conv_flag;
reg conv_flag_control;
reg flag_conv4;


reg [3:0] limit_cnt_chg;

reg [4:0] cnt_output;
reg [8:0] cnt_output_times;
reg [8:0] limit_output_stop;

reg rw_control;

wire [19:0] conv_out; 
reg [19:0] conv_out_reg;
reg bit_output;
reg flag_output;

wire rw_img_control, rw_filt_control, rw_mp_control;

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
            if(in_valid)
                next_state = IN1;
            else if(in_valid2)
                next_state = IN2;
            else
                next_state = IDLE;
        end
        IN1: begin
            if(addr_img_ == img_limit) next_state = IN2;
            else next_state = current_state;
        end
        IN2: begin
			if(in_valid2 == 0) next_state = action_reg[action_index];//action_reg[action_index]
            else next_state = current_state;
        end
		ACT_MAX: begin
			next_state = mp_stop ? IN2 : ACT_MAX;
		end
        ACT_NEG: begin
            next_state = IN2;
        end
        ACT_HOR: begin
            next_state = IN2;
        end
        ACT_FILT: begin
            if(filt_stop) next_state = IN2;
            else next_state = current_state;
        end
        ACT_CONV: begin
            if(cnt_output_times == limit_output_stop) next_state = IDLE;
            else next_state = current_state;
        end
        default: next_state = IDLE;
    endcase
end

//==================================================================
// design
//==================================================================
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        action_reg[0] <= 0;
        action_reg[1] <= 0;
        action_reg[2] <= 0;
        action_reg[3] <= 0;
        action_reg[4] <= 0;
        action_reg[5] <= 0;
        action_reg[6] <= 0;
        action_reg[7] <= 0;
    end
    else if(next_state == IDLE) begin
        action_reg[0] <= 0;
        action_reg[1] <= 0;
        action_reg[2] <= 0;
        action_reg[3] <= 0;
        action_reg[4] <= 0;
        action_reg[5] <= 0;
        action_reg[6] <= 0;
        action_reg[7] <= 0;
    end
    else if(in_valid2) action_reg[action_size] <= action;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) action_index <= 0;
    else if(current_state == IDLE && next_state != IN2) action_index <= 0;
    else if(next_state == IN2 && current_state != IN2) action_index <= action_index + 1;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) cnt_MP <= 1;
    else if(current_state == IDLE) cnt_MP <= 1;
    else if(in_valid2 && action == 3) cnt_MP <= cnt_MP + 1;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) action_size <= 0;
    else if(next_state == IDLE) action_size <= 0;
    else if(in_valid2 && (cnt_MP > img_size) && (action == 3)) action_size <= action_size;
    else if(in_valid2) action_size <= action_size + 1;
end

always@(posedge clk ) begin
    if(in_valid && (cnt_img == 0)) img_size <= image_size;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) img_size_tmp <= 0;
    else if(next_state == IN2 && (current_state == IDLE || current_state == IN1)) img_size_tmp <= img_size;
    else if(current_state == ACT_MAX && next_state == IN2) img_size_tmp <= img_size_tmp - 1;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) cnt_img <= 0;
    else if(next_state == IDLE) cnt_img <= 0;
    else if(current_state == IN2) cnt_img <= 0;
    else if(next_state == IN1) cnt_img <= cnt_img + 1;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) cnt_RGB <= 0;
    else if(current_state == IDLE) cnt_RGB <= 0;
    else if(cnt_RGB == 2) cnt_RGB <= 0;
    else if(current_state == IN1) cnt_RGB <= cnt_RGB + 1;
end

always@(posedge clk ) begin
    if(in_valid && cnt_img < 9) begin
        template_reg[cnt_img] <= template;
    end
end

always @(posedge clk ) begin
    if(current_state == IDLE) flag_state <= 0;
    else if(next_state == IN2 && (current_state == ACT_FILT || current_state == ACT_MAX)) flag_state <= 1;
end

always @(*) begin
    if(flag_state) begin
        img_read_kind = 192;
    end
    else begin
        case(action_reg[0])
            0: begin
                img_read_kind = 0;
            end
            1: begin
                img_read_kind = 64;
            end
            2: begin
                img_read_kind = 128;
            end
            default: img_read_kind = 0;
        endcase
    end
end


always @(posedge clk ) begin
    if(next_state == IDLE) max <= 0;
    else if(in_valid && cnt_RGB == 2) max <= image;
    else if(in_valid && (image > max)) max <= image; 
end

always @(posedge clk ) begin
    gray0_reg[0] <= (in_valid && cnt_RGB == 2) ? max : gray0_reg[0];
    gray0_reg[1] <= (in_valid && cnt_RGB == 2) ? gray0_reg[0] : gray0_reg[1];
    gray0_reg[2] <= (in_valid && cnt_RGB == 2) ? gray0_reg[1] : gray0_reg[2];
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) gray1 <= 0;
    else if(next_state == IDLE) gray1 <= 0;
    else if(in_valid && cnt_RGB == 2) gray1 <= image;
    else gray1 <= gray1 + image; 
end

always @(posedge clk ) begin
    if(cnt_RGB == 2) gray1_div <= gray1 / 3;
end

always @(posedge clk ) begin
    gray1_reg[0] <= (in_valid && cnt_RGB == 0) ? gray1_div : gray1_reg[0];
    gray1_reg[1] <= (in_valid && cnt_RGB == 0) ? gray1_reg[0] : gray1_reg[1];
    gray1_reg[2] <= (in_valid && cnt_RGB == 0) ? gray1_reg[1] : gray1_reg[2];
end

always @(posedge clk ) begin
    if(next_state == IDLE) weight <= 0;
    else if(current_state == IDLE && in_valid) weight <= (image >> 2);
    else if(in_valid && cnt_RGB == 2) weight <= (image >> 2);
    else if(in_valid) weight <= weight + (image >> (cnt_RGB ? 2 : 1));
end

always @(posedge clk ) begin
    weight_r <= weight;
end

always @(posedge clk ) begin
    weight_rr <= weight_r;
end

always @(posedge clk ) begin
    gray2_reg[0] <= (in_valid && cnt_RGB == 1) ? weight_rr : gray2_reg[0];
    gray2_reg[1] <= (in_valid && cnt_RGB == 1) ? gray2_reg[0] : gray2_reg[1];
    gray2_reg[2] <= (in_valid && cnt_RGB == 1) ? gray2_reg[1] : gray2_reg[2];
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) addr_img <= 0;
    else if(current_state == IDLE) addr_img <= 0;
    else if(cnt_img == 11) addr_img <= 0;
    else if(addr_img == 3 && cnt_RGB == 1) addr_img <= 0;
    else if(cnt_RGB == 1) addr_img <= addr_img + 1;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) addr_img_ <= 0;
    else if(current_state == IDLE) addr_img_ <= 0;
    else if(cnt_img == 11) addr_img_ <= 0;
    else if(addr_img == 3 && cnt_RGB == 1) addr_img_ <= addr_img_ + 1;
end

always @(*) begin
    case(img_size)
        0: img_limit = 4;
        1: img_limit = 16;
        2: img_limit = 64;
        default: img_limit = 0;
    endcase
end


//================================================//
//                    ACT_NEG                     //
//================================================//

always @(posedge clk ) begin
    if(current_state == IDLE) flag_neg <= 0;
    else if(current_state == ACT_MAX && next_state == IN2) flag_neg <= 0;
    else if(current_state == ACT_NEG) flag_neg <= !flag_neg;
end

assign control_neg = (next_state == ACT_MAX || next_state == ACT_CONV) && flag_neg;

always @(posedge clk ) begin
    control_neg_reg <= control_neg;
end

//================================================//
//                    ACT_HOR                     //
//================================================//

always @(posedge clk ) begin
    if(current_state == IDLE) flag_flip <= 0;
    else if(current_state == ACT_HOR) flag_flip <= !flag_flip;
end

assign control_flip = (next_state == ACT_CONV) && flag_flip;

always @(posedge clk ) begin
    control_flip_reg <= control_flip;
end


//================================================//
//                    ACT_MAX                     //
//================================================//

assign mp_stop = (img_size_tmp == 2 && cnt_mp_times == 16) || (img_size_tmp == 1 && cnt_mp_times == 4);

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) cnt_mp <= 0;
    else if(current_state == IDLE) cnt_mp <= 0;
    else if(next_state == ACT_MAX && current_state == IN2) cnt_mp <= 5;
    else if(cnt_mp == 6 || cnt_mp == 4) cnt_mp <= 0;
    else cnt_mp <= cnt_mp + 1;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) cnt_mp_times <= 0;
    else if(current_state == IDLE) cnt_mp_times <= 0;
    else if(current_state == IN2) cnt_mp_times <= 0;
    else if(cnt_mp == 6) cnt_mp_times <= 0;
    else if(cnt_mp == 4) cnt_mp_times <= cnt_mp_times + 1;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) cnt_mp_times_addr <= 0;
    else if(current_state == IDLE) cnt_mp_times_addr <= 0;
    else if(cnt_mp == 6) cnt_mp_times_addr <= (flag_state == 0) ? ((action_reg[0] == 0) ? 192 : ((action_reg[0] == 1) ? 128 : 64)) : 0;
    else if(cnt_mp == 4) cnt_mp_times_addr <= cnt_mp_times_addr + 1;
end

always @(posedge clk ) begin
    if(cnt_mp == 1 || cnt_mp == 3 || (cnt_mp == 6 && cnt_mp_times == 0)) begin
        element_mp_0[0] <= (control_neg_reg ? ~data_out[31:24] : data_out[31:24]);
        element_mp_0[1] <= (control_neg_reg ? ~data_out[23:16] : data_out[23:16]);
        element_mp_0[2] <= (control_neg_reg ? ~data_out[15:8]  : data_out[15:8] );
        element_mp_0[3] <= (control_neg_reg ? ~data_out[7:0]   : data_out[7:0]  );
    end
end

always @(posedge clk ) begin
    if(cnt_mp == 2 || cnt_mp == 4 || (cnt_mp == 0 && cnt_mp_times == 0)) begin
        element_mp_1[0] <= (control_neg_reg ? ~data_out[31:24] : data_out[31:24]);
        element_mp_1[1] <= (control_neg_reg ? ~data_out[23:16] : data_out[23:16]);
        element_mp_1[2] <= (control_neg_reg ? ~data_out[15:8]  : data_out[15:8] );
        element_mp_1[3] <= (control_neg_reg ? ~data_out[7:0]   : data_out[7:0]  );
    end
end

always @(*) begin
    case(cnt_mp)
        0: addr_mp_offset = (img_size_tmp == 2) ? addr_mp_cnt1 : addr_mp_cnt3;
        1: addr_mp_offset = (img_size_tmp == 2) ? addr_mp_cnt1 : addr_mp_cnt3;
        2: addr_mp_offset = (img_size_tmp == 2) ? addr_mp_cnt2 : addr_mp_cnt3;
        3: addr_mp_offset = (img_size_tmp == 2) ? addr_mp_cnt2 : addr_mp_cnt3;
        default: addr_mp_offset = 0;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) addr_mp_cnt1 <= 0;
    else if(current_state == IDLE) addr_mp_cnt1 <= 0;
    else if(cnt_mp == 5) addr_mp_cnt1 <= 0;
    else if(cnt_mp == 4 && cnt_mp_times[0]) addr_mp_cnt1 <= addr_mp_cnt1 + 6;
    else if(cnt_mp == 4 && !cnt_mp_times[0]) addr_mp_cnt1 <= addr_mp_cnt1 + 2;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) addr_mp_cnt2 <= 0;
    else if(current_state == IDLE) addr_mp_cnt2 <= 0;
    else if(cnt_mp == 5) addr_mp_cnt2 <= 0;
    else if(cnt_mp == 4 && cnt_mp_times[0]) addr_mp_cnt2 <= addr_mp_cnt2 + 2;
    else if(cnt_mp == 4 && !cnt_mp_times[0]) addr_mp_cnt2 <= addr_mp_cnt2 + 6;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) addr_mp_cnt3 <= 0;
    else if(current_state == IDLE) addr_mp_cnt3 <= 0;
    else if(cnt_mp == 5) addr_mp_cnt3 <= 0;
    else if(cnt_mp == 4) addr_mp_cnt3 <= addr_mp_cnt3 + 4;
end

always @(*) begin
    case(cnt_mp)
        0: ele_addr_mp_input = 1;
        1: ele_addr_mp_input = (img_size_tmp == 2) ? 5 : 3;
        2: ele_addr_mp_input = (img_size_tmp == 2) ? 2 : 4;
        3: ele_addr_mp_input = 6;
        4: ele_addr_mp_input = cnt_mp_times_addr;
        5: ele_addr_mp_input = 0;
        6: ele_addr_mp_input = (img_size_tmp == 2) ? 4 : 2;
        default: ele_addr_mp_input = 0;
    endcase
end

assign ele_addr_mp = ele_addr_mp_input + (cnt_mp_times == 0 ? 0 : addr_mp_offset);

MP mp1(.s0(element_mp_0[0]),.s1(element_mp_0[1]),.s2(element_mp_1[0]),.s3(element_mp_1[1]),.out(mp_out_1));
MP mp2(.s0(element_mp_0[2]),.s1(element_mp_0[3]),.s2(element_mp_1[2]),.s3(element_mp_1[3]),.out(mp_out_2));

always @(posedge clk ) begin
    if((cnt_mp == 1 && cnt_mp_times == 0) || cnt_mp == 0 || cnt_mp == 3) mp_out_1_reg <= mp_out_1;
end

always @(posedge clk ) begin
    if((cnt_mp == 2 && cnt_mp_times == 0) || cnt_mp == 1) mp_out_1_reg_r <= mp_out_1_reg;
end

always @(posedge clk ) begin
    if((cnt_mp == 1 && cnt_mp_times == 0) || cnt_mp == 0 || cnt_mp == 3) mp_out_2_reg <= mp_out_2;
end

always @(posedge clk ) begin
    if((cnt_mp == 2 && cnt_mp_times == 0) || cnt_mp == 1) mp_out_2_reg_r <= mp_out_2_reg;
end

//================================================//
//                    ACT_FILT                    //
//================================================//

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) cnt_filt <= 0;
    else if(current_state == IDLE) cnt_filt <= 0;
    else if(current_state == IN2) cnt_filt <= 0;
    else if(current_state == ACT_FILT || (current_state == ACT_CONV && conv_flag)) cnt_filt <= cnt_filt + 1;
end

always @(posedge clk ) begin
    if(cnt_filt == 1) begin
        element_0[0] <= control_flip_reg ? (control_neg_reg ? ~data_out[7:0]   : data_out[7:0]  ) : (control_neg_reg ? ~data_out[31:24] : data_out[31:24]);
        element_0[1] <= control_flip_reg ? (control_neg_reg ? ~data_out[15:8]  : data_out[15:8] ) : (control_neg_reg ? ~data_out[23:16] : data_out[23:16]);
        element_0[2] <= control_flip_reg ? (control_neg_reg ? ~data_out[23:16] : data_out[23:16]) : (control_neg_reg ? ~data_out[15:8]  : data_out[15:8] );
        element_0[3] <= control_flip_reg ? (control_neg_reg ? ~data_out[31:24] : data_out[31:24]) : (control_neg_reg ? ~data_out[7:0]   : data_out[7:0]  );
    end
end

always @(posedge clk ) begin
    if(cnt_filt == 2) begin
        element_1[0] <= control_flip_reg ? (control_neg_reg ? ~data_out[7:0]   : data_out[7:0]  ) : (control_neg_reg ? ~data_out[31:24] : data_out[31:24]);
        element_1[1] <= control_flip_reg ? (control_neg_reg ? ~data_out[15:8]  : data_out[15:8] ) : (control_neg_reg ? ~data_out[23:16] : data_out[23:16]);
        element_1[2] <= control_flip_reg ? (control_neg_reg ? ~data_out[23:16] : data_out[23:16]) : (control_neg_reg ? ~data_out[15:8]  : data_out[15:8] );
        element_1[3] <= control_flip_reg ? (control_neg_reg ? ~data_out[31:24] : data_out[31:24]) : (control_neg_reg ? ~data_out[7:0]   : data_out[7:0]  );
    end
end

always @(posedge clk ) begin
    if(cnt_filt == 3) begin
        element_2[0] <= control_flip_reg ? (control_neg_reg ? ~data_out[7:0]   : data_out[7:0]  ) : (control_neg_reg ? ~data_out[31:24] : data_out[31:24]);
        element_2[1] <= control_flip_reg ? (control_neg_reg ? ~data_out[15:8]  : data_out[15:8] ) : (control_neg_reg ? ~data_out[23:16] : data_out[23:16]);
        element_2[2] <= control_flip_reg ? (control_neg_reg ? ~data_out[23:16] : data_out[23:16]) : (control_neg_reg ? ~data_out[15:8]  : data_out[15:8] );
        element_2[3] <= control_flip_reg ? (control_neg_reg ? ~data_out[31:24] : data_out[31:24]) : (control_neg_reg ? ~data_out[7:0]   : data_out[7:0]  );
    end
end

always @(posedge clk ) begin
    if(current_state == IN2) flag_conv4 <= 0;
    else if(cnt_output == 8) flag_conv4 <= 1;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) cnt_chg <= 0;
    else if(current_state == IDLE) cnt_chg <= 0;
    else if((next_state == ACT_CONV || next_state == ACT_FILT) && current_state == IN2) cnt_chg <= limit_cnt_chg;
    else if(cnt_chg == limit_cnt_chg && filt_flag && (current_state == ACT_FILT || (current_state == ACT_CONV && cnt_output == 8 && (flag_conv4 || img_size_tmp != 0)))) cnt_chg <= 0;
    else if((current_state == ACT_CONV && cnt_output == 8 && (flag_conv4 || img_size_tmp != 0)) || (current_state == ACT_FILT && filt_flag)) cnt_chg <= cnt_chg + 1;
end

always @(posedge clk ) begin
    if((next_state == ACT_CONV || next_state == ACT_FILT) && current_state == IN2) cnt_chg_r <= limit_cnt_chg;
    else if(img_size_tmp == 0 && cnt_filt == 3 && cnt_flag == 0) cnt_chg_r <= 2;
    else cnt_chg_r <= cnt_chg;
end

always @(*) begin
    case(img_size_tmp)
        0: control_big_update = cnt_chg == 3;
        1,2: control_big_update = cnt_chg == 0;
        default: control_big_update = 0;
    endcase
end

assign flag_big_update = (cnt_chg[0] != cnt_chg_r[0]) && control_big_update;


always @(*) begin
    case(img_size_tmp)
        0: control_small_update = 0;  //never occur
        1: control_small_update = cnt_chg == 3; 
        2: control_small_update = cnt_chg == 3 || cnt_chg == 7 || cnt_chg == 11;
        default: control_small_update = 0;
    endcase
end

assign flag_small_update = (cnt_chg[0] != cnt_chg_r[0]) && control_small_update;


assign flag_shift_update = (cnt_chg[0] != cnt_chg_r[0]) && !(control_big_update || control_small_update);

always @(*) begin
    case(img_size_tmp)
        0: control_padding_shift_update = 0;
        1: control_padding_shift_update = cnt_chg == 4; 
        2: control_padding_shift_update = cnt_chg == 4 || cnt_chg == 8 || cnt_chg == 12;
        default: control_padding_shift_update = 0;
    endcase
end

assign padding_shift_update = (cnt_chg[0] != cnt_chg_r[0]) && control_padding_shift_update;

always @(*) begin
    case(img_size_tmp)
        0: control_zero_padding_update1 = cnt_flag == 1;
        1: control_zero_padding_update1 = (cnt_flag == 1 || cnt_flag == 2); 
        2: control_zero_padding_update1 = (cnt_flag == 1 || cnt_flag == 2 || cnt_flag == 3 || cnt_flag == 4);
        default: control_zero_padding_update1 = 0;
    endcase
end

assign zero_padding_update1 = control_zero_padding_update1 && (current_state == ACT_CONV);

always @(*) begin
    case(img_size_tmp)
        0: control_zero_padding_update2 = ((cnt_flag == 4 && cnt_chg != 2) || cnt_flag == 5);
        1: control_zero_padding_update2 = ((cnt_flag == 15 && cnt_chg != 7) || cnt_flag == 16);
        2: control_zero_padding_update2 = ((cnt_flag == 61 && (cnt_chg == 0 || cnt_chg == 1)) || cnt_flag == 62 || cnt_flag == 63 || cnt_flag == 64);
        default: control_zero_padding_update2 = 0;
    endcase
end
assign zero_padding_update2 = control_zero_padding_update2 && (current_state == ACT_CONV);

always @(*) begin
    case(img_size_tmp)
        0: control_zero_padding_shift_update = cnt_chg == 0;
        1: control_zero_padding_shift_update = cnt_chg == 5; 
        2: control_zero_padding_shift_update = cnt_chg == 13;
        default: control_zero_padding_shift_update = 0;
    endcase
end

assign zero_padding_shift_update = (cnt_chg[0] != cnt_chg_r[0]) && control_zero_padding_shift_update && (current_state == ACT_CONV);

always @(posedge clk ) begin
    filt_item_0[0] <= zero_padding_update1 ? 0 : (flag_shift_update ? filt_item_0[1] : (flag_small_update ? filt_item_0[1] : (flag_big_update ? ((current_state == ACT_CONV) ? 0 : element_0[0]) : filt_item_0[0])));
    filt_item_0[1] <= zero_padding_update1 ? 0 : (flag_shift_update ? filt_item_0[2] : (flag_small_update ? filt_item_0[2] : (flag_big_update ? element_0[0] : filt_item_0[1])));
    filt_item_0[2] <= zero_padding_update1 ? 0 : (flag_shift_update ? filt_item_0[3] : (flag_small_update ? element_0[0]   : (flag_big_update ? element_0[1] : filt_item_0[2])));
    filt_item_0[3] <= zero_padding_update1 ? 0 : (flag_shift_update ? filt_item_0[4] : (flag_small_update ? element_0[1]   : (flag_big_update ? element_0[2] : filt_item_0[3])));
    filt_item_0[4] <= zero_padding_update1 ? 0 : (padding_shift_update ? element_0[3] : (zero_padding_shift_update ? 0 : (flag_small_update ? element_0[2] : (flag_big_update ? element_0[3] : filt_item_0[4]))));
end

always @(posedge clk ) begin
    filt_item_1[0] <= flag_shift_update ? filt_item_1[1]  : (flag_small_update ? filt_item_1[1] : (flag_big_update ? ((current_state == ACT_CONV) ? 0 : element_1[0]) : filt_item_1[0]));
    filt_item_1[1] <= flag_shift_update ? filt_item_1[2]  : (flag_small_update ? filt_item_1[2] : (flag_big_update ? element_1[0] : filt_item_1[1]));
    filt_item_1[2] <= flag_shift_update ? filt_item_1[3]  : (flag_small_update ? element_1[0]   : (flag_big_update ? element_1[1] : filt_item_1[2]));
    filt_item_1[3] <= flag_shift_update ? filt_item_1[4]  : (flag_small_update ? element_1[1]   : (flag_big_update ? element_1[2] : filt_item_1[3]));
    filt_item_1[4] <= padding_shift_update ? element_1[3] : (zero_padding_shift_update ? 0 : (flag_small_update ? element_1[2]  : (flag_big_update ? element_1[3] : filt_item_1[4])));
end

always @(posedge clk ) begin
    filt_item_2[0] <= zero_padding_update2 ? 0 : (flag_shift_update ? filt_item_2[1]  : (flag_small_update ? filt_item_2[1] : (flag_big_update ? ((current_state == ACT_CONV) ? 0 : element_2[0]) : filt_item_2[0])));
    filt_item_2[1] <= zero_padding_update2 ? 0 : (flag_shift_update ? filt_item_2[2]  : (flag_small_update ? filt_item_2[2] : (flag_big_update ? element_2[0] : filt_item_2[1])));
    filt_item_2[2] <= zero_padding_update2 ? 0 : (flag_shift_update ? filt_item_2[3]  : (flag_small_update ? element_2[0]   : (flag_big_update ? element_2[1] : filt_item_2[2])));
    filt_item_2[3] <= zero_padding_update2 ? 0 : (flag_shift_update ? filt_item_2[4]  : (flag_small_update ? element_2[1]   : (flag_big_update ? element_2[2] : filt_item_2[3])));
    filt_item_2[4] <= zero_padding_update2 ? 0 : (padding_shift_update ? element_2[3] : (zero_padding_shift_update ? 0 : (flag_small_update ? element_2[2]   : (flag_big_update ? element_2[3] : filt_item_2[4]))));
end

filter filt(.s0(filt_item_0[0]),.s1(filt_item_0[1]),.s2(filt_item_0[2]),.s3(filt_item_1[0]),.s4(filt_item_1[1]),.s5(filt_item_1[2]),.s6(filt_item_2[0]),.s7(filt_item_2[1]),.s8(filt_item_2[2]),.out(filt_out));

always @(*) begin
    case(img_size_tmp)
        0: shift_first = 0;
        default: shift_first = 1;
    endcase
end
always @(*) begin
    case(img_size_tmp)
        0: shift_second = 1;
        default: shift_second = 2;
    endcase
end
always @(*) begin
    case(img_size_tmp)
        0: shift_third = 2;
        default: shift_third = 3;
    endcase
end
always @(*) begin
    case(img_size_tmp)
        0: shift_fourth = 3;
        default: shift_fourth = 0;
    endcase
end

always @(*) begin
    case(img_size_tmp)
        0: shift_big = 0;
        default: shift_big = 1;
    endcase
end

always @(posedge clk ) begin
    data_in_filt_0[0] <= (cnt_chg[1:0] == shift_first && cnt_flag != limit_filt_stop)  ? filt_out : data_in_filt_0[0];
    data_in_filt_0[1] <= (cnt_chg[1:0] == shift_second && cnt_flag != limit_filt_stop) ? filt_out : data_in_filt_0[1];
    data_in_filt_0[2] <= (cnt_chg[1:0] == shift_third)                                 ? filt_out : data_in_filt_0[2];
    data_in_filt_0[3] <= (cnt_chg[1:0] == shift_fourth)                                ? filt_out : data_in_filt_0[3];
end

always @(posedge clk ) begin
    data_in_filt_1[0] <= (((cnt_flag != 5 && img_size_tmp == 0) || img_size_tmp == 1 || img_size_tmp == 2) && cnt_chg[1:0] == shift_big) ? data_in_filt_0[0] : data_in_filt_1[0];
    data_in_filt_1[1] <= (((cnt_flag != 5 && img_size_tmp == 0) || img_size_tmp == 1 || img_size_tmp == 2) && cnt_chg[1:0] == shift_big) ? data_in_filt_0[1] : data_in_filt_1[1];
    data_in_filt_1[2] <= (((cnt_flag != 5 && img_size_tmp == 0) || img_size_tmp == 1 || img_size_tmp == 2) && cnt_chg[1:0] == shift_big) ? data_in_filt_0[2] : data_in_filt_1[2];
    data_in_filt_1[3] <= (((cnt_flag != 5 && img_size_tmp == 0) || img_size_tmp == 1 || img_size_tmp == 2) && cnt_chg[1:0] == shift_big) ? data_in_filt_0[3] : data_in_filt_1[3];
end

always @(posedge clk ) begin
    data_in_filt_2[0] <= (cnt_chg[1:0] == shift_big) ? data_in_filt_1[0] : data_in_filt_2[0];
    data_in_filt_2[1] <= (cnt_chg[1:0] == shift_big) ? data_in_filt_1[1] : data_in_filt_2[1];
    data_in_filt_2[2] <= (cnt_chg[1:0] == shift_big) ? data_in_filt_1[2] : data_in_filt_2[2];
    data_in_filt_2[3] <= (cnt_chg[1:0] == shift_big) ? data_in_filt_1[3] : data_in_filt_2[3];
end

always @(posedge clk ) begin
    data_in_filt_3[0] <= (cnt_chg[1:0] == shift_big) ? data_in_filt_2[0] : data_in_filt_3[0];
    data_in_filt_3[1] <= (cnt_chg[1:0] == shift_big) ? data_in_filt_2[1] : data_in_filt_3[1];
    data_in_filt_3[2] <= (cnt_chg[1:0] == shift_big) ? data_in_filt_2[2] : data_in_filt_3[2];
    data_in_filt_3[3] <= (cnt_chg[1:0] == shift_big) ? data_in_filt_2[3] : data_in_filt_3[3];
end


always @(*) begin
    case(cnt_filt)
        0: data_in_filt_case = {data_in_filt_3[0],data_in_filt_3[1],data_in_filt_3[2],data_in_filt_3[3]};
        1: data_in_filt_case = {data_in_filt_2[0],data_in_filt_2[1],data_in_filt_2[2],data_in_filt_2[3]};
        2: data_in_filt_case = {data_in_filt_1[0],data_in_filt_1[1],data_in_filt_1[2],data_in_filt_1[3]};
        3: data_in_filt_case = (cnt_flag == limit_filt_stop) ? {data_in_filt_0[0],data_in_filt_0[1],data_in_filt_0[2],data_in_filt_0[3]} : {data_in_filt_3[0],data_in_filt_3[1],data_in_filt_3[2],data_in_filt_3[3]};
        default: data_in_filt_case = 0;
    endcase
end

always @(*) begin
    case(img_size_tmp)
        0: limit_cnt_chg = 3;
        1: limit_cnt_chg = 7;
        2: limit_cnt_chg = 15;
        default: limit_cnt_chg = 0;
    endcase
end

always @(posedge clk ) begin
    if(current_state == IDLE) filt_flag <= 0;
    else if(current_state == IN2) filt_flag <= 0;
    else if((current_state == ACT_FILT || current_state == ACT_CONV) && cnt_output == 7) filt_flag <= 1;
end


always @(*) begin
    case(img_size_tmp)
        0: addr_filt_flag1_offset1 = 1;
        1: addr_filt_flag1_offset1 = 2;
        2: addr_filt_flag1_offset1 = 4;
        default: addr_filt_flag1_offset1 = 0;
    endcase
end



always @(*) begin
    case(img_size_tmp)
        0: addr_filt_flag1_offset2 = 2;
        1: addr_filt_flag1_offset2 = 4;
        2: addr_filt_flag1_offset2 = 8;
        default: addr_filt_flag1_offset2 = 0;
    endcase
end



always @(*) begin
    case(img_size_tmp)
        0: addr_filt_flag3_offset1 = (flag_state) ? 0 :  (action_reg[0] == 0) ? 192 : (action_reg[0] == 1 ? 128 : 64);
        1: addr_filt_flag3_offset1 = (flag_state) ? 12 : (action_reg[0] == 0) ? 204 : (action_reg[0] == 1 ? 140 : 76);
        2: addr_filt_flag3_offset1 = (flag_state) ? 60 : (action_reg[0] == 0) ? 252 : (action_reg[0] == 1 ? 188 : 124);
        default: addr_filt_flag3_offset1 = 0;
    endcase
end

always @(*) begin
    case(img_size_tmp)
        0: addr_filt_flag3_offset2 = (flag_state) ? 1 :  (action_reg[0] == 0) ? 193 : (action_reg[0] == 1 ? 129 : 65);
        1: addr_filt_flag3_offset2 = (flag_state) ? 13 : (action_reg[0] == 0) ? 205 : (action_reg[0] == 1 ? 141 : 77);
        2: addr_filt_flag3_offset2 = (flag_state) ? 61 : (action_reg[0] == 0) ? 253 : (action_reg[0] == 1 ? 189 : 125);
        default: addr_filt_flag3_offset2 = 0;
    endcase
end

always @(*) begin
    case(img_size_tmp)
        0: addr_filt_flag3_offset3 = (flag_state) ? 2 :  (action_reg[0] == 0) ? 194 : (action_reg[0] == 1 ? 130 : 66);
        1: addr_filt_flag3_offset3 = (flag_state) ? 14 : (action_reg[0] == 0) ? 206 : (action_reg[0] == 1 ? 142 : 78);
        2: addr_filt_flag3_offset3 = (flag_state) ? 62 : (action_reg[0] == 0) ? 254 : (action_reg[0] == 1 ? 190 : 126);
        default: addr_filt_flag3_offset3 = 0;
    endcase
end

always @(*) begin
    case(img_size_tmp)
        0: addr_filt_flag3_offset4 = (flag_state) ? 3 :  (action_reg[0] == 0) ? 195 : (action_reg[0] == 1 ? 131 : 67);
        1: addr_filt_flag3_offset4 = (flag_state) ? 15 : (action_reg[0] == 0) ? 207 : (action_reg[0] == 1 ? 143 : 79);
        2: addr_filt_flag3_offset4 = (flag_state) ? 63 : (action_reg[0] == 0) ? 255 : (action_reg[0] == 1 ? 191 : 127);
        default: addr_filt_flag3_offset4 = 0;
    endcase
end

always @(*) begin
    case(img_size_tmp)
        0: trigger_addr_filt_finalwrite = 4;
        1: trigger_addr_filt_finalwrite = 16;
        2: trigger_addr_filt_finalwrite = 64;
        default: trigger_addr_filt_finalwrite = 0;
    endcase
end

always @(*) begin
    case(img_size_tmp)
        0: trigger_flag1 = 0;
        1: trigger_flag1 = 2;
        2: trigger_flag1 = 4;
        default: trigger_flag1 = 0;
    endcase
end

always @(*) begin
    case(img_size_tmp)
        0: trigger_flag1_ = 0;
        1: trigger_flag1_ = 1;
        2: trigger_flag1_ = 3;
        default: trigger_flag1_ = 0;
    endcase
end

always @(*) begin
    case(img_size_tmp)
        0: trigger_flag2 = 3;
        1: trigger_flag2 = 14;
        2: trigger_flag2 = 60;
        default: trigger_flag2 = 0;
    endcase
end


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) cnt_flag <= 0;
    else if(current_state == IDLE) cnt_flag <= 0;
    else if(current_state == IN2) cnt_flag <= 0;
    else if(cnt_filt == 3) cnt_flag <= cnt_flag + 1;
end

always @(posedge clk ) begin
    if(current_state == IDLE) flag1 <= 0;
    else if(current_state == IN2) flag1 <= 0;
    else if(cnt_filt == 2 && cnt_flag == trigger_flag1_) flag1 <= 1;
end

always @(posedge clk ) begin
    flag1_r <= flag1;
end

always @(posedge clk ) begin
    if(current_state == IDLE) flag2 <= 0;
    else if(current_state == IN2) flag2 <= 0;
    else if(cnt_flag == trigger_flag2) flag2 <= 1;
end


always @(posedge clk ) begin
    if(current_state == IDLE) flag3 <= 0;
    else if(current_state == IN2) flag3 <= 0;
    else if(cnt_filt == 3 && cnt_flag == trigger_addr_filt_finalwrite) flag3 <= 1;
end

always @(posedge clk ) begin
    flag3_r <= (current_state == IN2) ? 0 : flag3;
    flag3_rr <= (current_state == IN2) ? 0 : flag3_r;
    flag3_rrr <= (current_state == IN2) ? 0 : flag3_rr;
    flag3_rrrr <= (current_state == IN2) ? 0 : flag3_rrr;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) cnt_write_addr <= 0;
    else if(current_state == IN2) cnt_write_addr <= (flag_state == 0) ? ((action_reg[0] == 0) ? 192 : ((action_reg[0] == 1) ? 128 : 64)) : 0;
    else if(cnt_filt == 0 && cnt_flag > 4) cnt_write_addr <= cnt_write_addr + 1;
end

always @(*) begin
    case(cnt_filt)
        0:  ele_addr_input = flag3 ? addr_filt_flag3_offset1 : 0;
        1:  ele_addr_input = (flag3 ? addr_filt_flag3_offset2 : (flag2 ? addr_filt_flag1_offset1 : (flag1_r ? addr_filt_flag1_offset1 : 0)));
        2:  ele_addr_input = (flag3 ? addr_filt_flag3_offset3 : (flag2 ? addr_filt_flag1_offset1 : (flag1_r ? addr_filt_flag1_offset2 : addr_filt_flag1_offset1)));
        3:  ele_addr_input = flag3 ? addr_filt_flag3_offset4 : cnt_write_addr;
        default: ele_addr_input = 0;
    endcase
end



always @(posedge clk or negedge rst_n) begin
    if(!rst_n) cnt_filt_addr <= 0;
    else if(current_state == IDLE || current_state == IN2) cnt_filt_addr <= 0;
    else if(flag1 != flag1_r) cnt_filt_addr <= 0;
    else if(cnt_filt == 3) cnt_filt_addr <= cnt_filt_addr + 1;
end




//================================================//
//                      FLIP                      //
//================================================//

always @(*) begin
    case(cnt_filt)
        1:  ele_addr_flip_input = (flag2 ? addr_filt_flag1_offset1 : (flag1_r ? addr_filt_flag1_offset1 : 0));
        2:  ele_addr_flip_input = (flag2 ? addr_filt_flag1_offset1 : (flag1_r ? addr_filt_flag1_offset2 : addr_filt_flag1_offset1));
        default: ele_addr_flip_input = 0;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) cnt_flip_addr_8 <= 0;
    else if(current_state == IDLE) cnt_flip_addr_8 <= 0;
    else if(current_state == IN2 && next_state == ACT_CONV) cnt_flip_addr_8 <= 1;
    else if(flag1 != flag1_r) cnt_flip_addr_8 <= 1;
    else if(cnt_filt == 3 && ~cnt_flag[0]) cnt_flip_addr_8 <= cnt_flip_addr_8 - 1;
    else if(cnt_filt == 3 && cnt_flag[0]) cnt_flip_addr_8 <= cnt_flip_addr_8 + 3;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) cnt_flip_addr_16 <= 0;
    else if(current_state == IDLE) cnt_flip_addr_16 <= 0;
    else if(current_state == IN2 && next_state == ACT_CONV) cnt_flip_addr_16 <= 3;
    else if(flag1 != flag1_r) cnt_flip_addr_16 <= 3;
    else if(cnt_filt == 3 && cnt_flag[1:0] == 3) cnt_flip_addr_16 <= cnt_flip_addr_16 + 7;
    else if(cnt_filt == 3) cnt_flip_addr_16 <= cnt_flip_addr_16 - 1;
end

always @(posedge clk ) begin
    if(current_state == IDLE) occur_flip <= 0;
    else if (current_state == IN2 && next_state == ACT_CONV) occur_flip <= flag_flip && (img_size_tmp != 0);
end

assign ele_addr = ele_addr_input + ((cnt_filt == 3 || flag3) ? 0 : (occur_flip ? (img_size_tmp == 1 ? cnt_flip_addr_8 : cnt_flip_addr_16) : cnt_filt_addr));

always @(*) begin
    case(img_size_tmp)
        0: limit_filt_stop = 5;
        1: limit_filt_stop = 17;
        2: limit_filt_stop = 65;
        default: limit_filt_stop = 0;
    endcase
end


assign filt_stop = (cnt_flag == limit_filt_stop) && cnt_filt == 3;








always @(posedge clk or negedge rst_n) begin
    if(!rst_n) cnt_output <= 0;
    else if(current_state == IDLE) cnt_output <= 0;
    else if(next_state == IN2) cnt_output <= 0;
    else if((next_state == ACT_CONV || next_state == ACT_FILT) && current_state == IN2) cnt_output <= 4;
    else if(cnt_output == 19) cnt_output <= 0;
    else cnt_output <= cnt_output + 1;
end

always @(*) begin
    case(img_size_tmp)
        0: trigger_conv_flag = cnt_chg == 1;
        1: trigger_conv_flag = cnt_chg == 1 || cnt_chg == 6;
        2: trigger_conv_flag = cnt_chg == 1 || cnt_chg == 5 || cnt_chg == 9 || cnt_chg == 14;
        default: trigger_conv_flag = 0;
    endcase
end



always @(posedge clk ) begin
    if(current_state == IDLE) conv_flag_control <= 0;
    else if(next_state == ACT_CONV && current_state == IN2) conv_flag_control <= 1;
    else if(cnt_filt == 2) conv_flag_control <= 0;
end

always @(posedge clk ) begin
    if(current_state == IDLE) conv_flag <= 0;
    else if(cnt_output == 12 || (cnt_output == 7 && conv_flag == 1)) conv_flag <= 0;
    else if((cnt_output == 8 && trigger_conv_flag) || (next_state == ACT_CONV && current_state == IN2) || conv_flag_control) conv_flag <= 1;
end

CORRELATION cor(.clk(clk),.cnt(cnt_output),.s0(filt_item_0[0]),.s1(filt_item_0[1]),.s2(filt_item_0[2]),.s3(filt_item_1[0]),.s4(filt_item_1[1]),.s5(filt_item_1[2]),.s6(filt_item_2[0]),.s7(filt_item_2[1]),.s8(filt_item_2[2]),.t0(template_reg[0]),.t1(template_reg[1]),.t2(template_reg[2]),.t3(template_reg[3]),.t4(template_reg[4]),.t5(template_reg[5]),.t6(template_reg[6]),.t7(template_reg[7]),.t8(template_reg[8]),.out(conv_out));


always @(*) begin
    case(current_state)
        IN1: begin
            case(cnt_RGB)
                2: img_address = addr_img_;
                0: img_address = addr_img_ + 64;
                1: img_address = addr_img_ + 128;
                default: img_address = 0;
            endcase
        end
        ACT_MAX: begin
            img_address = img_read_kind + ele_addr_mp;
        end
        ACT_FILT, ACT_CONV: begin
            img_address = img_read_kind + ele_addr;
        end
        default: img_address = 0;
    endcase
end

always @(*) begin
    case(current_state)
        IN1: begin
            case(cnt_RGB)
                2: data_in = {gray0_reg[2],gray0_reg[1],gray0_reg[0],max};
                0: data_in = {gray1_reg[2],gray1_reg[1],gray1_reg[0],gray1_div};
                1: data_in = {gray2_reg[2],gray2_reg[1],gray2_reg[0],weight_rr};
                default : data_in = 0;
            endcase
        end
        ACT_FILT: begin
            data_in = data_in_filt_case;
        end
        ACT_MAX: begin
            data_in = {mp_out_1_reg_r, mp_out_2_reg_r, mp_out_1_reg, mp_out_2_reg};
        end
        default: data_in = 0;
    endcase
end

assign rw_img_control = (cnt_img > 11) && (addr_img_ < img_limit) && (addr_img == 0);

assign rw_filt_control = (current_state == ACT_FILT) && ((cnt_flag > 3 && cnt_flag < trigger_addr_filt_finalwrite && cnt_filt == 3) || (flag3 ^ flag3_rrrr));

assign rw_mp_control = (current_state == ACT_MAX) && (cnt_mp == 4);

always @(*) begin
    if(rw_img_control || rw_filt_control || rw_mp_control) rw_control = 0;
    else rw_control = 1;
end

assign data_out = {data_out1, data_out2};
assign data_in1 = data_in[31:16];
assign data_in2 = data_in[15:0];

sram_256x16_inst SRAM1(.A(img_address), .DO(data_out1), .DI(data_in1), .CK(clk), .WEB(rw_control));
sram_256x16_inst SRAM2(.A(img_address), .DO(data_out2), .DI(data_in2), .CK(clk), .WEB(rw_control));


//================================================//
//                     OUTPUT                     //
//================================================//

always @(*) begin
    case(img_size_tmp)
        0: limit_output_stop = 17;
        1: limit_output_stop = 65;
        2: limit_output_stop = 257;
        default: limit_output_stop = 0;
    endcase
end

always @(posedge clk ) begin
    if(current_state == IDLE) conv_out_reg <= 0;
    else if(cnt_output == 0) conv_out_reg <= conv_out;
    else conv_out_reg <= (conv_out_reg << 1);
end

always @(posedge clk ) begin
    bit_output <= conv_out_reg[19];
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) cnt_output_times <= 0;
    else if(current_state == IDLE) cnt_output_times <= 0;
    else if(current_state == ACT_CONV && cnt_output == 0) cnt_output_times <= cnt_output_times + 1;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) flag_output <= 0;
    else if(current_state == ACT_CONV && cnt_output_times == limit_output_stop) flag_output <= 0;
    else if(current_state == ACT_CONV && cnt_output == 1) flag_output <= 1;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) out_valid <= 0;
    else out_valid <= flag_output;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) out_value <= 0;
    else if(current_state == IDLE) out_value <= 0;
    else if(flag_output) out_value <= bit_output;
end


endmodule

module filter(
    input [7:0] s0,s1,s2,s3,s4,s5,s6,s7,s8,
    output [7:0] out
);

reg [7:0] sp1[0:8], sp2[0:8], sp3[0:8], sp4[0:8], sp5[0:8], sp6[0:8], sp7[0:8];
reg [7:0] tmp[0:6];

/* [(0,3),(1,7),(2,5),(4,8)]
[(0,7),(2,4),(3,8),(5,6)]
[(0,2),(1,3),(4,5),(7,8)]
[(1,4),(3,6),(5,7)]
[(0,1),(2,4),(3,5),(6,8)]
[(2,3),(4,5),(6,7)]
[(1,2),(3,4),(5,6)] */
    
//[(0,3),(1,7),(2,5),(4,8)]
always @(*) begin
    sp1[6] = s6;
    if(s0 > s3) begin
        tmp[0] = s0;
        sp1[0] = s3;
        sp1[3] = tmp[0];
    end
    else begin
        sp1[0] = s0;
        sp1[3] = s3;
    end
    if(s1 > s7) begin
        tmp[0] = s1;
        sp1[1] = s7;
        sp1[7] = tmp[0];
    end
    else begin
        sp1[1] = s1;
        sp1[7] = s7;
    end
    if(s2 > s5) begin
        tmp[0] = s2;
        sp1[2] = s5;
        sp1[5] = tmp[0];
    end
    else begin
        sp1[2] = s2;
        sp1[5] = s5;
    end
    if(s4 > s8) begin
        tmp[0] = s4;
        sp1[4] = s8;
        sp1[8] = tmp[0];
    end
    else begin
        sp1[4] = s4;
        sp1[8] = s8;
    end
end


//[(0,7),(2,4),(3,8),(5,6)]

always @(*) begin
    sp2[1] = sp1[1];
    if(sp1[0] > sp1[7]) begin
        tmp[1] = sp1[0];
        sp2[0] = sp1[7];
        sp2[7] = tmp[1];
    end
    else begin
        sp2[0] = sp1[0];
        sp2[7] = sp1[7];
    end
    if(sp1[2] > sp1[4]) begin
        tmp[1] = sp1[2];
        sp2[2] = sp1[4];
        sp2[4] = tmp[1];
    end
    else begin
        sp2[2] = sp1[2];
        sp2[4] = sp1[4];
    end
    if(sp1[3] > sp1[8]) begin
        tmp[1] = sp1[3];
        sp2[3] = sp1[8];
        sp2[8] = tmp[1];
    end
    else begin
        sp2[3] = sp1[3];
        sp2[8] = sp1[8];
    end
    if(sp1[5] > sp1[6]) begin
        tmp[1] = sp1[5];
        sp2[5] = sp1[6];
        sp2[6] = tmp[1];
    end
    else begin
        sp2[5] = sp1[5];
        sp2[6] = sp1[6];
    end
end

//[(0,2),(1,3),(4,5),(7,8)]


always @(*) begin
    sp3[6] = sp2[6];
    if(sp2[0] > sp2[2]) begin
        tmp[2] = sp2[0]; 
        sp3[0] = sp2[2];
        sp3[2] = tmp[2];
    end
    else begin
        sp3[0] = sp2[0];
        sp3[2] = sp2[2];
    end
    if(sp2[1] > sp2[3]) begin
        tmp[2] = sp2[1];
        sp3[1] = sp2[3];
        sp3[3] = tmp[2];
    end
    else begin
        sp3[1] = sp2[1];
        sp3[3] = sp2[3];
    end
    if(sp2[4] > sp2[5]) begin
        tmp[2] = sp2[4];
        sp3[4] = sp2[5];
        sp3[5] = tmp[2];
    end
    else begin
        sp3[4] = sp2[4];
        sp3[5] = sp2[5];
    end
    if(sp2[7] > sp2[8]) begin
        tmp[2] = sp2[7];
        sp3[7] = sp2[8];
        sp3[8] = tmp[2];
    end
    else begin
        sp3[7] = sp2[7];
        sp3[8] = sp2[8];
    end
end



//[(1,4),(3,6),(5,7)]

always @(*) begin
    sp4[0] = sp3[0];
    sp4[2] = sp3[2];
    sp4[8] = sp3[8];
    if(sp3[1] > sp3[4]) begin
        tmp[3] = sp3[1];
        sp4[1] = sp3[4];
        sp4[4] = tmp[3];
    end
    else begin
        sp4[1] = sp3[1];
        sp4[4] = sp3[4];
    end
    if(sp3[3] > sp3[6]) begin
        tmp[3] = sp3[3];
        sp4[3] = sp3[6];
        sp4[6] = tmp[3];
    end
    else begin
        sp4[3] = sp3[3];
        sp4[6] = sp3[6];
    end
    if(sp3[5] > sp3[7]) begin
        tmp[3] = sp3[5];
        sp4[5] = sp3[7];
        sp4[7] = tmp[3];
    end
    else begin
        sp4[5] = sp3[5];
        sp4[7] = sp3[7];
    end
end


//[(0,1),(2,4),(3,5),(6,8)]

always @(*) begin
    sp5[7] = sp4[7];
    if(sp4[0] > sp4[1]) begin
        tmp[4] = sp4[0];
        sp5[0] = sp4[1];
        sp5[1] = tmp[4];
    end
    else begin
        sp5[0] = sp4[0];
        sp5[1] = sp4[1];
    end
    if(sp4[2] > sp4[4]) begin
        tmp[4] = sp4[2];
        sp5[2] = sp4[4];
        sp5[4] = tmp[4];
    end
    else begin
        sp5[2] = sp4[2];
        sp5[4] = sp4[4];
    end
    if(sp4[3] > sp4[5]) begin
        tmp[4] = sp4[3];
        sp5[3] = sp4[5];
        sp5[5] = tmp[4];
    end
    else begin
        sp5[3] = sp4[3];
        sp5[5] = sp4[5];
    end
    if(sp4[6] > sp4[8]) begin
        tmp[4] = sp4[6];
        sp5[6] = sp4[8];
        sp5[8] = tmp[4];
    end
    else begin
        sp5[6] = sp4[6];
        sp5[8] = sp4[8];
    end
end



//[(2,3),(4,5),(6,7)]

always @(*) begin
    sp6[0] = sp5[0];
    sp6[1] = sp5[1];
    sp6[8] = sp5[8];
    if(sp5[2] > sp5[3]) begin
        tmp[5] = sp5[2];
        sp6[2] = sp5[3];
        sp6[3] = tmp[5];
    end
    else begin
        sp6[2] = sp5[2];
        sp6[3] = sp5[3];
    end
    if(sp5[4] > sp5[5]) begin
        tmp[5] = sp5[4];
        sp6[4] = sp5[5];
        sp6[5] = tmp[5];
    end
    else begin
        sp6[4] = sp5[4];
        sp6[5] = sp5[5];
    end
    if(sp5[6] > sp5[7]) begin
        tmp[5] = sp5[6];
        sp6[6] = sp5[7];
        sp6[7] = tmp[5];
    end
    else begin
        sp6[6] = sp5[6];
        sp6[7] = sp5[7];
    end
end

//[(1,2),(3,4),(5,6)]

always @(*) begin
    sp7[0] = sp6[0];
    sp7[7] = sp6[7];
    sp7[8] = sp6[8];
    if(sp6[1] > sp6[2]) begin
        tmp[6] = sp6[1];
        sp7[1] = sp6[2];
        sp7[2] = tmp[6];
    end
    else begin
        sp7[1] = sp6[1];
        sp7[2] = sp6[2];
    end
    if(sp6[3] > sp6[4]) begin
        tmp[6] = sp6[3];
        sp7[3] = sp6[4];
        sp7[4] = tmp[6];
    end
    else begin
        sp7[3] = sp6[3];
        sp7[4] = sp6[4];
    end
    if(sp6[5] > sp6[6]) begin
        tmp[6] = sp6[5];
        sp7[5] = sp6[6];
        sp7[6] = tmp[6];
    end
    else begin
        sp7[5] = sp6[5];
        sp7[6] = sp6[6];
    end
end

assign out = sp7[4];
endmodule

module CORRELATION(
    input clk,
    input [7:0] s0,s1,s2,s3,s4,s5,s6,s7,s8,t0,t1,t2,t3,t4,t5,t6,t7,t8,
    input [4:0] cnt,
    output reg [19:0] out
);  
    reg [7:0] s, t;

    always @(*) begin
        case(cnt)
            11: s = s0;
            12: s = s1;
            13: s = s2;
            14: s = s3;
            15: s = s4;
            16: s = s5;
            17: s = s6;
            18: s = s7;
            19: s = s8;
            default: s = 0;
        endcase
    end

    always @(*) begin
        case(cnt)
            11: t = t0;
            12: t = t1;
            13: t = t2;
            14: t = t3;
            15: t = t4;
            16: t = t5;
            17: t = t6;
            18: t = t7;
            19: t = t8;
            default: t = 0;
        endcase
    end

    always @(posedge clk ) begin
        if(cnt == 10) out <= 0;
        else out <= out + s * t;
    end
    

endmodule

module MP(
    input [7:0] s0,s1,s2,s3,
    output [7:0] out
);

    wire [7:0] max_tmp[0:1];
    assign max_tmp[0] = (s0 > s1) ? s0 : s1;
    assign max_tmp[1] = (s2 > s3) ? s2 : s3;
    assign out = (max_tmp[0] > max_tmp[1]) ? max_tmp[0] : max_tmp[1];

endmodule

//==========================================//
//             Memory Module                //
//==========================================//
// 256 blocks * 32 bits single-port SRAM
/* module sram_256x32_inst(A, DO, DI, CK, WEB);
	input [7:0] A;
	input [31:0] DI;
	input CK, WEB;
	output [31:0] DO;

	SUMA180_256X32X1BM1 U0 (
		// address
		.A0(A[0]), .A1(A[1]), .A2(A[2]), .A3(A[3]), .A4(A[4]), .A5(A[5]), .A6(A[6]), .A7(A[7]),
		
		// data out
		.DO0(DO[0]), .DO1(DO[1]), .DO2(DO[2]), .DO3(DO[3]), .DO4(DO[4]), .DO5(DO[5]), .DO6(DO[6]), .DO7(DO[7]),
		.DO8(DO[8]), .DO9(DO[9]), .DO10(DO[10]), .DO11(DO[11]), .DO12(DO[12]), .DO13(DO[13]), .DO14(DO[14]), .DO15(DO[15]),
		.DO16(DO[16]), .DO17(DO[17]), .DO18(DO[18]), .DO19(DO[19]), .DO20(DO[20]), .DO21(DO[21]), .DO22(DO[22]), .DO23(DO[23]),
		.DO24(DO[24]), .DO25(DO[25]), .DO26(DO[26]), .DO27(DO[27]), .DO28(DO[28]), .DO29(DO[29]), .DO30(DO[30]), .DO31(DO[31]),
		
		
		// data in
		.DI0(DI[0]), .DI1(DI[1]), .DI2(DI[2]), .DI3(DI[3]), .DI4(DI[4]), .DI5(DI[5]), .DI6(DI[6]), .DI7(DI[7]),
		.DI8(DI[8]), .DI9(DI[9]), .DI10(DI[10]), .DI11(DI[11]), .DI12(DI[12]), .DI13(DI[13]), .DI14(DI[14]), .DI15(DI[15]),
		.DI16(DI[16]), .DI17(DI[17]), .DI18(DI[18]), .DI19(DI[19]), .DI20(DI[20]), .DI21(DI[21]), .DI22(DI[22]), .DI23(DI[23]),
		.DI24(DI[24]), .DI25(DI[25]), .DI26(DI[26]), .DI27(DI[27]), .DI28(DI[28]), .DI29(DI[29]), .DI30(DI[30]), .DI31(DI[31]),
		

		// control signal
		.CK(CK), .WEB(WEB), .OE(1'b1), .CS(1'b1)
	);

endmodule */

// 256 blocks * 16 bits single-port SRAM
module sram_256x16_inst(A, DO, DI, CK, WEB);
	input [7:0] A;
	input [15:0] DI;
	input CK, WEB;
	output [15:0] DO;

	SUMA180_256X16X1BM1 U0 (
		// address
		.A0(A[0]), .A1(A[1]), .A2(A[2]), .A3(A[3]), .A4(A[4]), .A5(A[5]), .A6(A[6]), .A7(A[7]),
		
		// data out
		.DO0(DO[0]), .DO1(DO[1]), .DO2(DO[2]), .DO3(DO[3]), .DO4(DO[4]), .DO5(DO[5]), .DO6(DO[6]), .DO7(DO[7]),
		.DO8(DO[8]), .DO9(DO[9]), .DO10(DO[10]), .DO11(DO[11]), .DO12(DO[12]), .DO13(DO[13]), .DO14(DO[14]), .DO15(DO[15]),
		
		
		
		// data in
		.DI0(DI[0]), .DI1(DI[1]), .DI2(DI[2]), .DI3(DI[3]), .DI4(DI[4]), .DI5(DI[5]), .DI6(DI[6]), .DI7(DI[7]),
		.DI8(DI[8]), .DI9(DI[9]), .DI10(DI[10]), .DI11(DI[11]), .DI12(DI[12]), .DI13(DI[13]), .DI14(DI[14]), .DI15(DI[15]),
		

		// control signal
		.CK(CK), .WEB(WEB), .OE(1'b1), .CS(1'b1)
	);

endmodule