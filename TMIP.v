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

enum logic[3:0] {
    IDLE =    4'd0,
    READ =   4'd1,
    ACTION =   4'd2,
    MP =  4'd3,
    NEG = 4'd4,
    FILT =  4'd6,
    OUTPUT = 4'd8,
    OUTPUT_S = 4'd7,
    FLIP = 4'd5
    } current_state,next_state;

//==================================================================
// reg & wire
//==================================================================

reg [7:0] img_reg;
wire [7:0] img;
reg [7:0] img_write;
reg [19:0] final_write;
reg [7:0] final_address;
wire [19:0] final_out;
wire [19:0] final_out_v;
reg [7:0] flip_out;

reg [7:0] img_tmp [0:2];
wire [7:0] img_larger;
reg [9:0] img_cnt;
reg [1:0] img_size;
reg [1:0] img_size_tmp;
reg [10:0] img_address;
reg [7:0] img_write_tmp [0:2];
reg [2:0] action_reg [0:7];
reg [3:0] action_size;
reg [2:0] action_index;
reg flip_flag;


reg [7:0] template_reg [0:8];
reg rw_control;
integer i;

reg [2:0] MP_cnt;

reg [10:0] img_filt_cnt;
reg [10:0] img_flip_cnt;
reg [10:0] img_mp_cnt;
reg [10:0] img_neg_cnt;
reg [10:0] img_cor_cnt;
reg mp_stop;
wire [10:0] img_read_cor;
wire [10:0] img_read_filt;
wire [10:0] img_write_filt;
wire [10:0] img_write_cor;
wire [10:0] img_read_mp;
wire [10:0] img_read_flip;
wire [10:0] img_read_neg;
wire [10:0] img_write_mp;
wire [10:0] img_write_neg;
wire [10:0] img_write_flip;
reg [7:0] img_read_filt_cnt;
reg [7:0] img_read_neg_cnt;
reg [7:0] img_read_cor_cnt;
reg [7:0] img_read_mp_cnt;
reg [7:0] img_read_flip_cnt;
reg img_cor_read_stop, img_cor_write_stop, img_cor_write_stop2;
reg img_read_mp_stop;
//reg img_read_neg_stop;
//reg img_write_neg_stop;
reg img_write_mp_stop;
reg img_cor_control_buff, img_cor_control;
reg [7:0] img_write_filt_cnt;
reg [7:0] img_write_cor_cnt;
wire [7:0] img_write_cor_cnt_w;
reg [7:0] img_write_neg_cnt;
reg [7:0] img_write_mp_cnt;
reg [8:0] img_write_flip_cnt;
reg [10:0] img_read_kind;
reg [10:0] img_write_kind;
reg img_read_filt_stop;
reg img_write_filt_stop;
reg img_write_filt_stop2;
reg img_rw_flip_control;
reg img_rw_flip_control_buff;
reg img_rw_filt_control;
reg img_rw_filt_control_buff;
reg img_rw_neg_control;
reg img_rw_neg_control_buff;
reg img_rw_mp_control;
reg img_rw_mp_control_buff;
reg old_new_flag;
reg [7:0] img16_filt_buffer[0:47], img16_cor_buffer[0:47], img16_mp_buffer[0:31], img16_neg_buffer[0:15], img16_flip_buffer[0:15];
reg [19:0] output_buffer[0:14];
reg [7:0] s16[0:8], s8[0:8], s4[0:8], s[0:8];
reg [7:0] mp16[0:3], mp8[0:3];
wire [7:0] mp[0:3];
reg [7:0] c16[0:8],c8[0:8],c4[0:8],c[0:8];
wire [7:0] filt_out;
reg [7:0] neg_out;
wire [7:0] mp_out;
wire [19:0] cor_out;
reg [19:0] cor_out_reg;
reg [5:0] out_index;
reg filt_stop;
reg neg_stop;
reg flip_stop;
reg cor_stop;
reg [5:0] count1;
reg [12:0] count2;
reg out_stop;
reg read_stop;


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
                next_state = READ;
            else if(in_valid2)
                next_state = ACTION;
            else
                next_state = IDLE;
        end
        READ: begin
            if(action_size == 2) next_state = ACTION;
            else next_state = READ;
        end
        ACTION: begin
			if(in_valid2 == 0) next_state = action_reg[action_index];//action_reg[action_index]
            else next_state = ACTION;
        end
		MP: begin
			if(mp_stop == 1) next_state = ACTION;
            else next_state = MP;
		end
        NEG: begin
            if(neg_stop == 1) next_state = ACTION;
            else next_state = NEG;
        end
        FLIP: begin
            if(flip_stop == 1) next_state = ACTION;
            else next_state = FLIP;
        end
        FILT: begin
            if(filt_stop == 1) next_state = ACTION;
            else next_state = FILT;
        end
        OUTPUT_S: begin
            if(cor_stop == 1) next_state = OUTPUT;
            else next_state = OUTPUT_S;
        end
        OUTPUT: begin
            if(out_stop == 1) next_state = IDLE;
            else next_state = OUTPUT;
        end 
        default: next_state = IDLE;
    endcase
end

//==================================================================
// design
//==================================================================

always@(*) begin
    case(img_size)
        0: read_stop = (img_cnt <= 51);
        1: read_stop = (img_cnt <= 195);
        2: read_stop = (img_cnt <= 771);
        default: read_stop = 0;
    endcase
end


always @(*) begin
    case(img_size_tmp)
        0: out_stop = (count2 == 321);
        1: out_stop = (count2 == 1281);
        2: out_stop = (count2 == 5121);
    default: out_stop = 0;
    endcase
end

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
    if(!rst_n) action_size <= 0;
    else if(next_state == IDLE) action_size <= 0;
    else if((MP_cnt >= img_size) && (action == 3)) action_size <= action_size;
    else if(in_valid2) action_size <= action_size + 1;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) img_cnt <= 0;
    else if(action_size == 2) img_cnt <= 0;
    else if(next_state == READ) img_cnt <= img_cnt + 1;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) img_size <= 0;
    else if(in_valid && (img_cnt == 0)) img_size <= image_size;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) img_size_tmp <= 0;
    else if(next_state == ACTION && (current_state == IDLE || current_state == READ)) img_size_tmp <= img_size;
    else if(current_state == MP && next_state == ACTION) img_size_tmp <= img_size_tmp - 1;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) MP_cnt <= 0;
    else if(current_state == IDLE) MP_cnt <= 0;
    else if(in_valid2) begin
        if(action == 3)
            MP_cnt <= MP_cnt + 1;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) action_index <= 0;
    else if(next_state == IDLE || next_state == OUTPUT) action_index <= 0;
    else if((current_state != ACTION) && (next_state == ACTION)) begin
        action_index <= action_index + 1;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        template_reg[0] <= 0;
        template_reg[1] <= 0;
        template_reg[2] <= 0;
        template_reg[3] <= 0;
        template_reg[4] <= 0;
        template_reg[5] <= 0;
        template_reg[6] <= 0;
        template_reg[7] <= 0;
        template_reg[8] <= 0;
    end
    else if(in_valid && img_cnt < 9) begin
        template_reg[img_cnt] <= template;
    end
end


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) old_new_flag <= 0;
    else if(next_state == OUTPUT || next_state == IDLE) old_new_flag <= 0;
    else if((current_state != ACTION) && (next_state == ACTION)) old_new_flag <= ~old_new_flag;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) out_value <= 0;
    else if(out_stop) out_value <= 0;
    else if(count2 >= 1) out_value <= final_out_v[20-count1];
end

assign final_out_v = out_valid ? final_out : 0;

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) out_valid <= 0;
    else if(out_stop) out_valid <= 0;
    else if(count2 >= 1) out_valid <= 1;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) count2 <= 0;
    else if(current_state != next_state) count2 <= 0;
    else if(current_state == OUTPUT) count2 <= count2 + 1;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) img_tmp[0] <= 0;
    else if(img_cnt%3 == 0)
        img_tmp[0] <= image; 
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) img_tmp[1] <= 0;
    else if(img_cnt%3 == 1)
        img_tmp[1] <= image; 
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) img_tmp[2] <= 0;
    else if(img_cnt%3 == 2)
        img_tmp[2] <= image; 
end

assign img_larger = (img_tmp[0] > img_tmp[1]) ? img_tmp[0] : img_tmp[1];

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) img_write_tmp[0] <= 0;
    else if(img_cnt%3 == 0) img_write_tmp[0] <= (img_tmp[2] > img_larger) ? img_tmp[2] : img_larger;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) img_write_tmp[1] <= 0;
    else if(img_cnt%3 == 0) img_write_tmp[1] <= (img_tmp[0] + img_tmp[1] + img_tmp[2])/3;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) img_write_tmp[2] <= 0;
    else if(img_cnt%3 == 0) img_write_tmp[2] <= (img_tmp[0] >> 2) + (img_tmp[1] >> 1) + (img_tmp[2] >> 2);
end




always @(*) begin
    if(action_index == 1) begin
        case(action_reg[0])
            0: begin
                img_read_kind = 0;
            end
            1: begin
                img_read_kind = 256;
            end
            2: begin
                img_read_kind = 512;
            end
            default: img_read_kind = 0;
        endcase
    end
    else begin
        if(old_new_flag) img_read_kind = 1024;
        else img_read_kind = 768;
    end
end
always @(*) begin
    if(old_new_flag) img_write_kind = 768;
    else img_write_kind = 1024;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        img16_filt_buffer[47] <= 0;
        for(i = 0; i < 47; i = i + 1) begin
            img16_filt_buffer[i] <= 0 ;
        end
    end
    else begin
        img16_filt_buffer[47] <= (img_rw_filt_control_buff ? img16_filt_buffer[47] : img);
        for(i = 0; i < 47; i = i + 1) begin
            img16_filt_buffer[i] <= (img_rw_filt_control_buff ? img16_filt_buffer[i] : img16_filt_buffer[i + 1]);
        end
    end
    
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        img16_mp_buffer[31] <= 0;
        for(i = 0; i < 31; i = i + 1) begin
            img16_mp_buffer[i] <= 0;
        end
    end
    else begin
        img16_mp_buffer[31] <= (img_rw_mp_control_buff ? img16_mp_buffer[31] : img);
    for(i = 0; i < 31; i = i + 1) begin
        img16_mp_buffer[i] <= (img_rw_mp_control_buff ? img16_mp_buffer[i] : img16_mp_buffer[i + 1]);
    end
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        img16_neg_buffer[15] <= 0;
        for(i = 0; i < 15; i = i + 1) begin
            img16_neg_buffer[i] <= 0;
        end
    end
    else begin
        img16_neg_buffer[15] <= (img_rw_neg_control_buff ? img16_neg_buffer[15] : img);
    for(i = 0; i < 15; i = i + 1) begin
         img16_neg_buffer[i] <= (img_rw_neg_control_buff ? img16_neg_buffer[i] : img16_neg_buffer[i + 1]);
    end
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        img16_flip_buffer[15] <= 0;
        for(i = 0; i < 15; i = i + 1) begin
            img16_flip_buffer[i] <= 0;
        end
    end
    else begin
        img16_flip_buffer[15] <= (img_rw_flip_control_buff ? img16_flip_buffer[15] : img);
    for(i = 0; i < 15; i = i + 1) begin
        img16_flip_buffer[i] <= (img_rw_flip_control_buff ? img16_flip_buffer[i] : img16_flip_buffer[i + 1]);
    end
    end
end



always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        img16_cor_buffer[47] <= 0;
        for(i = 0; i < 47; i = i + 1) begin
            img16_cor_buffer[i] <= 0;
        end
    end
    else begin
        img16_cor_buffer[47] <= (img_cor_control_buff ? img16_cor_buffer[47] : img);
    for(i = 0; i < 47; i = i + 1) begin
        img16_cor_buffer[i] <= (img_cor_control_buff ? img16_cor_buffer[i] : img16_cor_buffer[i + 1]);
    end
    end
end



always @(*) begin
    case(img_size_tmp)
        2'd0: img_cor_read_stop = (|img_read_cor_cnt[3:2]) && (img_read_cor_cnt[1:0] == 3);
        2'd1: img_cor_read_stop = (|img_read_cor_cnt[5:3]) && (img_read_cor_cnt[2:0] == 7);
        2'd2: img_cor_read_stop = (|img_read_cor_cnt[7:4]) && (img_read_cor_cnt[3:0] == 15);
        default:  img_cor_read_stop = 0;
    endcase
