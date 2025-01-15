//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab04 Exercise		: Convolution Neural Network 
//   Author     		: Yu-Chi Lin (a6121461214.st12@nycu.edu.tw)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CNN.v
//   Module Name : CNN
//   Release version : V1.0 (Release Date: 2024-10)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module CNN(
    //Input Port
    clk,
    rst_n,
    in_valid,
    Img,
    Kernel_ch1,
    Kernel_ch2,
	Weight,
    Opt,

    //Output Port
    out_valid,
    out
    );


//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------

// IEEE floating point parameter
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;

/* parameter IDLE = 3'd0;
parameter IN = 3'd1;
parameter CAL = 3'd2;
parameter OUT = 3'd3; */

input rst_n, clk, in_valid;
input [inst_sig_width+inst_exp_width:0] Img, Kernel_ch1, Kernel_ch2, Weight;
input Opt;

output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;


//---------------------------------------------------------------------
//   Reg & Wires
//---------------------------------------------------------------------


//---------------------------------------------------------------------
// IPs
//---------------------------------------------------------------------


//---------------------------------------------------------------------
// Design
//---------------------------------------------------------------------
//==============================================//
//             Parameter and Integer            //
//==============================================//
integer i;
//parameter
parameter FP_minus1 = 32'hBF800000;
parameter FP0 = 32'h00000000;
parameter FP1 = 32'h3F800000;
parameter FPminus =  32'b11111111100000000000000000000000;
parameter FP_TANH_0 = FP0;   
parameter FP_TANH_1 = 32'h3F42F7D6;     //0.76159415595
parameter FP_SIGM_0 = 32'h3f000000;   //0.5
parameter FP_SIGM_1 = 32'h3F3B26A8;   //0.73105857863
parameter FP_SOFTP_0 = 32'h3F317218; 
parameter FP_SOFTP_1 = 32'h3FA818F6;  //3FA818F5
//================================================================
//  
//================================================================

//================================================================
//   Wires & Registers 
//================================================================
wire [6:0] n_cnt;
wire [5:0] n_cnt_2;
reg  [6:0] cnt;
reg  [5:0] cnt_2;

reg mode;
reg [inst_sig_width + inst_exp_width:0] img [0:24];
reg [inst_sig_width + inst_exp_width:0] img_tmp;
reg [inst_sig_width + inst_exp_width:0] kernel1 [0:3];
reg [inst_sig_width + inst_exp_width:0] kernel2 [0:3];
reg [inst_sig_width + inst_exp_width:0] kernel_1 [0:3];
reg [inst_sig_width + inst_exp_width:0] kernel_2 [0:3];
reg [inst_sig_width + inst_exp_width:0] kernel_3 [0:3];
reg [inst_sig_width + inst_exp_width:0] kernel_4 [0:3];
reg [inst_sig_width + inst_exp_width:0] kernel_5 [0:3];
reg [inst_sig_width + inst_exp_width:0] kernel_6 [0:3];
wire [inst_sig_width + inst_exp_width:0] n_kernel_1 [0:3];
wire [inst_sig_width + inst_exp_width:0] n_kernel_2 [0:3];
wire [inst_sig_width + inst_exp_width:0] n_kernel_3 [0:3];
wire [inst_sig_width + inst_exp_width:0] n_kernel_4 [0:3];
wire [inst_sig_width + inst_exp_width:0] n_kernel_5 [0:3];
wire [inst_sig_width + inst_exp_width:0] n_kernel_6 [0:3];
wire [inst_sig_width + inst_exp_width:0] AM_input[0:2];
wire [inst_sig_width + inst_exp_width:0] EXP_out;
wire [inst_sig_width + inst_exp_width:0] div_top_tmp;
wire [inst_sig_width + inst_exp_width:0] div_bot_tmp;
wire [inst_sig_width + inst_exp_width:0] EXP_input;
wire [7:0] exp_add_1; 
reg [4:0] count;
reg [inst_sig_width + inst_exp_width:0] in_cmp_mp[0:17];
reg [inst_sig_width + inst_exp_width:0] MP[0:7];
wire [inst_sig_width + inst_exp_width:0] FC_z[0:2], add_temp, total;
reg [inst_sig_width + inst_exp_width:0] total_reg, FC_z_reg[0:2];
wire [inst_sig_width + inst_exp_width:0] div_input[0:1];


reg [inst_sig_width + inst_exp_width:0] weight [1:24];
//padding
reg [inst_sig_width + inst_exp_width:0] img_pad [0:3];

