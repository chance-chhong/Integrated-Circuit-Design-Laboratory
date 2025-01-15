/**************************************************************************/
// Copyright (c) 2024, OASIS Lab
// MODULE: SA
// FILE NAME: SA.v
// VERSRION: 1.0
// DATE: Nov 06, 2024
// AUTHOR: Yen-Ning Tung, NYCU AIG
// CODE TYPE: RTL or Behavioral Level (Verilog)
// DESCRIPTION: 2024 Fall IC Lab / Exersise Lab08 / SA
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/

module SA(
    //Input signals
    clk,
    rst_n,
    in_valid,
    T,
    in_data,
    w_Q,
    w_K,
    w_V,

    //Output signals
    out_valid,
    out_data
    );

input clk;
input rst_n;
input in_valid;
input [3:0] T;
input signed [7:0] in_data;
input signed [7:0] w_Q;
input signed [7:0] w_K;
input signed [7:0] w_V;

output reg out_valid;
output reg signed [63:0] out_data;

//==============================================//
//       parameter & integer declaration        //
//==============================================//
enum logic [2:0] {
    IDLE = 3'd0,
	STORE_INDATA = 3'd1,
	STORE_K = 3'd2,
	STORE_V = 3'd3,
    MM2 = 3'd4
    } current_state, next_state;

integer i, j;


//==============================================//
//           reg & wire declaration             //
//==============================================//

reg [8:0] in_cnt;
reg [3:0] T_tmp;
reg [6:0] out_cnt;
reg signed [7:0] indata[0:7][0:7];

reg signed [7:0] w_Q_r[0:7][0:7];
reg signed [7:0] w_K_r;
reg signed [7:0] w_V_r;

reg signed [18:0] row_0_a;
reg signed [18:0] row_0_b;
reg signed [18:0] row_1_3_a[0:2];
reg signed [18:0] row_4_7_a[0:3];

reg signed [39:0] A_a[0:7];
reg signed [18:0] A_b[0:1];
reg signed [18:0] A_c[0:7];

reg signed [39:0] div[0:7];


reg signed [18:0] Q[0:7][0:7];
reg signed [18:0] K[0:7][0:7];
reg signed [18:0] V[0:7][0:7];
reg signed [39:0] A[0:7][0:7];

wire [7:0] state_cnt;
wire [2:0] cal_cnt;
wire signed [18:0] row_0;
wire signed [18:0] row_1_3[0:2];
wire signed [18:0] row_4_7[0:3];

wire signed [39:0] A_sum[0:7];
wire signed [39:0] A_div[0:7];



//==============================================//
//                  design                      //
//==============================================//


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
always@(*) begin 
    case (current_state)
        IDLE: begin
            if(in_valid) next_state = STORE_INDATA;
            else next_state = IDLE;
        end
		STORE_INDATA: begin
            if(in_cnt == 64) next_state = STORE_K;
            else next_state = STORE_INDATA;
        end
		STORE_K: begin
            if(in_cnt == 63) next_state = STORE_V;
            else next_state = STORE_K;
        end
		STORE_V: begin
            if(in_cnt == 63) next_state = MM2;
            else next_state = STORE_V;
        end
		MM2: begin
			if(in_cnt == ((T_tmp << 3) - 1)) next_state = IDLE;
			else next_state = MM2;
		end
        default: next_state = IDLE;
    endcase
end


assign state_cnt = T_tmp << 3;

always @(posedge clk) begin
	if(next_state == IDLE) in_cnt <= 0;
	else if(current_state == IDLE && next_state == STORE_INDATA) in_cnt <= in_cnt + 1;
	else if(current_state != next_state) in_cnt <= 0;
	else in_cnt <= in_cnt + 1;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) T_tmp <= 2;
	else if(in_valid && current_state == IDLE) T_tmp <= T;
end

assign cal_cnt = in_cnt[2:0];

always @(posedge clk ) begin
	if(next_state == IDLE) begin
		for(i = 0; i < 8; i = i + 1) begin
			for(j = 0; j < 8; j = j + 1) begin
				indata[i][j] <= 0;
			end
		end
	end
	else if((next_state == STORE_INDATA || current_state == STORE_INDATA) && (in_cnt < (T_tmp << 3))) begin
		indata[in_cnt[8:3]][cal_cnt] <= in_data;
	end
end

always @(posedge clk ) begin
	if(next_state == IDLE) begin
		for(i = 0; i < 8; i = i + 1) begin
			for(j = 0; j < 8; j = j + 1) begin
				w_Q_r[i][j] <= 0;
			end
		end
	end
	else if((next_state == STORE_INDATA || current_state == STORE_INDATA)) begin
		w_Q_r[in_cnt[8:3]][cal_cnt] <= w_Q;
	end
end

always @(posedge clk ) begin
	w_K_r <= w_K;
end
always @(posedge clk ) begin
	w_V_r <= w_V;
end

//==============================================//
//                    STORE                     //
//==============================================//

//==============================================//
//                   0th row                    //
//==============================================//

always @(*) begin
	case(current_state)
		STORE_K: row_0_a = K[0][cal_cnt];
		STORE_V: row_0_a = V[0][cal_cnt];
		default: row_0_a = 0;
	endcase
end
always @(*) begin
	case(current_state)
		STORE_K: row_0_b = w_K_r;
		STORE_V: row_0_b = w_V_r;
		default: row_0_b = 0;
	endcase
end

assign row_0 = row_0_a + indata[0][in_cnt[5:3]] * row_0_b;

always @(posedge clk ) begin
	if(current_state == IDLE) begin
		for(i = 0; i < 8; i = i + 1) begin
			Q[0][i] <= 0;
		end
	end
	else if(current_state == STORE_K) begin
		Q[0][cal_cnt] <= Q[0][cal_cnt] + indata[0][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][cal_cnt];
	end
end
always @(posedge clk ) begin
	if(current_state == IDLE) begin
		for(i = 0; i < 8; i = i + 1) begin
			K[0][i] <= 0;
		end
	end
	else if(current_state == STORE_K) begin
		K[0][cal_cnt] <= row_0;
	end
end
always @(posedge clk ) begin
	if(current_state == IDLE) begin
		for(i = 0; i < 8; i = i + 1) begin
			V[0][i] <= 0;
		end
	end
	else if(current_state == STORE_V) begin
		V[0][cal_cnt] <= row_0;
	end
end

//==============================================//
//                 1st~3rd row                  //
//==============================================//

always @(*) begin
	case(current_state)
		STORE_K: row_1_3_a[0] = K[1][cal_cnt];
		STORE_V: row_1_3_a[0] = V[1][cal_cnt];
		default: row_1_3_a[0] = 0;
	endcase
end
always @(*) begin
	case(current_state)
		STORE_K: row_1_3_a[1] = K[2][cal_cnt];
		STORE_V: row_1_3_a[1] = V[2][cal_cnt];
		default: row_1_3_a[1] = 0;
	endcase
end
always @(*) begin
	case(current_state)
		STORE_K: row_1_3_a[2] = K[3][cal_cnt];
		STORE_V: row_1_3_a[2] = V[3][cal_cnt];
		default: row_1_3_a[2] = 0;
	endcase
end




assign row_1_3[0] = row_1_3_a[0] + indata[1][in_cnt[5:3]] * row_0_b;
assign row_1_3[1] = row_1_3_a[1] + indata[2][in_cnt[5:3]] * row_0_b;
assign row_1_3[2] = row_1_3_a[2] + indata[3][in_cnt[5:3]] * row_0_b;