end
always @(*) begin
    case(img_size_tmp)
        2'd0: img_cor_write_stop = img_write_cor_cnt[1:0] == 3;
        2'd1: img_cor_write_stop = img_write_cor_cnt[2:0] == 7;
        2'd2: img_cor_write_stop = img_write_cor_cnt[3:0] == 15;
        default:  img_cor_write_stop = 0;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) img_cor_control_buff <= 0;
    else img_cor_control_buff <= img_cor_control;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  img_write_cor_cnt <= 0;
    else if(current_state != next_state) img_write_cor_cnt <= 0;
    else if(current_state == OUTPUT_S && img_cor_control) img_write_cor_cnt <= img_write_cor_cnt + 1;
    else if(current_state == OUTPUT && count1 == 20) img_write_cor_cnt <= img_write_cor_cnt + 1;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) count1 <= 0;
    else if(current_state != next_state) count1 <= 0;
    else if(count1 == 20) count1 <= 1;
    else if(current_state == OUTPUT) count1 <= count1 + 1;
end



always @(*) begin
    case(img_size_tmp)
        2'd1: img_read_mp_stop = (img_read_mp_cnt[3:0] == 15);
        default:  img_read_mp_stop = (img_read_mp_cnt[4:0] == 31);
    endcase
end
always @(*) begin
    case(img_size_tmp)
        2'd0: img_read_filt_stop = (|img_read_filt_cnt[3:2]) && (img_read_filt_cnt[1:0] == 3);
        2'd1: img_read_filt_stop = (|img_read_filt_cnt[5:3]) && (img_read_filt_cnt[2:0] == 7);
        2'd2: img_read_filt_stop = (|img_read_filt_cnt[7:4]) && (img_read_filt_cnt[3:0] == 15);
        default:  img_read_filt_stop = 0;
    endcase
end
always @(*) begin
    case(img_size_tmp)
        2'd0: img_write_filt_stop = img_write_filt_cnt[1:0] == 3;
        2'd1: img_write_filt_stop = img_write_filt_cnt[2:0] == 7;
        2'd2: img_write_filt_stop = img_write_filt_cnt[3:0] == 15;
        default:  img_write_filt_stop = 0;
    endcase
end
always @(*) begin
    case(img_size_tmp)
        2'd1: img_write_mp_stop = (img_write_mp_cnt[1:0] == 3);
        2'd2: img_write_mp_stop = (img_write_mp_cnt[2:0] == 7);
        default:  img_write_mp_stop = 0;
    endcase
end



always @(*) begin
    case(img_size_tmp)
        2'd0: img_write_filt_stop2 = img_write_filt_cnt[3] == 0;
        2'd1: img_write_filt_stop2 = (&img_write_filt_cnt[5:4]) == 0;
        2'd2: img_write_filt_stop2 = (&img_write_filt_cnt[7:5]) == 0;
        default:  img_write_filt_stop2 = 0;
    endcase
end
always @(*) begin
    case(img_size_tmp)
        2'd0: img_cor_write_stop2 = img_write_cor_cnt[3] == 0;
        2'd1: img_cor_write_stop2 = (&img_write_cor_cnt[5:4]) == 0;
        2'd2: img_cor_write_stop2 = (&img_write_cor_cnt[7:5]) == 0;
        default:  img_cor_write_stop2 = 0;
    endcase
end

always @(*) begin
    case(img_size_tmp)
        2'd0: filt_stop = (img_write_filt_cnt[3:0] == 15) ? 1 : 0;
        2'd1: filt_stop = (img_write_filt_cnt[5:0] == 63) ? 1 : 0;
        2'd2: filt_stop = (img_write_filt_cnt[7:0] == 255) ? 1 : 0;
        default: filt_stop = 0;
    endcase
end
always @(*) begin
    case(img_size_tmp)
        2'd0: flip_stop = (img_write_flip_cnt[4:0] == 16) ? 1 : 0;
        2'd1: flip_stop = (img_write_flip_cnt[6:0] == 64) ? 1 : 0;
        2'd2: flip_stop = (img_write_flip_cnt[8:0] == 256) ? 1 : 0;
        default: flip_stop = 0;
    endcase
end
always @(*) begin
    case(img_size_tmp)
        2'd0: neg_stop = (img_write_neg_cnt[3:0] == 15) ? 1 : 0;
        2'd1: neg_stop = (img_write_neg_cnt[5:0] == 63) ? 1 : 0;
        2'd2: neg_stop = (img_write_neg_cnt[7:0] == 255) ? 1 : 0;
        default: neg_stop = 0;
    endcase
end
always @(*) begin
    case(img_size_tmp)
        2'd1: mp_stop = (img_write_mp_cnt[3:0] == 15);
        2'd2: mp_stop = (img_write_mp_cnt[5:0] == 63);
        default: mp_stop = 0;
    endcase
end
always @(*) begin
    case(img_size_tmp)
        2'd0: cor_stop = (img_write_cor_cnt[3:0] == 15) ? 1 : 0;
        2'd1: cor_stop = (img_write_cor_cnt[5:0] == 63) ? 1 : 0;
        2'd2: cor_stop = (img_write_cor_cnt[7:0] == 255) ? 1 : 0;
        default: cor_stop = 0;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)   img_cor_control <= 0;
    else if((current_state != next_state))  img_cor_control <= 0;
    else if(img_cor_read_stop) img_cor_control <= 1;
    else if(img_cor_write_stop && img_cor_write_stop2) img_cor_control <= 0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)   img_rw_mp_control <= 0;
    else if((current_state != next_state) || (current_state != MP))  img_rw_mp_control <= 0;
    else if(img_read_mp_stop) img_rw_mp_control <= 1;
    else if(img_write_mp_stop) img_rw_mp_control <= 0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)   img_rw_neg_control <= 0;
    else if((current_state != next_state) || (current_state != NEG))  img_rw_neg_control <= 0;
    else if(img_read_neg_cnt[3:0] == 15) img_rw_neg_control <= 1;
    else if(img_write_neg_cnt[3:0] == 15) img_rw_neg_control <= 0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)   img_rw_filt_control <= 0;
    else if((current_state != next_state) || (current_state != FILT))  img_rw_filt_control <= 0;
    else if(img_read_filt_stop) img_rw_filt_control <= 1;
    else if(img_write_filt_stop && img_write_filt_stop2) img_rw_filt_control <= 0;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)   img_rw_flip_control <= 0;
    else if((current_state != next_state) || (current_state != FLIP))  img_rw_flip_control <= 0;
    else if(img_read_flip_cnt[3:0] == 15) img_rw_flip_control <= 1;
    else if(img_write_flip_cnt[3:0] == 15) img_rw_flip_control <= 0;
end

always @(*) begin
    if(img_rw_filt_control) img_filt_cnt = img_write_filt;
    else img_filt_cnt = img_read_filt;
end
always @(*) begin
    if(img_rw_mp_control) img_mp_cnt = img_write_mp;
    else img_mp_cnt = img_read_mp;
end
always @(*) begin
    if(img_rw_neg_control) img_neg_cnt = img_write_neg;
    else img_neg_cnt = img_read_neg;
end
always @(*) begin
    if(img_rw_flip_control_buff) img_flip_cnt = img_write_flip;
    else img_flip_cnt = img_read_flip;
end
always @(*) begin
    if(img_cor_control) img_cor_cnt = img_write_cor;
    else img_cor_cnt = img_read_cor;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) img_rw_filt_control_buff <= 0;
    else img_rw_filt_control_buff <= img_rw_filt_control;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) img_rw_mp_control_buff <= 0;
    else img_rw_mp_control_buff <= img_rw_mp_control;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) img_rw_neg_control_buff <= 0;
    else img_rw_neg_control_buff <= img_rw_neg_control;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) img_rw_flip_control_buff <= 0;
    else img_rw_flip_control_buff <= img_rw_flip_control;
end
assign img_read_filt = img_read_kind + img_read_filt_cnt;
assign img_read_cor = img_read_kind + img_read_cor_cnt;
assign img_read_mp = img_read_kind + img_read_mp_cnt;
assign img_read_neg = img_read_kind + img_read_neg_cnt;
assign img_read_flip = img_read_kind + img_read_flip_cnt;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) img_read_cor_cnt <= 0;
    else if(current_state != next_state) img_read_cor_cnt <= 0;
    else if(current_state == OUTPUT_S && (~img_cor_control)) img_read_cor_cnt <= img_read_cor_cnt + 1;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) img_read_filt_cnt <= 0;
    else if(current_state != next_state) img_read_filt_cnt <= 0;
    else if(current_state == FILT && (~img_rw_filt_control)) img_read_filt_cnt <= img_read_filt_cnt + 1;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) img_read_mp_cnt <= 0;
    else if(current_state != next_state) img_read_mp_cnt <= 0;
    else if(current_state == MP && (~img_rw_mp_control)) img_read_mp_cnt <= img_read_mp_cnt + 1;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) img_read_neg_cnt <= 0;
    else if(current_state != next_state) img_read_neg_cnt <= 0;
    else if(current_state == NEG && (~img_rw_neg_control)) img_read_neg_cnt <= img_read_neg_cnt + 1;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) img_read_flip_cnt <= 0;
    else if(current_state != next_state) img_read_flip_cnt <= 0;
    else if(current_state == FLIP && (~img_rw_flip_control && ~img_rw_flip_control_buff)) img_read_flip_cnt <= img_read_flip_cnt + 1;
end

assign img_write_filt = img_write_kind + img_write_filt_cnt;
assign img_write_mp = img_write_kind + img_write_mp_cnt;
assign img_write_neg = img_write_kind + img_write_neg_cnt;
assign img_write_flip = img_write_kind + img_write_flip_cnt - 1;
assign img_write_cor = img_write_kind + img_write_cor_cnt;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) img_write_filt_cnt <= 0;
    else if(current_state != next_state) img_write_filt_cnt <= 0;
    else if(current_state == FILT && img_rw_filt_control) img_write_filt_cnt <= img_write_filt_cnt + 1;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) img_write_flip_cnt <= 0;
    else if(current_state != next_state) img_write_flip_cnt <= 0;
    else if(current_state == FLIP && img_rw_flip_control) img_write_flip_cnt <= img_write_flip_cnt + 1;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) img_write_mp_cnt <= 0;
    else if(current_state != next_state) img_write_mp_cnt <= 0;
    else if(current_state == MP && img_rw_mp_control) img_write_mp_cnt <= img_write_mp_cnt + 1;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) img_write_neg_cnt <= 0;
    else if(current_state != next_state) img_write_neg_cnt <= 0;
    else if(current_state == NEG && img_rw_neg_control) img_write_neg_cnt <= img_write_neg_cnt + 1;