//convolution
wire [inst_sig_width + inst_exp_width:0] conv[0:4];
wire [inst_sig_width + inst_exp_width:0] conv_refill_1, conv_refill_2;
reg [inst_sig_width + inst_exp_width:0] conv_buffer_1[0:31];
reg [inst_sig_width + inst_exp_width:0] conv_buffer_2[0:31];
//maxpooling && fully conntected
wire [inst_sig_width + inst_exp_width:0] max_mp_temp[0:7];
reg [inst_sig_width + inst_exp_width:0] max_mp_temp_reg[0:7];
//activation
wire [inst_sig_width + inst_exp_width:0] div_out;
reg [inst_sig_width + inst_exp_width:0] div_top;
reg [inst_sig_width + inst_exp_width:0] div_bot;
//output
reg cal_control;

// ===============================================================
// Design
// ===============================================================
//counter
assign n_cnt = (cal_control || in_valid) ? cnt + 1 : 0;
assign n_cnt_2 = (cnt_2 == 36) ? 1 : ((cal_control || in_valid) ? cnt_2 + 1 : 0);

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)  cnt <= 0;
    else cnt <= n_cnt;
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)  cnt_2 <= 0;
    else cnt_2 <= n_cnt_2;
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n) cal_control <= 0;
    else if(out_valid) begin
        cal_control <= 0;
    end
    else if(in_valid) begin
        cal_control <= 1;
    end
end

//img reg
always@(posedge clk) begin
    for(i = 0; i < 25; i = i + 1)begin
        if((i==(cnt%25)) && (cnt < 75))
            img[i] <= Img;
        else
            img[i] <= img[i];
    end
end
always@(posedge clk) begin
    if(cnt<50) img_tmp <= Img;
end
//weight reg
always@(posedge clk) begin
    if(cnt < 24)begin
        weight[n_cnt[4:0]] <= Weight;
    end
end

//kernel reg
always@(posedge clk)begin
    for(i = 0; i < 4; i = i + 1)begin
        kernel_1[i] <= n_kernel_1[i];
        kernel_2[i] <= n_kernel_2[i];
        kernel_3[i] <= n_kernel_3[i];
        kernel_4[i] <= n_kernel_4[i];
        kernel_5[i] <= n_kernel_5[i];
        kernel_6[i] <= n_kernel_6[i];
    end
end

always@(*) begin
    if(cnt < 37) begin
        kernel1[0] = kernel_1[0];
    end
    else if(cnt < 73) begin
        kernel1[0] = kernel_2[0];
    end
    else begin
        kernel1[0] = kernel_3[0];
    end
end
always@(*) begin
    if(cnt < 38) begin
        kernel1[1] = kernel_1[1];
    end
    else if(cnt < 74) begin
        kernel1[1] = kernel_2[1];
    end
    else begin
        kernel1[1] = kernel_3[1];
    end
end
always@(*) begin
    if(cnt < 39) begin
        kernel1[2] = kernel_1[2];
    end
    else if(cnt < 75) begin
        kernel1[2] = kernel_2[2];
    end
    else begin
        kernel1[2] = kernel_3[2];
    end
end
always@(*) begin
    if(cnt < 40) begin
        kernel1[3] = kernel_1[3];
    end
    else if(cnt < 76) begin
        kernel1[3] = kernel_2[3];
    end
    else begin
        kernel1[3] = kernel_3[3];
    end
end


always@(*) begin
    if(cnt < 37) begin
        kernel2[0] = kernel_4[0];
    end
    else if(cnt < 73) begin
        kernel2[0] = kernel_5[0];
    end
    else begin
        kernel2[0] = kernel_6[0];
    end
end
always@(*) begin
    if(cnt < 38) begin
        kernel2[1] = kernel_4[1];
    end
    else if(cnt < 74) begin
        kernel2[1] = kernel_5[1];
    end
    else begin
        kernel2[1] = kernel_6[1];
    end
end
always@(*) begin
    if(cnt < 39) begin
        kernel2[2] = kernel_4[2];
    end
    else if(cnt < 75) begin
        kernel2[2] = kernel_5[2];
    end
    else begin
        kernel2[2] = kernel_6[2];
    end
end
always@(*) begin
    if(cnt < 40) begin
        kernel2[3] = kernel_4[3];
    end
    else if(cnt < 76) begin
        kernel2[3] = kernel_5[3];
    end
    else begin
        kernel2[3] = kernel_6[3];
    end
end


assign n_kernel_1[0] = (cnt == 0) ? Kernel_ch1 : kernel_1[0];
assign n_kernel_1[1] = (cnt == 1) ? Kernel_ch1 : kernel_1[1];
assign n_kernel_1[2] = (cnt == 2) ? Kernel_ch1 : kernel_1[2];
assign n_kernel_1[3] = (cnt == 3) ? Kernel_ch1 : kernel_1[3];


