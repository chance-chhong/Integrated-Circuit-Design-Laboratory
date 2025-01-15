module CLK_1_MODULE (
    clk,
    rst_n,
    in_valid,
	in_row,
    in_kernel,
    out_idle,
    handshake_sready,
    handshake_din,

    flag_handshake_to_clk1,
    flag_clk1_to_handshake,

	fifo_empty,
    fifo_rdata,
    fifo_rinc,
    out_valid,
    out_data,

    flag_clk1_to_fifo,
    flag_fifo_to_clk1
);
input clk;
input rst_n;
input in_valid;
input [17:0] in_row;
input [11:0] in_kernel;
input out_idle;
output reg handshake_sready;
output reg [29:0] handshake_din;
// You can use the the custom flag ports for your design
input  flag_handshake_to_clk1;
output flag_clk1_to_handshake;

input fifo_empty;
input [7:0] fifo_rdata;
output fifo_rinc;
output reg out_valid;
output reg [7:0] out_data;
// You can use the the custom flag ports for your design
output flag_clk1_to_fifo;
input flag_fifo_to_clk1;

//==============================================//
//             Parameter and Integer            //
//==============================================//
enum logic [2:0] {
    IDLE = 3'd0,
    READ = 3'd1,
    TRAN = 3'd2
    } current_state, next_state;

integer i, j;



//==============================================//
//                     REG                      //
//==============================================//
reg [2:0] cnt, tran_M_cnt, tran_K_cnt;
reg [17:0] Matrix_row [0:5];
reg [11:0] Kernel [0:5];
reg fifo_empty_q ;
reg fifo_empty_qq;


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
			// when input is valid
			if(in_valid) next_state = READ;
			else next_state = current_state;
		end
        READ: begin
            if(cnt > 5) next_state = TRAN;
            else next_state = READ;
        end
        TRAN: begin
            if(tran_K_cnt > 5) next_state = IDLE;
            else next_state = TRAN;
        end
        default: next_state = IDLE;
    endcase
end


always@(posedge clk) begin
    if(in_valid) begin 
        Matrix_row[cnt] <= in_row;
        Kernel[cnt] <= in_kernel;
    end
end


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) cnt <= 0;
    else begin
        if(in_valid) cnt <= cnt + 1;
        else if(current_state == IDLE) cnt <= 0;
    end
end

//==============================================//
//                  SEND DATA                   //
//==============================================//



// handshake_sready
always @(*) begin
    handshake_sready = (cnt != 6) ? 1'b0 : out_idle;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) tran_M_cnt <= 0;
    else begin
        if(next_state == TRAN) begin 
            if(handshake_sready && (tran_M_cnt < 6)) tran_M_cnt <= tran_M_cnt + 1;
            else tran_M_cnt <= tran_M_cnt;
        end
        else tran_M_cnt <= 0;
    end
end


always@(posedge clk or negedge rst_n) begin
    if(!rst_n) tran_K_cnt <= 0;
    else begin
        if(current_state == TRAN) begin
            if (handshake_sready && tran_M_cnt == 6) tran_K_cnt <= tran_K_cnt + 1;
            else tran_K_cnt <= tran_K_cnt;      
        end
        else tran_K_cnt <= 0;
    end
end


always@(posedge clk or negedge rst_n) begin
    if(!rst_n) handshake_din <= 0;
    else if(handshake_sready && next_state == TRAN) handshake_din <= (tran_M_cnt < 6) ? Matrix_row[tran_M_cnt] : Kernel[tran_K_cnt];
end

//==============================================//
//                  READ FIFO                   //
//==============================================//


assign fifo_rinc = (!fifo_empty) ? 1 : 0;


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) fifo_empty_q <= 1;
    else fifo_empty_q <= fifo_empty;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) fifo_empty_qq <= 1;
    else fifo_empty_qq <= fifo_empty_q;
end

//==============================================//
//                    OUTPUT                    //
//==============================================//

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        out_valid <= 0 ;
        out_data <= 0 ;
    end else begin
        if(!fifo_empty_qq) begin
            out_valid <= 1'b1 ;
            out_data <= fifo_rdata ;
        end
        else begin
            out_valid <= 0 ;
            out_data <= 0 ;
        end
    end
