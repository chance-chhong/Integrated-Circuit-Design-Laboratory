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

// synopsys translate_off
`ifdef RTL
	`include "GATED_OR.v"
`else
	`include "Netlist/GATED_OR_SYN.v"
`endif
// synopsys translate_on


module SA(
    //Input signals
    clk,
    rst_n,
    cg_en,
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
input cg_en;
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

wire cg_ctrl_sa4x4 = cg_en && (T_tmp == 1);
wire cg_ctrl_sa8x8 = cg_en && (T_tmp == 1 || T_tmp == 4);
wire cg_clk_sa_4x4[0:86], cg_clk_sa_8x8[0:143];


//==============================================//
//                 GATED_OR                     //
//==============================================//

GATED_OR GATED_SA_4x4_0 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[0])
);
GATED_OR GATED_SA_4x4_1 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[1])
);
GATED_OR GATED_SA_4x4_2 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[2])
);
GATED_OR GATED_SA_4x4_3 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[3])
);
GATED_OR GATED_SA_4x4_4 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[4])
);
GATED_OR GATED_SA_4x4_5 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[5])
);
GATED_OR GATED_SA_4x4_6 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[6])
);
GATED_OR GATED_SA_4x4_7 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[7])
);
GATED_OR GATED_SA_4x4_8 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[8])
);
GATED_OR GATED_SA_4x4_9 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[9])
);
GATED_OR GATED_SA_4x4_10 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[10])
);
GATED_OR GATED_SA_4x4_11 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[11])
);
GATED_OR GATED_SA_4x4_12 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[12])
);
GATED_OR GATED_SA_4x4_13 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[13])
);
GATED_OR GATED_SA_4x4_14 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[14])
);
GATED_OR GATED_SA_4x4_15 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[15])
);
GATED_OR GATED_SA_4x4_16 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[16])
);
GATED_OR GATED_SA_4x4_17 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[17])
);
GATED_OR GATED_SA_4x4_18 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[18])
);
GATED_OR GATED_SA_4x4_19 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[19])
);
GATED_OR GATED_SA_4x4_20 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[20])
);
GATED_OR GATED_SA_4x4_21 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[21])
);
GATED_OR GATED_SA_4x4_22 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[22])
);
GATED_OR GATED_SA_4x4_23 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[23])
);
GATED_OR GATED_SA_4x4_24 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[24])
);
GATED_OR GATED_SA_4x4_25 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[25])
);
GATED_OR GATED_SA_4x4_26 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[26])
);
GATED_OR GATED_SA_4x4_27 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[27])
);
GATED_OR GATED_SA_4x4_28 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[28])
);
GATED_OR GATED_SA_4x4_29 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[29])
);
GATED_OR GATED_SA_4x4_30 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[30])
);
GATED_OR GATED_SA_4x4_31 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[31])
);
GATED_OR GATED_SA_4x4_32 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[32])
);
GATED_OR GATED_SA_4x4_33 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[33])
);
GATED_OR GATED_SA_4x4_34 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[34])
);
GATED_OR GATED_SA_4x4_35 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[35])
);
GATED_OR GATED_SA_4x4_36 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[36])
);
GATED_OR GATED_SA_4x4_37 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[37])
);
GATED_OR GATED_SA_4x4_38 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[38])
);
GATED_OR GATED_SA_4x4_39 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[39])
);
GATED_OR GATED_SA_4x4_40 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[40])
);
GATED_OR GATED_SA_4x4_41 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[41])
);
GATED_OR GATED_SA_4x4_42 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[42])
);
GATED_OR GATED_SA_4x4_43 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[43])
);
GATED_OR GATED_SA_4x4_44 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[44])
);
GATED_OR GATED_SA_4x4_45 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[45])
);
GATED_OR GATED_SA_4x4_46 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[46])
);
GATED_OR GATED_SA_4x4_47 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[47])
);
GATED_OR GATED_SA_4x4_48 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[48])
);
GATED_OR GATED_SA_4x4_49 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[49])
);
GATED_OR GATED_SA_4x4_50 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[50])
);
GATED_OR GATED_SA_4x4_51 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[51])
);
GATED_OR GATED_SA_4x4_52 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[52])
);
GATED_OR GATED_SA_4x4_53 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[53])
);
GATED_OR GATED_SA_4x4_54 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[54])
);
GATED_OR GATED_SA_4x4_55 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[55])
);
GATED_OR GATED_SA_4x4_56 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[56])
);
GATED_OR GATED_SA_4x4_57 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[57])
);
GATED_OR GATED_SA_4x4_58 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[58])
);
GATED_OR GATED_SA_4x4_59 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[59])
);
GATED_OR GATED_SA_4x4_60 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[60])
);
GATED_OR GATED_SA_4x4_61 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[61])
);
GATED_OR GATED_SA_4x4_62 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[62])
);
GATED_OR GATED_SA_4x4_63 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[63])
);
GATED_OR GATED_SA_4x4_64 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[64])
);
GATED_OR GATED_SA_4x4_65 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[65])
);
GATED_OR GATED_SA_4x4_66 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[66])
);
GATED_OR GATED_SA_4x4_67 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[67])
);
GATED_OR GATED_SA_4x4_68 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[68])
);
GATED_OR GATED_SA_4x4_69 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[69])
);
GATED_OR GATED_SA_4x4_70 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[70])
);
GATED_OR GATED_SA_4x4_71 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[71])
);
GATED_OR GATED_SA_4x4_72 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[72])
);
GATED_OR GATED_SA_4x4_73 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[73])
);
GATED_OR GATED_SA_4x4_74 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[74])
);
GATED_OR GATED_SA_4x4_75 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[75])
);
GATED_OR GATED_SA_4x4_76 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[76])
);
GATED_OR GATED_SA_4x4_77 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[77])
);
GATED_OR GATED_SA_4x4_78 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[78])
);
GATED_OR GATED_SA_4x4_79 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[79])
);
GATED_OR GATED_SA_4x4_80 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[80])
);
GATED_OR GATED_SA_4x4_81 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[81])
);
GATED_OR GATED_SA_4x4_82 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[82])
);
GATED_OR GATED_SA_4x4_83 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[83])
);
GATED_OR GATED_SA_4x4_84 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[84])
);
GATED_OR GATED_SA_4x4_85 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[85])
);
GATED_OR GATED_SA_4x4_86 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa4x4),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_4x4[86])
);



GATED_OR GATED_SA_8x8_0 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[0])
);
GATED_OR GATED_SA_8x8_1 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[1])
);
GATED_OR GATED_SA_8x8_2 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[2])
);
GATED_OR GATED_SA_8x8_3 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[3])
);
GATED_OR GATED_SA_8x8_4 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[4])
);
GATED_OR GATED_SA_8x8_5 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[5])
);
GATED_OR GATED_SA_8x8_6 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[6])
);
GATED_OR GATED_SA_8x8_7 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[7])
);
GATED_OR GATED_SA_8x8_8 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[8])
);
GATED_OR GATED_SA_8x8_9 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[9])
);
GATED_OR GATED_SA_8x8_10 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[10])
);
GATED_OR GATED_SA_8x8_11 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[11])
);
GATED_OR GATED_SA_8x8_12 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[12])
);
GATED_OR GATED_SA_8x8_13 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[13])
);
GATED_OR GATED_SA_8x8_14 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[14])
);
GATED_OR GATED_SA_8x8_15 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[15])
);
GATED_OR GATED_SA_8x8_16 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[16])
);
GATED_OR GATED_SA_8x8_17 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[17])
);
GATED_OR GATED_SA_8x8_18 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[18])
);
GATED_OR GATED_SA_8x8_19 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[19])
);
GATED_OR GATED_SA_8x8_20 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[20])
);
GATED_OR GATED_SA_8x8_21 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[21])
);
GATED_OR GATED_SA_8x8_22 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[22])
);
GATED_OR GATED_SA_8x8_23 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[23])
);
GATED_OR GATED_SA_8x8_24 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[24])
);
GATED_OR GATED_SA_8x8_25 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[25])
);
GATED_OR GATED_SA_8x8_26 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[26])
);
GATED_OR GATED_SA_8x8_27 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[27])
);
GATED_OR GATED_SA_8x8_28 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[28])
);
GATED_OR GATED_SA_8x8_29 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[29])
);
GATED_OR GATED_SA_8x8_30 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[30])
);
GATED_OR GATED_SA_8x8_31 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[31])
);
GATED_OR GATED_SA_8x8_32 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[32])
);
GATED_OR GATED_SA_8x8_33 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[33])
);
GATED_OR GATED_SA_8x8_34 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[34])
);
GATED_OR GATED_SA_8x8_35 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[35])
);
GATED_OR GATED_SA_8x8_36 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[36])
);
GATED_OR GATED_SA_8x8_37 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[37])
);
GATED_OR GATED_SA_8x8_38 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[38])
);
GATED_OR GATED_SA_8x8_39 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[39])
);
GATED_OR GATED_SA_8x8_40 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[40])
);
GATED_OR GATED_SA_8x8_41 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[41])
);
GATED_OR GATED_SA_8x8_42 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[42])
);
GATED_OR GATED_SA_8x8_43 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[43])
);
GATED_OR GATED_SA_8x8_44 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[44])
);
GATED_OR GATED_SA_8x8_45 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[45])
);
GATED_OR GATED_SA_8x8_46 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[46])
);
GATED_OR GATED_SA_8x8_47 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[47])
);
GATED_OR GATED_SA_8x8_48 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[48])
);
GATED_OR GATED_SA_8x8_49 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[49])
);
GATED_OR GATED_SA_8x8_50 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[50])
);
GATED_OR GATED_SA_8x8_51 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[51])
);
GATED_OR GATED_SA_8x8_52 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[52])
);
GATED_OR GATED_SA_8x8_53 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[53])
);
GATED_OR GATED_SA_8x8_54 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[54])
);
GATED_OR GATED_SA_8x8_55 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[55])
);
GATED_OR GATED_SA_8x8_56 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[56])
);
GATED_OR GATED_SA_8x8_57 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[57])
);
GATED_OR GATED_SA_8x8_58 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[58])
);
GATED_OR GATED_SA_8x8_59 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[59])
);
GATED_OR GATED_SA_8x8_60 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[60])
);
GATED_OR GATED_SA_8x8_61 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[61])
);
GATED_OR GATED_SA_8x8_62 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[62])
);
GATED_OR GATED_SA_8x8_63 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[63])
);
GATED_OR GATED_SA_8x8_64 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[64])
);
GATED_OR GATED_SA_8x8_65 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[65])
);
GATED_OR GATED_SA_8x8_66 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[66])
);
GATED_OR GATED_SA_8x8_67 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[67])
);
GATED_OR GATED_SA_8x8_68 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[68])
);
GATED_OR GATED_SA_8x8_69 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[69])
);
GATED_OR GATED_SA_8x8_70 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[70])
);
GATED_OR GATED_SA_8x8_71 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[71])
);
GATED_OR GATED_SA_8x8_72 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[72])
);
GATED_OR GATED_SA_8x8_73 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[73])
);
GATED_OR GATED_SA_8x8_74 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[74])
);
GATED_OR GATED_SA_8x8_75 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[75])
);
GATED_OR GATED_SA_8x8_76 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[76])
);
GATED_OR GATED_SA_8x8_77 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[77])
);
GATED_OR GATED_SA_8x8_78 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[78])
);
GATED_OR GATED_SA_8x8_79 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[79])
);
GATED_OR GATED_SA_8x8_80 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[80])
);
GATED_OR GATED_SA_8x8_81 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[81])
);
GATED_OR GATED_SA_8x8_82 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[82])
);
GATED_OR GATED_SA_8x8_83 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[83])
);
GATED_OR GATED_SA_8x8_84 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[84])
);
GATED_OR GATED_SA_8x8_85 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[85])
);
GATED_OR GATED_SA_8x8_86 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[86])
);
GATED_OR GATED_SA_8x8_87 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[87])
);
GATED_OR GATED_SA_8x8_88 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[88])
);
GATED_OR GATED_SA_8x8_89 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[89])
);
GATED_OR GATED_SA_8x8_90 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[90])
);
GATED_OR GATED_SA_8x8_91 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[91])
);
GATED_OR GATED_SA_8x8_92 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[92])
);
GATED_OR GATED_SA_8x8_93 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[93])
);
GATED_OR GATED_SA_8x8_94 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[94])
);
GATED_OR GATED_SA_8x8_95 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[95])
);
GATED_OR GATED_SA_8x8_96 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[96])
);
GATED_OR GATED_SA_8x8_97 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[97])
);
GATED_OR GATED_SA_8x8_98 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[98])
);
GATED_OR GATED_SA_8x8_99 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[99])
);
GATED_OR GATED_SA_8x8_100 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[100])
);
GATED_OR GATED_SA_8x8_101 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[101])
);
GATED_OR GATED_SA_8x8_102 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[102])
);
GATED_OR GATED_SA_8x8_103 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[103])
);
GATED_OR GATED_SA_8x8_104 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[104])
);
GATED_OR GATED_SA_8x8_105 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[105])
);
GATED_OR GATED_SA_8x8_106 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[106])
);
GATED_OR GATED_SA_8x8_107 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[107])
);
GATED_OR GATED_SA_8x8_108 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[108])
);
GATED_OR GATED_SA_8x8_109 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[109])
);
GATED_OR GATED_SA_8x8_110 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[110])
);
GATED_OR GATED_SA_8x8_111 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[111])
);
GATED_OR GATED_SA_8x8_112 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[112])
);
GATED_OR GATED_SA_8x8_113 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[113])
);
GATED_OR GATED_SA_8x8_114 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[114])
);
GATED_OR GATED_SA_8x8_115 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[115])
);
GATED_OR GATED_SA_8x8_116 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[116])
);
GATED_OR GATED_SA_8x8_117 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[117])
);
GATED_OR GATED_SA_8x8_118 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[118])
);
GATED_OR GATED_SA_8x8_119 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[119])
);
GATED_OR GATED_SA_8x8_120 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[120])
);
GATED_OR GATED_SA_8x8_121 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[121])
);
GATED_OR GATED_SA_8x8_122 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[122])
);
GATED_OR GATED_SA_8x8_123 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[123])
);
GATED_OR GATED_SA_8x8_124 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[124])
);
GATED_OR GATED_SA_8x8_125 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[125])
);
GATED_OR GATED_SA_8x8_126 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[126])
);
GATED_OR GATED_SA_8x8_127 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[127])
);
GATED_OR GATED_SA_8x8_128 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[128])
);
GATED_OR GATED_SA_8x8_129 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[129])
);
GATED_OR GATED_SA_8x8_130 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[130])
);
GATED_OR GATED_SA_8x8_131 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[131])
);
GATED_OR GATED_SA_8x8_132 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[132])
);
GATED_OR GATED_SA_8x8_133 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[133])
);
GATED_OR GATED_SA_8x8_134 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[134])
);
GATED_OR GATED_SA_8x8_135 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[135])
);
GATED_OR GATED_SA_8x8_136 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[136])
);
GATED_OR GATED_SA_8x8_137 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[137])
);
GATED_OR GATED_SA_8x8_138 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[138])
);
GATED_OR GATED_SA_8x8_139 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[139])
);
GATED_OR GATED_SA_8x8_140 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[140])
);
GATED_OR GATED_SA_8x8_141 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[141])
);
GATED_OR GATED_SA_8x8_142 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[142])
);
GATED_OR GATED_SA_8x8_143 (
	.CLOCK(clk),
	.SLEEP_CTRL(cg_ctrl_sa8x8),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(cg_clk_sa_8x8[143])
);


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




always @(posedge cg_clk_sa_4x4[15] ) begin
	if(current_state == IDLE) Q[1][0] <= 0;
	else if(current_state == STORE_K) Q[1][0] <= Q[1][0] + ((cal_cnt == 0) ? indata[1][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][0] : 0);
end
always @(posedge cg_clk_sa_4x4[16] ) begin
	if(current_state == IDLE) Q[1][1] <= 0;
	else if(current_state == STORE_K) Q[1][1] <= Q[1][1] + ((cal_cnt == 1) ? indata[1][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][1] : 0);
end
always @(posedge cg_clk_sa_4x4[17] ) begin
	if(current_state == IDLE) Q[1][2] <= 0;
	else if(current_state == STORE_K) Q[1][2] <= Q[1][2] + ((cal_cnt == 2) ? indata[1][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][2] : 0);
end
always @(posedge cg_clk_sa_4x4[18] ) begin
	if(current_state == IDLE) Q[1][3] <= 0;
	else if(current_state == STORE_K) Q[1][3] <= Q[1][3] + ((cal_cnt == 3) ? indata[1][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][3] : 0);
end
always @(posedge cg_clk_sa_4x4[19] ) begin
	if(current_state == IDLE) Q[1][4] <= 0;
	else if(current_state == STORE_K) Q[1][4] <= Q[1][4] + ((cal_cnt == 4) ? indata[1][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][4] : 0);
end
always @(posedge cg_clk_sa_4x4[20] ) begin
	if(current_state == IDLE) Q[1][5] <= 0;
	else if(current_state == STORE_K) Q[1][5] <= Q[1][5] + ((cal_cnt == 5) ? indata[1][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][5] : 0);
end
always @(posedge cg_clk_sa_4x4[21] ) begin
	if(current_state == IDLE) Q[1][6] <= 0;
	else if(current_state == STORE_K) Q[1][6] <= Q[1][6] + ((cal_cnt == 6) ? indata[1][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][6] : 0);
end
always @(posedge cg_clk_sa_4x4[22] ) begin
	if(current_state == IDLE) Q[1][7] <= 0;
	else if(current_state == STORE_K) Q[1][7] <= Q[1][7] + ((cal_cnt == 7) ? indata[1][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][7] : 0);
end


always @(posedge cg_clk_sa_4x4[23] ) begin
	if(current_state == IDLE) Q[2][0] <= 0;
	else if(current_state == STORE_K) Q[2][0] <= Q[2][0] + ((cal_cnt == 0) ? indata[2][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][0] : 0);
end
always @(posedge cg_clk_sa_4x4[24] ) begin
	if(current_state == IDLE) Q[2][1] <= 0;
	else if(current_state == STORE_K) Q[2][1] <= Q[2][1] + ((cal_cnt == 1) ? indata[2][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][1] : 0);
end
always @(posedge cg_clk_sa_4x4[25] ) begin
	if(current_state == IDLE) Q[2][2] <= 0;
	else if(current_state == STORE_K) Q[2][2] <= Q[2][2] + ((cal_cnt == 2) ? indata[2][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][2] : 0);
end
always @(posedge cg_clk_sa_4x4[26] ) begin
	if(current_state == IDLE) Q[2][3] <= 0;
	else if(current_state == STORE_K) Q[2][3] <= Q[2][3] + ((cal_cnt == 3) ? indata[2][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][3] : 0);
end
always @(posedge cg_clk_sa_4x4[27] ) begin
	if(current_state == IDLE) Q[2][4] <= 0;
	else if(current_state == STORE_K) Q[2][4] <= Q[2][4] + ((cal_cnt == 4) ? indata[2][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][4] : 0);
end
always @(posedge cg_clk_sa_4x4[28] ) begin
	if(current_state == IDLE) Q[2][5] <= 0;
	else if(current_state == STORE_K) Q[2][5] <= Q[2][5] + ((cal_cnt == 5) ? indata[2][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][5] : 0);
end
always @(posedge cg_clk_sa_4x4[29] ) begin
	if(current_state == IDLE) Q[2][6] <= 0;
	else if(current_state == STORE_K) Q[2][6] <= Q[2][6] + ((cal_cnt == 6) ? indata[2][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][6] : 0);
end
always @(posedge cg_clk_sa_4x4[30] ) begin
	if(current_state == IDLE) Q[2][7] <= 0;
	else if(current_state == STORE_K) Q[2][7] <= Q[2][7] + ((cal_cnt == 7) ? indata[2][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][7] : 0);
end


always @(posedge cg_clk_sa_4x4[31] ) begin
	if(current_state == IDLE) Q[3][0] <= 0;
	else if(current_state == STORE_K) Q[3][0] <= Q[3][0] + ((cal_cnt == 0) ? indata[3][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][0] : 0);
end
always @(posedge cg_clk_sa_4x4[32] ) begin
	if(current_state == IDLE) Q[3][1] <= 0;
	else if(current_state == STORE_K) Q[3][1] <= Q[3][1] + ((cal_cnt == 1) ? indata[3][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][1] : 0);
end
always @(posedge cg_clk_sa_4x4[33] ) begin
	if(current_state == IDLE) Q[3][2] <= 0;
	else if(current_state == STORE_K) Q[3][2] <= Q[3][2] + ((cal_cnt == 2) ? indata[3][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][2] : 0);
end
always @(posedge cg_clk_sa_4x4[34] ) begin
	if(current_state == IDLE) Q[3][3] <= 0;
	else if(current_state == STORE_K) Q[3][3] <= Q[3][3] + ((cal_cnt == 3) ? indata[3][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][3] : 0);
end
always @(posedge cg_clk_sa_4x4[35] ) begin
	if(current_state == IDLE) Q[3][4] <= 0;
	else if(current_state == STORE_K) Q[3][4] <= Q[3][4] + ((cal_cnt == 4) ? indata[3][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][4] : 0);
end
always @(posedge cg_clk_sa_4x4[36] ) begin
	if(current_state == IDLE) Q[3][5] <= 0;
	else if(current_state == STORE_K) Q[3][5] <= Q[3][5] + ((cal_cnt == 5) ? indata[3][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][5] : 0);
end
always @(posedge cg_clk_sa_4x4[37] ) begin
	if(current_state == IDLE) Q[3][6] <= 0;
	else if(current_state == STORE_K) Q[3][6] <= Q[3][6] + ((cal_cnt == 6) ? indata[3][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][6] : 0);
end
always @(posedge cg_clk_sa_4x4[38] ) begin
	if(current_state == IDLE) Q[3][7] <= 0;
	else if(current_state == STORE_K) Q[3][7] <= Q[3][7] + ((cal_cnt == 7) ? indata[3][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][7] : 0);
end



always @(posedge cg_clk_sa_4x4[39] ) begin
	if(current_state == IDLE) K[1][0] <= 0;
	else if(current_state == STORE_K) K[1][0] <= ((cal_cnt == 0) ? row_1_3[0] : K[1][0]);
end
always @(posedge cg_clk_sa_4x4[40] ) begin
	if(current_state == IDLE) K[1][1] <= 0;
	else if(current_state == STORE_K) K[1][1] <= ((cal_cnt == 1) ? row_1_3[0] : K[1][1]);
end
always @(posedge cg_clk_sa_4x4[41] ) begin
	if(current_state == IDLE) K[1][2] <= 0;
	else if(current_state == STORE_K) K[1][2] <= ((cal_cnt == 2) ? row_1_3[0] : K[1][2]);
end
always @(posedge cg_clk_sa_4x4[42] ) begin
	if(current_state == IDLE) K[1][3] <= 0;
	else if(current_state == STORE_K) K[1][3] <= ((cal_cnt == 3) ? row_1_3[0] : K[1][3]);
end
always @(posedge cg_clk_sa_4x4[43] ) begin
	if(current_state == IDLE) K[1][4] <= 0;
	else if(current_state == STORE_K) K[1][4] <= ((cal_cnt == 4) ? row_1_3[0] : K[1][4]);
end
always @(posedge cg_clk_sa_4x4[44] ) begin
	if(current_state == IDLE) K[1][5] <= 0;
	else if(current_state == STORE_K) K[1][5] <= ((cal_cnt == 5) ? row_1_3[0] : K[1][5]);
end
always @(posedge cg_clk_sa_4x4[45] ) begin
	if(current_state == IDLE) K[1][6] <= 0;
	else if(current_state == STORE_K) K[1][6] <= ((cal_cnt == 6) ? row_1_3[0] : K[1][6]);
end
always @(posedge cg_clk_sa_4x4[46] ) begin
	if(current_state == IDLE) K[1][7] <= 0;
	else if(current_state == STORE_K) K[1][7] <= ((cal_cnt == 7) ? row_1_3[0] : K[1][7]);
end


always @(posedge cg_clk_sa_4x4[47] ) begin
	if(current_state == IDLE) K[2][0] <= 0;
	else if(current_state == STORE_K) K[2][0] <= ((cal_cnt == 0) ? row_1_3[1] : K[2][0]);
end
always @(posedge cg_clk_sa_4x4[48] ) begin
	if(current_state == IDLE) K[2][1] <= 0;
	else if(current_state == STORE_K) K[2][1] <= ((cal_cnt == 1) ? row_1_3[1] : K[2][1]);
end
always @(posedge cg_clk_sa_4x4[49] ) begin
	if(current_state == IDLE) K[2][2] <= 0;
	else if(current_state == STORE_K) K[2][2] <= ((cal_cnt == 2) ? row_1_3[1] : K[2][2]);
end
always @(posedge cg_clk_sa_4x4[50] ) begin
	if(current_state == IDLE) K[2][3] <= 0;
	else if(current_state == STORE_K) K[2][3] <= ((cal_cnt == 3) ? row_1_3[1] : K[2][3]);
end
always @(posedge cg_clk_sa_4x4[51] ) begin
	if(current_state == IDLE) K[2][4] <= 0;
	else if(current_state == STORE_K) K[2][4] <= ((cal_cnt == 4) ? row_1_3[1] : K[2][4]);
end
always @(posedge cg_clk_sa_4x4[52] ) begin
	if(current_state == IDLE) K[2][5] <= 0;
	else if(current_state == STORE_K) K[2][5] <= ((cal_cnt == 5) ? row_1_3[1] : K[2][5]);
end
always @(posedge cg_clk_sa_4x4[53] ) begin
	if(current_state == IDLE) K[2][6] <= 0;
	else if(current_state == STORE_K) K[2][6] <= ((cal_cnt == 6) ? row_1_3[1] : K[2][6]);
end
always @(posedge cg_clk_sa_4x4[54] ) begin
	if(current_state == IDLE) K[2][7] <= 0;
	else if(current_state == STORE_K) K[2][7] <= ((cal_cnt == 7) ? row_1_3[1] : K[2][7]);
end



always @(posedge cg_clk_sa_4x4[55] ) begin
	if(current_state == IDLE) K[3][0] <= 0;
	else if(current_state == STORE_K) K[3][0] <= ((cal_cnt == 0) ? row_1_3[2] : K[3][0]);
end
always @(posedge cg_clk_sa_4x4[56] ) begin
	if(current_state == IDLE) K[3][1] <= 0;
	else if(current_state == STORE_K) K[3][1] <= ((cal_cnt == 1) ? row_1_3[2] : K[3][1]);
end
always @(posedge cg_clk_sa_4x4[57] ) begin
	if(current_state == IDLE) K[3][2] <= 0;
	else if(current_state == STORE_K) K[3][2] <= ((cal_cnt == 2) ? row_1_3[2] : K[3][2]);
end
always @(posedge cg_clk_sa_4x4[58] ) begin
	if(current_state == IDLE) K[3][3] <= 0;
	else if(current_state == STORE_K) K[3][3] <= ((cal_cnt == 3) ? row_1_3[2] : K[3][3]);
end
always @(posedge cg_clk_sa_4x4[59] ) begin
	if(current_state == IDLE) K[3][4] <= 0;
	else if(current_state == STORE_K) K[3][4] <= ((cal_cnt == 4) ? row_1_3[2] : K[3][4]);
end
always @(posedge cg_clk_sa_4x4[60] ) begin
	if(current_state == IDLE) K[3][5] <= 0;
	else if(current_state == STORE_K) K[3][5] <= ((cal_cnt == 5) ? row_1_3[2] : K[3][5]);
end
always @(posedge cg_clk_sa_4x4[61] ) begin
	if(current_state == IDLE) K[3][6] <= 0;
	else if(current_state == STORE_K) K[3][6] <= ((cal_cnt == 6) ? row_1_3[2] : K[3][6]);
end
always @(posedge cg_clk_sa_4x4[62] ) begin
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





always @(posedge cg_clk_sa_4x4[71] ) begin
	if(current_state == IDLE) V[2][0] <= 0;
	else if(current_state == STORE_V) V[2][0] <= ((cal_cnt == 0) ? row_1_3[1] : V[2][0]);
end
always @(posedge cg_clk_sa_4x4[72] ) begin
	if(current_state == IDLE) V[2][1] <= 0;
	else if(current_state == STORE_V) V[2][1] <= ((cal_cnt == 1) ? row_1_3[1] : V[2][1]);
end
always @(posedge cg_clk_sa_4x4[73] ) begin
	if(current_state == IDLE) V[2][2] <= 0;
	else if(current_state == STORE_V) V[2][2] <= ((cal_cnt == 2) ? row_1_3[1] : V[2][2]);
end
always @(posedge cg_clk_sa_4x4[74] ) begin
	if(current_state == IDLE) V[2][3] <= 0;
	else if(current_state == STORE_V) V[2][3] <= ((cal_cnt == 3) ? row_1_3[1] : V[2][3]);
end
always @(posedge cg_clk_sa_4x4[75] ) begin
	if(current_state == IDLE) V[2][4] <= 0;
	else if(current_state == STORE_V) V[2][4] <= ((cal_cnt == 4) ? row_1_3[1] : V[2][4]);
end
always @(posedge cg_clk_sa_4x4[76] ) begin
	if(current_state == IDLE) V[2][5] <= 0;
	else if(current_state == STORE_V) V[2][5] <= ((cal_cnt == 5) ? row_1_3[1] : V[2][5]);
end
always @(posedge cg_clk_sa_4x4[77] ) begin
	if(current_state == IDLE) V[2][6] <= 0;
	else if(current_state == STORE_V) V[2][6] <= ((cal_cnt == 6) ? row_1_3[1] : V[2][6]);
end
always @(posedge cg_clk_sa_4x4[78] ) begin
	if(current_state == IDLE) V[2][7] <= 0;
	else if(current_state == STORE_V) V[2][7] <= ((cal_cnt == 7) ? row_1_3[1] : V[2][7]);
end



always @(posedge cg_clk_sa_4x4[79] ) begin
	if(current_state == IDLE) V[3][0] <= 0;
	else if(current_state == STORE_V) V[3][0] <= ((cal_cnt == 0) ? row_1_3[2] : V[3][0]);
end
always @(posedge cg_clk_sa_4x4[80] ) begin
	if(current_state == IDLE) V[3][1] <= 0;
	else if(current_state == STORE_V) V[3][1] <= ((cal_cnt == 1) ? row_1_3[2] : V[3][1]);
end
always @(posedge cg_clk_sa_4x4[81] ) begin
	if(current_state == IDLE) V[3][2] <= 0;
	else if(current_state == STORE_V) V[3][2] <= ((cal_cnt == 2) ? row_1_3[2] : V[3][2]);
end
always @(posedge cg_clk_sa_4x4[82] ) begin
	if(current_state == IDLE) V[3][3] <= 0;
	else if(current_state == STORE_V) V[3][3] <= ((cal_cnt == 3) ? row_1_3[2] : V[3][3]);
end
always @(posedge cg_clk_sa_4x4[83] ) begin
	if(current_state == IDLE) V[3][4] <= 0;
	else if(current_state == STORE_V) V[3][4] <= ((cal_cnt == 4) ? row_1_3[2] : V[3][4]);
end
always @(posedge cg_clk_sa_4x4[84] ) begin
	if(current_state == IDLE) V[3][5] <= 0;
	else if(current_state == STORE_V) V[3][5] <= ((cal_cnt == 5) ? row_1_3[2] : V[3][5]);
end
always @(posedge cg_clk_sa_4x4[85] ) begin
	if(current_state == IDLE) V[3][6] <= 0;
	else if(current_state == STORE_V) V[3][6] <= ((cal_cnt == 6) ? row_1_3[2] : V[3][6]);
end
always @(posedge cg_clk_sa_4x4[86] ) begin
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



always @(posedge cg_clk_sa_8x8[48] ) begin
	if(current_state == IDLE) Q[4][0] <= 0;
	else if(current_state == STORE_K) Q[4][0] <= Q[4][0] + ((cal_cnt == 0) ? indata[4][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][0] : 0);
end
always @(posedge cg_clk_sa_8x8[49] ) begin
	if(current_state == IDLE) Q[4][1] <= 0;
	else if(current_state == STORE_K) Q[4][1] <= Q[4][1] + ((cal_cnt == 1) ? indata[4][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][1] : 0);
end
always @(posedge cg_clk_sa_8x8[50] ) begin
	if(current_state == IDLE) Q[4][2] <= 0;
	else if(current_state == STORE_K) Q[4][2] <= Q[4][2] + ((cal_cnt == 2) ? indata[4][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][2] : 0);
end
always @(posedge cg_clk_sa_8x8[51] ) begin
	if(current_state == IDLE) Q[4][3] <= 0;
	else if(current_state == STORE_K) Q[4][3] <= Q[4][3] + ((cal_cnt == 3) ? indata[4][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][3] : 0);
end
always @(posedge cg_clk_sa_8x8[52] ) begin
	if(current_state == IDLE) Q[4][4] <= 0;
	else if(current_state == STORE_K) Q[4][4] <= Q[4][4] + ((cal_cnt == 4) ? indata[4][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][4] : 0);
end
always @(posedge cg_clk_sa_8x8[53] ) begin
	if(current_state == IDLE) Q[4][5] <= 0;
	else if(current_state == STORE_K) Q[4][5] <= Q[4][5] + ((cal_cnt == 5) ? indata[4][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][5] : 0);
end
always @(posedge cg_clk_sa_8x8[54] ) begin
	if(current_state == IDLE) Q[4][6] <= 0;
	else if(current_state == STORE_K) Q[4][6] <= Q[4][6] + ((cal_cnt == 6) ? indata[4][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][6] : 0);
end
always @(posedge cg_clk_sa_8x8[55] ) begin
	if(current_state == IDLE) Q[4][7] <= 0;
	else if(current_state == STORE_K) Q[4][7] <= Q[4][7] + ((cal_cnt == 7) ? indata[4][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][7] : 0);
end



always @(posedge cg_clk_sa_8x8[56] ) begin
	if(current_state == IDLE) Q[5][0] <= 0;
	else if(current_state == STORE_K) Q[5][0] <= Q[5][0] + ((cal_cnt == 0) ? indata[5][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][0] : 0);
end
always @(posedge cg_clk_sa_8x8[57] ) begin
	if(current_state == IDLE) Q[5][1] <= 0;
	else if(current_state == STORE_K) Q[5][1] <= Q[5][1] + ((cal_cnt == 1) ? indata[5][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][1] : 0);
end
always @(posedge cg_clk_sa_8x8[58] ) begin
	if(current_state == IDLE) Q[5][2] <= 0;
	else if(current_state == STORE_K) Q[5][2] <= Q[5][2] + ((cal_cnt == 2) ? indata[5][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][2] : 0);
end
always @(posedge cg_clk_sa_8x8[59] ) begin
	if(current_state == IDLE) Q[5][3] <= 0;
	else if(current_state == STORE_K) Q[5][3] <= Q[5][3] + ((cal_cnt == 3) ? indata[5][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][3] : 0);
end
always @(posedge cg_clk_sa_8x8[60] ) begin
	if(current_state == IDLE) Q[5][4] <= 0;
	else if(current_state == STORE_K) Q[5][4] <= Q[5][4] + ((cal_cnt == 4) ? indata[5][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][4] : 0);
end
always @(posedge cg_clk_sa_8x8[61] ) begin
	if(current_state == IDLE) Q[5][5] <= 0;
	else if(current_state == STORE_K) Q[5][5] <= Q[5][5] + ((cal_cnt == 5) ? indata[5][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][5] : 0);
end
always @(posedge cg_clk_sa_8x8[62] ) begin
	if(current_state == IDLE) Q[5][6] <= 0;
	else if(current_state == STORE_K) Q[5][6] <= Q[5][6] + ((cal_cnt == 6) ? indata[5][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][6] : 0);
end
always @(posedge cg_clk_sa_8x8[63] ) begin
	if(current_state == IDLE) Q[5][7] <= 0;
	else if(current_state == STORE_K) Q[5][7] <= Q[5][7] + ((cal_cnt == 7) ? indata[5][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][7] : 0);
end



always @(posedge cg_clk_sa_8x8[64] ) begin
	if(current_state == IDLE) Q[6][0] <= 0;
	else if(current_state == STORE_K) Q[6][0] <= Q[6][0] + ((cal_cnt == 0) ? indata[6][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][0] : 0);
end
always @(posedge cg_clk_sa_8x8[65] ) begin
	if(current_state == IDLE) Q[6][1] <= 0;
	else if(current_state == STORE_K) Q[6][1] <= Q[6][1] + ((cal_cnt == 1) ? indata[6][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][1] : 0);
end
always @(posedge cg_clk_sa_8x8[66] ) begin
	if(current_state == IDLE) Q[6][2] <= 0;
	else if(current_state == STORE_K) Q[6][2] <= Q[6][2] + ((cal_cnt == 2) ? indata[6][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][2] : 0);
end
always @(posedge cg_clk_sa_8x8[67] ) begin
	if(current_state == IDLE) Q[6][3] <= 0;
	else if(current_state == STORE_K) Q[6][3] <= Q[6][3] + ((cal_cnt == 3) ? indata[6][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][3] : 0);
end
always @(posedge cg_clk_sa_8x8[68] ) begin
	if(current_state == IDLE) Q[6][4] <= 0;
	else if(current_state == STORE_K) Q[6][4] <= Q[6][4] + ((cal_cnt == 4) ? indata[6][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][4] : 0);
end
always @(posedge cg_clk_sa_8x8[69] ) begin
	if(current_state == IDLE) Q[6][5] <= 0;
	else if(current_state == STORE_K) Q[6][5] <= Q[6][5] + ((cal_cnt == 5) ? indata[6][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][5] : 0);
end
always @(posedge cg_clk_sa_8x8[70] ) begin
	if(current_state == IDLE) Q[6][6] <= 0;
	else if(current_state == STORE_K) Q[6][6] <= Q[6][6] + ((cal_cnt == 6) ? indata[6][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][6] : 0);
end
always @(posedge cg_clk_sa_8x8[71] ) begin
	if(current_state == IDLE) Q[6][7] <= 0;
	else if(current_state == STORE_K) Q[6][7] <= Q[6][7] + ((cal_cnt == 7) ? indata[6][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][7] : 0);
end



always @(posedge cg_clk_sa_8x8[72] ) begin
	if(current_state == IDLE) Q[7][0] <= 0;
	else if(current_state == STORE_K) Q[7][0] <= Q[7][0] + ((cal_cnt == 0) ? indata[7][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][0] : 0);
end
always @(posedge cg_clk_sa_8x8[73] ) begin
	if(current_state == IDLE) Q[7][1] <= 0;
	else if(current_state == STORE_K) Q[7][1] <= Q[7][1] + ((cal_cnt == 1) ? indata[7][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][1] : 0);
end
always @(posedge cg_clk_sa_8x8[74] ) begin
	if(current_state == IDLE) Q[7][2] <= 0;
	else if(current_state == STORE_K) Q[7][2] <= Q[7][2] + ((cal_cnt == 2) ? indata[7][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][2] : 0);
end
always @(posedge cg_clk_sa_8x8[75] ) begin
	if(current_state == IDLE) Q[7][3] <= 0;
	else if(current_state == STORE_K) Q[7][3] <= Q[7][3] + ((cal_cnt == 3) ? indata[7][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][3] : 0);
end
always @(posedge cg_clk_sa_8x8[76] ) begin
	if(current_state == IDLE) Q[7][4] <= 0;
	else if(current_state == STORE_K) Q[7][4] <= Q[7][4] + ((cal_cnt == 4) ? indata[7][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][4] : 0);
end
always @(posedge cg_clk_sa_8x8[77] ) begin
	if(current_state == IDLE) Q[7][5] <= 0;
	else if(current_state == STORE_K) Q[7][5] <= Q[7][5] + ((cal_cnt == 5) ? indata[7][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][5] : 0);
end
always @(posedge cg_clk_sa_8x8[78] ) begin
	if(current_state == IDLE) Q[7][6] <= 0;
	else if(current_state == STORE_K) Q[7][6] <= Q[7][6] + ((cal_cnt == 6) ? indata[7][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][6] : 0);
end
always @(posedge cg_clk_sa_8x8[79] ) begin
	if(current_state == IDLE) Q[7][7] <= 0;
	else if(current_state == STORE_K) Q[7][7] <= Q[7][7] + ((cal_cnt == 7) ? indata[7][in_cnt[5:3]] * w_Q_r[in_cnt[5:3]][7] : 0);
end




always @(posedge cg_clk_sa_8x8[80] ) begin
	if(current_state == IDLE) K[4][0] <= 0;
	else if(current_state == STORE_K) K[4][0] <= ((cal_cnt == 0) ? row_4_7[0] : K[4][0]);
end
always @(posedge cg_clk_sa_8x8[81] ) begin
	if(current_state == IDLE) K[4][1] <= 0;
	else if(current_state == STORE_K) K[4][1] <= ((cal_cnt == 1) ? row_4_7[0] : K[4][1]);
end
always @(posedge cg_clk_sa_8x8[82] ) begin
	if(current_state == IDLE) K[4][2] <= 0;
	else if(current_state == STORE_K) K[4][2] <= ((cal_cnt == 2) ? row_4_7[0] : K[4][2]);
end
always @(posedge cg_clk_sa_8x8[83] ) begin
	if(current_state == IDLE) K[4][3] <= 0;
	else if(current_state == STORE_K) K[4][3] <= ((cal_cnt == 3) ? row_4_7[0] : K[4][3]);
end
always @(posedge cg_clk_sa_8x8[84] ) begin
	if(current_state == IDLE) K[4][4] <= 0;
	else if(current_state == STORE_K) K[4][4] <= ((cal_cnt == 4) ? row_4_7[0] : K[4][4]);
end
always @(posedge cg_clk_sa_8x8[85] ) begin
	if(current_state == IDLE) K[4][5] <= 0;
	else if(current_state == STORE_K) K[4][5] <= ((cal_cnt == 5) ? row_4_7[0] : K[4][5]);
end
always @(posedge cg_clk_sa_8x8[86] ) begin
	if(current_state == IDLE) K[4][6] <= 0;
	else if(current_state == STORE_K) K[4][6] <= ((cal_cnt == 6) ? row_4_7[0] : K[4][6]);
end
always @(posedge cg_clk_sa_8x8[87] ) begin
	if(current_state == IDLE) K[4][7] <= 0;
	else if(current_state == STORE_K) K[4][7] <= ((cal_cnt == 7) ? row_4_7[0] : K[4][7]);
end




always @(posedge cg_clk_sa_8x8[88] ) begin
	if(current_state == IDLE) K[5][0] <= 0;
	else if(current_state == STORE_K) K[5][0] <= ((cal_cnt == 0) ? row_4_7[1] : K[5][0]);
end
always @(posedge cg_clk_sa_8x8[89] ) begin
	if(current_state == IDLE) K[5][1] <= 0;
	else if(current_state == STORE_K) K[5][1] <= ((cal_cnt == 1) ? row_4_7[1] : K[5][1]);
end
always @(posedge cg_clk_sa_8x8[90] ) begin
	if(current_state == IDLE) K[5][2] <= 0;
	else if(current_state == STORE_K) K[5][2] <= ((cal_cnt == 2) ? row_4_7[1] : K[5][2]);
end
always @(posedge cg_clk_sa_8x8[91] ) begin
	if(current_state == IDLE) K[5][3] <= 0;
	else if(current_state == STORE_K) K[5][3] <= ((cal_cnt == 3) ? row_4_7[1] : K[5][3]);
end
always @(posedge cg_clk_sa_8x8[92] ) begin
	if(current_state == IDLE) K[5][4] <= 0;
	else if(current_state == STORE_K) K[5][4] <= ((cal_cnt == 4) ? row_4_7[1] : K[5][4]);
end
always @(posedge cg_clk_sa_8x8[93] ) begin
	if(current_state == IDLE) K[5][5] <= 0;
	else if(current_state == STORE_K) K[5][5] <= ((cal_cnt == 5) ? row_4_7[1] : K[5][5]);
end
always @(posedge cg_clk_sa_8x8[94] ) begin
	if(current_state == IDLE) K[5][6] <= 0;
	else if(current_state == STORE_K) K[5][6] <= ((cal_cnt == 6) ? row_4_7[1] : K[5][6]);
end
always @(posedge cg_clk_sa_8x8[95] ) begin
	if(current_state == IDLE) K[5][7] <= 0;
	else if(current_state == STORE_K) K[5][7] <= ((cal_cnt == 7) ? row_4_7[1] : K[5][7]);
end




always @(posedge cg_clk_sa_8x8[96] ) begin
	if(current_state == IDLE) K[6][0] <= 0;
	else if(current_state == STORE_K) K[6][0] <= ((cal_cnt == 0) ? row_4_7[2] : K[6][0]);
end
always @(posedge cg_clk_sa_8x8[97] ) begin
	if(current_state == IDLE) K[6][1] <= 0;
	else if(current_state == STORE_K) K[6][1] <= ((cal_cnt == 1) ? row_4_7[2] : K[6][1]);
end
always @(posedge cg_clk_sa_8x8[98] ) begin
	if(current_state == IDLE) K[6][2] <= 0;
	else if(current_state == STORE_K) K[6][2] <= ((cal_cnt == 2) ? row_4_7[2] : K[6][2]);
end
always @(posedge cg_clk_sa_8x8[99] ) begin
	if(current_state == IDLE) K[6][3] <= 0;
	else if(current_state == STORE_K) K[6][3] <= ((cal_cnt == 3) ? row_4_7[2] : K[6][3]);
end
always @(posedge cg_clk_sa_8x8[100] ) begin
	if(current_state == IDLE) K[6][4] <= 0;
	else if(current_state == STORE_K) K[6][4] <= ((cal_cnt == 4) ? row_4_7[2] : K[6][4]);
end
always @(posedge cg_clk_sa_8x8[101] ) begin
	if(current_state == IDLE) K[6][5] <= 0;
	else if(current_state == STORE_K) K[6][5] <= ((cal_cnt == 5) ? row_4_7[2] : K[6][5]);
end
always @(posedge cg_clk_sa_8x8[102] ) begin
	if(current_state == IDLE) K[6][6] <= 0;
	else if(current_state == STORE_K) K[6][6] <= ((cal_cnt == 6) ? row_4_7[2] : K[6][6]);
end
always @(posedge cg_clk_sa_8x8[103] ) begin
	if(current_state == IDLE) K[6][7] <= 0;
	else if(current_state == STORE_K) K[6][7] <= ((cal_cnt == 7) ? row_4_7[2] : K[6][7]);
end




always @(posedge cg_clk_sa_8x8[104] ) begin
	if(current_state == IDLE) K[7][0] <= 0;
	else if(current_state == STORE_K) K[7][0] <= ((cal_cnt == 0) ? row_4_7[3] : K[7][0]);
end
always @(posedge cg_clk_sa_8x8[105] ) begin
	if(current_state == IDLE) K[7][1] <= 0;
	else if(current_state == STORE_K) K[7][1] <= ((cal_cnt == 1) ? row_4_7[3] : K[7][1]);
end
always @(posedge cg_clk_sa_8x8[106] ) begin
	if(current_state == IDLE) K[7][2] <= 0;
	else if(current_state == STORE_K) K[7][2] <= ((cal_cnt == 2) ? row_4_7[3] : K[7][2]);
end
always @(posedge cg_clk_sa_8x8[107] ) begin
	if(current_state == IDLE) K[7][3] <= 0;
	else if(current_state == STORE_K) K[7][3] <= ((cal_cnt == 3) ? row_4_7[3] : K[7][3]);
end
always @(posedge cg_clk_sa_8x8[108] ) begin
	if(current_state == IDLE) K[7][4] <= 0;
	else if(current_state == STORE_K) K[7][4] <= ((cal_cnt == 4) ? row_4_7[3] : K[7][4]);
end
always @(posedge cg_clk_sa_8x8[109] ) begin
	if(current_state == IDLE) K[7][5] <= 0;
	else if(current_state == STORE_K) K[7][5] <= ((cal_cnt == 5) ? row_4_7[3] : K[7][5]);
end
always @(posedge cg_clk_sa_8x8[110] ) begin
	if(current_state == IDLE) K[7][6] <= 0;
	else if(current_state == STORE_K) K[7][6] <= ((cal_cnt == 6) ? row_4_7[3] : K[7][6]);
end
always @(posedge cg_clk_sa_8x8[111] ) begin
	if(current_state == IDLE) K[7][7] <= 0;
	else if(current_state == STORE_K) K[7][7] <= ((cal_cnt == 7) ? row_4_7[3] : K[7][7]);
end





always @(posedge cg_clk_sa_8x8[112] ) begin
	if(current_state == IDLE) V[4][0] <= 0;
	else if(current_state == STORE_V) V[4][0] <= ((cal_cnt == 0) ? row_4_7[0] : V[4][0]);
end
always @(posedge cg_clk_sa_8x8[113] ) begin
	if(current_state == IDLE) V[4][1] <= 0;
	else if(current_state == STORE_V) V[4][1] <= ((cal_cnt == 1) ? row_4_7[0] : V[4][1]);
end
always @(posedge cg_clk_sa_8x8[114] ) begin
	if(current_state == IDLE) V[4][2] <= 0;
	else if(current_state == STORE_V) V[4][2] <= ((cal_cnt == 2) ? row_4_7[0] : V[4][2]);
end
always @(posedge cg_clk_sa_8x8[115] ) begin
	if(current_state == IDLE) V[4][3] <= 0;
	else if(current_state == STORE_V) V[4][3] <= ((cal_cnt == 3) ? row_4_7[0] : V[4][3]);
end
always @(posedge cg_clk_sa_8x8[116] ) begin
	if(current_state == IDLE) V[4][4] <= 0;
	else if(current_state == STORE_V) V[4][4] <= ((cal_cnt == 4) ? row_4_7[0] : V[4][4]);
end
always @(posedge cg_clk_sa_8x8[117] ) begin
	if(current_state == IDLE) V[4][5] <= 0;
	else if(current_state == STORE_V) V[4][5] <= ((cal_cnt == 5) ? row_4_7[0] : V[4][5]);
end
always @(posedge cg_clk_sa_8x8[118] ) begin
	if(current_state == IDLE) V[4][6] <= 0;
	else if(current_state == STORE_V) V[4][6] <= ((cal_cnt == 6) ? row_4_7[0] : V[4][6]);
end
always @(posedge cg_clk_sa_8x8[119] ) begin
	if(current_state == IDLE) V[4][7] <= 0;
	else if(current_state == STORE_V) V[4][7] <= ((cal_cnt == 7) ? row_4_7[0] : V[4][7]);
end




always @(posedge cg_clk_sa_8x8[120] ) begin
	if(current_state == IDLE) V[5][0] <= 0;
	else if(current_state == STORE_V) V[5][0] <= ((cal_cnt == 0) ? row_4_7[1] : V[5][0]);
end
always @(posedge cg_clk_sa_8x8[121] ) begin
	if(current_state == IDLE) V[5][1] <= 0;
	else if(current_state == STORE_V) V[5][1] <= ((cal_cnt == 1) ? row_4_7[1] : V[5][1]);
end
always @(posedge cg_clk_sa_8x8[122] ) begin
	if(current_state == IDLE) V[5][2] <= 0;
	else if(current_state == STORE_V) V[5][2] <= ((cal_cnt == 2) ? row_4_7[1] : V[5][2]);
end
always @(posedge cg_clk_sa_8x8[123] ) begin
	if(current_state == IDLE) V[5][3] <= 0;
	else if(current_state == STORE_V) V[5][3] <= ((cal_cnt == 3) ? row_4_7[1] : V[5][3]);
end
always @(posedge cg_clk_sa_8x8[124] ) begin
	if(current_state == IDLE) V[5][4] <= 0;
	else if(current_state == STORE_V) V[5][4] <= ((cal_cnt == 4) ? row_4_7[1] : V[5][4]);
end
always @(posedge cg_clk_sa_8x8[125] ) begin
	if(current_state == IDLE) V[5][5] <= 0;
	else if(current_state == STORE_V) V[5][5] <= ((cal_cnt == 5) ? row_4_7[1] : V[5][5]);
end
always @(posedge cg_clk_sa_8x8[126] ) begin
	if(current_state == IDLE) V[5][6] <= 0;
	else if(current_state == STORE_V) V[5][6] <= ((cal_cnt == 6) ? row_4_7[1] : V[5][6]);
end
always @(posedge cg_clk_sa_8x8[127] ) begin
	if(current_state == IDLE) V[5][7] <= 0;
	else if(current_state == STORE_V) V[5][7] <= ((cal_cnt == 7) ? row_4_7[1] : V[5][7]);
end




always @(posedge cg_clk_sa_8x8[128] ) begin
	if(current_state == IDLE) V[6][0] <= 0;
	else if(current_state == STORE_V) V[6][0] <= ((cal_cnt == 0) ? row_4_7[2] : V[6][0]);
end
always @(posedge cg_clk_sa_8x8[129] ) begin
	if(current_state == IDLE) V[6][1] <= 0;
	else if(current_state == STORE_V) V[6][1] <= ((cal_cnt == 1) ? row_4_7[2] : V[6][1]);
end
always @(posedge cg_clk_sa_8x8[130] ) begin
	if(current_state == IDLE) V[6][2] <= 0;
	else if(current_state == STORE_V) V[6][2] <= ((cal_cnt == 2) ? row_4_7[2] : V[6][2]);
end
always @(posedge cg_clk_sa_8x8[131] ) begin
	if(current_state == IDLE) V[6][3] <= 0;
	else if(current_state == STORE_V) V[6][3] <= ((cal_cnt == 3) ? row_4_7[2] : V[6][3]);
end
always @(posedge cg_clk_sa_8x8[132] ) begin
	if(current_state == IDLE) V[6][4] <= 0;
	else if(current_state == STORE_V) V[6][4] <= ((cal_cnt == 4) ? row_4_7[2] : V[6][4]);
end
always @(posedge cg_clk_sa_8x8[133] ) begin
	if(current_state == IDLE) V[6][5] <= 0;
	else if(current_state == STORE_V) V[6][5] <= ((cal_cnt == 5) ? row_4_7[2] : V[6][5]);
end
always @(posedge cg_clk_sa_8x8[134] ) begin
	if(current_state == IDLE) V[6][6] <= 0;
	else if(current_state == STORE_V) V[6][6] <= ((cal_cnt == 6) ? row_4_7[2] : V[6][6]);
end
always @(posedge cg_clk_sa_8x8[135] ) begin
	if(current_state == IDLE) V[6][7] <= 0;
	else if(current_state == STORE_V) V[6][7] <= ((cal_cnt == 7) ? row_4_7[2] : V[6][7]);
end




always @(posedge cg_clk_sa_8x8[136] ) begin
	if(current_state == IDLE) V[7][0] <= 0;
	else if(current_state == STORE_V) V[7][0] <= ((cal_cnt == 0) ? row_4_7[3] : V[7][0]);
end
always @(posedge cg_clk_sa_8x8[137] ) begin
	if(current_state == IDLE) V[7][1] <= 0;
	else if(current_state == STORE_V) V[7][1] <= ((cal_cnt == 1) ? row_4_7[3] : V[7][1]);
end
always @(posedge cg_clk_sa_8x8[138] ) begin
	if(current_state == IDLE) V[7][2] <= 0;
	else if(current_state == STORE_V) V[7][2] <= ((cal_cnt == 2) ? row_4_7[3] : V[7][2]);
end
always @(posedge cg_clk_sa_8x8[139] ) begin
	if(current_state == IDLE) V[7][3] <= 0;
	else if(current_state == STORE_V) V[7][3] <= ((cal_cnt == 3) ? row_4_7[3] : V[7][3]);
end
always @(posedge cg_clk_sa_8x8[140] ) begin
	if(current_state == IDLE) V[7][4] <= 0;
	else if(current_state == STORE_V) V[7][4] <= ((cal_cnt == 4) ? row_4_7[3] : V[7][4]);
end
always @(posedge cg_clk_sa_8x8[141] ) begin
	if(current_state == IDLE) V[7][5] <= 0;
	else if(current_state == STORE_V) V[7][5] <= ((cal_cnt == 5) ? row_4_7[3] : V[7][5]);
end
always @(posedge cg_clk_sa_8x8[142] ) begin
	if(current_state == IDLE) V[7][6] <= 0;
	else if(current_state == STORE_V) V[7][6] <= ((cal_cnt == 6) ? row_4_7[3] : V[7][6]);
end
always @(posedge cg_clk_sa_8x8[143] ) begin
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

always @(posedge cg_clk_sa_4x4[0] ) begin
	if(current_state == IDLE) A[0][1] <= 0;
	else if(current_state == STORE_V && (in_cnt < 8)) A[0][1] <= A_sum[1];
	else if(current_state == STORE_V && in_cnt == 8) A[0][1] <= A_div[1];
end
always @(posedge cg_clk_sa_4x4[1] ) begin
	if(current_state == IDLE) A[0][2] <= 0;
	else if(current_state == STORE_V && (in_cnt < 8)) A[0][2] <= A_sum[2];
	else if(current_state == STORE_V && in_cnt == 8) A[0][2] <= A_div[2];
end
always @(posedge cg_clk_sa_4x4[2] ) begin
	if(current_state == IDLE) A[0][3] <= 0;
	else if(current_state == STORE_V && (in_cnt < 8)) A[0][3] <= A_sum[3];
	else if(current_state == STORE_V && in_cnt == 8) A[0][3] <= A_div[3];
end
always @(posedge cg_clk_sa_4x4[3] ) begin
	if(current_state == IDLE) A[1][0] <= 0;
	else if(current_state == STORE_V && (in_cnt < 8)) A[1][0] <= A_sum[4];
	else if(current_state == STORE_V && in_cnt == 8) A[1][0] <= A_div[4];
end
always @(posedge cg_clk_sa_4x4[4] ) begin
	if(current_state == IDLE) A[1][1] <= 0;
	else if(current_state == STORE_V && (in_cnt < 8)) A[1][1] <= A_sum[5];
	else if(current_state == STORE_V && in_cnt == 8) A[1][1] <= A_div[5];
end
always @(posedge cg_clk_sa_4x4[5] ) begin
	if(current_state == IDLE) A[1][2] <= 0;
	else if(current_state == STORE_V && (in_cnt < 8)) A[1][2] <= A_sum[6];
	else if(current_state == STORE_V && in_cnt == 8) A[1][2] <= A_div[6];
end
always @(posedge cg_clk_sa_4x4[6] ) begin
	if(current_state == IDLE) A[1][3] <= 0;
	else if(current_state == STORE_V && (in_cnt < 8)) A[1][3] <= A_sum[7];
	else if(current_state == STORE_V && in_cnt == 8) A[1][3] <= A_div[7];
end




always @(posedge cg_clk_sa_4x4[7] ) begin
	if(current_state == IDLE) A[2][0] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 8) && (in_cnt < 16)) A[2][0] <= A_sum[0];
	else if(current_state == STORE_V && in_cnt == 16) A[2][0] <= A_div[0];
end
always @(posedge cg_clk_sa_4x4[8] ) begin
	if(current_state == IDLE) A[2][1] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 8) && (in_cnt < 16)) A[2][1] <= A_sum[1];
	else if(current_state == STORE_V && in_cnt == 16) A[2][1] <= A_div[1];
end
always @(posedge cg_clk_sa_4x4[9] ) begin
	if(current_state == IDLE) A[2][2] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 8) && (in_cnt < 16)) A[2][2] <= A_sum[2];
	else if(current_state == STORE_V && in_cnt == 16) A[2][2] <= A_div[2];
end
always @(posedge cg_clk_sa_4x4[10] ) begin
	if(current_state == IDLE) A[2][3] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 8) && (in_cnt < 16)) A[2][3] <= A_sum[3];
	else if(current_state == STORE_V && in_cnt == 16) A[2][3] <= A_div[3];
end
always @(posedge cg_clk_sa_4x4[11] ) begin
	if(current_state == IDLE) A[3][0] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 8) && (in_cnt < 16)) A[3][0] <= A_sum[4];
	else if(current_state == STORE_V && in_cnt == 16) A[3][0] <= A_div[4];
end
always @(posedge cg_clk_sa_4x4[12] ) begin
	if(current_state == IDLE) A[3][1] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 8) && (in_cnt < 16)) A[3][1] <= A_sum[5];
	else if(current_state == STORE_V && in_cnt == 16) A[3][1] <= A_div[5];
end
always @(posedge cg_clk_sa_4x4[13] ) begin
	if(current_state == IDLE) A[3][2] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 8) && (in_cnt < 16)) A[3][2] <= A_sum[6];
	else if(current_state == STORE_V && in_cnt == 16) A[3][2] <= A_div[6];
end
always @(posedge cg_clk_sa_4x4[14] ) begin
	if(current_state == IDLE) A[3][3] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 8) && (in_cnt < 16)) A[3][3] <= A_sum[7];
	else if(current_state == STORE_V && in_cnt == 16) A[3][3] <= A_div[7];
end

//==============================================//
//                     8x8                      //
//==============================================//

always @(posedge cg_clk_sa_8x8[0] ) begin
	if(current_state == IDLE) A[0][4] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 16) && (in_cnt < 24)) A[0][4] <= A_sum[0];
	else if(current_state == STORE_V && in_cnt == 24) A[0][4] <= A_div[0];
end
always @(posedge cg_clk_sa_8x8[1] ) begin
	if(current_state == IDLE) A[0][5] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 16) && (in_cnt < 24)) A[0][5] <= A_sum[1];
	else if(current_state == STORE_V && in_cnt == 24) A[0][5] <= A_div[1];
end
always @(posedge cg_clk_sa_8x8[2] ) begin
	if(current_state == IDLE) A[0][6] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 16) && (in_cnt < 24)) A[0][6] <= A_sum[2];
	else if(current_state == STORE_V && in_cnt == 24) A[0][6] <= A_div[2];
end
always @(posedge cg_clk_sa_8x8[3] ) begin
	if(current_state == IDLE) A[0][7] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 16) && (in_cnt < 24)) A[0][7] <= A_sum[3];
	else if(current_state == STORE_V && in_cnt == 24) A[0][7] <= A_div[3];
end
always @(posedge cg_clk_sa_8x8[4] ) begin
	if(current_state == IDLE) A[1][4] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 16) && (in_cnt < 24)) A[1][4] <= A_sum[4];
	else if(current_state == STORE_V && in_cnt == 24) A[1][4] <= A_div[4];
end
always @(posedge cg_clk_sa_8x8[5] ) begin
	if(current_state == IDLE) A[1][5] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 16) && (in_cnt < 24)) A[1][5] <= A_sum[5];
	else if(current_state == STORE_V && in_cnt == 24) A[1][5] <= A_div[5];
end
always @(posedge cg_clk_sa_8x8[6] ) begin
	if(current_state == IDLE) A[1][6] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 16) && (in_cnt < 24)) A[1][6] <= A_sum[6];
	else if(current_state == STORE_V && in_cnt == 24) A[1][6] <= A_div[6];
end
always @(posedge cg_clk_sa_8x8[7] ) begin
	if(current_state == IDLE) A[1][7] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 16) && (in_cnt < 24)) A[1][7] <= A_sum[7];
	else if(current_state == STORE_V && in_cnt == 24) A[1][7] <= A_div[7];
end




always @(posedge cg_clk_sa_8x8[8] ) begin
	if(current_state == IDLE) A[2][4] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 24) && (in_cnt < 32)) A[2][4] <= A_sum[0];
	else if(current_state == STORE_V && in_cnt == 32) A[2][4] <= A_div[0];
end
always @(posedge cg_clk_sa_8x8[9] ) begin
	if(current_state == IDLE) A[2][5] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 24) && (in_cnt < 32)) A[2][5] <= A_sum[1];
	else if(current_state == STORE_V && in_cnt == 32) A[2][5] <= A_div[1];
end
always @(posedge cg_clk_sa_8x8[10] ) begin
	if(current_state == IDLE) A[2][6] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 24) && (in_cnt < 32)) A[2][6] <= A_sum[2];
	else if(current_state == STORE_V && in_cnt == 32) A[2][6] <= A_div[2];
end
always @(posedge cg_clk_sa_8x8[11] ) begin
	if(current_state == IDLE) A[2][7] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 24) && (in_cnt < 32)) A[2][7] <= A_sum[3];
	else if(current_state == STORE_V && in_cnt == 32) A[2][7] <= A_div[3];
end
always @(posedge cg_clk_sa_8x8[12] ) begin
	if(current_state == IDLE) A[3][4] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 24) && (in_cnt < 32)) A[3][4] <= A_sum[4];
	else if(current_state == STORE_V && in_cnt == 32) A[3][4] <= A_div[4];
end
always @(posedge clk ) begin
	if(current_state == IDLE) A[3][5] <= A_sum[5];
	else if(current_state == STORE_V && (in_cnt >= 24) && (in_cnt < 32)) A[3][5] <= A_sum[5];
	else if(current_state == STORE_V && in_cnt == 32) A[3][5] <= A_div[5];
end
always @(posedge cg_clk_sa_8x8[14] ) begin
	if(current_state == IDLE) A[3][6] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 24) && (in_cnt < 32)) A[3][6] <= A_sum[6];
	else if(current_state == STORE_V && in_cnt == 32) A[3][6] <= A_div[6];
end
always @(posedge cg_clk_sa_8x8[15] ) begin
	if(current_state == IDLE) A[3][7] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 24) && (in_cnt < 32)) A[3][7] <= A_sum[7];
	else if(current_state == STORE_V && in_cnt == 32) A[3][7] <= A_div[7];
end






always @(posedge cg_clk_sa_8x8[16] ) begin
	if(current_state == IDLE) A[4][0] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 32) && (in_cnt < 40)) A[4][0] <= A_sum[0];
	else if(current_state == STORE_V && in_cnt == 40) A[4][0] <= A_div[0];
end
always @(posedge cg_clk_sa_8x8[17] ) begin
	if(current_state == IDLE) A[4][1] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 32) && (in_cnt < 40)) A[4][1] <= A_sum[1];
	else if(current_state == STORE_V && in_cnt == 40) A[4][1] <= A_div[1];
end
always @(posedge cg_clk_sa_8x8[18] ) begin
	if(current_state == IDLE) A[4][2] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 32) && (in_cnt < 40)) A[4][2] <= A_sum[2];
	else if(current_state == STORE_V && in_cnt == 40) A[4][2] <= A_div[2];
end
always @(posedge cg_clk_sa_8x8[19] ) begin
	if(current_state == IDLE) A[4][3] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 32) && (in_cnt < 40)) A[4][3] <= A_sum[3];
	else if(current_state == STORE_V && in_cnt == 40) A[4][3] <= A_div[3];
end
always @(posedge cg_clk_sa_8x8[20] ) begin
	if(current_state == IDLE) A[4][4] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 32) && (in_cnt < 40)) A[4][4] <= A_sum[4];
	else if(current_state == STORE_V && in_cnt == 40) A[4][4] <= A_div[4];
end
always @(posedge cg_clk_sa_8x8[21] ) begin
	if(current_state == IDLE) A[4][5] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 32) && (in_cnt < 40)) A[4][5] <= A_sum[5];
	else if(current_state == STORE_V && in_cnt == 40) A[4][5] <= A_div[5];
end
always @(posedge cg_clk_sa_8x8[22] ) begin
	if(current_state == IDLE) A[4][6] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 32) && (in_cnt < 40)) A[4][6] <= A_sum[6];
	else if(current_state == STORE_V && in_cnt == 40) A[4][6] <= A_div[6];
end
always @(posedge cg_clk_sa_8x8[23] ) begin
	if(current_state == IDLE) A[4][7] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 32) && (in_cnt < 40)) A[4][7] <= A_sum[7];
	else if(current_state == STORE_V && in_cnt == 40) A[4][7] <= A_div[7];
end




always @(posedge cg_clk_sa_8x8[24] ) begin
	if(current_state == IDLE) A[5][0] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 40) && (in_cnt < 48)) A[5][0] <= A_sum[0];
	else if(current_state == STORE_V && in_cnt == 48) A[5][0] <= A_div[0];
end
always @(posedge cg_clk_sa_8x8[25] ) begin
	if(current_state == IDLE) A[5][1] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 40) && (in_cnt < 48)) A[5][1] <= A_sum[1];
	else if(current_state == STORE_V && in_cnt == 48) A[5][1] <= A_div[1];
end
always @(posedge cg_clk_sa_8x8[26] ) begin
	if(current_state == IDLE) A[5][2] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 40) && (in_cnt < 48)) A[5][2] <= A_sum[2];
	else if(current_state == STORE_V && in_cnt == 48) A[5][2] <= A_div[2];
end
always @(posedge cg_clk_sa_8x8[27] ) begin
	if(current_state == IDLE) A[5][3] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 40) && (in_cnt < 48)) A[5][3] <= A_sum[3];
	else if(current_state == STORE_V && in_cnt == 48) A[5][3] <= A_div[3];
end
always @(posedge cg_clk_sa_8x8[28] ) begin
	if(current_state == IDLE) A[5][4] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 40) && (in_cnt < 48)) A[5][4] <= A_sum[4];
	else if(current_state == STORE_V && in_cnt == 48) A[5][4] <= A_div[4];
end
always @(posedge cg_clk_sa_8x8[29] ) begin
	if(current_state == IDLE) A[5][5] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 40) && (in_cnt < 48)) A[5][5] <= A_sum[5];
	else if(current_state == STORE_V && in_cnt == 48) A[5][5] <= A_div[5];
end
always @(posedge cg_clk_sa_8x8[30] ) begin
	if(current_state == IDLE) A[5][6] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 40) && (in_cnt < 48)) A[5][6] <= A_sum[6];
	else if(current_state == STORE_V && in_cnt == 48) A[5][6] <= A_div[6];
end
always @(posedge cg_clk_sa_8x8[31] ) begin
	if(current_state == IDLE) A[5][7] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 40) && (in_cnt < 48)) A[5][7] <= A_sum[7];
	else if(current_state == STORE_V && in_cnt == 48) A[5][7] <= A_div[7];
end



always @(posedge cg_clk_sa_8x8[32] ) begin
	if(current_state == IDLE) A[6][0] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 48) && (in_cnt < 56)) A[6][0] <= A_sum[0];
	else if(current_state == STORE_V && in_cnt == 56) A[6][0] <= A_div[0];
end
always @(posedge cg_clk_sa_8x8[33] ) begin
	if(current_state == IDLE) A[6][1] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 48) && (in_cnt < 56)) A[6][1] <= A_sum[1];
	else if(current_state == STORE_V && in_cnt == 56) A[6][1] <= A_div[1];
end
always @(posedge cg_clk_sa_8x8[34] ) begin
	if(current_state == IDLE) A[6][2] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 48) && (in_cnt < 56)) A[6][2] <= A_sum[2];
	else if(current_state == STORE_V && in_cnt == 56) A[6][2] <= A_div[2];
end
always @(posedge cg_clk_sa_8x8[35] ) begin
	if(current_state == IDLE) A[6][3] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 48) && (in_cnt < 56)) A[6][3] <= A_sum[3];
	else if(current_state == STORE_V && in_cnt == 56) A[6][3] <= A_div[3];
end
always @(posedge cg_clk_sa_8x8[36] ) begin
	if(current_state == IDLE) A[6][4] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 48) && (in_cnt < 56)) A[6][4] <= A_sum[4];
	else if(current_state == STORE_V && in_cnt == 56) A[6][4] <= A_div[4];
end
always @(posedge cg_clk_sa_8x8[37] ) begin
	if(current_state == IDLE) A[6][5] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 48) && (in_cnt < 56)) A[6][5] <= A_sum[5];
	else if(current_state == STORE_V && in_cnt == 56) A[6][5] <= A_div[5];
end
always @(posedge cg_clk_sa_8x8[38] ) begin
	if(current_state == IDLE) A[6][6] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 48) && (in_cnt < 56)) A[6][6] <= A_sum[6];
	else if(current_state == STORE_V && in_cnt == 56) A[6][6] <= A_div[6];
end
always @(posedge cg_clk_sa_8x8[39] ) begin
	if(current_state == IDLE) A[6][7] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 48) && (in_cnt < 56)) A[6][7] <= A_sum[7];
	else if(current_state == STORE_V && in_cnt == 56) A[6][7] <= A_div[7];
end



always @(posedge cg_clk_sa_8x8[40] ) begin
	if(current_state == IDLE) A[7][0] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 56) && (in_cnt < 64)) A[7][0] <= A_sum[0];
	else if(current_state == MM2 && out_cnt == 1) A[7][0] <= A_div[0];
end
always @(posedge cg_clk_sa_8x8[41] ) begin
	if(current_state == IDLE) A[7][1] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 56) && (in_cnt < 64)) A[7][1] <= A_sum[1];
	else if(current_state == MM2 && out_cnt == 1) A[7][1] <= A_div[1];
end
always @(posedge cg_clk_sa_8x8[42] ) begin
	if(current_state == IDLE) A[7][2] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 56) && (in_cnt < 64)) A[7][2] <= A_sum[2];
	else if(current_state == MM2 && out_cnt == 1) A[7][2] <= A_div[2];
end
always @(posedge cg_clk_sa_8x8[43] ) begin
	if(current_state == IDLE) A[7][3] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 56) && (in_cnt < 64)) A[7][3] <= A_sum[3];
	else if(current_state == MM2 && out_cnt == 1) A[7][3] <= A_div[3];
end
always @(posedge cg_clk_sa_8x8[44] ) begin
	if(current_state == IDLE) A[7][4] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 56) && (in_cnt < 64)) A[7][4] <= A_sum[4];
	else if(current_state == MM2 && out_cnt == 1) A[7][4] <= A_div[4];
end
always @(posedge cg_clk_sa_8x8[45] ) begin
	if(current_state == IDLE) A[7][5] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 56) && (in_cnt < 64)) A[7][5] <= A_sum[5];
	else if(current_state == MM2 && out_cnt == 1) A[7][5] <= A_div[5];
end
always @(posedge cg_clk_sa_8x8[46] ) begin
	if(current_state == IDLE) A[7][6] <= 0;
	else if(current_state == STORE_V && (in_cnt >= 56) && (in_cnt < 64)) A[7][6] <= A_sum[6];
	else if(current_state == MM2 && out_cnt == 1) A[7][6] <= A_div[6];
end
always @(posedge cg_clk_sa_8x8[47] ) begin
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