assign n_kernel_2[0] = (cnt == 4) ? Kernel_ch1 : kernel_2[0];
assign n_kernel_2[1] = (cnt == 5) ? Kernel_ch1 : kernel_2[1];
assign n_kernel_2[2] = (cnt == 6) ? Kernel_ch1 : kernel_2[2];
assign n_kernel_2[3] = (cnt == 7) ? Kernel_ch1 : kernel_2[3];



assign n_kernel_3[0] = (cnt == 8 ) ?  Kernel_ch1 : kernel_3[0];
assign n_kernel_3[1] = (cnt == 9 ) ?  Kernel_ch1 : kernel_3[1];
assign n_kernel_3[2] = (cnt == 10) ? Kernel_ch1 : kernel_3[2];
assign n_kernel_3[3] = (cnt == 11) ? Kernel_ch1 : kernel_3[3];


assign n_kernel_4[0] = (cnt == 0) ? Kernel_ch2 : kernel_4[0];
assign n_kernel_4[1] = (cnt == 1) ? Kernel_ch2 : kernel_4[1];
assign n_kernel_4[2] = (cnt == 2) ? Kernel_ch2 : kernel_4[2];
assign n_kernel_4[3] = (cnt == 3) ? Kernel_ch2 : kernel_4[3];


assign n_kernel_5[0] = (cnt == 4) ? Kernel_ch2 : kernel_5[0];
assign n_kernel_5[1] = (cnt == 5) ? Kernel_ch2 : kernel_5[1];
assign n_kernel_5[2] = (cnt == 6) ? Kernel_ch2 : kernel_5[2];
assign n_kernel_5[3] = (cnt == 7) ? Kernel_ch2 : kernel_5[3];



assign n_kernel_6[0] = (cnt == 8 ) ?  Kernel_ch2 : kernel_6[0];
assign n_kernel_6[1] = (cnt == 9 ) ?  Kernel_ch2 : kernel_6[1];
assign n_kernel_6[2] = (cnt == 10) ? Kernel_ch2 : kernel_6[2];
assign n_kernel_6[3] = (cnt == 11) ? Kernel_ch2 : kernel_6[3];





//opt reg
always@(negedge rst_n or posedge clk)begin
    if(!rst_n) mode <= 0;
    else if(cnt == 0 && in_valid)    mode <= Opt;
    else mode <= mode;
end
// padding

always@(*)begin
    case(cnt_2)
    6'd1: img_pad[0] = mode ? img[0] : FP0;
    6'd2: img_pad[0] = mode ? img[0] : FP0;
    6'd3: img_pad[0] = mode ? img[1] : FP0;
    6'd4: img_pad[0] = mode ? img[2] : FP0;
    6'd5: img_pad[0] = mode ? img[3] : FP0;
    6'd6: img_pad[0] = mode ? img[4] : FP0;
    6'd7: img_pad[0] = mode ? img[0] : FP0;
    6'd8: img_pad[0] = img[0];
    6'd9: img_pad[0] = img[1];
    6'd10: img_pad[0] = img[2];
    6'd11: img_pad[0] = img[3];
    6'd12: img_pad[0] = img[4];
    6'd13: img_pad[0] = mode ? img[5] : FP0;
    6'd14: img_pad[0] = img[5];
    6'd15: img_pad[0] = img[6];
    6'd16: img_pad[0] = img[7];
    6'd17: img_pad[0] = img[8];
    6'd18: img_pad[0] = img[9];
    6'd19: img_pad[0] = mode ? img[10] : FP0;
    6'd20: img_pad[0] = img[10];
    6'd21: img_pad[0] = img[11];
    6'd22: img_pad[0] = img[12];
    6'd23: img_pad[0] = img[13];
    6'd24: img_pad[0] = img[14];
    6'd25: img_pad[0] = mode ? img[15] : FP0;
    6'd26: img_pad[0] = img[15];
    6'd27: img_pad[0] = img[16];
    6'd28: img_pad[0] = img[17];
    6'd29: img_pad[0] = img[18];
    6'd30: img_pad[0] = img[19];
    6'd31: img_pad[0] = mode ? img[20] : FP0;
    6'd32: img_pad[0] = img[20];
    6'd33: img_pad[0] = img[21];
    6'd34: img_pad[0] = img[22];
    6'd35: img_pad[0] = img[23];
    6'd36: img_pad[0] = img[24];
    default: img_pad[0] = 0;
    endcase
end