end
always @(*) begin
    case(img_write_neg_cnt[3:0])
        0: neg_out = {~img16_neg_buffer[1][7],~img16_neg_buffer[1][6],~img16_neg_buffer[1][5],~img16_neg_buffer[1][4],~img16_neg_buffer[1][3],~img16_neg_buffer[1][2],~img16_neg_buffer[1][1],~img16_neg_buffer[1][0]};
        1: neg_out = {~img16_neg_buffer[1][7],~img16_neg_buffer[1][6],~img16_neg_buffer[1][5],~img16_neg_buffer[1][4],~img16_neg_buffer[1][3],~img16_neg_buffer[1][2],~img16_neg_buffer[1][1],~img16_neg_buffer[1][0]};
        2: neg_out = {~img16_neg_buffer[2][7],~img16_neg_buffer[2][6],~img16_neg_buffer[2][5],~img16_neg_buffer[2][4],~img16_neg_buffer[2][3],~img16_neg_buffer[2][2],~img16_neg_buffer[2][1],~img16_neg_buffer[2][0]};
        3: neg_out = {~img16_neg_buffer[3][7],~img16_neg_buffer[3][6],~img16_neg_buffer[3][5],~img16_neg_buffer[3][4],~img16_neg_buffer[3][3],~img16_neg_buffer[3][2],~img16_neg_buffer[3][1],~img16_neg_buffer[3][0]};
        4: neg_out = {~img16_neg_buffer[4][7],~img16_neg_buffer[4][6],~img16_neg_buffer[4][5],~img16_neg_buffer[4][4],~img16_neg_buffer[4][3],~img16_neg_buffer[4][2],~img16_neg_buffer[4][1],~img16_neg_buffer[4][0]};
        5: neg_out = {~img16_neg_buffer[5][7],~img16_neg_buffer[5][6],~img16_neg_buffer[5][5],~img16_neg_buffer[5][4],~img16_neg_buffer[5][3],~img16_neg_buffer[5][2],~img16_neg_buffer[5][1],~img16_neg_buffer[5][0]};
        6: neg_out = {~img16_neg_buffer[6][7],~img16_neg_buffer[6][6],~img16_neg_buffer[6][5],~img16_neg_buffer[6][4],~img16_neg_buffer[6][3],~img16_neg_buffer[6][2],~img16_neg_buffer[6][1],~img16_neg_buffer[6][0]};
        7: neg_out = {~img16_neg_buffer[7][7],~img16_neg_buffer[7][6],~img16_neg_buffer[7][5],~img16_neg_buffer[7][4],~img16_neg_buffer[7][3],~img16_neg_buffer[7][2],~img16_neg_buffer[7][1],~img16_neg_buffer[7][0]};
        8: neg_out = {~img16_neg_buffer[8][7],~img16_neg_buffer[8][6],~img16_neg_buffer[8][5],~img16_neg_buffer[8][4],~img16_neg_buffer[8][3],~img16_neg_buffer[8][2],~img16_neg_buffer[8][1],~img16_neg_buffer[8][0]};
        9: neg_out = {~img16_neg_buffer[9][7],~img16_neg_buffer[9][6],~img16_neg_buffer[9][5],~img16_neg_buffer[9][4],~img16_neg_buffer[9][3],~img16_neg_buffer[9][2],~img16_neg_buffer[9][1],~img16_neg_buffer[9][0]};
        10: neg_out = {~img16_neg_buffer[10][7],~img16_neg_buffer[10][6],~img16_neg_buffer[10][5],~img16_neg_buffer[10][4],~img16_neg_buffer[10][3],~img16_neg_buffer[10][2],~img16_neg_buffer[10][1],~img16_neg_buffer[10][0]};
        11: neg_out = {~img16_neg_buffer[11][7],~img16_neg_buffer[11][6],~img16_neg_buffer[11][5],~img16_neg_buffer[11][4],~img16_neg_buffer[11][3],~img16_neg_buffer[11][2],~img16_neg_buffer[11][1],~img16_neg_buffer[11][0]};
        12: neg_out = {~img16_neg_buffer[12][7],~img16_neg_buffer[12][6],~img16_neg_buffer[12][5],~img16_neg_buffer[12][4],~img16_neg_buffer[12][3],~img16_neg_buffer[12][2],~img16_neg_buffer[12][1],~img16_neg_buffer[12][0]};
        13: neg_out = {~img16_neg_buffer[13][7],~img16_neg_buffer[13][6],~img16_neg_buffer[13][5],~img16_neg_buffer[13][4],~img16_neg_buffer[13][3],~img16_neg_buffer[13][2],~img16_neg_buffer[13][1],~img16_neg_buffer[13][0]};
        14: neg_out = {~img16_neg_buffer[14][7],~img16_neg_buffer[14][6],~img16_neg_buffer[14][5],~img16_neg_buffer[14][4],~img16_neg_buffer[14][3],~img16_neg_buffer[14][2],~img16_neg_buffer[14][1],~img16_neg_buffer[14][0]};
        15: neg_out = {~img16_neg_buffer[15][7],~img16_neg_buffer[15][6],~img16_neg_buffer[15][5],~img16_neg_buffer[15][4],~img16_neg_buffer[15][3],~img16_neg_buffer[15][2],~img16_neg_buffer[15][1],~img16_neg_buffer[15][0]};
    endcase
end

always @(*) begin
    case(img_write_flip_cnt[3:0])
        1: begin
            case(img_size_tmp)
                0: flip_out = img16_flip_buffer[3];
                1: flip_out = img16_flip_buffer[7];
                2: flip_out = img16_flip_buffer[15];
                default: flip_out = 0;
            endcase
        end
        2: begin
            case(img_size_tmp)
                0: flip_out = img16_flip_buffer[2];
                1: flip_out = img16_flip_buffer[6];
                2: flip_out = img16_flip_buffer[14];
                default: flip_out = 0;
            endcase
        end
        3: begin
            case(img_size_tmp)
                0: flip_out = img16_flip_buffer[1];
                1: flip_out = img16_flip_buffer[5];
                2: flip_out = img16_flip_buffer[13];
                default: flip_out = 0;
            endcase
        end
        4: begin
            case(img_size_tmp)
                0: flip_out = img16_flip_buffer[0];
                1: flip_out = img16_flip_buffer[4];
                2: flip_out = img16_flip_buffer[12];
                default: flip_out = 0;
            endcase
        end
        5: begin
            case(img_size_tmp)
                0: flip_out = img16_flip_buffer[7];
                1: flip_out = img16_flip_buffer[3];
                2: flip_out = img16_flip_buffer[11];
                default: flip_out = 0;
            endcase
        end
        6: begin
            case(img_size_tmp)
                0: flip_out = img16_flip_buffer[6];
                1: flip_out = img16_flip_buffer[2];
                2: flip_out = img16_flip_buffer[10];
                default: flip_out = 0;
            endcase
        end
        7: begin
            case(img_size_tmp)
                0: flip_out = img16_flip_buffer[5];
                1: flip_out = img16_flip_buffer[1];
                2: flip_out = img16_flip_buffer[9];
                default: flip_out = 0;
            endcase
        end
        8: begin
            case(img_size_tmp)
                0: flip_out = img16_flip_buffer[4];
                1: flip_out = img16_flip_buffer[0];
                2: flip_out = img16_flip_buffer[8];
                default: flip_out = 0;
            endcase
        end
        9: begin
            case(img_size_tmp)
                0: flip_out = img16_flip_buffer[11];
                1: flip_out = img16_flip_buffer[15];
                2: flip_out = img16_flip_buffer[7];
                default: flip_out = 0;
            endcase
        end
        10: begin
            case(img_size_tmp)
                0: flip_out = img16_flip_buffer[10];
                1: flip_out = img16_flip_buffer[14];
                2: flip_out = img16_flip_buffer[6];
                default: flip_out = 0;
            endcase
        end
        11: begin
            case(img_size_tmp)
                0: flip_out = img16_flip_buffer[9];
                1: flip_out = img16_flip_buffer[13];
                2: flip_out = img16_flip_buffer[5];
                default: flip_out = 0;
            endcase
        end
        12: begin
            case(img_size_tmp)
                0: flip_out = img16_flip_buffer[8];
                1: flip_out = img16_flip_buffer[12];
                2: flip_out = img16_flip_buffer[4];
                default: flip_out = 0;
            endcase
        end
        13: begin
            case(img_size_tmp)
                0: flip_out = img16_flip_buffer[15];
                1: flip_out = img16_flip_buffer[11];
                2: flip_out = img16_flip_buffer[3];
                default: flip_out = 0;
            endcase
        end
        14: begin
            case(img_size_tmp)
                0: flip_out = img16_flip_buffer[14];
                1: flip_out = img16_flip_buffer[10];
                2: flip_out = img16_flip_buffer[2];
                default: flip_out = 0;
            endcase
        end
        15: begin
            case(img_size_tmp)
                0: flip_out = img16_flip_buffer[13];
                1: flip_out = img16_flip_buffer[9];
                2: flip_out = img16_flip_buffer[1];
                default: flip_out = 0;
            endcase
        end
        0: begin
            case(img_size_tmp)
                0: flip_out = img16_flip_buffer[12];
                1: flip_out = img16_flip_buffer[8];
                2: flip_out = img16_flip_buffer[0];
                default: flip_out = 0;
            endcase
        end
        default: flip_out = 0;
    endcase
end



sorting sort(.s0(s[0]),.s1(s[1]),.s2(s[2]),.s3(s[3]),.s4(s[4]),.s5(s[5]),.s6(s[6]),.s7(s[7]),.s8(s[8]),.out(filt_out));
MP mp1(.s0(mp[0]),.s1(mp[1]),.s2(mp[2]),.s3(mp[3]),.out(mp_out));
always @(*) begin
    case(img_write_mp_cnt[2:0])
        0: mp16[0] = img16_mp_buffer[1];
        1: mp16[0] = img16_mp_buffer[2];
        2: mp16[0] = img16_mp_buffer[4];
        3: mp16[0] = img16_mp_buffer[6];
        4: mp16[0] = img16_mp_buffer[8];
        5: mp16[0] = img16_mp_buffer[10];
        6: mp16[0] = img16_mp_buffer[12];
        7: mp16[0] = img16_mp_buffer[14];
    endcase
end
always @(*) begin
    case(img_write_mp_cnt[2:0])
        0: mp16[1] = img16_mp_buffer[2];
        1: mp16[1] = img16_mp_buffer[3];
        2: mp16[1] = img16_mp_buffer[5];
        3: mp16[1] = img16_mp_buffer[7];
        4: mp16[1] = img16_mp_buffer[9];
        5: mp16[1] = img16_mp_buffer[11];
        6: mp16[1] = img16_mp_buffer[13];
        7: mp16[1] = img16_mp_buffer[15];
    endcase
end
always @(*) begin
    case(img_write_mp_cnt[2:0])
        0: mp16[2] = img16_mp_buffer[17];
        1: mp16[2] = img16_mp_buffer[18];
        2: mp16[2] = img16_mp_buffer[20];
        3: mp16[2] = img16_mp_buffer[22];
        4: mp16[2] = img16_mp_buffer[24];
        5: mp16[2] = img16_mp_buffer[26];
        6: mp16[2] = img16_mp_buffer[28];
        7: mp16[2] = img16_mp_buffer[30];
    endcase
end
always @(*) begin
    case(img_write_mp_cnt[2:0])
        0: mp16[3] = img16_mp_buffer[18];
        1: mp16[3] = img16_mp_buffer[19];
        2: mp16[3] = img16_mp_buffer[21];
        3: mp16[3] = img16_mp_buffer[23];
        4: mp16[3] = img16_mp_buffer[25];
        5: mp16[3] = img16_mp_buffer[27];
        6: mp16[3] = img16_mp_buffer[29];
        7: mp16[3] = img16_mp_buffer[31];
    endcase
end
always @(*) begin
    case(img_write_mp_cnt[1:0])
        0: mp8[0] = img16_mp_buffer[17];
        1: mp8[0] = img16_mp_buffer[18];
        2: mp8[0] = img16_mp_buffer[20];
        3: mp8[0] = img16_mp_buffer[22];
    endcase
end
always @(*) begin
    case(img_write_mp_cnt[1:0])
        0: mp8[1] = img16_mp_buffer[18];
        1: mp8[1] = img16_mp_buffer[19];
        2: mp8[1] = img16_mp_buffer[21];
        3: mp8[1] = img16_mp_buffer[23];
    endcase
end
always @(*) begin
    case(img_write_mp_cnt[1:0])
        0: mp8[2] = img16_mp_buffer[25];
        1: mp8[2] = img16_mp_buffer[26];
        2: mp8[2] = img16_mp_buffer[28];
        3: mp8[2] = img16_mp_buffer[30];
    endcase
end
always @(*) begin
    case(img_write_mp_cnt[1:0])
        0: mp8[3] = img16_mp_buffer[26];
        1: mp8[3] = img16_mp_buffer[27];
        2: mp8[3] = img16_mp_buffer[29];
        3: mp8[3] = img16_mp_buffer[31];
    endcase
end

assign mp[0] = (img_size_tmp == 1) ? mp8[0] : mp16[0];
assign mp[1] = (img_size_tmp == 1) ? mp8[1] : mp16[1];
assign mp[2] = (img_size_tmp == 1) ? mp8[2] : mp16[2];
assign mp[3] = (img_size_tmp == 1) ? mp8[3] : mp16[3];


always @(*) begin
    case(img_size_tmp)
        2'd0: s[0] = s4[0];
        2'd1: s[0] = s8[0];
        2'd2: s[0] = s16[0];
        default: s[0] = 0;
    endcase
end
always @(*) begin
    case(img_size_tmp)
        2'd0: s[1] = s4[1];
        2'd1: s[1] = s8[1];
        2'd2: s[1] = s16[1];
        default: s[1] = 0;
    endcase
end
always @(*) begin
    case(img_size_tmp)
        2'd0: s[2] = s4[2];
        2'd1: s[2] = s8[2];
        2'd2: s[2] = s16[2];
        default: s[2] = 0;
    endcase
end
always @(*) begin
    case(img_size_tmp)
        2'd0: s[3] = s4[3];
        2'd1: s[3] = s8[3];
        2'd2: s[3] = s16[3];
        default: s[3] = 0;
    endcase
end
always @(*) begin
    case(img_size_tmp)
        2'd0: s[4] = s4[4];
        2'd1: s[4] = s8[4];
        2'd2: s[4] = s16[4];
        default: s[4] = 0;
    endcase
end
always @(*) begin
    case(img_size_tmp)
        2'd0: s[5] = s4[5];
        2'd1: s[5] = s8[5];
        2'd2: s[5] = s16[5];
        default: s[5] = 0;
    endcase
end
always @(*) begin
    case(img_size_tmp)
        2'd0: s[6] = s4[6];
        2'd1: s[6] = s8[6];
        2'd2: s[6] = s16[6];
        default: s[6] = 0;
    endcase
