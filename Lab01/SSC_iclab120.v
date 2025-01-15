//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2024 Fall
//   Lab01 Exercise		: Snack Shopping Calculator
//   Author     		  : Yu-Hsiang Wang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : SSC.v
//   Module Name : SSC
//   Release version : V1.0 (Release Date: 2024-09)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module SSC(
    // Input signals
    card_num,
    input_money,
    snack_num,
    price, 
    // Output signals
    out_valid,
    out_change
);

//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
input [63:0] card_num;
input [8:0] input_money;
input [31:0] snack_num;
input [31:0] price;
output reg out_valid;
output reg [8:0] out_change;    

//================================================================
//    Wire & Registers 
//================================================================
// Declare the wire/reg you would use in your circuit
// remember 
// wire for port connection and cont. assignment
// reg for proc. assignment


/***** card number validation *****/

reg [3:0] card_num1, card_num3, card_num5, card_num7, card_num9, card_num11, card_num13, card_num15;
wire [7:0] total_num;


/***** buy snack *****/

reg [8:0] out_change_tmp;
reg [7:0] sp[1:8];
reg [7:0] sp1[1:8], sp2[1:8], sp3[1:8];
reg [7:0] sp4[1:4], sp5[1:4]; 
reg [7:0] t[1:8];
reg [9:0] diff [0:7];
reg [7:0] tmp [0:5];








//================================================================
//    DESIGN
//================================================================



/***** card number validation *****/


always @(*) begin
    
    case(card_num[7:4])

        4'd5: card_num1 = 1;
        4'd6: card_num1 = 3;
        4'd7: card_num1 = 5;
        4'd8: card_num1 = 7;
        4'd9: card_num1 = 9;
        default: card_num1 = card_num[7:4]<<1;

    endcase

    case(card_num[15:12])

        4'd5: card_num3 = 1;
        4'd6: card_num3 = 3;
        4'd7: card_num3 = 5;
        4'd8: card_num3 = 7;
        4'd9: card_num3 = 9;
        default: card_num3 = card_num[15:12]<<1;

    endcase

    case(card_num[23:20])

        4'd5: card_num5 = 1;
        4'd6: card_num5 = 3;
        4'd7: card_num5 = 5;
        4'd8: card_num5 = 7;
        4'd9: card_num5 = 9;
        default: card_num5 = card_num[23:20]<<1;

    endcase

    case(card_num[31:28])

        4'd5: card_num7 = 1;
        4'd6: card_num7 = 3;
        4'd7: card_num7 = 5;
        4'd8: card_num7 = 7;
        4'd9: card_num7 = 9;
        default: card_num7 = card_num[31:28]<<1;

    endcase

    case(card_num[39:36])

        4'd5: card_num9 = 1;
        4'd6: card_num9 = 3;
        4'd7: card_num9 = 5;
        4'd8: card_num9 = 7;
        4'd9: card_num9 = 9;
        default: card_num9 = card_num[39:36]<<1;

    endcase

    case(card_num[47:44])

        4'd5: card_num11 = 1;
        4'd6: card_num11 = 3;
        4'd7: card_num11 = 5;
        4'd8: card_num11 = 7;
        4'd9: card_num11 = 9;
        default: card_num11 = card_num[47:44]<<1;

    endcase

    case(card_num[55:52])

        4'd5: card_num13 = 1;
        4'd6: card_num13 = 3;
        4'd7: card_num13 = 5;
        4'd8: card_num13 = 7;
        4'd9: card_num13 = 9;
        default: card_num13 = card_num[55:52]<<1;

    endcase

    case(card_num[63:60])

        4'd5: card_num15 = 1;
        4'd6: card_num15 = 3;
        4'd7: card_num15 = 5;
        4'd8: card_num15 = 7;
        4'd9: card_num15 = 9;
        default: card_num15 = card_num[63:60]<<1;

    endcase

end

assign total_num = (card_num[3:0] + card_num[11:8]) + (card_num[19:16] + card_num[27:24]) + (card_num[35:32] + card_num[43:40]) + (card_num[51:48] + card_num[59:56]) + (card_num1 + card_num3) + (card_num5 + card_num7) + (card_num9 + card_num11) + (card_num13 + card_num15);


always @(*) begin
    case(total_num)
        8'd0: out_valid = 1;
        8'd10: out_valid = 1;
        8'd20: out_valid = 1;
        8'd30: out_valid = 1;
        8'd40: out_valid = 1;
        8'd50: out_valid = 1;
        8'd60: out_valid = 1;
        8'd70: out_valid = 1;
        8'd80: out_valid = 1;
        8'd90: out_valid = 1;
        8'd100: out_valid = 1;
        8'd110: out_valid = 1;
        8'd120: out_valid = 1;
        8'd130: out_valid = 1;
        8'd140: out_valid = 1;
        default: out_valid = 0;
    endcase