always@(*)begin
    case(cnt_2)
    6'd2: img_pad[1] = mode ? img[0] : FP0;
    6'd3: img_pad[1] = mode ? img[1] : FP0;
    6'd4: img_pad[1] = mode ? img[2] : FP0;
    6'd5: img_pad[1] = mode ? img[3] : FP0;
    6'd6: img_pad[1] = mode ? img[4] : FP0;
    6'd7: img_pad[1] = mode ? img[4] : FP0;
    6'd8: img_pad[1] = img[0];
    6'd9: img_pad[1] = img[1];
    6'd10: img_pad[1] = img[2];
    6'd11: img_pad[1] = img[3];
    6'd12: img_pad[1] = img[4];
    6'd13: img_pad[1] = mode ? img[4] : FP0;
    6'd14: img_pad[1] = img[5];
    6'd15: img_pad[1] = img[6];
    6'd16: img_pad[1] = img[7];
    6'd17: img_pad[1] = img[8];
    6'd18: img_pad[1] = img[9];
    6'd19: img_pad[1] = mode ? img[9] : FP0;
    6'd20: img_pad[1] = img[10];
    6'd21: img_pad[1] = img[11];
    6'd22: img_pad[1] = img[12];
    6'd23: img_pad[1] = img[13];
    6'd24: img_pad[1] = img[14];
    6'd25: img_pad[1] = mode ? img[14] : FP0;
    6'd26: img_pad[1] = img[15];
    6'd27: img_pad[1] = img[16];
    6'd28: img_pad[1] = img[17];
    6'd29: img_pad[1] = img[18];
    6'd30: img_pad[1] = img[19];
    6'd31: img_pad[1] = mode ? img[19] : FP0;
    6'd32: img_pad[1] = img[20];
    6'd33: img_pad[1] = img[21];
    6'd34: img_pad[1] = img[22];
    6'd35: img_pad[1] = img[23];
    6'd36: img_pad[1] = img[24];
    6'd1: img_pad[1] = mode ? img[24] : FP0;
    default: img_pad[1] = 0;
    endcase
end

always@(*)begin
    case(cnt_2)
    6'd3: img_pad[2] = mode ? img[0] : FP0;
    6'd4: img_pad[2] = img[0];
    6'd5: img_pad[2] = img[1];
    6'd6: img_pad[2] = img[2];
    6'd7: img_pad[2] = img[3];
    6'd8: img_pad[2] = img[4];
    6'd9: img_pad[2] = mode ? img[5] : FP0;
    6'd10: img_pad[2] = img[5];
    6'd11: img_pad[2] = img[6];
    6'd12: img_pad[2] = img[7];
    6'd13: img_pad[2] = img[8];
    6'd14: img_pad[2] = img[9];
    6'd15: img_pad[2] = mode ? img[10] : FP0;
    6'd16: img_pad[2] = img[10];
    6'd17: img_pad[2] = img[11];
    6'd18: img_pad[2] = img[12];
    6'd19: img_pad[2] = img[13];
    6'd20: img_pad[2] = img[14];
    6'd21: img_pad[2] = mode ? img[15] : FP0;
    6'd22: img_pad[2] = img[15];
    6'd23: img_pad[2] = img[16];
    6'd24: img_pad[2] = img[17];
    6'd25: img_pad[2] = img[18];
    6'd26: img_pad[2] = img[19];
    6'd27: img_pad[2] = mode ? img[20] : FP0;
    6'd28: img_pad[2] = img[20];
    6'd29: img_pad[2] = img[21];
    6'd30: img_pad[2] = img[22];
    6'd31: img_pad[2] = img[23];
    6'd32: img_pad[2] = img[24];
    6'd33: img_pad[2] = mode ? img[20] : FP0;
    6'd34: img_pad[2] = mode ? img[20] : FP0;
    6'd35: img_pad[2] = mode ? img[21] : FP0;
    6'd36: img_pad[2] = mode ? img[22] : FP0;
    6'd1: img_pad[2] = mode ? img[23] : FP0;
    6'd2: img_pad[2] = mode ? img[24] : FP0;
    default: img_pad[2] = 0;
    endcase
end