always @(posedge clk ) begin
	if(current_state == IDLE) Q[1][0] <= 0;
	else if(current_state == STORE_K) Q[1][0] <= Q[1][0] + ((cal_cnt == 0) ? indata[1][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][0] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[1][1] <= 0;
	else if(current_state == STORE_K) Q[1][1] <= Q[1][1] + ((cal_cnt == 1) ? indata[1][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][1] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[1][2] <= 0;
	else if(current_state == STORE_K) Q[1][2] <= Q[1][2] + ((cal_cnt == 2) ? indata[1][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][2] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[1][3] <= 0;
	else if(current_state == STORE_K) Q[1][3] <= Q[1][3] + ((cal_cnt == 3) ? indata[1][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][3] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[1][4] <= 0;
	else if(current_state == STORE_K) Q[1][4] <= Q[1][4] + ((cal_cnt == 4) ? indata[1][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][4] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[1][5] <= 0;
	else if(current_state == STORE_K) Q[1][5] <= Q[1][5] + ((cal_cnt == 5) ? indata[1][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][5] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[1][6] <= 0;
	else if(current_state == STORE_K) Q[1][6] <= Q[1][6] + ((cal_cnt == 6) ? indata[1][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][6] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[1][7] <= 0;
	else if(current_state == STORE_K) Q[1][7] <= Q[1][7] + ((cal_cnt == 7) ? indata[1][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][7] : 0);
end


always @(posedge clk ) begin
	if(current_state == IDLE) Q[2][0] <= 0;
	else if(current_state == STORE_K) Q[2][0] <= Q[2][0] + ((cal_cnt == 0) ? indata[2][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][0] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[2][1] <= 0;
	else if(current_state == STORE_K) Q[2][1] <= Q[2][1] + ((cal_cnt == 1) ? indata[2][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][1] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[2][2] <= 0;
	else if(current_state == STORE_K) Q[2][2] <= Q[2][2] + ((cal_cnt == 2) ? indata[2][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][2] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[2][3] <= 0;
	else if(current_state == STORE_K) Q[2][3] <= Q[2][3] + ((cal_cnt == 3) ? indata[2][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][3] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[2][4] <= 0;
	else if(current_state == STORE_K) Q[2][4] <= Q[2][4] + ((cal_cnt == 4) ? indata[2][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][4] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[2][5] <= 0;
	else if(current_state == STORE_K) Q[2][5] <= Q[2][5] + ((cal_cnt == 5) ? indata[2][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][5] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[2][6] <= 0;
	else if(current_state == STORE_K) Q[2][6] <= Q[2][6] + ((cal_cnt == 6) ? indata[2][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][6] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[2][7] <= 0;
	else if(current_state == STORE_K) Q[2][7] <= Q[2][7] + ((cal_cnt == 7) ? indata[2][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][7] : 0);
end


always @(posedge clk ) begin
	if(current_state == IDLE) Q[3][0] <= 0;
	else if(current_state == STORE_K) Q[3][0] <= Q[3][0] + ((cal_cnt == 0) ? indata[3][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][0] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[3][1] <= 0;
	else if(current_state == STORE_K) Q[3][1] <= Q[3][1] + ((cal_cnt == 1) ? indata[3][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][1] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[3][2] <= 0;
	else if(current_state == STORE_K) Q[3][2] <= Q[3][2] + ((cal_cnt == 2) ? indata[3][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][2] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[3][3] <= 0;
	else if(current_state == STORE_K) Q[3][3] <= Q[3][3] + ((cal_cnt == 3) ? indata[3][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][3] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[3][4] <= 0;
	else if(current_state == STORE_K) Q[3][4] <= Q[3][4] + ((cal_cnt == 4) ? indata[3][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][4] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[3][5] <= 0;
	else if(current_state == STORE_K) Q[3][5] <= Q[3][5] + ((cal_cnt == 5) ? indata[3][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][5] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[3][6] <= 0;
	else if(current_state == STORE_K) Q[3][6] <= Q[3][6] + ((cal_cnt == 6) ? indata[3][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][6] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[3][7] <= 0;
	else if(current_state == STORE_K) Q[3][7] <= Q[3][7] + ((cal_cnt == 7) ? indata[3][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][7] : 0);
end



always @(posedge clk ) begin
	if(current_state == IDLE) K[1][0] <= 0;
	else if(current_state == STORE_K) K[1][0] <= ((cal_cnt == 0) ? row_1_3[0] : K[1][0]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[1][1] <= 0;
	else if(current_state == STORE_K) K[1][1] <= ((cal_cnt == 1) ? row_1_3[0] : K[1][1]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[1][2] <= 0;
	else if(current_state == STORE_K) K[1][2] <= ((cal_cnt == 2) ? row_1_3[0] : K[1][2]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[1][3] <= 0;
	else if(current_state == STORE_K) K[1][3] <= ((cal_cnt == 3) ? row_1_3[0] : K[1][3]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[1][4] <= 0;
	else if(current_state == STORE_K) K[1][4] <= ((cal_cnt == 4) ? row_1_3[0] : K[1][4]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[1][5] <= 0;
	else if(current_state == STORE_K) K[1][5] <= ((cal_cnt == 5) ? row_1_3[0] : K[1][5]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[1][6] <= 0;
	else if(current_state == STORE_K) K[1][6] <= ((cal_cnt == 6) ? row_1_3[0] : K[1][6]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[1][7] <= 0;
	else if(current_state == STORE_K) K[1][7] <= ((cal_cnt == 7) ? row_1_3[0] : K[1][7]);
end


always @(posedge clk ) begin
	if(current_state == IDLE) K[2][0] <= 0;
	else if(current_state == STORE_K) K[2][0] <= ((cal_cnt == 0) ? row_1_3[1] : K[2][0]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[2][1] <= 0;
	else if(current_state == STORE_K) K[2][1] <= ((cal_cnt == 1) ? row_1_3[1] : K[2][1]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[2][2] <= 0;
	else if(current_state == STORE_K) K[2][2] <= ((cal_cnt == 2) ? row_1_3[1] : K[2][2]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[2][3] <= 0;
	else if(current_state == STORE_K) K[2][3] <= ((cal_cnt == 3) ? row_1_3[1] : K[2][3]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[2][4] <= 0;
	else if(current_state == STORE_K) K[2][4] <= ((cal_cnt == 4) ? row_1_3[1] : K[2][4]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[2][5] <= 0;
	else if(current_state == STORE_K) K[2][5] <= ((cal_cnt == 5) ? row_1_3[1] : K[2][5]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[2][6] <= 0;
	else if(current_state == STORE_K) K[2][6] <= ((cal_cnt == 6) ? row_1_3[1] : K[2][6]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[2][7] <= 0;
	else if(current_state == STORE_K) K[2][7] <= ((cal_cnt == 7) ? row_1_3[1] : K[2][7]);
end



always @(posedge clk ) begin
	if(current_state == IDLE) K[3][0] <= 0;
	else if(current_state == STORE_K) K[3][0] <= ((cal_cnt == 0) ? row_1_3[2] : K[3][0]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[3][1] <= 0;
	else if(current_state == STORE_K) K[3][1] <= ((cal_cnt == 1) ? row_1_3[2] : K[3][1]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[3][2] <= 0;
	else if(current_state == STORE_K) K[3][2] <= ((cal_cnt == 2) ? row_1_3[2] : K[3][2]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[3][3] <= 0;
	else if(current_state == STORE_K) K[3][3] <= ((cal_cnt == 3) ? row_1_3[2] : K[3][3]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[3][4] <= 0;
	else if(current_state == STORE_K) K[3][4] <= ((cal_cnt == 4) ? row_1_3[2] : K[3][4]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[3][5] <= 0;
	else if(current_state == STORE_K) K[3][5] <= ((cal_cnt == 5) ? row_1_3[2] : K[3][5]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[3][6] <= 0;
	else if(current_state == STORE_K) K[3][6] <= ((cal_cnt == 6) ? row_1_3[2] : K[3][6]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[3][7] <= 0;
	else if(current_state == STORE_K) K[3][7] <= ((cal_cnt == 7) ? row_1_3[2] : K[3][7]);
end




always @(posedge clk ) begin
	if(current_state == IDLE) V[1][0] <= 0;
	else if(current_state == STORE_V) V[1][0] <= ((cal_cnt == 0) ? row_1_3[0] : V[1][0]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[1][1] <= 0;
	else if(current_state == STORE_V) V[1][1] <= ((cal_cnt == 1) ? row_1_3[0] : V[1][1]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[1][2] <= 0;
	else if(current_state == STORE_V) V[1][2] <= ((cal_cnt == 2) ? row_1_3[0] : V[1][2]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[1][3] <= 0;
	else if(current_state == STORE_V) V[1][3] <= ((cal_cnt == 3) ? row_1_3[0] : V[1][3]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[1][4] <= 0;
	else if(current_state == STORE_V) V[1][4] <= ((cal_cnt == 4) ? row_1_3[0] : V[1][4]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[1][5] <= 0;
	else if(current_state == STORE_V) V[1][5] <= ((cal_cnt == 5) ? row_1_3[0] : V[1][5]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[1][6] <= 0;
	else if(current_state == STORE_V) V[1][6] <= ((cal_cnt == 6) ? row_1_3[0] : V[1][6]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[1][7] <= 0;
	else if(current_state == STORE_V) V[1][7] <= ((cal_cnt == 7) ? row_1_3[0] : V[1][7]);
end





always @(posedge clk ) begin
	if(current_state == IDLE) V[2][0] <= 0;
	else if(current_state == STORE_V) V[2][0] <= ((cal_cnt == 0) ? row_1_3[1] : V[2][0]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[2][1] <= 0;
	else if(current_state == STORE_V) V[2][1] <= ((cal_cnt == 1) ? row_1_3[1] : V[2][1]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[2][2] <= 0;
	else if(current_state == STORE_V) V[2][2] <= ((cal_cnt == 2) ? row_1_3[1] : V[2][2]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[2][3] <= 0;
	else if(current_state == STORE_V) V[2][3] <= ((cal_cnt == 3) ? row_1_3[1] : V[2][3]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[2][4] <= 0;
	else if(current_state == STORE_V) V[2][4] <= ((cal_cnt == 4) ? row_1_3[1] : V[2][4]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[2][5] <= 0;
	else if(current_state == STORE_V) V[2][5] <= ((cal_cnt == 5) ? row_1_3[1] : V[2][5]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[2][6] <= 0;
	else if(current_state == STORE_V) V[2][6] <= ((cal_cnt == 6) ? row_1_3[1] : V[2][6]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[2][7] <= 0;
	else if(current_state == STORE_V) V[2][7] <= ((cal_cnt == 7) ? row_1_3[1] : V[2][7]);
end



always @(posedge clk ) begin
	if(current_state == IDLE) V[3][0] <= 0;
	else if(current_state == STORE_V) V[3][0] <= ((cal_cnt == 0) ? row_1_3[2] : V[3][0]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[3][1] <= 0;
	else if(current_state == STORE_V) V[3][1] <= ((cal_cnt == 1) ? row_1_3[2] : V[3][1]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[3][2] <= 0;
	else if(current_state == STORE_V) V[3][2] <= ((cal_cnt == 2) ? row_1_3[2] : V[3][2]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[3][3] <= 0;
	else if(current_state == STORE_V) V[3][3] <= ((cal_cnt == 3) ? row_1_3[2] : V[3][3]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[3][4] <= 0;
	else if(current_state == STORE_V) V[3][4] <= ((cal_cnt == 4) ? row_1_3[2] : V[3][4]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[3][5] <= 0;
	else if(current_state == STORE_V) V[3][5] <= ((cal_cnt == 5) ? row_1_3[2] : V[3][5]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[3][6] <= 0;
	else if(current_state == STORE_V) V[3][6] <= ((cal_cnt == 6) ? row_1_3[2] : V[3][6]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[3][7] <= 0;
	else if(current_state == STORE_V) V[3][7] <= ((cal_cnt == 7) ? row_1_3[2] : V[3][7]);
end





//==============================================//
//                 4th~7th row                  //
//==============================================//

always @(*) begin
	case(current_state)
		STORE_K: row_4_7_a[0] = K[4][cal_cnt];
		STORE_V: row_4_7_a[0] = V[4][cal_cnt];
		default: row_4_7_a[0] = 0;
	endcase
end
always @(*) begin
	case(current_state)
		STORE_K: row_4_7_a[1] = K[5][cal_cnt];
		STORE_V: row_4_7_a[1] = V[5][cal_cnt];
		default: row_4_7_a[1] = 0;
	endcase
end
always @(*) begin
	case(current_state)
		STORE_K: row_4_7_a[2] = K[6][cal_cnt];
		STORE_V: row_4_7_a[2] = V[6][cal_cnt];
		default: row_4_7_a[2] = 0;
	endcase
end
always @(*) begin
	case(current_state)
		STORE_K: row_4_7_a[3] = K[7][cal_cnt];
		STORE_V: row_4_7_a[3] = V[7][cal_cnt];
		default: row_4_7_a[3] = 0;
	endcase
end

assign row_4_7[0] = row_4_7_a[0] + indata[4][in_cnt[5:3]] * row_0_b;
assign row_4_7[1] = row_4_7_a[1] + indata[5][in_cnt[5:3]] * row_0_b;
assign row_4_7[2] = row_4_7_a[2] + indata[6][in_cnt[5:3]] * row_0_b;
assign row_4_7[3] = row_4_7_a[3] + indata[7][in_cnt[5:3]] * row_0_b;



always @(posedge clk ) begin
	if(current_state == IDLE) Q[4][0] <= 0;
	else if(current_state == STORE_K) Q[4][0] <= Q[4][0] + ((cal_cnt == 0) ? indata[4][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][0] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[4][1] <= 0;
	else if(current_state == STORE_K) Q[4][1] <= Q[4][1] + ((cal_cnt == 1) ? indata[4][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][1] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[4][2] <= 0;
	else if(current_state == STORE_K) Q[4][2] <= Q[4][2] + ((cal_cnt == 2) ? indata[4][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][2] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[4][3] <= 0;
	else if(current_state == STORE_K) Q[4][3] <= Q[4][3] + ((cal_cnt == 3) ? indata[4][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][3] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[4][4] <= 0;
	else if(current_state == STORE_K) Q[4][4] <= Q[4][4] + ((cal_cnt == 4) ? indata[4][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][4] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[4][5] <= 0;
	else if(current_state == STORE_K) Q[4][5] <= Q[4][5] + ((cal_cnt == 5) ? indata[4][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][5] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[4][6] <= 0;
	else if(current_state == STORE_K) Q[4][6] <= Q[4][6] + ((cal_cnt == 6) ? indata[4][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][6] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[4][7] <= 0;
	else if(current_state == STORE_K) Q[4][7] <= Q[4][7] + ((cal_cnt == 7) ? indata[4][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][7] : 0);
end



always @(posedge clk ) begin
	if(current_state == IDLE) Q[5][0] <= 0;
	else if(current_state == STORE_K) Q[5][0] <= Q[5][0] + ((cal_cnt == 0) ? indata[5][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][0] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[5][1] <= 0;
	else if(current_state == STORE_K) Q[5][1] <= Q[5][1] + ((cal_cnt == 1) ? indata[5][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][1] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[5][2] <= 0;
	else if(current_state == STORE_K) Q[5][2] <= Q[5][2] + ((cal_cnt == 2) ? indata[5][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][2] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[5][3] <= 0;
	else if(current_state == STORE_K) Q[5][3] <= Q[5][3] + ((cal_cnt == 3) ? indata[5][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][3] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[5][4] <= 0;
	else if(current_state == STORE_K) Q[5][4] <= Q[5][4] + ((cal_cnt == 4) ? indata[5][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][4] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[5][5] <= 0;
	else if(current_state == STORE_K) Q[5][5] <= Q[5][5] + ((cal_cnt == 5) ? indata[5][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][5] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[5][6] <= 0;
	else if(current_state == STORE_K) Q[5][6] <= Q[5][6] + ((cal_cnt == 6) ? indata[5][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][6] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[5][7] <= 0;
	else if(current_state == STORE_K) Q[5][7] <= Q[5][7] + ((cal_cnt == 7) ? indata[5][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][7] : 0);
end



always @(posedge clk ) begin
	if(current_state == IDLE) Q[6][0] <= 0;
	else if(current_state == STORE_K) Q[6][0] <= Q[6][0] + ((cal_cnt == 0) ? indata[6][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][0] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[6][1] <= 0;
	else if(current_state == STORE_K) Q[6][1] <= Q[6][1] + ((cal_cnt == 1) ? indata[6][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][1] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[6][2] <= 0;
	else if(current_state == STORE_K) Q[6][2] <= Q[6][2] + ((cal_cnt == 2) ? indata[6][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][2] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[6][3] <= 0;
	else if(current_state == STORE_K) Q[6][3] <= Q[6][3] + ((cal_cnt == 3) ? indata[6][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][3] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[6][4] <= 0;
	else if(current_state == STORE_K) Q[6][4] <= Q[6][4] + ((cal_cnt == 4) ? indata[6][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][4] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[6][5] <= 0;
	else if(current_state == STORE_K) Q[6][5] <= Q[6][5] + ((cal_cnt == 5) ? indata[6][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][5] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[6][6] <= 0;
	else if(current_state == STORE_K) Q[6][6] <= Q[6][6] + ((cal_cnt == 6) ? indata[6][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][6] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[6][7] <= 0;
	else if(current_state == STORE_K) Q[6][7] <= Q[6][7] + ((cal_cnt == 7) ? indata[6][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][7] : 0);
end



always @(posedge clk ) begin
	if(current_state == IDLE) Q[7][0] <= 0;
	else if(current_state == STORE_K) Q[7][0] <= Q[7][0] + ((cal_cnt == 0) ? indata[7][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][0] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[7][1] <= 0;
	else if(current_state == STORE_K) Q[7][1] <= Q[7][1] + ((cal_cnt == 1) ? indata[7][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][1] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[7][2] <= 0;
	else if(current_state == STORE_K) Q[7][2] <= Q[7][2] + ((cal_cnt == 2) ? indata[7][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][2] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[7][3] <= 0;
	else if(current_state == STORE_K) Q[7][3] <= Q[7][3] + ((cal_cnt == 3) ? indata[7][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][3] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[7][4] <= 0;
	else if(current_state == STORE_K) Q[7][4] <= Q[7][4] + ((cal_cnt == 4) ? indata[7][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][4] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[7][5] <= 0;
	else if(current_state == STORE_K) Q[7][5] <= Q[7][5] + ((cal_cnt == 5) ? indata[7][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][5] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[7][6] <= 0;
	else if(current_state == STORE_K) Q[7][6] <= Q[7][6] + ((cal_cnt == 6) ? indata[7][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][6] : 0);
end
always @(posedge clk ) begin
	if(current_state == IDLE) Q[7][7] <= 0;
	else if(current_state == STORE_K) Q[7][7] <= Q[7][7] + ((cal_cnt == 7) ? indata[7][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][7] : 0);
end



always @(posedge clk ) begin
	if(current_state == IDLE) K[4][0] <= 0;
	else if(current_state == STORE_K) K[4][0] <= ((cal_cnt == 0) ? row_4_7[0] : K[4][0]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[4][1] <= 0;
	else if(current_state == STORE_K) K[4][1] <= ((cal_cnt == 1) ? row_4_7[0] : K[4][1]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[4][2] <= 0;
	else if(current_state == STORE_K) K[4][2] <= ((cal_cnt == 2) ? row_4_7[0] : K[4][2]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[4][3] <= 0;
	else if(current_state == STORE_K) K[4][3] <= ((cal_cnt == 3) ? row_4_7[0] : K[4][3]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[4][4] <= 0;
	else if(current_state == STORE_K) K[4][4] <= ((cal_cnt == 4) ? row_4_7[0] : K[4][4]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[4][5] <= 0;
	else if(current_state == STORE_K) K[4][5] <= ((cal_cnt == 5) ? row_4_7[0] : K[4][5]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[4][6] <= 0;
	else if(current_state == STORE_K) K[4][6] <= ((cal_cnt == 6) ? row_4_7[0] : K[4][6]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[4][7] <= 0;
	else if(current_state == STORE_K) K[4][7] <= ((cal_cnt == 7) ? row_4_7[0] : K[4][7]);
end




always @(posedge clk ) begin
	if(current_state == IDLE) K[5][0] <= 0;
	else if(current_state == STORE_K) K[5][0] <= ((cal_cnt == 0) ? row_4_7[1] : K[5][0]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[5][1] <= 0;
	else if(current_state == STORE_K) K[5][1] <= ((cal_cnt == 1) ? row_4_7[1] : K[5][1]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[5][2] <= 0;
	else if(current_state == STORE_K) K[5][2] <= ((cal_cnt == 2) ? row_4_7[1] : K[5][2]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[5][3] <= 0;
	else if(current_state == STORE_K) K[5][3] <= ((cal_cnt == 3) ? row_4_7[1] : K[5][3]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[5][4] <= 0;
	else if(current_state == STORE_K) K[5][4] <= ((cal_cnt == 4) ? row_4_7[1] : K[5][4]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[5][5] <= 0;
	else if(current_state == STORE_K) K[5][5] <= ((cal_cnt == 5) ? row_4_7[1] : K[5][5]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[5][6] <= 0;
	else if(current_state == STORE_K) K[5][6] <= ((cal_cnt == 6) ? row_4_7[1] : K[5][6]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[5][7] <= 0;
	else if(current_state == STORE_K) K[5][7] <= ((cal_cnt == 7) ? row_4_7[1] : K[5][7]);
end




always @(posedge clk ) begin
	if(current_state == IDLE) K[6][0] <= 0;
	else if(current_state == STORE_K) K[6][0] <= ((cal_cnt == 0) ? row_4_7[2] : K[6][0]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[6][1] <= 0;
	else if(current_state == STORE_K) K[6][1] <= ((cal_cnt == 1) ? row_4_7[2] : K[6][1]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[6][2] <= 0;
	else if(current_state == STORE_K) K[6][2] <= ((cal_cnt == 2) ? row_4_7[2] : K[6][2]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[6][3] <= 0;
	else if(current_state == STORE_K) K[6][3] <= ((cal_cnt == 3) ? row_4_7[2] : K[6][3]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[6][4] <= 0;
	else if(current_state == STORE_K) K[6][4] <= ((cal_cnt == 4) ? row_4_7[2] : K[6][4]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[6][5] <= 0;
	else if(current_state == STORE_K) K[6][5] <= ((cal_cnt == 5) ? row_4_7[2] : K[6][5]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[6][6] <= 0;
	else if(current_state == STORE_K) K[6][6] <= ((cal_cnt == 6) ? row_4_7[2] : K[6][6]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[6][7] <= 0;
	else if(current_state == STORE_K) K[6][7] <= ((cal_cnt == 7) ? row_4_7[2] : K[6][7]);
end




always @(posedge clk ) begin
	if(current_state == IDLE) K[7][0] <= 0;
	else if(current_state == STORE_K) K[7][0] <= ((cal_cnt == 0) ? row_4_7[3] : K[7][0]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[7][1] <= 0;
	else if(current_state == STORE_K) K[7][1] <= ((cal_cnt == 1) ? row_4_7[3] : K[7][1]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[7][2] <= 0;
	else if(current_state == STORE_K) K[7][2] <= ((cal_cnt == 2) ? row_4_7[3] : K[7][2]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[7][3] <= 0;
	else if(current_state == STORE_K) K[7][3] <= ((cal_cnt == 3) ? row_4_7[3] : K[7][3]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[7][4] <= 0;
	else if(current_state == STORE_K) K[7][4] <= ((cal_cnt == 4) ? row_4_7[3] : K[7][4]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[7][5] <= 0;
	else if(current_state == STORE_K) K[7][5] <= ((cal_cnt == 5) ? row_4_7[3] : K[7][5]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[7][6] <= 0;
	else if(current_state == STORE_K) K[7][6] <= ((cal_cnt == 6) ? row_4_7[3] : K[7][6]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) K[7][7] <= 0;
	else if(current_state == STORE_K) K[7][7] <= ((cal_cnt == 7) ? row_4_7[3] : K[7][7]);
end





always @(posedge clk ) begin
	if(current_state == IDLE) V[4][0] <= 0;
	else if(current_state == STORE_V) V[4][0] <= ((cal_cnt == 0) ? row_4_7[0] : V[4][0]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[4][1] <= 0;
	else if(current_state == STORE_V) V[4][1] <= ((cal_cnt == 1) ? row_4_7[0] : V[4][1]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[4][2] <= 0;
	else if(current_state == STORE_V) V[4][2] <= ((cal_cnt == 2) ? row_4_7[0] : V[4][2]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[4][3] <= 0;
	else if(current_state == STORE_V) V[4][3] <= ((cal_cnt == 3) ? row_4_7[0] : V[4][3]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[4][4] <= 0;
	else if(current_state == STORE_V) V[4][4] <= ((cal_cnt == 4) ? row_4_7[0] : V[4][4]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[4][5] <= 0;
	else if(current_state == STORE_V) V[4][5] <= ((cal_cnt == 5) ? row_4_7[0] : V[4][5]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[4][6] <= 0;
	else if(current_state == STORE_V) V[4][6] <= ((cal_cnt == 6) ? row_4_7[0] : V[4][6]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[4][7] <= 0;
	else if(current_state == STORE_V) V[4][7] <= ((cal_cnt == 7) ? row_4_7[0] : V[4][7]);
end




always @(posedge clk ) begin
	if(current_state == IDLE) V[5][0] <= 0;
	else if(current_state == STORE_V) V[5][0] <= ((cal_cnt == 0) ? row_4_7[1] : V[5][0]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[5][1] <= 0;
	else if(current_state == STORE_V) V[5][1] <= ((cal_cnt == 1) ? row_4_7[1] : V[5][1]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[5][2] <= 0;
	else if(current_state == STORE_V) V[5][2] <= ((cal_cnt == 2) ? row_4_7[1] : V[5][2]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[5][3] <= 0;
	else if(current_state == STORE_V) V[5][3] <= ((cal_cnt == 3) ? row_4_7[1] : V[5][3]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[5][4] <= 0;
	else if(current_state == STORE_V) V[5][4] <= ((cal_cnt == 4) ? row_4_7[1] : V[5][4]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[5][5] <= 0;
	else if(current_state == STORE_V) V[5][5] <= ((cal_cnt == 5) ? row_4_7[1] : V[5][5]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[5][6] <= 0;
	else if(current_state == STORE_V) V[5][6] <= ((cal_cnt == 6) ? row_4_7[1] : V[5][6]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[5][7] <= 0;
	else if(current_state == STORE_V) V[5][7] <= ((cal_cnt == 7) ? row_4_7[1] : V[5][7]);
end




always @(posedge clk ) begin
	if(current_state == IDLE) V[6][0] <= 0;
	else if(current_state == STORE_V) V[6][0] <= ((cal_cnt == 0) ? row_4_7[2] : V[6][0]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[6][1] <= 0;
	else if(current_state == STORE_V) V[6][1] <= ((cal_cnt == 1) ? row_4_7[2] : V[6][1]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[6][2] <= 0;
	else if(current_state == STORE_V) V[6][2] <= ((cal_cnt == 2) ? row_4_7[2] : V[6][2]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[6][3] <= 0;
	else if(current_state == STORE_V) V[6][3] <= ((cal_cnt == 3) ? row_4_7[2] : V[6][3]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[6][4] <= 0;
	else if(current_state == STORE_V) V[6][4] <= ((cal_cnt == 4) ? row_4_7[2] : V[6][4]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[6][5] <= 0;
	else if(current_state == STORE_V) V[6][5] <= ((cal_cnt == 5) ? row_4_7[2] : V[6][5]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[6][6] <= 0;
	else if(current_state == STORE_V) V[6][6] <= ((cal_cnt == 6) ? row_4_7[2] : V[6][6]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[6][7] <= 0;
	else if(current_state == STORE_V) V[6][7] <= ((cal_cnt == 7) ? row_4_7[2] : V[6][7]);
end




always @(posedge clk ) begin
	if(current_state == IDLE) V[7][0] <= 0;
	else if(current_state == STORE_V) V[7][0] <= ((cal_cnt == 0) ? row_4_7[3] : V[7][0]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[7][1] <= 0;
	else if(current_state == STORE_V) V[7][1] <= ((cal_cnt == 1) ? row_4_7[3] : V[7][1]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[7][2] <= 0;
	else if(current_state == STORE_V) V[7][2] <= ((cal_cnt == 2) ? row_4_7[3] : V[7][2]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[7][3] <= 0;
	else if(current_state == STORE_V) V[7][3] <= ((cal_cnt == 3) ? row_4_7[3] : V[7][3]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[7][4] <= 0;
	else if(current_state == STORE_V) V[7][4] <= ((cal_cnt == 4) ? row_4_7[3] : V[7][4]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[7][5] <= 0;
	else if(current_state == STORE_V) V[7][5] <= ((cal_cnt == 5) ? row_4_7[3] : V[7][5]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[7][6] <= 0;
	else if(current_state == STORE_V) V[7][6] <= ((cal_cnt == 6) ? row_4_7[3] : V[7][6]);
end
always @(posedge clk ) begin
	if(current_state == IDLE) V[7][7] <= 0;
	else if(current_state == STORE_V) V[7][7] <= ((cal_cnt == 7) ? row_4_7[3] : V[7][7]);
end


//==============================================//
//                     QKSR                     //
//==============================================//

always @(*) begin
	case(in_cnt[5:3])
		0: A_a[0] = A[0][0];
		1: A_a[0] = A[2][0];
		2: A_a[0] = A[0][4];
		3: A_a[0] = A[2][4];
		4: A_a[0] = A[4][0];
		5: A_a[0] = A[5][0];
		6: A_a[0] = A[6][0];
		7: A_a[0] = A[7][0];
		default: A_a[0] = 0;
	endcase
end
always @(*) begin
	case(in_cnt[5:3])
		0: A_a[1] = A[0][1];
		1: A_a[1] = A[2][1];
		2: A_a[1] = A[0][5];
		3: A_a[1] = A[2][5];
		4: A_a[1] = A[4][1];
		5: A_a[1] = A[5][1];
		6: A_a[1] = A[6][1];
		7: A_a[1] = A[7][1];
		default: A_a[1] = 0;
	endcase
end
always @(*) begin
	case(in_cnt[5:3])
		0: A_a[2] = A[0][2];
		1: A_a[2] = A[2][2];
		2: A_a[2] = A[0][6];
		3: A_a[2] = A[2][6];
		4: A_a[2] = A[4][2];
		5: A_a[2] = A[5][2];
		6: A_a[2] = A[6][2];
		7: A_a[2] = A[7][2];
		default: A_a[2] = 0;
	endcase
end
always @(*) begin
	case(in_cnt[5:3])
		0: A_a[3] = A[0][3];
		1: A_a[3] = A[2][3];
		2: A_a[3] = A[0][7];
		3: A_a[3] = A[2][7];
		4: A_a[3] = A[4][3];
		5: A_a[3] = A[5][3];
		6: A_a[3] = A[6][3];
		7: A_a[3] = A[7][3];
		default: A_a[3] = 0;
	endcase
end
always @(*) begin
	case(in_cnt[5:3])
		0: A_a[4] = A[1][0];
		1: A_a[4] = A[3][0];
		2: A_a[4] = A[1][4];
		3: A_a[4] = A[3][4];
		4: A_a[4] = A[4][4];
		5: A_a[4] = A[5][4];
		6: A_a[4] = A[6][4];
		7: A_a[4] = A[7][4];
		default: A_a[4] = 0;
	endcase
end
always @(*) begin
	case(in_cnt[5:3])
		0: A_a[5] = A[1][1];
		1: A_a[5] = A[3][1];
		2: A_a[5] = A[1][5];
		3: A_a[5] = A[3][5];
		4: A_a[5] = A[4][5];
		5: A_a[5] = A[5][5];
		6: A_a[5] = A[6][5];
		7: A_a[5] = A[7][5];
		default: A_a[5] = 0;
	endcase
end
always @(*) begin
	case(in_cnt[5:3])
		0: A_a[6] = A[1][2];
		1: A_a[6] = A[3][2];
		2: A_a[6] = A[1][6];
		3: A_a[6] = A[3][6];
		4: A_a[6] = A[4][6];
		5: A_a[6] = A[5][6];
		6: A_a[6] = A[6][6];
		7: A_a[6] = A[7][6];
		default: A_a[6] = 0;
	endcase
end
always @(*) begin
	case(in_cnt[5:3])
		0: A_a[7] = A[1][3];
		1: A_a[7] = A[3][3];
		2: A_a[7] = A[1][7];
		3: A_a[7] = A[3][7];
		4: A_a[7] = A[4][7];
		5: A_a[7] = A[5][7];
		6: A_a[7] = A[6][7];
		7: A_a[7] = A[7][7];
		default: A_a[7] = 0;
	endcase
end


always @(*) begin
	case(in_cnt[5:3])
		0: A_b[0] = Q[0][cal_cnt];
		1: A_b[0] = Q[2][cal_cnt];
		2: A_b[0] = Q[0][cal_cnt];
		3: A_b[0] = Q[2][cal_cnt];
		4: A_b[0] = Q[4][cal_cnt];
		5: A_b[0] = Q[5][cal_cnt];
		6: A_b[0] = Q[6][cal_cnt];
		7: A_b[0] = Q[7][cal_cnt];
		default: A_b[0] = 0;
	endcase
end
always @(*) begin
	case(in_cnt[5:3])
		0: A_b[1] = Q[1][cal_cnt];
		1: A_b[1] = Q[3][cal_cnt];
		2: A_b[1] = Q[1][cal_cnt];
		3: A_b[1] = Q[3][cal_cnt];
		4: A_b[1] = Q[4][cal_cnt];
		5: A_b[1] = Q[5][cal_cnt];
		6: A_b[1] = Q[6][cal_cnt];
		7: A_b[1] = Q[7][cal_cnt];
		default: A_b[1] = 0;
	endcase
end



always @(*) begin
	case(in_cnt[5:3])
		0: A_c[0] = K[0][cal_cnt];
		1: A_c[0] = K[0][cal_cnt];
		2: A_c[0] = K[4][cal_cnt];
		3: A_c[0] = K[4][cal_cnt];
		4: A_c[0] = K[0][cal_cnt];
		5: A_c[0] = K[0][cal_cnt];
		6: A_c[0] = K[0][cal_cnt];
		7: A_c[0] = K[0][cal_cnt];
		default: A_c[0] = 0;
	endcase
end
always @(*) begin
	case(in_cnt[5:3])
		0: A_c[1] = K[1][cal_cnt];
		1: A_c[1] = K[1][cal_cnt];
		2: A_c[1] = K[5][cal_cnt];
		3: A_c[1] = K[5][cal_cnt];
		4: A_c[1] = K[1][cal_cnt];
		5: A_c[1] = K[1][cal_cnt];
		6: A_c[1] = K[1][cal_cnt];
		7: A_c[1] = K[1][cal_cnt];
		default: A_c[1] = 0;
	endcase
end
always @(*) begin
	case(in_cnt[5:3])
		0: A_c[2] = K[2][cal_cnt];
		1: A_c[2] = K[2][cal_cnt];
		2: A_c[2] = K[6][cal_cnt];
		3: A_c[2] = K[6][cal_cnt];
		4: A_c[2] = K[2][cal_cnt];
		5: A_c[2] = K[2][cal_cnt];
		6: A_c[2] = K[2][cal_cnt];
		7: A_c[2] = K[2][cal_cnt];
		default: A_c[2] = 0;
	endcase
end
always @(*) begin
	case(in_cnt[5:3])
		0: A_c[3] = K[3][cal_cnt];
		1: A_c[3] = K[3][cal_cnt];
		2: A_c[3] = K[7][cal_cnt];
		3: A_c[3] = K[7][cal_cnt];
		4: A_c[3] = K[3][cal_cnt];
		5: A_c[3] = K[3][cal_cnt];
		6: A_c[3] = K[3][cal_cnt];
		7: A_c[3] = K[3][cal_cnt];
		default: A_c[3] = 0;
	endcase
end
always @(*) begin
	case(in_cnt[5:3])
		0: A_c[4] = K[0][cal_cnt];
		1: A_c[4] = K[0][cal_cnt];
		2: A_c[4] = K[4][cal_cnt];
		3: A_c[4] = K[4][cal_cnt];
		4: A_c[4] = K[4][cal_cnt];
		5: A_c[4] = K[4][cal_cnt];
		6: A_c[4] = K[4][cal_cnt];
		7: A_c[4] = K[4][cal_cnt];
		default: A_c[4] = 0;
	endcase
end
always @(*) begin
	case(in_cnt[5:3])
		0: A_c[5] = K[1][cal_cnt];
		1: A_c[5] = K[1][cal_cnt];
		2: A_c[5] = K[5][cal_cnt];
		3: A_c[5] = K[5][cal_cnt];
		4: A_c[5] = K[5][cal_cnt];
		5: A_c[5] = K[5][cal_cnt];
		6: A_c[5] = K[5][cal_cnt];
		7: A_c[5] = K[5][cal_cnt];
		default: A_c[5] = 0;
	endcase
end
always @(*) begin
	case(in_cnt[5:3])
		0: A_c[6] = K[2][cal_cnt];
		1: A_c[6] = K[2][cal_cnt];
		2: A_c[6] = K[6][cal_cnt];
		3: A_c[6] = K[6][cal_cnt];
		4: A_c[6] = K[6][cal_cnt];
		5: A_c[6] = K[6][cal_cnt];
		6: A_c[6] = K[6][cal_cnt];
		7: A_c[6] = K[6][cal_cnt];
		default: A_c[6] = 0;
	endcase
end
always @(*) begin
	case(in_cnt[5:3])
		0: A_c[7] = K[3][cal_cnt];
		1: A_c[7] = K[3][cal_cnt];
		2: A_c[7] = K[7][cal_cnt];
		3: A_c[7] = K[7][cal_cnt];
		4: A_c[7] = K[7][cal_cnt];
		5: A_c[7] = K[7][cal_cnt];
		6: A_c[7] = K[7][cal_cnt];
		7: A_c[7] = K[7][cal_cnt];
		default: A_c[7] = 0;
	endcase
end


assign A_sum[0] = A_a[0] + A_b[0] * A_c[0];
assign A_sum[1] = A_a[1] + A_b[0] * A_c[1];
assign A_sum[2] = A_a[2] + A_b[0] * A_c[2];
assign A_sum[3] = A_a[3] + A_b[0] * A_c[3];
assign A_sum[4] = A_a[4] + A_b[1] * A_c[4];
assign A_sum[5] = A_a[5] + A_b[1] * A_c[5];
assign A_sum[6] = A_a[6] + A_b[1] * A_c[6];
assign A_sum[7] = A_a[7] + A_b[1] * A_c[7];



always @(*) begin
	case(in_cnt)
		0: div[0] = A[7][0];
		8: div[0] = A[0][0];
		16: div[0] = A[2][0];
		24: div[0] = A[0][4];
		32: div[0] = A[2][4];
		40: div[0] = A[4][0];
		48: div[0] = A[5][0];
		56: div[0] = A[6][0];
		default: div[0] = 0;
	endcase
end
always @(*) begin
	case(in_cnt)
		0: div[1] = A[7][1];
		8: div[1] = A[0][1];
		16: div[1] = A[2][1];
		24: div[1] = A[0][5];
		32: div[1] = A[2][5];
		40: div[1] = A[4][1];
		48: div[1] = A[5][1];
		56: div[1] = A[6][1];
		default: div[1] = 0;
	endcase
end
always @(*) begin
	case(in_cnt)
		0: div[2] = A[7][2];
		8: div[2] = A[0][2];
		16: div[2] = A[2][2];
		24: div[2] = A[0][6];
		32: div[2] = A[2][6];
		40: div[2] = A[4][2];
		48: div[2] = A[5][2];
		56: div[2] = A[6][2];
		default: div[2] = 0;
	endcase
end
always @(*) begin
	case(in_cnt)
		0: div[3] = A[7][3];
		8: div[3] = A[0][3];
		16: div[3] = A[2][3];
		24: div[3] = A[0][7];
		32: div[3] = A[2][7];
		40: div[3] = A[4][3];
		48: div[3] = A[5][3];
		56: div[3] = A[6][3];
		default: div[3] = 0;
	endcase
end
always @(*) begin
	case(in_cnt)
		0: div[4] = A[7][4];
		8: div[4] = A[1][0];
		16: div[4] = A[3][0];
		24: div[4] = A[1][4];
		32: div[4] = A[3][4];
		40: div[4] = A[4][4];
		48: div[4] = A[5][4];
		56: div[4] = A[6][4];
		default: div[4] = 0;
	endcase
end

always @(*) begin
	case(in_cnt)
		0: div[5] = A[7][5];
		8: div[5] = A[1][1];
		16: div[5] = A[3][1];
		24: div[5] = A[1][5];
		32: div[5] = A[3][5];
		40: div[5] = A[4][5];
		48: div[5] = A[5][5];
		56: div[5] = A[6][5];
		default: div[5] = 0;
	endcase
end

always @(*) begin
	case(in_cnt)
		0: div[6] = A[7][6];
		8: div[6] = A[1][2];
		16: div[6] = A[3][2];
		24: div[6] = A[1][6];
		32: div[6] = A[3][6];
		40: div[6] = A[4][6];
		48: div[6] = A[5][6];
		56: div[6] = A[6][6];
		default: div[6] = 0;
	endcase
end
always @(*) begin
	case(in_cnt)
		0: div[7] = A[7][7];
		8: div[7] = A[1][3];
		16: div[7] = A[3][3];
		24: div[7] = A[1][7];
		32: div[7] = A[3][7];
		40: div[7] = A[4][7];
		48: div[7] = A[5][7];
		56: div[7] = A[6][7];
		default: div[7] = 0;
	endcase
end

assign A_div[0] = div[0][39] ? 0 : (div[0]/3);
assign A_div[1] = div[1][39] ? 0 : (div[1]/3);
assign A_div[2] = div[2][39] ? 0 : (div[2]/3);
assign A_div[3] = div[3][39] ? 0 : (div[3]/3);
assign A_div[4] = div[4][39] ? 0 : (div[4]/3);
assign A_div[5] = div[5][39] ? 0 : (div[5]/3);
assign A_div[6] = div[6][39] ? 0 : (div[6]/3);
assign A_div[7] = div[7][39] ? 0 : (div[7]/3);

//==============================================//
//                     1x1                      //
//==============================================//

always @(posedge clk ) begin
	if(current_state == IDLE) A[0][0] <= 0;
	else if(current_state == STORE_V && (in_cnt < 8)) A[0][0] <= A_sum[0];
	else if(current_state == STORE_V && in_cnt == 8) A[0][0] <= A_div[0];
end

//==============================================//
//                     4x4                      //
//==============================================//

always @(posedge clk ) begin
	if(current_state == IDLE) A[0][1] <= 0;
	else if(current_state == STORE_V && (in_cnt < 8)) A[0][1] <= A_sum[1];
	else if(current_state == STORE_V && in_cnt == 8) A[0][1] <= A_div[1];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[0][2] <= 0;
	else if(current_state == STORE_V && (in_cnt < 8)) A[0][2] <= A_sum[2];
	else if(current_state == STORE_V && in_cnt == 8) A[0][2] <= A_div[2];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[0][3] <= 0;
	else if(current_state == STORE_V && (in_cnt < 8)) A[0][3] <= A_sum[3];
	else if(current_state == STORE_V && in_cnt == 8) A[0][3] <= A_div[3];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[1][0] <= 0;
	else if(current_state == STORE_V && (in_cnt < 8)) A[1][0] <= A_sum[4];
	else if(current_state == STORE_V && in_cnt == 8) A[1][0] <= A_div[4];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[1][1] <= 0;
	else if(current_state == STORE_V && (in_cnt < 8)) A[1][1] <= A_sum[5];
	else if(current_state == STORE_V && in_cnt == 8) A[1][1] <= A_div[5];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[1][2] <= 0;
	else if(current_state == STORE_V && (in_cnt < 8)) A[1][2] <= A_sum[6];
	else if(current_state == STORE_V && in_cnt == 8) A[1][2] <= A_div[6];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[1][3] <= 0;
	else if(current_state == STORE_V && (in_cnt < 8)) A[1][3] <= A_sum[7];
	else if(current_state == STORE_V && in_cnt == 8) A[1][3] <= A_div[7];
end




always @(posedge clk ) begin
	if(current_state == IDLE) A[2][0] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 8) && (in_cnt < 16)) A[2][0] <= A_sum[0];
	else if(current_state == STORE_V && in_cnt == 16) A[2][0] <= A_div[0];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[2][1] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 8) && (in_cnt < 16)) A[2][1] <= A_sum[1];
	else if(current_state == STORE_V && in_cnt == 16) A[2][1] <= A_div[1];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[2][2] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 8) && (in_cnt < 16)) A[2][2] <= A_sum[2];
	else if(current_state == STORE_V && in_cnt == 16) A[2][2] <= A_div[2];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[2][3] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 8) && (in_cnt < 16)) A[2][3] <= A_sum[3];
	else if(current_state == STORE_V && in_cnt == 16) A[2][3] <= A_div[3];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[3][0] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 8) && (in_cnt < 16)) A[3][0] <= A_sum[4];
	else if(current_state == STORE_V && in_cnt == 16) A[3][0] <= A_div[4];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[3][1] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 8) && (in_cnt < 16)) A[3][1] <= A_sum[5];
	else if(current_state == STORE_V && in_cnt == 16) A[3][1] <= A_div[5];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[3][2] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 8) && (in_cnt < 16)) A[3][2] <= A_sum[6];
	else if(current_state == STORE_V && in_cnt == 16) A[3][2] <= A_div[6];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[3][3] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 8) && (in_cnt < 16)) A[3][3] <= A_sum[7];
	else if(current_state == STORE_V && in_cnt == 16) A[3][3] <= A_div[7];
end

//==============================================//
//                     8x8                      //
//==============================================//

always @(posedge clk ) begin
	if(current_state == IDLE) A[0][4] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 16) && (in_cnt < 24)) A[0][4] <= A_sum[0];
	else if(current_state == STORE_V && in_cnt == 24) A[0][4] <= A_div[0];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[0][5] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 16) && (in_cnt < 24)) A[0][5] <= A_sum[1];
	else if(current_state == STORE_V && in_cnt == 24) A[0][5] <= A_div[1];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[0][6] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 16) && (in_cnt < 24)) A[0][6] <= A_sum[2];
	else if(current_state == STORE_V && in_cnt == 24) A[0][6] <= A_div[2];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[0][7] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 16) && (in_cnt < 24)) A[0][7] <= A_sum[3];
	else if(current_state == STORE_V && in_cnt == 24) A[0][7] <= A_div[3];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[1][4] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 16) && (in_cnt < 24)) A[1][4] <= A_sum[4];
	else if(current_state == STORE_V && in_cnt == 24) A[1][4] <= A_div[4];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[1][5] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 16) && (in_cnt < 24)) A[1][5] <= A_sum[5];
	else if(current_state == STORE_V && in_cnt == 24) A[1][5] <= A_div[5];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[1][6] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 16) && (in_cnt < 24)) A[1][6] <= A_sum[6];
	else if(current_state == STORE_V && in_cnt == 24) A[1][6] <= A_div[6];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[1][7] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 16) && (in_cnt < 24)) A[1][7] <= A_sum[7];
	else if(current_state == STORE_V && in_cnt == 24) A[1][7] <= A_div[7];
end




always @(posedge clk ) begin
	if(current_state == IDLE) A[2][4] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 24) && (in_cnt < 32)) A[2][4] <= A_sum[0];
	else if(current_state == STORE_V && in_cnt == 32) A[2][4] <= A_div[0];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[2][5] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 24) && (in_cnt < 32)) A[2][5] <= A_sum[1];
	else if(current_state == STORE_V && in_cnt == 32) A[2][5] <= A_div[1];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[2][6] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 24) && (in_cnt < 32)) A[2][6] <= A_sum[2];
	else if(current_state == STORE_V && in_cnt == 32) A[2][6] <= A_div[2];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[2][7] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 24) && (in_cnt < 32)) A[2][7] <= A_sum[3];
	else if(current_state == STORE_V && in_cnt == 32) A[2][7] <= A_div[3];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[3][4] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 24) && (in_cnt < 32)) A[3][4] <= A_sum[4];
	else if(current_state == STORE_V && in_cnt == 32) A[3][4] <= A_div[4];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[3][5] <= A_sum[5];
	else if(current_state == STORE_V && (in_cnt >= 24) && (in_cnt < 32)) A[3][5] <= A_sum[5];
	else if(current_state == STORE_V && in_cnt == 32) A[3][5] <= A_div[5];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[3][6] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 24) && (in_cnt < 32)) A[3][6] <= A_sum[6];
	else if(current_state == STORE_V && in_cnt == 32) A[3][6] <= A_div[6];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[3][7] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 24) && (in_cnt < 32)) A[3][7] <= A_sum[7];
	else if(current_state == STORE_V && in_cnt == 32) A[3][7] <= A_div[7];
end






always @(posedge clk ) begin
	if(current_state == IDLE) A[4][0] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 32) && (in_cnt < 40)) A[4][0] <= A_sum[0];
	else if(current_state == STORE_V && in_cnt == 40) A[4][0] <= A_div[0];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[4][1] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 32) && (in_cnt < 40)) A[4][1] <= A_sum[1];
	else if(current_state == STORE_V && in_cnt == 40) A[4][1] <= A_div[1];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[4][2] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 32) && (in_cnt < 40)) A[4][2] <= A_sum[2];
	else if(current_state == STORE_V && in_cnt == 40) A[4][2] <= A_div[2];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[4][3] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 32) && (in_cnt < 40)) A[4][3] <= A_sum[3];
	else if(current_state == STORE_V && in_cnt == 40) A[4][3] <= A_div[3];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[4][4] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 32) && (in_cnt < 40)) A[4][4] <= A_sum[4];
	else if(current_state == STORE_V && in_cnt == 40) A[4][4] <= A_div[4];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[4][5] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 32) && (in_cnt < 40)) A[4][5] <= A_sum[5];
	else if(current_state == STORE_V && in_cnt == 40) A[4][5] <= A_div[5];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[4][6] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 32) && (in_cnt < 40)) A[4][6] <= A_sum[6];
	else if(current_state == STORE_V && in_cnt == 40) A[4][6] <= A_div[6];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[4][7] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 32) && (in_cnt < 40)) A[4][7] <= A_sum[7];
	else if(current_state == STORE_V && in_cnt == 40) A[4][7] <= A_div[7];
end




always @(posedge clk ) begin
	if(current_state == IDLE) A[5][0] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 40) && (in_cnt < 48)) A[5][0] <= A_sum[0];
	else if(current_state == STORE_V && in_cnt == 48) A[5][0] <= A_div[0];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[5][1] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 40) && (in_cnt < 48)) A[5][1] <= A_sum[1];
	else if(current_state == STORE_V && in_cnt == 48) A[5][1] <= A_div[1];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[5][2] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 40) && (in_cnt < 48)) A[5][2] <= A_sum[2];
	else if(current_state == STORE_V && in_cnt == 48) A[5][2] <= A_div[2];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[5][3] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 40) && (in_cnt < 48)) A[5][3] <= A_sum[3];
	else if(current_state == STORE_V && in_cnt == 48) A[5][3] <= A_div[3];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[5][4] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 40) && (in_cnt < 48)) A[5][4] <= A_sum[4];
	else if(current_state == STORE_V && in_cnt == 48) A[5][4] <= A_div[4];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[5][5] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 40) && (in_cnt < 48)) A[5][5] <= A_sum[5];
	else if(current_state == STORE_V && in_cnt == 48) A[5][5] <= A_div[5];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[5][6] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 40) && (in_cnt < 48)) A[5][6] <= A_sum[6];
	else if(current_state == STORE_V && in_cnt == 48) A[5][6] <= A_div[6];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[5][7] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 40) && (in_cnt < 48)) A[5][7] <= A_sum[7];
	else if(current_state == STORE_V && in_cnt == 48) A[5][7] <= A_div[7];
end



always @(posedge clk ) begin
	if(current_state == IDLE) A[6][0] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 48) && (in_cnt < 56)) A[6][0] <= A_sum[0];
	else if(current_state == STORE_V && in_cnt == 56) A[6][0] <= A_div[0];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[6][1] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 48) && (in_cnt < 56)) A[6][1] <= A_sum[1];
	else if(current_state == STORE_V && in_cnt == 56) A[6][1] <= A_div[1];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[6][2] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 48) && (in_cnt < 56)) A[6][2] <= A_sum[2];
	else if(current_state == STORE_V && in_cnt == 56) A[6][2] <= A_div[2];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[6][3] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 48) && (in_cnt < 56)) A[6][3] <= A_sum[3];
	else if(current_state == STORE_V && in_cnt == 56) A[6][3] <= A_div[3];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[6][4] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 48) && (in_cnt < 56)) A[6][4] <= A_sum[4];
	else if(current_state == STORE_V && in_cnt == 56) A[6][4] <= A_div[4];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[6][5] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 48) && (in_cnt < 56)) A[6][5] <= A_sum[5];
	else if(current_state == STORE_V && in_cnt == 56) A[6][5] <= A_div[5];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[6][6] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 48) && (in_cnt < 56)) A[6][6] <= A_sum[6];
	else if(current_state == STORE_V && in_cnt == 56) A[6][6] <= A_div[6];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[6][7] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 48) && (in_cnt < 56)) A[6][7] <= A_sum[7];
	else if(current_state == STORE_V && in_cnt == 56) A[6][7] <= A_div[7];
end



always @(posedge clk ) begin
	if(current_state == IDLE) A[7][0] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 56) && (in_cnt < 64)) A[7][0] <= A_sum[0];
	else if(current_state == MM2 && out_cnt == 1) A[7][0] <= A_div[0];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[7][1] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 56) && (in_cnt < 64)) A[7][1] <= A_sum[1];
	else if(current_state == MM2 && out_cnt == 1) A[7][1] <= A_div[1];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[7][2] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 56) && (in_cnt < 64)) A[7][2] <= A_sum[2];
	else if(current_state == MM2 && out_cnt == 1) A[7][2] <= A_div[2];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[7][3] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 56) && (in_cnt < 64)) A[7][3] <= A_sum[3];
	else if(current_state == MM2 && out_cnt == 1) A[7][3] <= A_div[3];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[7][4] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 56) && (in_cnt < 64)) A[7][4] <= A_sum[4];
	else if(current_state == MM2 && out_cnt == 1) A[7][4] <= A_div[4];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[7][5] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 56) && (in_cnt < 64)) A[7][5] <= A_sum[5];
	else if(current_state == MM2 && out_cnt == 1) A[7][5] <= A_div[5];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[7][6] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 56) && (in_cnt < 64)) A[7][6] <= A_sum[6];
	else if(current_state == MM2 && out_cnt == 1) A[7][6] <= A_div[6];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[7][7] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 56) && (in_cnt < 64)) A[7][7] <= A_sum[7];
	else if(current_state == MM2 && out_cnt == 1) A[7][7] <= A_div[7];
end





//==============================================//
//                     MM2                      //
//==============================================//

always @(posedge clk ) begin
	if(current_state == IDLE) out_cnt <= 0;
	else if(next_state == STORE_V && in_cnt == 62) out_cnt <= 0;
	else out_cnt <= out_cnt + 1;
end


always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		out_valid <= 0 ;
	end
	else if (next_state == MM2 && (out_cnt < (T_tmp << 3))) begin
		out_valid <= 1 ;
	end
	else begin  
		out_valid <= 0 ;
	end
end

reg [2:0] row_A;


always @(*) begin
	case(T_tmp)
		4, 8: row_A = out_cnt[5:3];
		default: row_A = 0;
	endcase
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		out_data <= 0;
	end
	else if (next_state == MM2 && (out_cnt < (T_tmp << 3))) begin
		out_data <= A[row_A][0] * V[0][out_cnt[2:0]] + ((T_tmp == 8 || T_tmp == 4) ? (A[row_A][1] * V[1][out_cnt[2:0]]) : 0) + ((T_tmp == 8 || T_tmp == 4) ? (A[row_A][2] * V[2][out_cnt[2:0]]) : 0) + ((T_tmp == 8 || T_tmp == 4) ? (A[row_A][3] * V[3][out_cnt[2:0]]) : 0) + ((T_tmp == 8) ? (A[row_A][4] * V[4][out_cnt[2:0]]) : 0) + ((T_tmp == 8) ? (A[row_A][5] * V[5][out_cnt[2:0]]) : 0) + ((T_tmp == 8) ? (A[row_A][6] * V[6][out_cnt[2:0]]) : 0) + ((T_tmp == 8) ? (A[row_A][7] * V[7][out_cnt[2:0]]) : 0);
	end
	else begin
		out_data <= 0;
	end
end

endmodule