end




////////////////////////////////////////////////////////////////////////////////////
//    OUTPUT                                                                      //
////////////////////////////////////////////////////////////////////////////////////

always @(*) begin
    out_change = (out_valid)? out_change_tmp : input_money ;
end

////////////////////////////////////////////////////////////////////////////////////
//    SORT                                                                        //
////////////////////////////////////////////////////////////////////////////////////


//****** layer1 ******************************************


/* MULT MU1(.a(snack_num[31:28]), .b(price[31:28]), .out(sp[1]));
MULT MU2(.a(snack_num[27:24]), .b(price[27:24]), .out(sp[2]));
MULT MU3(.a(snack_num[23:20]), .b(price[23:20]), .out(sp[3]));
MULT MU4(.a(snack_num[19:16]), .b(price[19:16]), .out(sp[4]));
MULT MU5(.a(snack_num[15:12]), .b(price[15:12]), .out(sp[5]));
MULT MU6(.a(snack_num[11:8]), .b(price[11:8]), .out(sp[6]));
MULT MU7(.a(snack_num[7:4]), .b(price[7:4]), .out(sp[7]));
MULT MU8(.a(snack_num[3:0]), .b(price[3:0]), .out(sp[8])); */


always @(*) begin
    sp[1] = snack_num[31:28]*price[31:28];
    sp[2] = snack_num[27:24]*price[27:24];
    sp[3] = snack_num[23:20]*price[23:20];
    sp[4] = snack_num[19:16]*price[19:16];
    sp[5] = snack_num[15:12]*price[15:12];
    sp[6] = snack_num[11:8]*price[11:8];
    sp[7] = snack_num[7:4]*price[7:4];
    sp[8] = snack_num[3:0]*price[3:0];
end


//****** layer2 ******************************************

always @(*) begin
    if(sp[1] > sp[2]) begin
        tmp[0] = sp[2];
        sp1[1] = sp[1];
        sp1[2] = tmp[0];
    end
    else begin
        sp1[1] = sp[2];
        sp1[2] = sp[1];
    end
    if(sp[3] > sp[4]) begin
        tmp[0] = sp[4];
        sp1[3] = sp[3];
        sp1[4] = tmp[0];
    end
    else begin
        sp1[3] = sp[4];
        sp1[4] = sp[3];
    end
    if(sp[5] > sp[6]) begin
        tmp[0] = sp[6];
        sp1[5] = sp[5];
        sp1[6] = tmp[0];
    end
    else begin
        sp1[5] = sp[6];
        sp1[6] = sp[5];
    end
    if(sp[7] > sp[8]) begin
        tmp[0] = sp[8];
        sp1[7] = sp[7];
        sp1[8] = tmp[0];
    end
    else begin
        sp1[7] = sp[8];
        sp1[8] = sp[7];
    end
end


//****** layer3 ******************************************

always @(*) begin
    if(sp1[1] > sp1[3]) begin
        tmp[1] = sp1[3];
        sp2[1] = sp1[1];
        sp2[2] = tmp[1];
    end
    else begin
        sp2[1] = sp1[3];
        sp2[2] = sp1[1];
    end
    if(sp1[2] > sp1[4]) begin
        tmp[1] = sp1[4];
        sp2[3] = sp1[2];
        sp2[4] = tmp[1];
    end
    else begin
        sp2[3] = sp1[4];
        sp2[4] = sp1[2];
    end
    if(sp1[5] > sp1[7]) begin
        tmp[1] = sp1[7];
        sp2[5] = sp1[5];
        sp2[6] = tmp[1];
    end
    else begin
        sp2[5] = sp1[7];
        sp2[6] = sp1[5];
    end
    if(sp1[6] > sp1[8]) begin
        tmp[1] = sp1[8];
        sp2[7] = sp1[6];
        sp2[8] = tmp[1];
    end
    else begin
        sp2[7] = sp1[8];
        sp2[8] = sp1[6];
    end
end

//****** layer4 ******************************************