always@(*)begin
    case(cnt_2)
    6'd4: img_pad[3] = img[0];
    6'd5: img_pad[3] = img[1];
    6'd6: img_pad[3] = img[2];
    6'd7: img_pad[3] = img[3];
    6'd8: img_pad[3] = img[4];
    6'd9: img_pad[3] = mode ? img[4] : FP0;
    6'd10: img_pad[3] = img[5];
    6'd11: img_pad[3] = img[6];
    6'd12: img_pad[3] = img[7];
    6'd13: img_pad[3] = img[8];
    6'd14: img_pad[3] = img[9];
    6'd15: img_pad[3] = mode ? img[9] : FP0;
    6'd16: img_pad[3] = img[10];
    6'd17: img_pad[3] = img[11];
    6'd18: img_pad[3] = img[12];
    6'd19: img_pad[3] = img[13];
    6'd20: img_pad[3] = img[14];
    6'd21: img_pad[3] = mode ? img[14] : FP0;
    6'd22: img_pad[3] = img[15];
    6'd23: img_pad[3] = img[16];
    6'd24: img_pad[3] = img[17];
    6'd25: img_pad[3] = img[18];
    6'd26: img_pad[3] = img[19];
    6'd27: img_pad[3] = mode ? img[19] : FP0;
    6'd28: img_pad[3] = img[20];
    6'd29: img_pad[3] = img[21];
    6'd30: img_pad[3] = img[22];
    6'd31: img_pad[3] = img[23];
    6'd32: img_pad[3] = img[24];
    6'd33: img_pad[3] = mode ? img[24] : FP0;
    6'd34: img_pad[3] = mode ? img[20] : FP0;
    6'd35: img_pad[3] = mode ? img[21] : FP0;
    6'd36: img_pad[3] = mode ? img[22] : FP0;
    6'd1: img_pad[3] = mode ? img[23] : FP0;
    6'd2: img_pad[3] = mode ? img[24] : FP0;
    6'd3: img_pad[3] = mode ? ((cnt==75) ? img_tmp : img[24]) : FP0;
    default: img_pad[3] = 0;
    endcase
end


//=================
// Convolution
//=================

wire [inst_sig_width + inst_exp_width:0] add_mult_input1[0:2];
wire [inst_sig_width + inst_exp_width:0] add_mult_input2[0:2];
wire [inst_sig_width + inst_exp_width:0] add_mult_input3[0:2];
wire [inst_sig_width + inst_exp_width:0] add_mult_output[0:2];

assign add_mult_input1[0] = (cnt < 113) ? conv[0] : ((count < 2) ? FP0 : add_mult_output[0]);
assign add_mult_input1[1] = (cnt < 113) ? add_mult_output[0] : ((count < 2) ? FP0 : add_mult_output[1]);
assign add_mult_input1[2] = (cnt < 113) ? add_mult_output[1] : ((count < 2) ? FP0 : add_mult_output[2]);
assign add_mult_input2[0] = (cnt < 113) ? img_pad[1] : div_out;
assign add_mult_input2[1] = (cnt < 113) ? img_pad[2] : div_out;
assign add_mult_input2[2] = (cnt < 113) ? img_pad[3] : div_out;
assign add_mult_input3[0] = (cnt < 113) ? kernel1[1] : weight[count];
assign add_mult_input3[1] = (cnt < 113) ? kernel1[2] : weight[count+8];
assign add_mult_input3[2] = (cnt < 113) ? kernel1[3] : weight[count+16];


add_mult #(inst_sig_width,inst_exp_width,inst_ieee_compliance, inst_arch_type) 
    u_add_mult_0(.clk(clk),.a(conv_refill_1),.ifm(img_pad[0]),.inw(kernel1[0]),.out(conv[0]));
add_mult#(inst_sig_width,inst_exp_width,inst_ieee_compliance, inst_arch_type) 
    u_add_mult_1(.clk(clk),.a(add_mult_input1[0]),.ifm(add_mult_input2[0]),.inw(add_mult_input3[0]),.out(add_mult_output[0]));
add_mult #(inst_sig_width,inst_exp_width,inst_ieee_compliance, inst_arch_type) 
    u_add_mult_2(.clk(clk),.a(add_mult_input1[1]),.ifm(add_mult_input2[1]),.inw(add_mult_input3[1]),.out(add_mult_output[1]));        
add_mult #(inst_sig_width,inst_exp_width,inst_ieee_compliance, inst_arch_type) 
    u_add_mult_3(.clk(clk),.a(add_mult_input1[2]),.ifm(add_mult_input2[2]),.inw(add_mult_input3[2]),.out(add_mult_output[2]));
add_mult #(inst_sig_width,inst_exp_width,inst_ieee_compliance, inst_arch_type) 
    u_add_mult_4(.clk(clk),.a(conv_refill_2),.ifm(img_pad[0]),.inw(kernel2[0]),.out(conv[1]));
add_mult #(inst_sig_width,inst_exp_width,inst_ieee_compliance, inst_arch_type) 
    u_add_mult_5(.clk(clk),.a(conv[1]),.ifm(img_pad[1]),.inw(kernel2[1]),.out(conv[2]));     