end




endmodule

module CLK_2_MODULE (
    clk,
    rst_n,
    in_valid,
    fifo_full,
    in_data,
    out_valid,
    out_data,
    busy,

    flag_handshake_to_clk2,
    flag_clk2_to_handshake,

    flag_fifo_to_clk2,
    flag_clk2_to_fifo
);

input clk;
input rst_n;
input in_valid;
input fifo_full;
input [29:0] in_data;
output reg out_valid;
output reg [7:0] out_data;
output reg busy;

// You can use the the custom flag ports for your design
input  flag_handshake_to_clk2;
output flag_clk2_to_handshake;

input  flag_fifo_to_clk2;
output flag_clk2_to_fifo;


//==============================================//
//             Parameter and Integer            //
//==============================================//
enum logic [2:0] {
    IDLE = 3'd0,
    STORE = 3'd1,
    CONV = 3'd2,
    WRITE = 3'd3
    } current_state, next_state;

integer i, j;


//==============================================//
//                     REG                      //
//==============================================//
reg in_valid_q;
reg in_valid_pulse;
reg [2:0] store_M_cnt;
reg [2:0] store_K_cnt;
reg [2:0] Matrix[0:5][0:5];
reg [2:0] Kernel[0:5][0:3];
reg [5:0] mult[0:3];
reg [7:0] add_4mult;
reg [2:0] conv_M_cnt_r, conv_M_cnt_c;
reg [2:0] conv_K_cnt;
reg [7:0] ans[0:149];
reg [7:0] ans_cnt;
reg [8:0] cnt_write;


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
            if(in_valid) next_state = STORE;
            else next_state = IDLE;
        end
        STORE: begin
            if(store_K_cnt == 6) next_state = CONV;
            else next_state = STORE;
        end
        CONV: begin
            if(ans_cnt == 150) next_state = WRITE;
            else next_state = CONV;
        end
        WRITE: begin
            if(cnt_write == 150) next_state = IDLE;
            else next_state = WRITE;
        end
        default: next_state = IDLE;
    endcase
end

//==============================================//
//                   Handshake                  //
//==============================================//

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) busy <= 0;
    else if(store_K_cnt == 6 && cnt_write != 150) busy <= 1;
    else if(cnt_write == 150 && !fifo_full) busy <= 0;
end


//==============================================//
//                     STORE                    //
//==============================================//


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) in_valid_q <= 0;
    else in_valid_q <= in_valid;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) in_valid_pulse <= 0 ;
    else if(!in_valid) in_valid_pulse <= (in_valid ^ in_valid_q) ;
end


always@(posedge clk or negedge rst_n) begin
    if(!rst_n) store_M_cnt <= 0;
    else begin
        if(current_state == STORE && in_valid_pulse && (store_M_cnt < 6)) store_M_cnt <= store_M_cnt + 1;
        else if(current_state == IDLE) store_M_cnt <= 0;
    end
end
  

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) store_K_cnt <= 0;
    else begin
        if(current_state == STORE && in_valid_pulse && store_M_cnt == 6 && store_K_cnt < 6) store_K_cnt <= store_K_cnt + 1;
        else if(current_state == IDLE) store_K_cnt <= 0;
    end
end