end
always @(*) begin
    case(img_size_tmp)
        2'd0: s[7] = s4[7];
        2'd1: s[7] = s8[7];
        2'd2: s[7] = s16[7];
        default: s[7] = 0;
    endcase
end
always @(*) begin
    case(img_size_tmp)
        2'd0: s[8] = s4[8];
        2'd1: s[8] = s8[8];
        2'd2: s[8] = s16[8];
        default: s[8] = 0;
    endcase
end


always @(*) begin
    case(img_write_filt_cnt[3:0])
        4'd0: s16[0] = (&img_write_filt_cnt[7:4]) ? img16_filt_buffer[16] : ((|img_write_filt_cnt[7:4]) ? img16_filt_buffer[1] : img16_filt_buffer[17]);
        4'd1: s16[0] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[0] : img16_filt_buffer[16];
        4'd2: s16[0] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[1] : img16_filt_buffer[17];
        4'd3: s16[0] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[2] : img16_filt_buffer[18];
        4'd4: s16[0] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[3] : img16_filt_buffer[19];
        4'd5: s16[0] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[4] : img16_filt_buffer[20];
        4'd6: s16[0] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[5] : img16_filt_buffer[21];
        4'd7: s16[0] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[6] : img16_filt_buffer[22];
        4'd8: s16[0] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[7] : img16_filt_buffer[23];
        4'd9: s16[0] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[8] : img16_filt_buffer[24];
        4'd10: s16[0] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[9] : img16_filt_buffer[25];
        4'd11: s16[0] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[10] : img16_filt_buffer[26];
        4'd12: s16[0] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[11] : img16_filt_buffer[27];
        4'd13: s16[0] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[12] : img16_filt_buffer[28];
        4'd14: s16[0] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[13] : img16_filt_buffer[29];
        4'd15: s16[0] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[14] : img16_filt_buffer[30];
    endcase
end
always @(*) begin
    case(img_write_filt_cnt[3:0])
        4'd0: s16[1] = (&img_write_filt_cnt[7:4]) ? img16_filt_buffer[16] : ((|img_write_filt_cnt[7:4]) ? img16_filt_buffer[1] : img16_filt_buffer[17]);
        4'd1: s16[1] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[1] : img16_filt_buffer[17];
        4'd2: s16[1] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[2] : img16_filt_buffer[18];
        4'd3: s16[1] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[3] : img16_filt_buffer[19];
        4'd4: s16[1] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[4] : img16_filt_buffer[20];
        4'd5: s16[1] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[5] : img16_filt_buffer[21];
        4'd6: s16[1] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[6] : img16_filt_buffer[22];
        4'd7: s16[1] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[7] : img16_filt_buffer[23];
        4'd8: s16[1] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[8] : img16_filt_buffer[24];
        4'd9: s16[1] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[9] : img16_filt_buffer[25];
        4'd10: s16[1] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[10] : img16_filt_buffer[26];
        4'd11: s16[1] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[11] : img16_filt_buffer[27];
        4'd12: s16[1] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[12] : img16_filt_buffer[28];
        4'd13: s16[1] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[13] : img16_filt_buffer[29];
        4'd14: s16[1] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[14] : img16_filt_buffer[30];
        4'd15: s16[1] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[15] : img16_filt_buffer[31];
    endcase
end
always @(*) begin
    case(img_write_filt_cnt[3:0])
        4'd0: s16[2] = (&img_write_filt_cnt[7:4]) ? img16_filt_buffer[17] : ((|img_write_filt_cnt[7:4]) ? img16_filt_buffer[2] : img16_filt_buffer[18]);
        4'd1: s16[2] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[2] : img16_filt_buffer[18];
        4'd2: s16[2] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[3] : img16_filt_buffer[19];
        4'd3: s16[2] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[4] : img16_filt_buffer[20];
        4'd4: s16[2] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[5] : img16_filt_buffer[21];
        4'd5: s16[2] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[6] : img16_filt_buffer[22];
        4'd6: s16[2] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[7] : img16_filt_buffer[23];
        4'd7: s16[2] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[8] : img16_filt_buffer[24];
        4'd8: s16[2] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[9] : img16_filt_buffer[25];
        4'd9: s16[2] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[10] : img16_filt_buffer[26];
        4'd10: s16[2] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[11] : img16_filt_buffer[27];
        4'd11: s16[2] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[12] : img16_filt_buffer[28];
        4'd12: s16[2] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[13] : img16_filt_buffer[29];
        4'd13: s16[2] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[14] : img16_filt_buffer[30];
        4'd14: s16[2] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[15] : img16_filt_buffer[31];
        4'd15: s16[2] = (|img_write_filt_cnt[7:4] && (&img_write_filt_cnt[7:4] == 0)) ? img16_filt_buffer[15] : img16_filt_buffer[31];
    endcase
end
always @(*) begin
    case(img_write_filt_cnt[3:0])
        4'd0: s16[3] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[32] : img16_filt_buffer[17];
        4'd1: s16[3] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[32] : img16_filt_buffer[16];
        4'd2: s16[3] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[33] : img16_filt_buffer[17];
        4'd3: s16[3] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[34] : img16_filt_buffer[18];
        4'd4: s16[3] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[35] : img16_filt_buffer[19];
        4'd5: s16[3] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[36] : img16_filt_buffer[20];
        4'd6: s16[3] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[37] : img16_filt_buffer[21];
        4'd7: s16[3] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[38] : img16_filt_buffer[22];
        4'd8: s16[3] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[39] : img16_filt_buffer[23];
        4'd9: s16[3] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[40] : img16_filt_buffer[24];
        4'd10: s16[3] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[41] : img16_filt_buffer[25];
        4'd11: s16[3] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[42] : img16_filt_buffer[26];
        4'd12: s16[3] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[43] : img16_filt_buffer[27];
        4'd13: s16[3] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[44] : img16_filt_buffer[28];
        4'd14: s16[3] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[45] : img16_filt_buffer[29];
        4'd15: s16[3] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[46] : img16_filt_buffer[30];
    endcase
end
always @(*) begin
    case(img_write_filt_cnt[3:0])
        4'd0: s16[4] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[32] : img16_filt_buffer[17];
        4'd1: s16[4] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[33] : img16_filt_buffer[17];
        4'd2: s16[4] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[34] : img16_filt_buffer[18];
        4'd3: s16[4] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[35] : img16_filt_buffer[19];
        4'd4: s16[4] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[36] : img16_filt_buffer[20];
        4'd5: s16[4] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[37] : img16_filt_buffer[21];
        4'd6: s16[4] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[38] : img16_filt_buffer[22];
        4'd7: s16[4] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[39] : img16_filt_buffer[23];
        4'd8: s16[4] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[40] : img16_filt_buffer[24];
        4'd9: s16[4] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[41] : img16_filt_buffer[25];
        4'd10: s16[4] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[42] : img16_filt_buffer[26];
        4'd11: s16[4] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[43] : img16_filt_buffer[27];
        4'd12: s16[4] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[44] : img16_filt_buffer[28];
        4'd13: s16[4] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[45] : img16_filt_buffer[29];
        4'd14: s16[4] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[46] : img16_filt_buffer[30];
        4'd15: s16[4] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[47] : img16_filt_buffer[31];
    endcase
end
always @(*) begin
    case(img_write_filt_cnt[3:0])
        4'd0: s16[5] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[33] : img16_filt_buffer[18];
        4'd1: s16[5] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[34] : img16_filt_buffer[18];
        4'd2: s16[5] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[35] : img16_filt_buffer[19];
        4'd3: s16[5] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[36] : img16_filt_buffer[20];
        4'd4: s16[5] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[37] : img16_filt_buffer[21];
        4'd5: s16[5] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[38] : img16_filt_buffer[22];
        4'd6: s16[5] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[39] : img16_filt_buffer[23];
        4'd7: s16[5] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[40] : img16_filt_buffer[24];
        4'd8: s16[5] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[41] : img16_filt_buffer[25];
        4'd9: s16[5] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[42] : img16_filt_buffer[26];
        4'd10: s16[5] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[43] : img16_filt_buffer[27];
        4'd11: s16[5] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[44] : img16_filt_buffer[28];
        4'd12: s16[5] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[45] : img16_filt_buffer[29];
        4'd13: s16[5] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[46] : img16_filt_buffer[30];
        4'd14: s16[5] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[47] : img16_filt_buffer[31];
        4'd15: s16[5] = &img_write_filt_cnt[7:4] ? img16_filt_buffer[47] : img16_filt_buffer[31];
    endcase
end
always @(*) begin
    case(img_write_filt_cnt[3:0])
        4'd0: s16[6] = (&img_write_filt_cnt[7:4]) ? img16_filt_buffer[32] : img16_filt_buffer[33];
        4'd1: s16[6] = img16_filt_buffer[32];
        4'd2: s16[6] = img16_filt_buffer[33];
        4'd3: s16[6] = img16_filt_buffer[34];
        4'd4: s16[6] = img16_filt_buffer[35];
        4'd5: s16[6] = img16_filt_buffer[36];
        4'd6: s16[6] = img16_filt_buffer[37];
        4'd7: s16[6] = img16_filt_buffer[38];
        4'd8: s16[6] = img16_filt_buffer[39];
        4'd9: s16[6] = img16_filt_buffer[40];
        4'd10: s16[6] = img16_filt_buffer[41];
        4'd11: s16[6] = img16_filt_buffer[42];
        4'd12: s16[6] = img16_filt_buffer[43];
        4'd13: s16[6] = img16_filt_buffer[44];
        4'd14: s16[6] = img16_filt_buffer[45];
        4'd15: s16[6] = img16_filt_buffer[46];
    endcase
end
always @(*) begin
    case(img_write_filt_cnt[3:0])
        4'd0: s16[7] = (&img_write_filt_cnt[7:4]) ? img16_filt_buffer[32] : img16_filt_buffer[33];
        4'd1: s16[7] = img16_filt_buffer[33];
        4'd2: s16[7] = img16_filt_buffer[34];
        4'd3: s16[7] = img16_filt_buffer[35];
        4'd4: s16[7] = img16_filt_buffer[36];
        4'd5: s16[7] = img16_filt_buffer[37];
        4'd6: s16[7] = img16_filt_buffer[38];
        4'd7: s16[7] = img16_filt_buffer[39];
        4'd8: s16[7] = img16_filt_buffer[40];
        4'd9: s16[7] = img16_filt_buffer[41];
        4'd10: s16[7] = img16_filt_buffer[42];
        4'd11: s16[7] = img16_filt_buffer[43];
        4'd12: s16[7] = img16_filt_buffer[44];
        4'd13: s16[7] = img16_filt_buffer[45];
        4'd14: s16[7] = img16_filt_buffer[46];
        4'd15: s16[7] = img16_filt_buffer[47];
    endcase
end
always @(*) begin
    case(img_write_filt_cnt[3:0])
        4'd0: s16[8] = (&img_write_filt_cnt[7:4]) ? img16_filt_buffer[33] : img16_filt_buffer[34];
        4'd1: s16[8] = img16_filt_buffer[34];
        4'd2: s16[8] = img16_filt_buffer[35];
        4'd3: s16[8] = img16_filt_buffer[36];
        4'd4: s16[8] = img16_filt_buffer[37];
        4'd5: s16[8] = img16_filt_buffer[38];
        4'd6: s16[8] = img16_filt_buffer[39];
        4'd7: s16[8] = img16_filt_buffer[40];
        4'd8: s16[8] = img16_filt_buffer[41];
        4'd9: s16[8] = img16_filt_buffer[42];
        4'd10: s16[8] = img16_filt_buffer[43];
        4'd11: s16[8] = img16_filt_buffer[44];
        4'd12: s16[8] = img16_filt_buffer[45];
        4'd13: s16[8] = img16_filt_buffer[46];
        4'd14: s16[8] = img16_filt_buffer[47];
        4'd15: s16[8] = img16_filt_buffer[47];
    endcase
end