add_mult #(inst_sig_width,inst_exp_width,inst_ieee_compliance, inst_arch_type) 
    u_add_mult_6(.clk(clk),.a(conv[2]),.ifm(img_pad[2]),.inw(kernel2[2]),.out(conv[3]));
add_mult #(inst_sig_width,inst_exp_width,inst_ieee_compliance, inst_arch_type) 
    u_add_mult_7(.clk(clk),.a(conv[3]),.ifm(img_pad[3]),.inw(kernel2[3]),.out(conv[4]));  

always@(posedge clk) begin
    conv_buffer_1[31] <= add_mult_output[2];
    conv_buffer_2[31] <= conv[4];
    for(i=0;i<31;i=i+1) begin
        conv_buffer_1[i] <= conv_buffer_1[i+1];
        conv_buffer_2[i] <= conv_buffer_2[i+1];
    end
end

assign conv_refill_1 = (cnt > 36)? conv_buffer_1[0] : FP0;
assign conv_refill_2 = (cnt > 36)? conv_buffer_2[0] : FP0;



always @(*) begin
    case(cnt)
    7'd78: in_cmp_mp[1] = add_mult_output[2];
    7'd79: in_cmp_mp[1] = add_mult_output[2];
    7'd83: in_cmp_mp[1] = add_mult_output[2];
    7'd84: in_cmp_mp[1] = add_mult_output[2];
    7'd85: in_cmp_mp[1] = add_mult_output[2];
    7'd89: in_cmp_mp[1] = add_mult_output[2];
    7'd90: in_cmp_mp[1] = add_mult_output[2];
    7'd91: in_cmp_mp[1] = add_mult_output[2];
    default: in_cmp_mp[1] = FPminus;
    endcase
end

always @(*) begin
    case(cnt)
    7'd81: in_cmp_mp[3] = add_mult_output[2];
    7'd82: in_cmp_mp[3] = add_mult_output[2];
    7'd86: in_cmp_mp[3] = add_mult_output[2];
    7'd87: in_cmp_mp[3] = add_mult_output[2];
    7'd88: in_cmp_mp[3] = add_mult_output[2];
    7'd92: in_cmp_mp[3] = add_mult_output[2];
    7'd93: in_cmp_mp[3] = add_mult_output[2];
    7'd94: in_cmp_mp[3] = add_mult_output[2];
    default: in_cmp_mp[3] = FPminus;
    endcase
end


always @(*) begin
    case(cnt)
    7'd96: in_cmp_mp[5] = add_mult_output[2];
    7'd97: in_cmp_mp[5] = add_mult_output[2];
    7'd101: in_cmp_mp[5] = add_mult_output[2];
    7'd102: in_cmp_mp[5] = add_mult_output[2];
    7'd103: in_cmp_mp[5] = add_mult_output[2];
    7'd107: in_cmp_mp[5] = add_mult_output[2];
    7'd108: in_cmp_mp[5] = add_mult_output[2];
    7'd109: in_cmp_mp[5] = add_mult_output[2];
    default: in_cmp_mp[5] = FPminus;
    endcase
end

always @(*) begin
    case(cnt)
    7'd99: in_cmp_mp[7] = add_mult_output[2];
    7'd100: in_cmp_mp[7] = add_mult_output[2];
    7'd104: in_cmp_mp[7] = add_mult_output[2];
    7'd105: in_cmp_mp[7] = add_mult_output[2];
    7'd106: in_cmp_mp[7] = add_mult_output[2];
    7'd110: in_cmp_mp[7] = add_mult_output[2];
    7'd111: in_cmp_mp[7] = add_mult_output[2];
    7'd112: in_cmp_mp[7] = add_mult_output[2];
    default: in_cmp_mp[7] = FPminus;
    endcase
end




always @(*) begin
    case(cnt)
    7'd78: in_cmp_mp[9] = conv[4];
    7'd79: in_cmp_mp[9] = conv[4];
    7'd83: in_cmp_mp[9] = conv[4];
    7'd84: in_cmp_mp[9] = conv[4];
    7'd85: in_cmp_mp[9] = conv[4];
    7'd89: in_cmp_mp[9] = conv[4];
    7'd90: in_cmp_mp[9] = conv[4];
    7'd91: in_cmp_mp[9] = conv[4];
    default: in_cmp_mp[9] = FPminus;
    endcase
end

always @(*) begin
    case(cnt)
    7'd81: in_cmp_mp[11] = conv[4];
    7'd82: in_cmp_mp[11] = conv[4];
    7'd86: in_cmp_mp[11] = conv[4];
    7'd87: in_cmp_mp[11] = conv[4];
    7'd88: in_cmp_mp[11] = conv[4];
    7'd92: in_cmp_mp[11] = conv[4];
    7'd93: in_cmp_mp[11] = conv[4];
    7'd94: in_cmp_mp[11] = conv[4];
    default: in_cmp_mp[11] = FPminus;
    endcase
