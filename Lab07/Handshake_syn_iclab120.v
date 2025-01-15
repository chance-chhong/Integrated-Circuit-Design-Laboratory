module Handshake_syn #(parameter WIDTH=8) (
    sclk,
    dclk,
    rst_n,
    sready,
    din,
    dbusy,
    sidle,
    dvalid,
    dout,

    flag_handshake_to_clk1,
    flag_clk1_to_handshake,

    flag_handshake_to_clk2,
    flag_clk2_to_handshake
);

input sclk, dclk;
input rst_n;
input sready;
input [WIDTH-1:0] din;
input dbusy;
output sidle;
output reg dvalid;
output reg [WIDTH-1:0] dout;

// You can change the input / output of the custom flag ports
output reg flag_handshake_to_clk1;
input flag_clk1_to_handshake;

output flag_handshake_to_clk2;
input flag_clk2_to_handshake;

// Remember:
//   Don't modify the signal name
reg sreq;
wire dreq;
reg dack;
wire sack;


//================================================//
//                        IP                      //
//================================================//
NDFF_syn U_NDFF_req(.D(sreq), .Q(dreq), .clk(dclk), .rst_n(rst_n));
NDFF_syn U_NDFF_ack(.D(dack), .Q(sack), .clk(sclk), .rst_n(rst_n));



//================================================//
//                    DESIGN                      //
//================================================//



// sidle
assign sidle = (sack || sreq) ? 0 : 1;

// sreq
always @(posedge sclk or negedge rst_n) begin
    if(!rst_n) sreq <= 0;
    else if(sack) sreq <= 1'b0;
    else if(sready) sreq <= 1'b1;
end

// dack
always @(posedge dclk or negedge rst_n) begin
    if(!rst_n) dack <= 0;
    else dack <= dreq && !dbusy;
end

// dvalid
always @(posedge dclk or negedge rst_n)begin
    if(!rst_n) dvalid <= 0;
    else dvalid <= dreq && !dbusy;
end

// dout
always @(posedge dclk or negedge rst_n) begin
    if(!rst_n) dout <= 0;
    else if(dreq && !dbusy) dout <= din;
end


endmodule