always @(*) begin
    if(sp2[1] > sp2[5]) begin
        tmp[2] = sp2[5]; 
        sp3[1] = sp2[1];
        sp3[2] = tmp[2];
    end
    else begin
        sp3[1] = sp2[5];
        sp3[2] = sp2[1];
    end
    if(sp2[2] > sp2[3]) begin
        tmp[2] = sp2[3];
        sp3[3] = sp2[2];
        sp3[4] = tmp[2];
    end
    else begin
        sp3[3] = sp2[3];
        sp3[4] = sp2[2];
    end
    if(sp2[6] > sp2[7]) begin
        tmp[2] = sp2[7];
        sp3[5] = sp2[6];
        sp3[6] = tmp[2];
    end
    else begin
        sp3[5] = sp2[7];
        sp3[6] = sp2[6];
    end
    if(sp2[4] > sp2[8]) begin
        tmp[2] = sp2[8];
        sp3[7] = sp2[4];
        sp3[8] = tmp[2];
    end
    else begin
        sp3[7] = sp2[8];
        sp3[8] = sp2[4];
    end
end



//****** layer5 ******************************************

always @(*) begin
    if(sp3[4] > sp3[6]) begin
        tmp[3] = sp3[6];
        sp4[1] = sp3[4];
        sp4[2] = tmp[3];
    end
    else begin
        sp4[1] = sp3[6];
        sp4[2] = sp3[4];
    end
    if(sp3[3] > sp3[5]) begin
        tmp[3] = sp3[5];
        sp4[3] = sp3[3];
        sp4[4] = tmp[3];
    end
    else begin
        sp4[3] = sp3[5];
        sp4[4] = sp3[3];
    end
end


//****** layer6 ******************************************

always @(*) begin
    if(sp3[2] > sp4[1]) begin
        tmp[4] = sp4[1];
        sp5[1] = sp3[2];
        sp5[2] = tmp[4];
    end
    else begin
        sp5[1] = sp4[1];
        sp5[2] = sp3[2];
    end
    if(sp4[4] > sp3[7]) begin
        tmp[4] = sp3[7];
        sp5[3] = sp4[4];
        sp5[4] = tmp[4];
    end
    else begin
        sp5[3] = sp3[7];
        sp5[4] = sp4[4];
    end
end



//****** layer7 ******************************************

always @(*) begin
    t[1] = sp3[1];
    if(sp5[1] > sp4[3]) begin
        tmp[5] = sp4[3];
        t[2] = sp5[1];
        t[3] = tmp[5];
    end
    else begin
        t[2] = sp4[3];
        t[3]= sp5[1];
    end
    if(sp5[2] > sp5[3]) begin
        tmp[5] = sp5[3];
        t[4] = sp5[2];
        t[5] = tmp[5];
    end
    else begin
        t[4] = sp5[3];
        t[5] = sp5[2];
    end
    if(sp4[2] > sp5[4]) begin
        tmp[5] = sp5[4];
        t[6] = sp4[2];
        t[7] = tmp[5];
    end
    else begin
        t[6] = sp5[4];
        t[7] = sp4[2];
    end
    t[8] = sp3[8];
end


/////////////////////////////////////////////////////////////////////////////////////
//    CONTINUOUS MINUS                                                            //
////////////////////////////////////////////////////////////////////////////////////

always @(*) begin
    diff[0] = input_money - t[1];
    diff[1] = diff[0] - t[2];
    diff[2] = diff[1] - t[3];
    diff[3] = diff[2] - t[4];
    diff[4] = diff[3] - t[5];
    diff[5] = diff[4] - t[6];
    diff[6] = diff[5] - t[7];
    diff[7] = diff[6] - t[8];
end


always @(*) begin

    if(diff[0][9]) begin
        out_change_tmp = input_money;
    end
    else if(diff[1][9]) begin
        out_change_tmp = diff[0];
    end
    else if(diff[2][9]) begin
        out_change_tmp = diff[1];
    end
    else if(diff[3][9]) begin
        out_change_tmp = diff[2];
    end
    else if(diff[4][9]) begin
        out_change_tmp = diff[3];
    end
    else if(diff[5][9]) begin
        out_change_tmp = diff[4];
    end
    else if(diff[6][9]) begin
        out_change_tmp = diff[5];
    end
    else if(diff[7][9]) begin
        out_change_tmp = diff[6];
    end
    else begin
        out_change_tmp = diff[7];
    end

end
endmodule