end


always @(*) begin
    case(cnt)
    7'd96: in_cmp_mp[13] = conv[4];
    7'd97: in_cmp_mp[13] = conv[4];
    7'd101: in_cmp_mp[13] = conv[4];
    7'd102: in_cmp_mp[13] = conv[4];
    7'd103: in_cmp_mp[13] = conv[4];
    7'd107: in_cmp_mp[13] = conv[4];
    7'd108: in_cmp_mp[13] = conv[4];
    7'd109: in_cmp_mp[13] = conv[4];
    default: in_cmp_mp[13] = FPminus;
    endcase
end

always @(*) begin
    case(cnt)
    7'd99: in_cmp_mp[15] = conv[4];
    7'd100: in_cmp_mp[15] = conv[4];
    7'd104: in_cmp_mp[15] = conv[4];
    7'd105: in_cmp_mp[15] = conv[4];
    7'd106: in_cmp_mp[15] = conv[4];
    7'd110: in_cmp_mp[15] = conv[4];
    7'd111: in_cmp_mp[15] = conv[4];
    7'd112: in_cmp_mp[15] = conv[4];
    default: in_cmp_mp[15] = FPminus;
    endcase
end




always @(posedge clk) begin
    for(i = 0; i < 8; i = i + 1) begin
        max_mp_temp_reg[i] <= max_mp_temp[i];
    end
end

assign in_cmp_mp[0] = (cnt == 78) ? conv_buffer_1[31]: max_mp_temp_reg[0];
assign in_cmp_mp[2] = (cnt == 81) ? conv_buffer_1[31]: max_mp_temp_reg[1];
assign in_cmp_mp[4] = (cnt == 96) ? conv_buffer_1[31]: max_mp_temp_reg[2];
assign in_cmp_mp[6] = (cnt == 99) ? conv_buffer_1[31]: max_mp_temp_reg[3];


