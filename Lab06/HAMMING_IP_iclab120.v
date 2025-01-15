//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2024/10
//		Version		: v1.0
//   	File Name   : HAMMING_IP.v
//   	Module Name : HAMMING_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
module HAMMING_IP #(parameter IP_BIT = 8) (
    // Input signals
    IN_code,
    // Output signals
    OUT_code
);

// ===============================================================
// Input & Output
// ===============================================================
input [IP_BIT+4-1:0] IN_code;

output reg [IP_BIT-1:0] OUT_code;

// ===============================================================
// Parameter
// ===============================================================
integer i;

// ===============================================================
// Reg & Wires
// ===============================================================

//reg [3:0] parity_check; // Holds the results of parity checks
reg [IP_BIT + 4 - 1:0] corrected_code;
wire signal_1_5, signal_1_6, signal_1_7, signal_1_8, signal_2_5, signal_2_6, signal_2_7, signal_2_8, signal_3_4, signal_3_5, signal_3_6, signal_3_7, signal_3_8, signal_4_2, signal_4_3, signal_4_4, signal_4_5, signal_4_6, signal_4_7, signal_4_8;
reg hamming_1, hamming_2, hamming_3, hamming_4;
wire [3:0] hamming_num;

// ===============================================================
// Design
// ===============================================================

// ===============================================================
// Parity Calculation
// ===============================================================

assign signal_1_5 = IN_code[IP_BIT + 3] ^ IN_code[IP_BIT + 1] ^ IN_code[IP_BIT - 1] ^ IN_code[IP_BIT - 3] ^ IN_code[IP_BIT - 5];
assign signal_1_6 = signal_1_5 ^ IN_code[IP_BIT - 7];
assign signal_1_7 = signal_1_6 ^ IN_code[IP_BIT - 9];
assign signal_1_8 = signal_1_7 ^ IN_code[IP_BIT - 11];
assign signal_2_4 = IN_code[IP_BIT + 2] ^ IN_code[IP_BIT + 1] ^ IN_code[IP_BIT - 2] ^ IN_code[IP_BIT - 3];
assign signal_2_5 = signal_2_4 ^ IN_code[IP_BIT - 6];
assign signal_2_6 = signal_2_5 ^ IN_code[IP_BIT - 7];
assign signal_2_7 = signal_2_6 ^ IN_code[IP_BIT - 10];
assign signal_2_8 = signal_2_7 ^ IN_code[IP_BIT - 11];
assign signal_3_4 = IN_code[IP_BIT] ^ IN_code[IP_BIT - 1] ^ IN_code[IP_BIT - 2] ^ IN_code[IP_BIT - 3];
assign signal_3_5 = signal_3_4 ^ IN_code[IP_BIT - 8];
assign signal_3_6 = signal_3_5 ^ IN_code[IP_BIT - 9];
assign signal_3_7 = signal_3_6 ^ IN_code[IP_BIT - 10];
assign signal_3_8 = signal_3_7 ^ IN_code[IP_BIT - 11];
assign signal_4_2 = IN_code[IP_BIT - 4] ^ IN_code[IP_BIT - 5];
assign signal_4_3 = signal_4_2 ^ IN_code[IP_BIT - 6];
assign signal_4_4 = signal_4_3 ^ IN_code[IP_BIT - 7];
assign signal_4_5 = signal_4_4 ^ IN_code[IP_BIT - 8];
assign signal_4_6 = signal_4_5 ^ IN_code[IP_BIT - 9];
assign signal_4_7 = signal_4_6 ^ IN_code[IP_BIT - 10];
assign signal_4_8 = signal_4_7 ^ IN_code[IP_BIT - 11];




always @(*) begin
    case(IP_BIT)
        5: hamming_1 = signal_4_2;
        6: hamming_1 = signal_4_3;
        7: hamming_1 = signal_4_4;
        8: hamming_1 = signal_4_5;
        9: hamming_1 = signal_4_6;
        10: hamming_1 = signal_4_7;
        11: hamming_1 = signal_4_8;
        default: hamming_1 = signal_4_2;
    endcase
end
always @(*) begin
    case(IP_BIT)
        5, 6, 7: hamming_2 = signal_3_4;
        8: hamming_2 = signal_3_5;
        9: hamming_2 = signal_3_6;
        10: hamming_2 = signal_3_7;
        11: hamming_2 = signal_3_8;
        default: hamming_2 = signal_3_4;
    endcase
end
always @(*) begin
    case(IP_BIT)
        5: hamming_3 = signal_2_4;
        6: hamming_3 = signal_2_5;
        7, 8, 9: hamming_3 = signal_2_6;
        10: hamming_3 = signal_2_7;
        11: hamming_3 = signal_2_8;
        default: hamming_3 = signal_2_6;
    endcase
end
always @(*) begin
    case(IP_BIT)
        5, 6: hamming_4 = signal_1_5;
        7, 8: hamming_4 = signal_1_6;
        9, 10: hamming_4 = signal_1_7;
        11: hamming_4 = signal_1_8;
        default: hamming_4 = signal_1_5;
    endcase
end
assign hamming_num = {hamming_1,hamming_2,hamming_3,hamming_4};

// ===============================================================
// Correct the wrong bit
// ===============================================================

always @(*) begin
    for(i = 1; i <= IP_BIT + 4; i  = i + 1) begin
        corrected_code[(IP_BIT + 4 - i)] = (i == hamming_num) ? ~IN_code[(IP_BIT + 4 - i)] : IN_code[(IP_BIT + 4 - i)];
    end
end

always @(*) begin
    OUT_code[IP_BIT - 1] = corrected_code[IP_BIT + 1];
    OUT_code[IP_BIT - 2] = corrected_code[IP_BIT - 1];
    OUT_code[IP_BIT - 3] = corrected_code[IP_BIT - 2];
    OUT_code[IP_BIT - 4] = corrected_code[IP_BIT - 3];
    OUT_code[IP_BIT - 5] = corrected_code[IP_BIT - 5];
    OUT_code[IP_BIT - 6] = corrected_code[IP_BIT - 6];
    OUT_code[IP_BIT - 7] = corrected_code[IP_BIT - 7];
    OUT_code[IP_BIT - 8] = corrected_code[IP_BIT - 8];
    OUT_code[IP_BIT - 9] = corrected_code[IP_BIT - 9];
    OUT_code[IP_BIT - 10] = corrected_code[IP_BIT - 10];
    OUT_code[IP_BIT - 11] = corrected_code[IP_BIT - 11];
end



endmodule