/* module MULT (
    input [3:0] a,
    input [3:0] b,
    output reg [7:0] out
);
    always @(*) begin
    case({a,b})
            8'b00010001: out = 1;
            8'b00010010: out = 2;
            8'b00010011: out = 3;
            8'b00010100: out = 4;
            8'b00010101: out = 5;
            8'b00010110: out = 6;
            8'b00010111: out = 7;
            8'b00011000: out = 8;
            8'b00011001: out = 9;
            8'b00011010: out = 10;
            8'b00011011: out = 11;
            8'b00011100: out = 12;
            8'b00011101: out = 13;
            8'b00011110: out = 14;
            8'b00011111: out = 15;
            8'b00100001: out = 2;
            8'b00100010: out = 4;
            8'b00100011: out = 6;
            8'b00100100: out = 8;
            8'b00100101: out = 10;
            8'b00100110: out = 12;
            8'b00100111: out = 14;
            8'b00101000: out = 16;
            8'b00101001: out = 18;
            8'b00101010: out = 20;
            8'b00101011: out = 22;
            8'b00101100: out = 24;
            8'b00101101: out = 26;
            8'b00101110: out = 28;
            8'b00101111: out = 30;
            8'b00110001: out = 3;
            8'b00110010: out = 6;
            8'b00110011: out = 9;
            8'b00110100: out = 12;
            8'b00110101: out = 15;
            8'b00110110: out = 18;
            8'b00110111: out = 21;
            8'b00111000: out = 24;
            8'b00111001: out = 27;
            8'b00111010: out = 30;
            8'b00111011: out = 33;
            8'b00111100: out = 36;
            8'b00111101: out = 39;
            8'b00111110: out = 42;
            8'b00111111: out = 45;
            8'b01000001: out = 4;
            8'b01000010: out = 8;
            8'b01000011: out = 12;
            8'b01000100: out = 16;
            8'b01000101: out = 20;
            8'b01000110: out = 24;
            8'b01000111: out = 28;
            8'b01001000: out = 32;
            8'b01001001: out = 36;
            8'b01001010: out = 40;
            8'b01001011: out = 44;
            8'b01001100: out = 48;
            8'b01001101: out = 52;
            8'b01001110: out = 56;
            8'b01001111: out = 60;
            8'b01010001: out = 5;
            8'b01010010: out = 10;
            8'b01010011: out = 15;
            8'b01010100: out = 20;
            8'b01010101: out = 25;
            8'b01010110: out = 30;
            8'b01010111: out = 35;
            8'b01011000: out = 40;
            8'b01011001: out = 45;
            8'b01011010: out = 50;
            8'b01011011: out = 55;
            8'b01011100: out = 60;
            8'b01011101: out = 65;
            8'b01011110: out = 70;
            8'b01011111: out = 75;
            8'b01100001: out = 6;
            8'b01100010: out = 12;
            8'b01100011: out = 18;
            8'b01100100: out = 24;
            8'b01100101: out = 30;
            8'b01100110: out = 36;
            8'b01100111: out = 42;
            8'b01101000: out = 48;
            8'b01101001: out = 54;
            8'b01101010: out = 60;
            8'b01101011: out = 66;
            8'b01101100: out = 72;
            8'b01101101: out = 78;
            8'b01101110: out = 84;
            8'b01101111: out = 90;
            8'b01110001: out = 7;
            8'b01110010: out = 14;
            8'b01110011: out = 21;
            8'b01110100: out = 28;
            8'b01110101: out = 35;
            8'b01110110: out = 42;
            8'b01110111: out = 49;
            8'b01111000: out = 56;
            8'b01111001: out = 63;
            8'b01111010: out = 70;
            8'b01111011: out = 77;
            8'b01111100: out = 84;
            8'b01111101: out = 91;
            8'b01111110: out = 98;
            8'b01111111: out = 105;
            8'b10000001: out = 8;
            8'b10000010: out = 16;
            8'b10000011: out = 24;
            8'b10000100: out = 32;
            8'b10000101: out = 40;
            8'b10000110: out = 48;
            8'b10000111: out = 56;
            8'b10001000: out = 64;
            8'b10001001: out = 72;
            8'b10001010: out = 80;
            8'b10001011: out = 88;
            8'b10001100: out = 96;
            8'b10001101: out = 104;
            8'b10001110: out = 112;
            8'b10001111: out = 120;
            8'b10010001: out = 9;
            8'b10010010: out = 18;
            8'b10010011: out = 27;
            8'b10010100: out = 36;
            8'b10010101: out = 45;
            8'b10010110: out = 54;
            8'b10010111: out = 63;
            8'b10011000: out = 72;
            8'b10011001: out = 81;
            8'b10011010: out = 90;
            8'b10011011: out = 99;
            8'b10011100: out = 108;
            8'b10011101: out = 117;
            8'b10011110: out = 126;
            8'b10011111: out = 135;
            8'b10100001: out = 10;
            8'b10100010: out = 20;
            8'b10100011: out = 30;
            8'b10100100: out = 40;
            8'b10100101: out = 50;
            8'b10100110: out = 60;
            8'b10100111: out = 70;
            8'b10101000: out = 80;
            8'b10101001: out = 90;
            8'b10101010: out = 100;
            8'b10101011: out = 110;
            8'b10101100: out = 120;
            8'b10101101: out = 130;
            8'b10101110: out = 140;
            8'b10101111: out = 150;
            8'b10110001: out = 11;
            8'b10110010: out = 22;
            8'b10110011: out = 33;
            8'b10110100: out = 44;
            8'b10110101: out = 55;
            8'b10110110: out = 66;
            8'b10110111: out = 77;
            8'b10111000: out = 88;
            8'b10111001: out = 99;
            8'b10111010: out = 110;
            8'b10111011: out = 121;
            8'b10111100: out = 132;
            8'b10111101: out = 143;
            8'b10111110: out = 154;
            8'b10111111: out = 165;
            8'b11000001: out = 12;
            8'b11000010: out = 24;
            8'b11000011: out = 36;
            8'b11000100: out = 48;
            8'b11000101: out = 60;
            8'b11000110: out = 72;
            8'b11000111: out = 84;
            8'b11001000: out = 96;
            8'b11001001: out = 108;
            8'b11001010: out = 120;
            8'b11001011: out = 132;
            8'b11001100: out = 144;
            8'b11001101: out = 156;
            8'b11001110: out = 168;
            8'b11001111: out = 180;
            8'b11010001: out = 13;
            8'b11010010: out = 26;
            8'b11010011: out = 39;
            8'b11010100: out = 52;
            8'b11010101: out = 65;
            8'b11010110: out = 78;
            8'b11010111: out = 91;
            8'b11011000: out = 104;
            8'b11011001: out = 117;
            8'b11011010: out = 130;
            8'b11011011: out = 143;
            8'b11011100: out = 156;
            8'b11011101: out = 169;
            8'b11011110: out = 182;
            8'b11011111: out = 195;
            8'b11100001: out = 14;
            8'b11100010: out = 28;
            8'b11100011: out = 42;
            8'b11100100: out = 56;
            8'b11100101: out = 70;
            8'b11100110: out = 84;
            8'b11100111: out = 98;
            8'b11101000: out = 112;
            8'b11101001: out = 126;
            8'b11101010: out = 140;
            8'b11101011: out = 154;
            8'b11101100: out = 168;
            8'b11101101: out = 182;
            8'b11101110: out = 196;
            8'b11101111: out = 210;
            8'b11110001: out = 15;
            8'b11110010: out = 30;
            8'b11110011: out = 45;
            8'b11110100: out = 60;
            8'b11110101: out = 75;
            8'b11110110: out = 90;
            8'b11110111: out = 105;
            8'b11111000: out = 120;
            8'b11111001: out = 135;
            8'b11111010: out = 150;
            8'b11111011: out = 165;
            8'b11111100: out = 180;
            8'b11111101: out = 195;
            8'b11111110: out = 210;
            8'b11111111: out = 225;
            default: out = 0;
        endcase
    end */