DW_fp_cmp#(inst_sig_width,inst_exp_width,inst_ieee_compliance, inst_arch_type) 
    mp_C0 (.a(in_cmp_mp[0]), .b(in_cmp_mp[1]), .zctr(1'd0), .z1(max_mp_temp[0]));
DW_fp_cmp#(inst_sig_width,inst_exp_width,inst_ieee_compliance, inst_arch_type) 
    mp_C1 (.a(in_cmp_mp[2]), .b(in_cmp_mp[3]), .zctr(1'd0), .z1(max_mp_temp[1]));
DW_fp_cmp#(inst_sig_width,inst_exp_width,inst_ieee_compliance, inst_arch_type) 
    mp_C2 (.a(in_cmp_mp[4]), .b(in_cmp_mp[5]), .zctr(1'd0), .z1(max_mp_temp[2]));
DW_fp_cmp#(inst_sig_width,inst_exp_width,inst_ieee_compliance, inst_arch_type) 
    mp_C3 (.a(in_cmp_mp[6]), .b(in_cmp_mp[7]), .zctr(1'd0), .z1(max_mp_temp[3]));


always @(posedge clk) begin
    if(cnt == 109) begin
        MP[0] <= max_mp_temp[0];
    end
end
always @(posedge clk) begin
    if(cnt == 110) begin
        MP[1] <= max_mp_temp[1];
    end
end
always @(posedge clk) begin
    if(cnt == 111) begin
        MP[2] <= max_mp_temp[2];
    end
end
always @(posedge clk) begin
    if(cnt == 112) begin
        MP[3] <= max_mp_temp[3];
    end
end

assign in_cmp_mp[8]  = (cnt == 78) ? conv_buffer_2[31]: max_mp_temp_reg[4];
assign in_cmp_mp[10] = (cnt == 81) ? conv_buffer_2[31]: max_mp_temp_reg[5];
assign in_cmp_mp[12] = (cnt == 96) ? conv_buffer_2[31]: max_mp_temp_reg[6];
assign in_cmp_mp[14] = (cnt == 99) ? conv_buffer_2[31]: max_mp_temp_reg[7];

DW_fp_cmp#(inst_sig_width,inst_exp_width,inst_ieee_compliance, inst_arch_type) 
    mp_C4 (.a(in_cmp_mp[8]), .b(in_cmp_mp[9]), .zctr(1'd0), .z1(max_mp_temp[4]));
DW_fp_cmp#(inst_sig_width,inst_exp_width,inst_ieee_compliance, inst_arch_type) 
    mp_C5 (.a(in_cmp_mp[10]), .b(in_cmp_mp[11]), .zctr(1'd0), .z1(max_mp_temp[5]));
DW_fp_cmp#(inst_sig_width,inst_exp_width,inst_ieee_compliance, inst_arch_type) 
    mp_C6 (.a(in_cmp_mp[12]), .b(in_cmp_mp[13]), .zctr(1'd0), .z1(max_mp_temp[6]));
DW_fp_cmp#(inst_sig_width,inst_exp_width,inst_ieee_compliance, inst_arch_type) 
    mp_C7 (.a(in_cmp_mp[14]), .b(in_cmp_mp[15]), .zctr(1'd0), .z1(max_mp_temp[7]));


always @(posedge clk) begin
    if(cnt == 109) begin
        MP[4] <= max_mp_temp[4];
    end
end
always @(posedge clk) begin
    if(cnt == 110) begin
        MP[5] <= max_mp_temp[5];
    end
end
always @(posedge clk) begin
    if(cnt == 111) begin
        MP[6] <= max_mp_temp[6];
    end
end
always @(posedge clk) begin
    if(cnt == 112) begin
        MP[7] <= max_mp_temp[7];
    end
end



always @(posedge clk) begin
    if(in_valid) count <= 0;
    else if(cnt > 111) count <= count + 1;
end

assign EXP_input = (count < 8) ? (mode ? {MP[count][31],exp_add_1,MP[count][22:0]} : MP[count]) : add_mult_output[0];
assign exp_add_1 = MP[count][30:23] + 1;

assign div_input[0] = (count < 9) ? div_top : FC_z_reg[count-10];
assign div_input[1] = (count < 9) ? div_bot : total_reg;

DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type)
    EXP1_1 (.a(EXP_input),.z(EXP_out),.status());


DW_fp_addsub #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type)
    S1 ( .a(EXP_out), .b(FP1),.op(1'b1), .rnd(3'd0),.z(div_top_tmp), .status());

DW_fp_addsub #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type)
    A1 ( .a(EXP_out), .b(FP1),.op(1'b0), .rnd(3'd0),.z(div_bot_tmp), .status());

DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type)
    u_div( .a(div_input[0]), .b(div_input[1]), .rnd(3'd0), .z(div_out), .status());


always @(posedge clk) begin
    if(mode) div_top <= div_top_tmp;
    else div_top <= EXP_out;
end
always @(posedge clk) begin
    div_bot <= div_bot_tmp;
end

always @(posedge clk) begin
    if(count  == 9) total_reg <= total;
end

always @(posedge clk) begin
    if(count  == 9) FC_z_reg[0] <= EXP_out;
end
always @(posedge clk) begin
    if(count  == 9) FC_z_reg[1] <= FC_z[1];
end
always @(posedge clk) begin
    if(count  == 9) FC_z_reg[2] <= FC_z[2];
end


DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type)
    EXP_soft2 (.a(add_mult_output[1]),.z(FC_z[1]),.status());

DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type)
    EXP_soft3 (.a(add_mult_output[2]),.z(FC_z[2]),.status());


DW_fp_addsub #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type)
    A2 ( .a(EXP_out), .b(FC_z[1]),.op(1'b0), .rnd(3'd0),.z(add_temp), .status());

DW_fp_addsub #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type)
    A3 ( .a(add_temp), .b(FC_z[2]),.op(1'b0), .rnd(3'd0),.z(total), .status());


//=================
// Output
//=================
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 0;
        out <= 0;
    end
    else if((count > 9) && (count < 13)) begin
        out_valid <= 1;
        out <= div_out;
    end
    else  begin
        out_valid <= 0;
        out <= 0;
    end
end

endmodule


module add_mult 
    #(  parameter inst_sig_width       = 23,
        parameter inst_exp_width       = 8,
        parameter inst_ieee_compliance = 0,
        parameter inst_arch_type = 0
    )(clk,a,ifm,inw,out);
    
    input clk;
    input [inst_sig_width +inst_exp_width :0] a, ifm, inw;
    output reg [inst_sig_width +inst_exp_width :0] out;

    wire [inst_sig_width +inst_exp_width :0] mult_temp ,add_temp;

    DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type)
        u_M1( .a(ifm), .b(inw), .rnd(3'd0), .z(mult_temp), .status() );

    DW_fp_addsub #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type)
        u_A1 ( .a(a), .b(mult_temp),.op(1'b0), .rnd(3'd0),.z(add_temp), .status() );
    
    always@(posedge clk) out <= add_temp;

endmodule