always @(*) begin
    case(img_write_filt_cnt[2:0])
        3'd0: s8[0] = (&img_write_filt_cnt[5:3]) ? img16_filt_buffer[32] : ((|img_write_filt_cnt[5:3]) ? img16_filt_buffer[25] : img16_filt_buffer[33]);
        3'd1: s8[0] = (|img_write_filt_cnt[5:3] && (&img_write_filt_cnt[5:3] == 0)) ? img16_filt_buffer[24] : img16_filt_buffer[32];
        3'd2: s8[0] = (|img_write_filt_cnt[5:3] && (&img_write_filt_cnt[5:3] == 0)) ? img16_filt_buffer[25] : img16_filt_buffer[33];
        3'd3: s8[0] = (|img_write_filt_cnt[5:3] && (&img_write_filt_cnt[5:3] == 0)) ? img16_filt_buffer[26] : img16_filt_buffer[34];
        3'd4: s8[0] = (|img_write_filt_cnt[5:3] && (&img_write_filt_cnt[5:3] == 0)) ? img16_filt_buffer[27] : img16_filt_buffer[35];
        3'd5: s8[0] = (|img_write_filt_cnt[5:3] && (&img_write_filt_cnt[5:3] == 0)) ? img16_filt_buffer[28] : img16_filt_buffer[36];
        3'd6: s8[0] = (|img_write_filt_cnt[5:3] && (&img_write_filt_cnt[5:3] == 0)) ? img16_filt_buffer[29] : img16_filt_buffer[37];
        3'd7: s8[0] = (|img_write_filt_cnt[5:3] && (&img_write_filt_cnt[5:3] == 0)) ? img16_filt_buffer[30] : img16_filt_buffer[38];
    endcase
end
always @(*) begin
    case(img_write_filt_cnt[2:0])
        3'd0: s8[1] = (&img_write_filt_cnt[5:3]) ? img16_filt_buffer[32] : ((|img_write_filt_cnt[5:3]) ? img16_filt_buffer[25] : img16_filt_buffer[33]);
        3'd1: s8[1] = (|img_write_filt_cnt[5:3] && (&img_write_filt_cnt[5:3] == 0)) ? img16_filt_buffer[25] : img16_filt_buffer[33];
        3'd2: s8[1] = (|img_write_filt_cnt[5:3] && (&img_write_filt_cnt[5:3] == 0)) ? img16_filt_buffer[26] : img16_filt_buffer[34];
        3'd3: s8[1] = (|img_write_filt_cnt[5:3] && (&img_write_filt_cnt[5:3] == 0)) ? img16_filt_buffer[27] : img16_filt_buffer[35];
        3'd4: s8[1] = (|img_write_filt_cnt[5:3] && (&img_write_filt_cnt[5:3] == 0)) ? img16_filt_buffer[28] : img16_filt_buffer[36];
        3'd5: s8[1] = (|img_write_filt_cnt[5:3] && (&img_write_filt_cnt[5:3] == 0)) ? img16_filt_buffer[29] : img16_filt_buffer[37];
        3'd6: s8[1] = (|img_write_filt_cnt[5:3] && (&img_write_filt_cnt[5:3] == 0)) ? img16_filt_buffer[30] : img16_filt_buffer[38];
        3'd7: s8[1] = (|img_write_filt_cnt[5:3] && (&img_write_filt_cnt[5:3] == 0)) ? img16_filt_buffer[31] : img16_filt_buffer[39];
    endcase
end
always @(*) begin
    case(img_write_filt_cnt[2:0])
        3'd0: s8[2] = (&img_write_filt_cnt[5:3]) ? img16_filt_buffer[33] : ((|img_write_filt_cnt[5:3]) ? img16_filt_buffer[26] : img16_filt_buffer[34]);
        3'd1: s8[2] = (|img_write_filt_cnt[5:3] && (&img_write_filt_cnt[5:3] == 0)) ? img16_filt_buffer[26] : img16_filt_buffer[34];
        3'd2: s8[2] = (|img_write_filt_cnt[5:3] && (&img_write_filt_cnt[5:3] == 0)) ? img16_filt_buffer[27] : img16_filt_buffer[35];
        3'd3: s8[2] = (|img_write_filt_cnt[5:3] && (&img_write_filt_cnt[5:3] == 0)) ? img16_filt_buffer[28] : img16_filt_buffer[36];
        3'd4: s8[2] = (|img_write_filt_cnt[5:3] && (&img_write_filt_cnt[5:3] == 0)) ? img16_filt_buffer[29] : img16_filt_buffer[37];
        3'd5: s8[2] = (|img_write_filt_cnt[5:3] && (&img_write_filt_cnt[5:3] == 0)) ? img16_filt_buffer[30] : img16_filt_buffer[38];
        3'd6: s8[2] = (|img_write_filt_cnt[5:3] && (&img_write_filt_cnt[5:3] == 0)) ? img16_filt_buffer[31] : img16_filt_buffer[39];
        3'd7: s8[2] = (|img_write_filt_cnt[5:3] && (&img_write_filt_cnt[5:3] == 0)) ? img16_filt_buffer[31] : img16_filt_buffer[39];
    endcase
end
always @(*) begin
    case(img_write_filt_cnt[2:0])
        3'd0: s8[3] = &img_write_filt_cnt[5:3] ? img16_filt_buffer[40] : img16_filt_buffer[33];
        3'd1: s8[3] = &img_write_filt_cnt[5:3] ? img16_filt_buffer[40] : img16_filt_buffer[32];
        3'd2: s8[3] = &img_write_filt_cnt[5:3] ? img16_filt_buffer[41] : img16_filt_buffer[33];
        3'd3: s8[3] = &img_write_filt_cnt[5:3] ? img16_filt_buffer[42] : img16_filt_buffer[34];
        3'd4: s8[3] = &img_write_filt_cnt[5:3] ? img16_filt_buffer[43] : img16_filt_buffer[35];
        3'd5: s8[3] = &img_write_filt_cnt[5:3] ? img16_filt_buffer[44] : img16_filt_buffer[36];
        3'd6: s8[3] = &img_write_filt_cnt[5:3] ? img16_filt_buffer[45] : img16_filt_buffer[37];
        3'd7: s8[3] = &img_write_filt_cnt[5:3] ? img16_filt_buffer[46] : img16_filt_buffer[38];
    endcase
end
always @(*) begin
    case(img_write_filt_cnt[2:0])
        3'd0: s8[4] = &img_write_filt_cnt[5:3] ? img16_filt_buffer[40] : img16_filt_buffer[33];
        3'd1: s8[4] = &img_write_filt_cnt[5:3] ? img16_filt_buffer[41] : img16_filt_buffer[33];
        3'd2: s8[4] = &img_write_filt_cnt[5:3] ? img16_filt_buffer[42] : img16_filt_buffer[34];
        3'd3: s8[4] = &img_write_filt_cnt[5:3] ? img16_filt_buffer[43] : img16_filt_buffer[35];
        3'd4: s8[4] = &img_write_filt_cnt[5:3] ? img16_filt_buffer[44] : img16_filt_buffer[36];
        3'd5: s8[4] = &img_write_filt_cnt[5:3] ? img16_filt_buffer[45] : img16_filt_buffer[37];
        3'd6: s8[4] = &img_write_filt_cnt[5:3] ? img16_filt_buffer[46] : img16_filt_buffer[38];
        3'd7: s8[4] = &img_write_filt_cnt[5:3] ? img16_filt_buffer[47] : img16_filt_buffer[39];
    endcase
end
always @(*) begin
    case(img_write_filt_cnt[2:0])
        3'd0: s8[5] = &img_write_filt_cnt[5:3] ? img16_filt_buffer[41] : img16_filt_buffer[34];
        3'd1: s8[5] = &img_write_filt_cnt[5:3] ? img16_filt_buffer[42] : img16_filt_buffer[34];
        3'd2: s8[5] = &img_write_filt_cnt[5:3] ? img16_filt_buffer[43] : img16_filt_buffer[35];
        3'd3: s8[5] = &img_write_filt_cnt[5:3] ? img16_filt_buffer[44] : img16_filt_buffer[36];
        3'd4: s8[5] = &img_write_filt_cnt[5:3] ? img16_filt_buffer[45] : img16_filt_buffer[37];
        3'd5: s8[5] = &img_write_filt_cnt[5:3] ? img16_filt_buffer[46] : img16_filt_buffer[38];
        3'd6: s8[5] = &img_write_filt_cnt[5:3] ? img16_filt_buffer[47] : img16_filt_buffer[39];
        3'd7: s8[5] = &img_write_filt_cnt[5:3] ? img16_filt_buffer[47] : img16_filt_buffer[39];
    endcase
end
always @(*) begin
    case(img_write_filt_cnt[2:0])
        3'd0: s8[6] = (&img_write_filt_cnt[5:3]) ? img16_filt_buffer[40] : img16_filt_buffer[41];
        3'd1: s8[6] = img16_filt_buffer[40];
        3'd2: s8[6] = img16_filt_buffer[41];
        3'd3: s8[6] = img16_filt_buffer[42];
        3'd4: s8[6] = img16_filt_buffer[43];
        3'd5: s8[6] = img16_filt_buffer[44];
        3'd6: s8[6] = img16_filt_buffer[45];
        3'd7: s8[6] = img16_filt_buffer[46];
    endcase
end
always @(*) begin
    case(img_write_filt_cnt[2:0])
        3'd0: s8[7] = (&img_write_filt_cnt[5:3]) ? img16_filt_buffer[40] : img16_filt_buffer[41];
        3'd1: s8[7] = img16_filt_buffer[41];
        3'd2: s8[7] = img16_filt_buffer[42];
        3'd3: s8[7] = img16_filt_buffer[43];
        3'd4: s8[7] = img16_filt_buffer[44];
        3'd5: s8[7] = img16_filt_buffer[45];
        3'd6: s8[7] = img16_filt_buffer[46];
        3'd7: s8[7] = img16_filt_buffer[47];
    endcase
end
always @(*) begin
    case(img_write_filt_cnt[2:0])
        3'd0: s8[8] = (&img_write_filt_cnt[5:3]) ? img16_filt_buffer[41] : img16_filt_buffer[42];
        3'd1: s8[8] = img16_filt_buffer[42];
        3'd2: s8[8] = img16_filt_buffer[43];
        3'd3: s8[8] = img16_filt_buffer[44];
        3'd4: s8[8] = img16_filt_buffer[45];
        3'd5: s8[8] = img16_filt_buffer[46];
        3'd6: s8[8] = img16_filt_buffer[47];
        3'd7: s8[8] = img16_filt_buffer[47];
    endcase
end



always @(*) begin
    case(img_write_filt_cnt[1:0])
        2'd0: s4[0] = (img_write_filt_cnt[2] ^ img_write_filt_cnt[3]) ? img16_filt_buffer[37] : ((img_write_filt_cnt[2] & img_write_filt_cnt[3]) ? img16_filt_buffer[40] : img16_filt_buffer[41]);
        2'd1: s4[0] = (img_write_filt_cnt[2] ^ img_write_filt_cnt[3]) ? img16_filt_buffer[36] : img16_filt_buffer[40];
        2'd2: s4[0] = (img_write_filt_cnt[2] ^ img_write_filt_cnt[3]) ? img16_filt_buffer[37] : img16_filt_buffer[41];
        2'd3: s4[0] = (img_write_filt_cnt[2] ^ img_write_filt_cnt[3]) ? img16_filt_buffer[38] : img16_filt_buffer[42];
    endcase
end
always @(*) begin
    case(img_write_filt_cnt[1:0])
        2'd0: s4[1] = (img_write_filt_cnt[2] & img_write_filt_cnt[3]) ? img16_filt_buffer[40] : ((img_write_filt_cnt[2] ^ img_write_filt_cnt[3]) ? img16_filt_buffer[37] : img16_filt_buffer[41]);
        2'd1: s4[1] = (img_write_filt_cnt[2] ^ img_write_filt_cnt[3]) ? img16_filt_buffer[37] : img16_filt_buffer[41];
        2'd2: s4[1] = (img_write_filt_cnt[2] ^ img_write_filt_cnt[3]) ? img16_filt_buffer[38] : img16_filt_buffer[42];
        2'd3: s4[1] = (img_write_filt_cnt[2] ^ img_write_filt_cnt[3]) ? img16_filt_buffer[39] : img16_filt_buffer[43];
    endcase
end
always @(*) begin
    case(img_write_filt_cnt[1:0])
        2'd0: s4[2] = (img_write_filt_cnt[2] & img_write_filt_cnt[3]) ? img16_filt_buffer[41] : ((img_write_filt_cnt[2] ^ img_write_filt_cnt[3]) ? img16_filt_buffer[38] : img16_filt_buffer[42]);
        2'd1: s4[2] = (img_write_filt_cnt[2] ^ img_write_filt_cnt[3]) ? img16_filt_buffer[38] : img16_filt_buffer[42];
        2'd2: s4[2] = (img_write_filt_cnt[2] ^ img_write_filt_cnt[3]) ? img16_filt_buffer[39] : img16_filt_buffer[43];
        2'd3: s4[2] = (img_write_filt_cnt[2] ^ img_write_filt_cnt[3]) ? img16_filt_buffer[39] : img16_filt_buffer[43];
    endcase