/* module MULT4x4(
    a,
    b,
    out
);
    input [3:0] a, b;
    reg [3:0] out_a, out_b, out_c, out_d; 
    output reg [7:0] out;

    MULT2x2 MUlT1(.a(a[3:2]), .b(b[3:2]), .out(out_a));
    MULT2x2 MUlT2(.a(a[3:2]), .b(b[1:0]), .out(out_b));
    MULT2x2 MUlT3(.a(a[1:0]), .b(b[3:2]), .out(out_c));
    MULT2x2 MUlT4(.a(a[1:0]), .b(b[1:0]), .out(out_d));

    always @(*) begin
        out = ((out_a<<4) + (out_b<<2)) + ((out_c<<2) + out_d);
    end



endmodule

module MULT2x2(
    a,
    b,
    out
);
    input [1:0] a, b;
    output reg [3:0] out;

    always @(*) begin
        case({a,b})
            4'd0: out = 0;
            4'd1: out = 0;
            4'd2: out = 0;
            4'd3: out = 0;
            4'd4: out = 0;
            4'd5: out = 1;
            4'd6: out = 2;
            4'd7: out = 3;
            4'd8: out = 0;
            4'd9: out = 2;
            4'd10: out = 4;
            4'd11: out = 6;
            4'd12: out = 0;
            4'd13: out = 3;
            4'd14: out = 6;
            4'd15: out = 9;
            default: out = 0;
        endcase
    end



endmodule */