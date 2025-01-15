//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2024/9
//		Version		: v1.0
//   	File Name   : MDC.v
//   	Module Name : MDC
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

//synopsys translate_off
`include "HAMMING_IP.v"
//synopsys translate_on

module MDC(
    // Input signals
    clk,
	rst_n,
	in_valid,
    in_data, 
	in_mode,
    // Output signals
    out_valid, 
	out_data
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid;
input [8:0] in_mode;
input [14:0] in_data;

output reg out_valid;
output reg [206:0] out_data;

// ===============================================================
// Parameter
// ===============================================================

parameter IN_DATA_BIT = 11;
parameter IN_MODE_BIT = 5;

// ===============================================================
// Reg & Wires
// ===============================================================

wire [4:0] mode;
wire signed [10:0] indata;
reg [4:0] mode_reg;
reg [4:0] cnt;
reg signed [10:0] a,b,c,d,e,f,g,h,i;
reg signed [22:0] af_be, bg_cf, ch_dg, ej_fi, fk_gj ,gl_hk, jo_kn;
wire signed [22:0] kp_lo, in_jm;
reg signed [22:0] ag_ce, bh_df, ah_de, ek_gi, fl_hj;
reg signed [10:0] multiplicand_1, multiplicand_2, multiplicand_3, multiplicand_4, multiplicand_5, multiplier_1, multiplier_2;
reg signed [22:0] multiplier_3, multiplier_4, multiplier_5;
wire signed [10:0] multiplicand_6, multiplicand_7;
wire signed [35:0] multiplier_6, multiplier_7;
reg signed [35:0] summand1;
reg signed [35:0] ibg_jag_kaf, jch_kbh_lbg, ich_kah_lag, ibh_jah_laf, mfk_nek_oej; //4x4
reg signed [35:0] jch_kbh, ibh_jah, ich_kah, ibg_jag, mfk_nek, ngl_ofl;
wire signed [35:0] ngl_ofl_pfk;
wire signed [22:0] mm12;
wire signed [35:0] mm34;
wire signed [35:0] smm5;
wire signed [47:0] mm67;
wire signed [47:0] det_4x4;
reg signed [47:0] mn;

// ===============================================================
// IP
// ===============================================================
HAMMING_IP #(IN_DATA_BIT) 
    IN_DECODE(.IN_code(in_data),.OUT_code(indata));

HAMMING_IP #(IN_MODE_BIT) 
    MODE_DECODE(.IN_code(in_mode),.OUT_code(mode));


// ===============================================================
// Design
// ===============================================================

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) mode_reg <= 0;
    else if(in_valid && (cnt == 0)) mode_reg <= mode;
end


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) out_data <= 0;
    else if(cnt == 16) begin
        if(mode_reg[4]) out_data <= {{159{det_4x4[47]}}, det_4x4};
        else if(mode_reg[1]) out_data <= {3'b0, {{15{ibg_jag_kaf[35]}},ibg_jag_kaf}, {{15{jch_kbh_lbg[35]}},jch_kbh_lbg}, {{15{mfk_nek_oej[35]}},mfk_nek_oej}, {{15{ngl_ofl_pfk[35]}},ngl_ofl_pfk}};//i(bg-cf) - j(ag-ce) + k(af-be)  j(ch-dg) - k(bh-df) + l(bg-cf)  m(fk-gj) - n(ek-gi) + o(ej-fi)  n(gl-hk) - o(fl-hj) + p(fk-gj)
        else out_data <= {af_be, bg_cf, ch_dg, ej_fi, fk_gj, gl_hk, in_jm, jo_kn, kp_lo};  //af-be bg-cf ch-dg ej-fi fk-gj gl-hk in-jm jo-kn kp-lo
    end
    else begin
        out_data <= 0;
    end
end

always @(posedge clk) begin
    if(in_valid) cnt <= cnt + 1;
    else cnt <= 0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) out_valid <= 0;
    else if(cnt == 16) out_valid <= 1;
    else out_valid <= 0;
end



always @(posedge clk) begin
    if(in_valid && (cnt == 0 || cnt == 9)) a <= indata; //a j || cnt == 9
end
always @(posedge clk) begin
    if(in_valid && (cnt == 1 || cnt == 10)) b <= indata; //b k
end
always @(posedge clk) begin
    if(in_valid && (cnt == 2 || cnt == 11)) c <= indata; //c l
end
always @(posedge clk) begin
    if(in_valid && (cnt == 3 || cnt == 12)) d <= indata; //d m
end
always @(posedge clk) begin
    if(in_valid && (cnt == 4 || cnt == 13)) e <= indata; //e n
end
always @(posedge clk) begin
    if(in_valid && (cnt == 5 || cnt == 14)) f <= indata; //f o
end
always @(posedge clk) begin
    if(in_valid && (cnt == 6 || cnt == 15)) g <= indata; //g p
end
always @(posedge clk) begin
    if(in_valid && cnt == 7) h <= indata;
end
always @(posedge clk) begin
    if(in_valid && cnt == 8) i <= indata;
end


always @(*) begin
    case(cnt)
        8: multiplicand_1 = c;
        10: multiplicand_1 = e;
        11: multiplicand_1 = f;
        12: multiplicand_1 = e;
        13: multiplicand_1 = f;
        14: multiplicand_1 = g;
        16: multiplicand_1 = i;
        default: multiplicand_1 = a;
    endcase
end
always @(*) begin
    case(cnt)
        6: multiplier_1 = f;
        7: multiplier_1 = g;
        8: multiplier_1 = h;
        10: multiplier_1 = a;
        13: multiplier_1 = c;
        14: multiplier_1 = c;
        15: multiplier_1 = f;
        16: multiplier_1 = e;
        default: multiplier_1 = b;
    endcase
end
always @(*) begin
    case(cnt)
        6: multiplicand_2 = b;
        7: multiplicand_2 = c;
        8: multiplicand_2 = d;
        10: multiplicand_2 = f;
        13: multiplicand_2 = h;
        14: multiplicand_2 = h;
        15: multiplicand_2 = b;
        16: multiplicand_2 = a;
        default: multiplicand_2 = g;
    endcase
end
always @(*) begin
    case(cnt)
        8: multiplier_2 = g;
        10: multiplier_2 = i;
        11: multiplier_2 = a;
        12: multiplier_2 = i;
        13: multiplier_2 = a;
        14: multiplier_2 = b;
        16: multiplier_2 = d;
        default: multiplier_2 = e;
    endcase
end

assign mm12 = multiplicand_1 * multiplier_1 - multiplicand_2 * multiplier_2;

always @(posedge clk) begin
    if(in_valid && cnt == 6) af_be <= mm12;
end
always @(posedge clk) begin
    if(in_valid && cnt == 7) ag_ce <= mm12;
end
always @(posedge clk) begin
    if(in_valid && cnt == 8) ch_dg <= mm12;
end
always @(posedge clk) begin
    if(in_valid && cnt == 10) ej_fi <= mm12;
end
always @(posedge clk) begin
    if(in_valid && cnt == 11) fk_gj <= mm12;
end
always @(posedge clk) begin
    if(in_valid && cnt == 12) ek_gi <= mm12;
end
always @(posedge clk) begin
    if(in_valid && cnt == 13) fl_hj <= mm12;
end
always @(posedge clk) begin
    if(in_valid && cnt == 14) gl_hk <= mm12;
end
always @(posedge clk) begin
    if(in_valid && cnt == 15) jo_kn <= mm12;
end

assign  in_jm = (cnt == 16) ? mm12 : 0;




always @(*) begin
    case(cnt)
        8: multiplicand_3 = a;
        10: multiplicand_3 = i;
        11: multiplicand_3 = a;
        12: multiplicand_3 = i;
        13: multiplicand_3 = i;
        14: multiplicand_3 = d;
        15: multiplicand_3 = e;
        default: multiplicand_3 = b;
    endcase
end
always @(*) begin
    case(cnt)
        7: multiplier_3 = g;
        10: multiplier_3 = bg_cf;
        11: multiplier_3 = ch_dg;
        12: multiplier_3 = ch_dg;
        13: multiplier_3 = bh_df;
        14: multiplier_3 = fk_gj;
        15: multiplier_3 = gl_hk;
        16: multiplier_3 = g;
        default: multiplier_3 = h;
    endcase
end
always @(*) begin
    case(cnt)
        7: multiplicand_4 = c;
        8: multiplicand_4 = d;
        9: multiplicand_4 = d;
        10: multiplicand_4 = a;
        13: multiplicand_4 = a;
        14: multiplicand_4 = e;
        15: multiplicand_4 = f;
        16: multiplicand_4 = c;
        default: multiplicand_4 = b;
    endcase
end
always @(*) begin
    case(cnt)
        8: multiplier_4 = e;
        10: multiplier_4 = ag_ce;
        11: multiplier_4 = bh_df;
        12: multiplier_4 = ah_de;
        13: multiplier_4 = ah_de;
        14: multiplier_4 = ek_gi;
        15: multiplier_4 = fl_hj;
        default: multiplier_4 = f;
    endcase
end

assign mm34 = multiplier_3 * multiplicand_3 - multiplier_4 * multiplicand_4;

always @(posedge clk) begin
    if(in_valid && cnt == 7) bg_cf <= mm34;
end
always @(posedge clk) begin
    if(in_valid && cnt == 8) ah_de <= mm34;
end
always @(posedge clk) begin
    if(in_valid && cnt == 9) bh_df <= mm34;
end
always @(posedge clk) begin
    if(in_valid && cnt == 10) ibg_jag <= mm34;
end
always @(posedge clk) begin
    if(in_valid && cnt == 11) jch_kbh <= mm34;
end
always @(posedge clk) begin
    if(in_valid && cnt == 12) ich_kah <= mm34;
end
always @(posedge clk) begin
    if(in_valid && cnt == 13) ibh_jah <= mm34;
end
always @(posedge clk) begin
    if(in_valid && cnt == 14) mfk_nek <= mm34;
end
always @(posedge clk) begin
    if(in_valid && cnt == 15) ngl_ofl <= mm34;
end
assign  kp_lo = (cnt == 16) ? mm34 : 0;







always @(*) begin
    case(cnt)
        11: summand1 = ibg_jag;
        12: summand1 = jch_kbh;
        13: summand1 = ich_kah;
        14: summand1 = ibh_jah;
        15: summand1 = mfk_nek;
        16: summand1 = ngl_ofl;
        default: summand1 = 0;
    endcase
end
always @(*) begin
    case(cnt)
        11: multiplicand_5 = b;
        15: multiplicand_5 = f;
        16: multiplicand_5 = g;
        default: multiplicand_5 = c;
    endcase
end
always @(*) begin
    case(cnt)
        11: multiplier_5 = af_be;
        12: multiplier_5 = bg_cf;
        13: multiplier_5 = ag_ce;
        14: multiplier_5 = af_be;
        15: multiplier_5 = ej_fi;
        16: multiplier_5 = fk_gj;
        default: multiplier_5 = 0;
    endcase
end

assign smm5 = summand1 + multiplier_5 * multiplicand_5;

always @(posedge clk) begin
    if(in_valid && cnt == 11) ibg_jag_kaf <= smm5;
end
always @(posedge clk) begin
    if(in_valid && cnt == 12) jch_kbh_lbg <= smm5;
end
always @(posedge clk) begin
    if(in_valid && cnt == 13) ich_kah_lag <= smm5;
end
always @(posedge clk) begin
    if(in_valid && cnt == 14) ibh_jah_laf <= smm5;
end
always @(posedge clk) begin
    if(in_valid && cnt == 15) mfk_nek_oej <= smm5;
end

assign ngl_ofl_pfk = (cnt == 16) ? smm5 : 0;

assign multiplicand_6 = (cnt == 16) ? g : e;
assign multiplier_6 = (cnt == 16) ? ibg_jag_kaf : ich_kah_lag;
assign multiplicand_7 = (cnt == 16) ? f : d;
assign multiplier_7 = (cnt == 16) ? ibh_jah_laf : jch_kbh_lbg;


assign mm67 =  multiplier_6 * multiplicand_6 - multiplier_7 * multiplicand_7;

always @(posedge clk) begin
    if(cnt == 14) mn <= mm67;
end

assign  det_4x4 = (cnt == 16) ? (mn + mm67) : 0;

endmodule

/* module determinant_2x2 (         //////// a  b  c  d  
    input signed [10:0] a,          //////// e  f  g  h   
    input signed [10:0] b,          //////// i  j  k  l
    input signed [10:0] c,          //////// m  n  o  p 
    input signed [10:0] d,
    output signed [31:0] det
);
    
    assign det = (a * d) - (b * c);
    
    
    //af-be bg-cf ch-dg ej-fi fk-gj gl-hk in-jm jo-kn kp-lo   9



endmodule

module determinant_3x3 (            //////// a  b  c  d
    input signed [10:0] a,          //////// e  f  g  h
    input signed [10:0] b,          //////// i  j  k  l
    input signed [10:0] c,          //////// m  n  o  p
    input signed [10:0] d,
    input signed [10:0] e,
    input signed [10:0] f,
    input signed [10:0] g,
    input signed [10:0] h,
    input signed [10:0] i,
    output signed [40:0] det
);

    assign det = a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g);



    ////i(bg-cf) - j(ag-ce) + k(af-be)
    ////j(ch-dg) - k(bh-df) + l(bg-cf)
    //m(fk-gj) - n(ek-gi)/cnt11 + o(ej-fi)
    //n(gl-hk) - o(fl-hj)/cnt12 + p(fk-gj)

endmodule

module determinant_4x4 (
    input signed [10:0] a, input signed [10:0] b, input signed [10:0] c, input signed [10:0] d,  //////// a  b  c  d
    input signed [10:0] e, input signed [10:0] f, input signed [10:0] g, input signed [10:0] h,  //////// e  f  g  h
    input signed [10:0] i, input signed [10:0] j, input signed [10:0] k, input signed [10:0] l,  //////// i  j  k  l
    input signed [10:0] m, input signed [10:0] n, input signed [10:0] o, input signed [10:0] p,  //////// m  n  o  p
    output signed [206:0] det
);
        
    assign det = -m * (j * (c * h - d * g) - k * (b * h - d * f) + l * (b * g - c * f))
        + n * (i * (c * h - d * g) - k * (a * h - d * e) + l * (a * g - c * e))
        - o * (i * (b * h - d * f) - j * (a * h - d * e) + l * (a * f - b * e))
        + p * (i * (b * g - c * f) - j * (a * g - c * e) + k * (a * f - b * e));

        //1 

endmodule */