end
always @(*) begin
    case(img_write_filt_cnt[1:0])
        2'd0: s4[3] = (img_write_filt_cnt[3] & img_write_filt_cnt[2]) ? img16_filt_buffer[44] : img16_filt_buffer[41];
        2'd1: s4[3] = (img_write_filt_cnt[3] & img_write_filt_cnt[2]) ? img16_filt_buffer[44] : img16_filt_buffer[40];
        2'd2: s4[3] = (img_write_filt_cnt[3] & img_write_filt_cnt[2]) ? img16_filt_buffer[45] : img16_filt_buffer[41];
        2'd3: s4[3] = (img_write_filt_cnt[3] & img_write_filt_cnt[2]) ? img16_filt_buffer[46] : img16_filt_buffer[42];
    endcase
end
always @(*) begin
    case(img_write_filt_cnt[1:0])
        2'd0: s4[4] = (img_write_filt_cnt[3] & img_write_filt_cnt[2]) ? img16_filt_buffer[44] : img16_filt_buffer[41];
        2'd1: s4[4] = (img_write_filt_cnt[3] & img_write_filt_cnt[2]) ? img16_filt_buffer[45] : img16_filt_buffer[41];
        2'd2: s4[4] = (img_write_filt_cnt[3] & img_write_filt_cnt[2]) ? img16_filt_buffer[46] : img16_filt_buffer[42];
        2'd3: s4[4] = (img_write_filt_cnt[3] & img_write_filt_cnt[2]) ? img16_filt_buffer[47] : img16_filt_buffer[43];
    endcase
end
always @(*) begin
    case(img_write_filt_cnt[1:0])
        2'd0: s4[5] = (img_write_filt_cnt[3] & img_write_filt_cnt[2]) ? img16_filt_buffer[45] : img16_filt_buffer[42];
        2'd1: s4[5] = (img_write_filt_cnt[3] & img_write_filt_cnt[2]) ? img16_filt_buffer[46] : img16_filt_buffer[42];
        2'd2: s4[5] = (img_write_filt_cnt[3] & img_write_filt_cnt[2]) ? img16_filt_buffer[47] : img16_filt_buffer[43];
        2'd3: s4[5] = (img_write_filt_cnt[3] & img_write_filt_cnt[2]) ? img16_filt_buffer[47] : img16_filt_buffer[43];
    endcase
end
always @(*) begin
    case(img_write_filt_cnt[1:0])
        2'd0: s4[6] = (img_write_filt_cnt[3] & img_write_filt_cnt[2]) ? img16_filt_buffer[44] : img16_filt_buffer[45];
        2'd1: s4[6] = img16_filt_buffer[44];
        2'd2: s4[6] = img16_filt_buffer[45];
        2'd3: s4[6] = img16_filt_buffer[46];
    endcase
end
always @(*) begin
    case(img_write_filt_cnt[1:0])
        2'd0: s4[7] = (img_write_filt_cnt[3] & img_write_filt_cnt[2]) ? img16_filt_buffer[44] : img16_filt_buffer[45];
        2'd1: s4[7] = img16_filt_buffer[45];
        2'd2: s4[7] = img16_filt_buffer[46];
        2'd3: s4[7] = img16_filt_buffer[47];
    endcase
end
always @(*) begin
    case(img_write_filt_cnt[1:0])
        2'd0: s4[8] = (img_write_filt_cnt[3] & img_write_filt_cnt[2]) ? img16_filt_buffer[45] : img16_filt_buffer[46];
        2'd1: s4[8] = img16_filt_buffer[46];
        2'd2: s4[8] = img16_filt_buffer[47];
        2'd3: s4[8] = img16_filt_buffer[47];
    endcase
end






always @(*) begin
    case(img_size_tmp)
        2'd0: c[0] = c4[0];
        2'd1: c[0] = c8[0];
        2'd2: c[0] = c16[0];
        default: c[0] = 0;
    endcase
end
always @(*) begin
    case(img_size_tmp)
        2'd0: c[1] = c4[1];
        2'd1: c[1] = c8[1];
        2'd2: c[1] = c16[1];
        default: c[1] = 0;
    endcase
end
always @(*) begin
    case(img_size_tmp)
        2'd0: c[2] = c4[2];
        2'd1: c[2] = c8[2];
        2'd2: c[2] = c16[2];
        default: c[2] = 0;
    endcase
end
always @(*) begin
    case(img_size_tmp)
        2'd0: c[3] = c4[3];
        2'd1: c[3] = c8[3];
        2'd2: c[3] = c16[3];
        default: c[3] = 0;
    endcase
end
always @(*) begin
    case(img_size_tmp)
        2'd0: c[4] = c4[4];
        2'd1: c[4] = c8[4];
        2'd2: c[4] = c16[4];
        default: c[4] = 0;
    endcase
end
always @(*) begin
    case(img_size_tmp)
        2'd0: c[5] = c4[5];
        2'd1: c[5] = c8[5];
        2'd2: c[5] = c16[5];
        default: c[5] = 0;
    endcase
end
always @(*) begin
    case(img_size_tmp)
        2'd0: c[6] = c4[6];
        2'd1: c[6] = c8[6];
        2'd2: c[6] = c16[6];
        default: c[6] = 0;
    endcase
end
always @(*) begin
    case(img_size_tmp)
        2'd0: c[7] = c4[7];
        2'd1: c[7] = c8[7];
        2'd2: c[7] = c16[7];
        default: c[7] = 0;
    endcase
end
always @(*) begin
    case(img_size_tmp)
        2'd0: c[8] = c4[8];
        2'd1: c[8] = c8[8];
        2'd2: c[8] = c16[8];
        default: c[8] = 0;
    endcase
end




always @(*) begin
    case(img_write_cor_cnt[3:0])
    4'd0: c16[0] = 0;
    4'd1: c16[0] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[16] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[0] : 0);
    4'd2: c16[0] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[17] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[1] : 0);
    4'd3: c16[0] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[18] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[2] : 0);
    4'd4: c16[0] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[19] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[3] : 0);
    4'd5: c16[0] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[20] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[4] : 0);
    4'd6: c16[0] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[21] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[5] : 0);
    4'd7: c16[0] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[22] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[6] : 0);
    4'd8: c16[0] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[23] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[7] : 0);
    4'd9: c16[0] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[24] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[8] : 0);
    4'd10: c16[0] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[25] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[9] : 0);
    4'd11: c16[0] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[26] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[10] : 0);
    4'd12: c16[0] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[27] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[11] : 0);
    4'd13: c16[0] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[28] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[12] : 0);
    4'd14: c16[0] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[29] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[13] : 0);
    4'd15: c16[0] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[30] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[14] : 0);
    endcase
end
always @(*) begin
    case(img_write_cor_cnt[3:0])
    4'd0: c16[1] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[16] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[1] : 0);
    4'd1: c16[1] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[17] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[1] : 0);
    4'd2: c16[1] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[18] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[2] : 0);
    4'd3: c16[1] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[19] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[3] : 0);
    4'd4: c16[1] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[20] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[4] : 0);
    4'd5: c16[1] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[21] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[5] : 0);
    4'd6: c16[1] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[22] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[6] : 0);
    4'd7: c16[1] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[23] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[7] : 0);
    4'd8: c16[1] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[24] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[8] : 0);
    4'd9: c16[1] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[25] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[9] : 0);
    4'd10: c16[1] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[26] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[10] : 0);
    4'd11: c16[1] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[27] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[11] : 0);
    4'd12: c16[1] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[28] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[12] : 0);
    4'd13: c16[1] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[29] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[13] : 0);
    4'd14: c16[1] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[30] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[14] : 0);
    4'd15: c16[1] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[31] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[15] : 0);
    endcase
end
always @(*) begin
    case(img_write_cor_cnt[3:0])
    4'd0: c16[2] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[17] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[2] : 0);
    4'd1: c16[2] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[18] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[2] : 0);
    4'd2: c16[2] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[19] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[3] : 0);
    4'd3: c16[2] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[20] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[4] : 0);
    4'd4: c16[2] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[21] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[5] : 0);
    4'd5: c16[2] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[22] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[6] : 0);
    4'd6: c16[2] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[23] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[7] : 0);
    4'd7: c16[2] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[24] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[8] : 0);
    4'd8: c16[2] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[25] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[9] : 0);
    4'd9: c16[2] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[26] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[10] : 0);
    4'd10: c16[2] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[27] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[11] : 0);
    4'd11: c16[2] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[28] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[12] : 0);
    4'd12: c16[2] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[29] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[13] : 0);
    4'd13: c16[2] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[30] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[14] : 0);
    4'd14: c16[2] = (&img_write_cor_cnt[7:4]) ? img16_cor_buffer[31] : ((|img_write_cor_cnt[7:4]) ? img16_cor_buffer[15] : 0);
    4'd15: c16[2] = 0;
    endcase
end
always @(*) begin
    case(img_write_cor_cnt[3:0])
    4'd0: c16[3] = 0;
    4'd1: c16[3] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[32] : img16_cor_buffer[16];
    4'd2: c16[3] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[33] : img16_cor_buffer[17];
    4'd3: c16[3] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[34] : img16_cor_buffer[18];
    4'd4: c16[3] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[35] : img16_cor_buffer[19];
    4'd5: c16[3] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[36] : img16_cor_buffer[20];
    4'd6: c16[3] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[37] : img16_cor_buffer[21];
    4'd7: c16[3] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[38] : img16_cor_buffer[22];
    4'd8: c16[3] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[39] : img16_cor_buffer[23];
    4'd9: c16[3] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[40] : img16_cor_buffer[24];
    4'd10: c16[3] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[41] : img16_cor_buffer[25];
    4'd11: c16[3] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[42] : img16_cor_buffer[26];
    4'd12: c16[3] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[43] : img16_cor_buffer[27];
    4'd13: c16[3] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[44] : img16_cor_buffer[28];
    4'd14: c16[3] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[45] : img16_cor_buffer[29];
    4'd15: c16[3] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[46] : img16_cor_buffer[30];
    endcase
end
always @(*) begin
    case(img_write_cor_cnt[3:0])
    4'd0: c16[4] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[32] : img16_cor_buffer[17];
    4'd1: c16[4] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[33] : img16_cor_buffer[17];
    4'd2: c16[4] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[34] : img16_cor_buffer[18];
    4'd3: c16[4] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[35] : img16_cor_buffer[19];
    4'd4: c16[4] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[36] : img16_cor_buffer[20];
    4'd5: c16[4] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[37] : img16_cor_buffer[21];
    4'd6: c16[4] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[38] : img16_cor_buffer[22];
    4'd7: c16[4] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[39] : img16_cor_buffer[23];
    4'd8: c16[4] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[40] : img16_cor_buffer[24];
    4'd9: c16[4] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[41] : img16_cor_buffer[25];
    4'd10: c16[4] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[42] : img16_cor_buffer[26];
    4'd11: c16[4] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[43] : img16_cor_buffer[27];
    4'd12: c16[4] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[44] : img16_cor_buffer[28];
    4'd13: c16[4] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[45] : img16_cor_buffer[29];
    4'd14: c16[4] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[46] : img16_cor_buffer[30];
    4'd15: c16[4] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[47] : img16_cor_buffer[31];
    endcase
end
always @(*) begin
    case(img_write_cor_cnt[3:0])
    4'd0: c16[5] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[33] : img16_cor_buffer[18];
    4'd1: c16[5] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[34] : img16_cor_buffer[18];
    4'd2: c16[5] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[35] : img16_cor_buffer[19];
    4'd3: c16[5] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[36] : img16_cor_buffer[20];
    4'd4: c16[5] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[37] : img16_cor_buffer[21];
    4'd5: c16[5] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[38] : img16_cor_buffer[22];
    4'd6: c16[5] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[39] : img16_cor_buffer[23];
    4'd7: c16[5] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[40] : img16_cor_buffer[24];
    4'd8: c16[5] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[41] : img16_cor_buffer[25];
    4'd9: c16[5] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[42] : img16_cor_buffer[26];
    4'd10: c16[5] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[43] : img16_cor_buffer[27];
    4'd11: c16[5] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[44] : img16_cor_buffer[28];
    4'd12: c16[5] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[45] : img16_cor_buffer[29];
    4'd13: c16[5] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[46] : img16_cor_buffer[30];
    4'd14: c16[5] = &img_write_cor_cnt[7:4] ? img16_cor_buffer[47] : img16_cor_buffer[31];
    4'd15: c16[5] = 0;
    endcase