always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0; i<6; i=i+1) begin
            Matrix[i][0] <= 0;
            Matrix[i][1] <= 0;
            Matrix[i][2] <= 0;
            Matrix[i][3] <= 0;
            Matrix[i][4] <= 0;
            Matrix[i][5] <= 0;
        end
    end
    else if(current_state == IDLE) begin
        for(i=0; i<6; i=i+1) begin
            Matrix[i][0] <= 0;
            Matrix[i][1] <= 0;
            Matrix[i][2] <= 0;
            Matrix[i][3] <= 0;
            Matrix[i][4] <= 0;
            Matrix[i][5] <= 0;
        end
    end
    else if(in_valid && current_state == STORE) begin
        Matrix[store_M_cnt][0] <= in_data[2:0];
        Matrix[store_M_cnt][1] <= in_data[5:3];
        Matrix[store_M_cnt][2] <= in_data[8:6];
        Matrix[store_M_cnt][3] <= in_data[11:9];
        Matrix[store_M_cnt][4] <= in_data[14:12];
        Matrix[store_M_cnt][5] <= in_data[17:15];
    end
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n) begin
        for(i=0; i<6; i=i+1) begin 
            Kernel[i][0] <= 0;
            Kernel[i][1] <= 0;
            Kernel[i][2] <= 0;
            Kernel[i][3] <= 0;
        end
    end
    else if(current_state == IDLE) begin
        for(i=0; i<6; i=i+1) begin 
            Kernel[i][0] <= 0;
            Kernel[i][1] <= 0;
            Kernel[i][2] <= 0;
            Kernel[i][3] <= 0;
        end
    end
    else if(in_valid && current_state == STORE) begin
        Kernel[store_K_cnt][0] <= in_data[2:0];
        Kernel[store_K_cnt][1] <= in_data[5:3];
        Kernel[store_K_cnt][2] <= in_data[8:6];
        Kernel[store_K_cnt][3] <= in_data[11:9];
    end
end

//==============================================//
//                     CONV                     //
//==============================================//

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) conv_M_cnt_r <= 0;
    else if(current_state == IDLE) conv_M_cnt_r <= 0;
    else if(current_state == CONV && conv_M_cnt_r == 4 && conv_M_cnt_c == 4) conv_M_cnt_r <= 0;
    else if(current_state == CONV && conv_M_cnt_c == 4) conv_M_cnt_r <= conv_M_cnt_r + 1;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) conv_M_cnt_c <= 0;
    else if(current_state == IDLE) conv_M_cnt_c <= 0;
    else if(current_state == CONV && conv_M_cnt_c == 4) conv_M_cnt_c <= 0;
    else if(current_state == CONV) conv_M_cnt_c <= conv_M_cnt_c + 1;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) conv_K_cnt <= 0;
    else if(current_state == IDLE) conv_K_cnt <= 0;
    else if(current_state == CONV && conv_M_cnt_r == 4 && conv_M_cnt_c == 4) conv_K_cnt <= conv_K_cnt + 1;
end



always @(posedge clk) begin
    if(current_state == IDLE) begin
        for(i=0 ; i<4; i=i+1) begin
            mult[i] <= 0;
        end
    end
    else if(current_state == CONV) begin
        mult[0] <= Matrix[conv_M_cnt_r][conv_M_cnt_c] * Kernel[conv_K_cnt][0];
        mult[1] <= Matrix[conv_M_cnt_r][conv_M_cnt_c+1] * Kernel[conv_K_cnt][1];
        mult[2] <= Matrix[conv_M_cnt_r+1][conv_M_cnt_c] * Kernel[conv_K_cnt][2];
        mult[3] <= Matrix[conv_M_cnt_r+1][conv_M_cnt_c+1] * Kernel[conv_K_cnt][3];
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) ans_cnt <= 0;
    else if(conv_K_cnt == 0 && conv_M_cnt_r == 0 && conv_M_cnt_c == 0) ans_cnt <= 0;
    else ans_cnt <= ans_cnt + 1;
end


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0; i<150; i=i+1) begin
            ans[i] <= 0;
        end
    end
    else if(current_state == CONV) ans[ans_cnt] <= (mult[0] + mult[1]) + (mult[2] + mult[3]);
end


//==============================================//
//                     WRITE                    //
//==============================================//

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) cnt_write <= 0;
    else if(current_state == CONV) cnt_write <= 0;
    else if(current_state == WRITE && cnt_write < 150 && !fifo_full) cnt_write <= cnt_write + 1;
    else cnt_write <= cnt_write;
end


always @(*) begin
    if(!rst_n) out_valid = 0;
    else begin
        if (current_state == WRITE && cnt_write < 150 && !fifo_full) out_valid = 1 ;
        else out_valid = 0;
    end
end


always @(*) begin
    if(!rst_n) out_data = 0;
    else begin
        if(current_state == WRITE && cnt_write < 150 && !fifo_full) out_data = ans[cnt_write];
        else out_data = 0;
    end
end



endmodule