end
always @(*) begin
    case(img_write_cor_cnt[3:0])
    4'd0: c16[6] = 0;
    4'd1: c16[6] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[32];
    4'd2: c16[6] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[33];
    4'd3: c16[6] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[34];
    4'd4: c16[6] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[35];
    4'd5: c16[6] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[36];
    4'd6: c16[6] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[37];
    4'd7: c16[6] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[38];
    4'd8: c16[6] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[39];
    4'd9: c16[6] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[40];
    4'd10: c16[6] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[41];
    4'd11: c16[6] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[42];
    4'd12: c16[6] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[43];
    4'd13: c16[6] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[44];
    4'd14: c16[6] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[45];
    4'd15: c16[6] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[46];
    endcase
end
always @(*) begin
    case(img_write_cor_cnt[3:0])
    4'd0: c16[7] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[33];
    4'd1: c16[7] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[33];
    4'd2: c16[7] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[34];
    4'd3: c16[7] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[35];
    4'd4: c16[7] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[36];
    4'd5: c16[7] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[37];
    4'd6: c16[7] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[38];
    4'd7: c16[7] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[39];
    4'd8: c16[7] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[40];
    4'd9: c16[7] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[41];
    4'd10: c16[7] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[42];
    4'd11: c16[7] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[43];
    4'd12: c16[7] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[44];
    4'd13: c16[7] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[45];
    4'd14: c16[7] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[46];
    4'd15: c16[7] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[47];
    endcase
end
always @(*) begin
    case(img_write_cor_cnt[3:0])
    4'd0: c16[8] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[34];
    4'd1: c16[8] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[34];
    4'd2: c16[8] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[35];
    4'd3: c16[8] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[36];
    4'd4: c16[8] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[37];
    4'd5: c16[8] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[38];
    4'd6: c16[8] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[39];
    4'd7: c16[8] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[40];
    4'd8: c16[8] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[41];
    4'd9: c16[8] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[42];
    4'd10: c16[8] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[43];
    4'd11: c16[8] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[44];
    4'd12: c16[8] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[45];
    4'd13: c16[8] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[46];
    4'd14: c16[8] = (&img_write_cor_cnt[7:4]) ? 0 : img16_cor_buffer[47];
    4'd15: c16[8] = 0;
    endcase
end


always @(*) begin
    case(img_write_cor_cnt[2:0])
    4'd0: c8[0] = 0;
    4'd1: c8[0] = (&img_write_cor_cnt[5:3]) ? img16_cor_buffer[32] : ((|img_write_cor_cnt[5:3]) ? img16_cor_buffer[24] : 0);
    4'd2: c8[0] = (&img_write_cor_cnt[5:3]) ? img16_cor_buffer[33] : ((|img_write_cor_cnt[5:3]) ? img16_cor_buffer[25] : 0);
    4'd3: c8[0] = (&img_write_cor_cnt[5:3]) ? img16_cor_buffer[34] : ((|img_write_cor_cnt[5:3]) ? img16_cor_buffer[26] : 0);
    4'd4: c8[0] = (&img_write_cor_cnt[5:3]) ? img16_cor_buffer[35] : ((|img_write_cor_cnt[5:3]) ? img16_cor_buffer[27] : 0);
    4'd5: c8[0] = (&img_write_cor_cnt[5:3]) ? img16_cor_buffer[36] : ((|img_write_cor_cnt[5:3]) ? img16_cor_buffer[28] : 0);
    4'd6: c8[0] = (&img_write_cor_cnt[5:3]) ? img16_cor_buffer[37] : ((|img_write_cor_cnt[5:3]) ? img16_cor_buffer[29] : 0);
    4'd7: c8[0] = (&img_write_cor_cnt[5:3]) ? img16_cor_buffer[38] : ((|img_write_cor_cnt[5:3]) ? img16_cor_buffer[30] : 0);
    endcase
end
always @(*) begin
    case(img_write_cor_cnt[2:0])
    4'd0: c8[1] = (&img_write_cor_cnt[5:3]) ? img16_cor_buffer[32] : ((|img_write_cor_cnt[5:3]) ? img16_cor_buffer[25] : 0);
    4'd1: c8[1] = (&img_write_cor_cnt[5:3]) ? img16_cor_buffer[33] : ((|img_write_cor_cnt[5:3]) ? img16_cor_buffer[25] : 0);
    4'd2: c8[1] = (&img_write_cor_cnt[5:3]) ? img16_cor_buffer[34] : ((|img_write_cor_cnt[5:3]) ? img16_cor_buffer[26] : 0);
    4'd3: c8[1] = (&img_write_cor_cnt[5:3]) ? img16_cor_buffer[35] : ((|img_write_cor_cnt[5:3]) ? img16_cor_buffer[27] : 0);
    4'd4: c8[1] = (&img_write_cor_cnt[5:3]) ? img16_cor_buffer[36] : ((|img_write_cor_cnt[5:3]) ? img16_cor_buffer[28] : 0);
    4'd5: c8[1] = (&img_write_cor_cnt[5:3]) ? img16_cor_buffer[37] : ((|img_write_cor_cnt[5:3]) ? img16_cor_buffer[29] : 0);
    4'd6: c8[1] = (&img_write_cor_cnt[5:3]) ? img16_cor_buffer[38] : ((|img_write_cor_cnt[5:3]) ? img16_cor_buffer[30] : 0);
    4'd7: c8[1] = (&img_write_cor_cnt[5:3]) ? img16_cor_buffer[39] : ((|img_write_cor_cnt[5:3]) ? img16_cor_buffer[31] : 0);
    endcase
end
always @(*) begin
    case(img_write_cor_cnt[2:0])
    4'd0: c8[2] = (&img_write_cor_cnt[5:3]) ? img16_cor_buffer[33] : ((|img_write_cor_cnt[5:3]) ? img16_cor_buffer[26] : 0);
    4'd1: c8[2] = (&img_write_cor_cnt[5:3]) ? img16_cor_buffer[34] : ((|img_write_cor_cnt[5:3]) ? img16_cor_buffer[26] : 0);
    4'd2: c8[2] = (&img_write_cor_cnt[5:3]) ? img16_cor_buffer[35] : ((|img_write_cor_cnt[5:3]) ? img16_cor_buffer[27] : 0);
    4'd3: c8[2] = (&img_write_cor_cnt[5:3]) ? img16_cor_buffer[36] : ((|img_write_cor_cnt[5:3]) ? img16_cor_buffer[28] : 0);
    4'd4: c8[2] = (&img_write_cor_cnt[5:3]) ? img16_cor_buffer[37] : ((|img_write_cor_cnt[5:3]) ? img16_cor_buffer[29] : 0);
    4'd5: c8[2] = (&img_write_cor_cnt[5:3]) ? img16_cor_buffer[38] : ((|img_write_cor_cnt[5:3]) ? img16_cor_buffer[30] : 0);
    4'd6: c8[2] = (&img_write_cor_cnt[5:3]) ? img16_cor_buffer[39] : ((|img_write_cor_cnt[5:3]) ? img16_cor_buffer[31] : 0);
    4'd7: c8[2] = 0;
    endcase
end
always @(*) begin
    case(img_write_cor_cnt[2:0])
    4'd0: c8[3] = 0;
    4'd1: c8[3] = &img_write_cor_cnt[5:3] ? img16_cor_buffer[40] : img16_cor_buffer[32];
    4'd2: c8[3] = &img_write_cor_cnt[5:3] ? img16_cor_buffer[41] : img16_cor_buffer[33];
    4'd3: c8[3] = &img_write_cor_cnt[5:3] ? img16_cor_buffer[42] : img16_cor_buffer[34];
    4'd4: c8[3] = &img_write_cor_cnt[5:3] ? img16_cor_buffer[43] : img16_cor_buffer[35];
    4'd5: c8[3] = &img_write_cor_cnt[5:3] ? img16_cor_buffer[44] : img16_cor_buffer[36];
    4'd6: c8[3] = &img_write_cor_cnt[5:3] ? img16_cor_buffer[45] : img16_cor_buffer[37];
    4'd7: c8[3] = &img_write_cor_cnt[5:3] ? img16_cor_buffer[46] : img16_cor_buffer[38];
    endcase
end
always @(*) begin
    case(img_write_cor_cnt[2:0])
    4'd0: c8[4] = &img_write_cor_cnt[5:3] ? img16_cor_buffer[40] : img16_cor_buffer[33];
    4'd1: c8[4] = &img_write_cor_cnt[5:3] ? img16_cor_buffer[41] : img16_cor_buffer[33];
    4'd2: c8[4] = &img_write_cor_cnt[5:3] ? img16_cor_buffer[42] : img16_cor_buffer[34];
    4'd3: c8[4] = &img_write_cor_cnt[5:3] ? img16_cor_buffer[43] : img16_cor_buffer[35];
    4'd4: c8[4] = &img_write_cor_cnt[5:3] ? img16_cor_buffer[44] : img16_cor_buffer[36];
    4'd5: c8[4] = &img_write_cor_cnt[5:3] ? img16_cor_buffer[45] : img16_cor_buffer[37];
    4'd6: c8[4] = &img_write_cor_cnt[5:3] ? img16_cor_buffer[46] : img16_cor_buffer[38];
    4'd7: c8[4] = &img_write_cor_cnt[5:3] ? img16_cor_buffer[47] : img16_cor_buffer[39];
    endcase
end
always @(*) begin
    case(img_write_cor_cnt[2:0])
    4'd0: c8[5] = &img_write_cor_cnt[5:3] ? img16_cor_buffer[41] : img16_cor_buffer[34];
    4'd1: c8[5] = &img_write_cor_cnt[5:3] ? img16_cor_buffer[42] : img16_cor_buffer[34];
    4'd2: c8[5] = &img_write_cor_cnt[5:3] ? img16_cor_buffer[43] : img16_cor_buffer[35];
    4'd3: c8[5] = &img_write_cor_cnt[5:3] ? img16_cor_buffer[44] : img16_cor_buffer[36];
    4'd4: c8[5] = &img_write_cor_cnt[5:3] ? img16_cor_buffer[45] : img16_cor_buffer[37];
    4'd5: c8[5] = &img_write_cor_cnt[5:3] ? img16_cor_buffer[46] : img16_cor_buffer[38];
    4'd6: c8[5] = &img_write_cor_cnt[5:3] ? img16_cor_buffer[47] : img16_cor_buffer[39];
    4'd7: c8[5] = 0;
    endcase
end
always @(*) begin
    case(img_write_cor_cnt[2:0])
    4'd0: c8[6] = 0;
    4'd1: c8[6] = &img_write_cor_cnt[5:3] ? 0 : img16_cor_buffer[40];
    4'd2: c8[6] = &img_write_cor_cnt[5:3] ? 0 : img16_cor_buffer[41];
    4'd3: c8[6] = &img_write_cor_cnt[5:3] ? 0 : img16_cor_buffer[42];
    4'd4: c8[6] = &img_write_cor_cnt[5:3] ? 0 : img16_cor_buffer[43];
    4'd5: c8[6] = &img_write_cor_cnt[5:3] ? 0 : img16_cor_buffer[44];
    4'd6: c8[6] = &img_write_cor_cnt[5:3] ? 0 : img16_cor_buffer[45];
    4'd7: c8[6] = &img_write_cor_cnt[5:3] ? 0 : img16_cor_buffer[46];
    endcase
end
always @(*) begin
    case(img_write_cor_cnt[2:0])
    4'd0: c8[7] = &img_write_cor_cnt[5:3] ? 0 : img16_cor_buffer[41];
    4'd1: c8[7] = &img_write_cor_cnt[5:3] ? 0 : img16_cor_buffer[41];
    4'd2: c8[7] = &img_write_cor_cnt[5:3] ? 0 : img16_cor_buffer[42];
    4'd3: c8[7] = &img_write_cor_cnt[5:3] ? 0 : img16_cor_buffer[43];
    4'd4: c8[7] = &img_write_cor_cnt[5:3] ? 0 : img16_cor_buffer[44];
    4'd5: c8[7] = &img_write_cor_cnt[5:3] ? 0 : img16_cor_buffer[45];
    4'd6: c8[7] = &img_write_cor_cnt[5:3] ? 0 : img16_cor_buffer[46];
    4'd7: c8[7] = &img_write_cor_cnt[5:3] ? 0 : img16_cor_buffer[47];
    endcase
end
always @(*) begin
    case(img_write_cor_cnt[2:0])
    4'd0: c8[8] = &img_write_cor_cnt[5:3] ? 0 : img16_cor_buffer[42];
    4'd1: c8[8] = &img_write_cor_cnt[5:3] ? 0 : img16_cor_buffer[42];
    4'd2: c8[8] = &img_write_cor_cnt[5:3] ? 0 : img16_cor_buffer[43];
    4'd3: c8[8] = &img_write_cor_cnt[5:3] ? 0 : img16_cor_buffer[44];
    4'd4: c8[8] = &img_write_cor_cnt[5:3] ? 0 : img16_cor_buffer[45];
    4'd5: c8[8] = &img_write_cor_cnt[5:3] ? 0 : img16_cor_buffer[46];
    4'd6: c8[8] = &img_write_cor_cnt[5:3] ? 0 : img16_cor_buffer[47];
    4'd7: c8[8] = 0;
    endcase
end


always @(*) begin
    case(img_write_cor_cnt[1:0])
    4'd0: c4[0] = 0;
    4'd1: c4[0] = (img_write_cor_cnt[2] ^ img_write_cor_cnt[3]) ? img16_cor_buffer[36] : ((img_write_cor_cnt[2] & img_write_cor_cnt[3]) ? img16_cor_buffer[40] : 0);
    4'd2: c4[0] = (img_write_cor_cnt[2] ^ img_write_cor_cnt[3]) ? img16_cor_buffer[37] : ((img_write_cor_cnt[2] & img_write_cor_cnt[3]) ? img16_cor_buffer[41] : 0);
    4'd3: c4[0] = (img_write_cor_cnt[2] ^ img_write_cor_cnt[3]) ? img16_cor_buffer[38] : ((img_write_cor_cnt[2] & img_write_cor_cnt[3]) ? img16_cor_buffer[42] : 0);
    endcase
end
always @(*) begin
    case(img_write_cor_cnt[1:0])
    4'd0: c4[1] = (img_write_cor_cnt[2] ^ img_write_cor_cnt[3]) ? img16_cor_buffer[37] : ((img_write_cor_cnt[2] & img_write_cor_cnt[3]) ? img16_cor_buffer[40] : 0);
    4'd1: c4[1] = (img_write_cor_cnt[2] ^ img_write_cor_cnt[3]) ? img16_cor_buffer[37] : ((img_write_cor_cnt[2] & img_write_cor_cnt[3]) ? img16_cor_buffer[41] : 0);
    4'd2: c4[1] = (img_write_cor_cnt[2] ^ img_write_cor_cnt[3]) ? img16_cor_buffer[38] : ((img_write_cor_cnt[2] & img_write_cor_cnt[3]) ? img16_cor_buffer[42] : 0);
    4'd3: c4[1] = (img_write_cor_cnt[2] ^ img_write_cor_cnt[3]) ? img16_cor_buffer[39] : ((img_write_cor_cnt[2] & img_write_cor_cnt[3]) ? img16_cor_buffer[43] : 0);
    endcase
end
always @(*) begin
    case(img_write_cor_cnt[1:0])
    4'd0: c4[2] = (img_write_cor_cnt[2] ^ img_write_cor_cnt[3]) ? img16_cor_buffer[38] : ((img_write_cor_cnt[2] & img_write_cor_cnt[3]) ? img16_cor_buffer[41] : 0);
    4'd1: c4[2] = (img_write_cor_cnt[2] ^ img_write_cor_cnt[3]) ? img16_cor_buffer[38] : ((img_write_cor_cnt[2] & img_write_cor_cnt[3]) ? img16_cor_buffer[42] : 0);
    4'd2: c4[2] = (img_write_cor_cnt[2] ^ img_write_cor_cnt[3]) ? img16_cor_buffer[39] : ((img_write_cor_cnt[2] & img_write_cor_cnt[3]) ? img16_cor_buffer[43] : 0);
    4'd3: c4[2] = 0;
    endcase
end
always @(*) begin
    case(img_write_cor_cnt[1:0])
    4'd0: c4[3] = 0;
    4'd1: c4[3] = (img_write_cor_cnt[2] & img_write_cor_cnt[3]) ? img16_cor_buffer[44] : img16_cor_buffer[40];
    4'd2: c4[3] = (img_write_cor_cnt[2] & img_write_cor_cnt[3]) ? img16_cor_buffer[45] : img16_cor_buffer[41];
    4'd3: c4[3] = (img_write_cor_cnt[2] & img_write_cor_cnt[3]) ? img16_cor_buffer[46] : img16_cor_buffer[42];
    endcase
end
always @(*) begin
    case(img_write_cor_cnt[1:0])
    4'd0: c4[4] = (img_write_cor_cnt[2] & img_write_cor_cnt[3]) ? img16_cor_buffer[44] : img16_cor_buffer[41];
    4'd1: c4[4] = (img_write_cor_cnt[2] & img_write_cor_cnt[3]) ? img16_cor_buffer[45] : img16_cor_buffer[41];
    4'd2: c4[4] = (img_write_cor_cnt[2] & img_write_cor_cnt[3]) ? img16_cor_buffer[46] : img16_cor_buffer[42];
    4'd3: c4[4] = (img_write_cor_cnt[2] & img_write_cor_cnt[3]) ? img16_cor_buffer[47] : img16_cor_buffer[43];
    endcase
end
always @(*) begin
    case(img_write_cor_cnt[1:0])
    4'd0: c4[5] = (img_write_cor_cnt[2] & img_write_cor_cnt[3]) ? img16_cor_buffer[45] : img16_cor_buffer[42];
    4'd1: c4[5] = (img_write_cor_cnt[2] & img_write_cor_cnt[3]) ? img16_cor_buffer[46] : img16_cor_buffer[42];
    4'd2: c4[5] = (img_write_cor_cnt[2] & img_write_cor_cnt[3]) ? img16_cor_buffer[47] : img16_cor_buffer[43];
    4'd3: c4[5] = 0;
    endcase
end
always @(*) begin
    case(img_write_cor_cnt[1:0])
    4'd0: c4[6] = 0;
    4'd1: c4[6] = (img_write_cor_cnt[2] & img_write_cor_cnt[3]) ? 0 : img16_cor_buffer[44];
    4'd2: c4[6] = (img_write_cor_cnt[2] & img_write_cor_cnt[3]) ? 0 : img16_cor_buffer[45];
    4'd3: c4[6] = (img_write_cor_cnt[2] & img_write_cor_cnt[3]) ? 0 : img16_cor_buffer[46];
    endcase
end
always @(*) begin
    case(img_write_cor_cnt[1:0])
    4'd0: c4[7] = (img_write_cor_cnt[2] & img_write_cor_cnt[3]) ? 0 : img16_cor_buffer[45];
    4'd1: c4[7] = (img_write_cor_cnt[2] & img_write_cor_cnt[3]) ? 0 : img16_cor_buffer[45];
    4'd2: c4[7] = (img_write_cor_cnt[2] & img_write_cor_cnt[3]) ? 0 : img16_cor_buffer[46];
    4'd3: c4[7] = (img_write_cor_cnt[2] & img_write_cor_cnt[3]) ? 0 : img16_cor_buffer[47];
    endcase
end
always @(*) begin
    case(img_write_cor_cnt[1:0])
    4'd0: c4[8] = (img_write_cor_cnt[2] & img_write_cor_cnt[3]) ? 0 : img16_cor_buffer[46];
    4'd1: c4[8] = (img_write_cor_cnt[2] & img_write_cor_cnt[3]) ? 0 : img16_cor_buffer[46];
    4'd2: c4[8] = (img_write_cor_cnt[2] & img_write_cor_cnt[3]) ? 0 : img16_cor_buffer[47];
    4'd3: c4[8] = 0;
    endcase
end


CORRELATION cor(.s0(c[0]),.s1(c[1]),.s2(c[2]),.s3(c[3]),.s4(c[4]),.s5(c[5]),.s6(c[6]),.s7(c[7]),.s8(c[8]),.t0(template_reg[0]),.t1(template_reg[1]),.t2(template_reg[2]),.t3(template_reg[3]),.t4(template_reg[4]),.t5(template_reg[5]),.t6(template_reg[6]),.t7(template_reg[7]),.t8(template_reg[8]),.out(cor_out));
OUTPUT_SRAM OUT_S (
    .CK(clk),
    .WEB(rw_control),
    .OE(1'b1),
    .CS(1'b1),
    .A0(img_write_cor_cnt_w[0]),.A1(img_write_cor_cnt_w[1]),.A2(img_write_cor_cnt_w[2]),.A3(img_write_cor_cnt_w[3]),.A4(img_write_cor_cnt_w[4]),.A5(img_write_cor_cnt_w[5]),.A6(img_write_cor_cnt_w[6]),.A7(img_write_cor_cnt_w[7]),
    .DO0(final_out[0]),.DO1(final_out[1]),.DO2(final_out[2]),.DO3(final_out[3]),.DO4(final_out[4]),.DO5(final_out[5]),.DO6(final_out[6]),.DO7(final_out[7]),.DO8(final_out[8]),.DO9(final_out[9]),.DO10(final_out[10]),.DO11(final_out[11]),.DO12(final_out[12]),.DO13(final_out[13]),.DO14(final_out[14]),.DO15(final_out[15]),.DO16(final_out[16]),.DO17(final_out[17]),.DO18(final_out[18]),.DO19(final_out[19]),
    .DI0(cor_out[0]),.DI1(cor_out[1]),.DI2(cor_out[2]),.DI3(cor_out[3]),.DI4(cor_out[4]),.DI5(cor_out[5]),.DI6(cor_out[6]),.DI7(cor_out[7]),.DI8(cor_out[8]),.DI9(cor_out[9]),.DI10(cor_out[10]),.DI11(cor_out[11]),.DI12(cor_out[12]),.DI13(cor_out[13]),.DI14(cor_out[14]),.DI15(cor_out[15]),.DI16(cor_out[16]),.DI17(cor_out[17]),.DI18(cor_out[18]),.DI19(cor_out[19])
);



always @(*) begin
    case(current_state)
        READ: begin
            case(img_cnt%3)
                2'd1: img_write = img_write_tmp[0];
                2'd2: img_write = img_write_tmp[1];
                2'd0: img_write = img_write_tmp[2];
                default : img_write = 0;
            endcase
        end
        FILT: begin
            img_write = filt_out;
        end
        MP: begin
            img_write = mp_out;
        end
        NEG: begin
            img_write = neg_out;
        end
        FLIP: begin
            img_write = flip_out;
        end
        default: img_write = 0;
    endcase
end




always @(*) begin
    case(current_state)
        READ: begin
            case(img_cnt%3)
                3'd1: img_address = ((img_cnt/3 - 1) > 1279) ? 0 : (img_cnt/3 - 1);
                3'd2: img_address = img_cnt/3 + 255;
                3'd0: img_address = img_cnt/3 + 510;
                default: img_address = 0;
            endcase
        end
        MP: begin
            img_address = img_mp_cnt;
        end
        FILT: begin
            img_address = img_filt_cnt;
        end
        NEG: begin
            img_address = img_neg_cnt;
        end
        FLIP: begin
            img_address = img_flip_cnt;
        end
        OUTPUT_S: begin
            img_address = img_cor_cnt;
        end
        default: img_address = 0;
    endcase
end




always @(*) begin
    if((img_cnt > 3 && read_stop) || img_rw_filt_control || img_rw_mp_control || img_rw_neg_control || img_cor_control || img_rw_flip_control_buff) rw_control = 0;
    else rw_control = 1;
end

assign img_write_cor_cnt_w = img_write_cor_cnt;


SRAM SR(.CK(clk),.WEB(rw_control),.OE(1'b1),.CS(1'b1),
        .A0(img_address[0]),.A1(img_address[1]),.A2(img_address[2]),.A3(img_address[3]),.A4(img_address[4]),.A5(img_address[5]),.A6(img_address[6]),.A7(img_address[7]),.A8(img_address[8]),.A9(img_address[9]),.A10(img_address[10])
        ,.DO0(img[0]),.DO1(img[1]),.DO2(img[2]),.DO3(img[3]),.DO4(img[4]),.DO5(img[5]),.DO6(img[6]),.DO7(img[7])
        ,.DI0(img_write[0]),.DI1(img_write[1]),.DI2(img_write[2]),.DI3(img_write[3]),.DI4(img_write[4]),.DI5(img_write[5]),.DI6(img_write[6]),.DI7(img_write[7]));

endmodule

module sorting(
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
    input [7:0] s0,s1,s2,s3,s4,s5,s6,s7,s8,t0,t1,t2,t3,t4,t5,t6,t7,t8,
    output [19:0] out
);
    wire [19:0] mult[0:8];
    //wire [19:0] out_w;

    assign mult[0] = s0*t0;
    assign mult[1] = s1*t1;
    assign mult[2] = s2*t2;
    assign mult[3] = s3*t3;
    assign mult[4] = s4*t4;
    assign mult[5] = s5*t5;
    assign mult[6] = s6*t6;
    assign mult[7] = s7*t7;
    assign mult[8] = s8*t8;
    assign out = mult[0] + ((mult[1] + mult[2]) + (mult[3] + mult[4])) + ((mult[5] + mult[6]) + (mult[7] + mult[8]));
    

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