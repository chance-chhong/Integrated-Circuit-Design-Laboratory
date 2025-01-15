/**************************************************************************/
// Copyright (c) 2024, OASIS Lab
// MODULE: TETRIS
// FILE NAME: TETRIS.v
// VERSRION: 1.0
// DATE: August 15, 2024
// AUTHOR: Yu-Hsuan Hsu, NYCU IEE
// DESCRIPTION: ICLAB2024FALL / LAB3 / TETRIS
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/
module TETRIS (
	//INPUT
	rst_n,
	clk,
	in_valid,
	tetrominoes,
	position,
	//OUTPUT
	tetris_valid,
	score_valid,
	fail,
	score,
	tetris
);

//---------------------------------------------------------------------
//   PORT DECLARATION          
//---------------------------------------------------------------------
input				rst_n, clk, in_valid;
input		[2:0]	tetrominoes;
input		[2:0]	position;
output reg			tetris_valid, score_valid, fail;
output reg	[3:0]	score;
output reg 	[71:0]	tetris;


//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------
enum logic[2:0] {
    IDLE =    3'd0,
    READ =   3'd1,
    MOVE =   3'd2,
    CHECK =   3'd3,
    OUTPUT =  3'd4,
	WAIT =  3'd5
    } current_state,next_state;

//---------------------------------------------------------------------
//   REG & WIRE DECLARATION
//---------------------------------------------------------------------
reg [4:0] highest_pos[0:5];
reg [2:0] place_indexX[0:3];
reg [3:0] place_indexY[0:3];
reg [5:0] tetris_tmp[0:20];
reg [4:0] round_count;
reg [2:0] tetrominoes_tmp, position_tmp;
reg game_end;
reg game_end_tmp;
wire fail_tmp;
reg [3:0] score_tmp;
reg in_valid_reg;


wire [2:0] x_tmp_1, x_tmp_2, x_tmp_3, x_tmp_4;
wire [3:0] y_tmp_1, y_tmp_2, y_tmp_3, y_tmp_4, y_tmp_3_1;
wire [3:0] highest_tmp_1, highest_tmp_2, highest, high1, high2, high3, high4;
reg [4:0] start_idx;
reg [3:0] row_kill;

//---------------------------------------------------------------------
//   DESIGN
//---------------------------------------------------------------------




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
            if(in_valid_reg) next_state = READ;
            else next_state = IDLE;
        end
        READ: begin
            next_state = MOVE;
        end
        MOVE: begin
			next_state = CHECK;
        end
		CHECK: begin
			next_state = (row_kill==0) ? WAIT : OUTPUT;
		end
		WAIT: begin
			next_state =  OUTPUT;
		end
        OUTPUT: begin
            next_state = IDLE;
        end
        default: next_state = IDLE;
    endcase
end


//reg
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) in_valid_reg <= 0;
	else in_valid_reg <= in_valid;
end


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) tetrominoes_tmp <= 0;
	else if(in_valid) begin
		tetrominoes_tmp <= tetrominoes;
	end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) position_tmp <= 0;
	else if(in_valid) begin
		position_tmp <= position;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) game_end <= 0;
	else if((current_state == OUTPUT && round_count == 16) || (current_state == OUTPUT && fail_tmp)) begin
		game_end <= 1;
	end
	else begin
		game_end <= 0;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) game_end_tmp <= 0;
	else begin
		game_end_tmp <= game_end;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) round_count <= 0;
	else if(game_end) begin
		round_count <= 0;
	end
	else begin if(in_valid)
		round_count <= round_count + 1;
	end
end

assign x_tmp_1 = position_tmp;
assign x_tmp_2 = position_tmp + 1;
assign x_tmp_3 = position_tmp + 2;
assign x_tmp_4 = position_tmp + 3;




assign y_tmp_1       = highest_pos[position_tmp + ((highest_pos[position_tmp] > highest_pos[position_tmp + 1]) ? 0 : 1)] + 1;
assign y_tmp_2       = highest_pos[position_tmp + ((highest_pos[position_tmp] > highest_pos[position_tmp + 1]) ? 0 : 1)] + 2;
assign highest_tmp_1 = (highest_pos[position_tmp] > highest_pos[position_tmp + 1]) ? highest_pos[position_tmp] : highest_pos[position_tmp + 1];
assign highest_tmp_2 = (highest_pos[position_tmp + 2] > highest_pos[position_tmp + 3]) ? highest_pos[position_tmp + 2] : highest_pos[position_tmp + 3];
assign highest       = 1 + ((highest_tmp_1 > highest_tmp_2) ? highest_tmp_1 : highest_tmp_2);
assign y_tmp_3       = (highest_pos[position_tmp] > (highest_pos[position_tmp + 1] + 2)) ? (highest_pos[position_tmp] + 1) : (highest_pos[position_tmp + 1] + 3);
assign high1         = (highest_pos[position_tmp + 1] > highest_pos[position_tmp + 2]) ? highest_pos[position_tmp + 1] : highest_pos[position_tmp + 2];
assign high2         = ((highest_pos[position_tmp] + 1) < high1) ? (high1 + 1) : (highest_pos[position_tmp] + 2);
assign y_tmp_4       = (highest_pos[position_tmp] > (highest_pos[position_tmp + 1] + 1)) ? (highest_pos[position_tmp] + 1) : (highest_pos[position_tmp + 1] + 2);
assign high3         = (highest_pos[position_tmp] > highest_pos[position_tmp + 1]) ? highest_pos[position_tmp] : highest_pos[position_tmp + 1];
assign high4         = (highest_pos[position_tmp + 2] > (high3 + 1)) ? (highest_pos[position_tmp + 2] + 1) : (high3 + 2);


//assign y_tmp_3_1     = (highest_pos[position_tmp] > (highest_pos[position_tmp + 1] + 2)) ? highest_pos[position_tmp] : (highest_pos[position_tmp + 1] + 2);

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		place_indexX[0] <= 0;
		place_indexY[0] <= 0;
		place_indexX[1] <= 0;
		place_indexY[1] <= 0;
		place_indexX[2] <= 0;
		place_indexY[2] <= 0;
		place_indexX[3] <= 0;
		place_indexY[3] <= 0;
	end
	else if(next_state == IDLE) begin
		place_indexX[0] <= 0;
		place_indexY[0] <= 0;
		place_indexX[1] <= 0;
		place_indexY[1] <= 0;
		place_indexX[2] <= 0;
		place_indexY[2] <= 0;
		place_indexX[3] <= 0;
		place_indexY[3] <= 0;
	end
	else begin
		case(tetrominoes_tmp)
			3'd0: begin
				place_indexX[0] <= x_tmp_1;
				place_indexY[0] <= y_tmp_1;
				place_indexX[1] <= x_tmp_2;
				place_indexY[1] <= y_tmp_1;
				place_indexX[2] <= x_tmp_1;
				place_indexY[2] <= y_tmp_2;
				place_indexX[3] <= x_tmp_2;
				place_indexY[3] <= y_tmp_2;
			end
			3'd1: begin
				place_indexX[0] <= x_tmp_1;
				place_indexY[0] <= highest_pos[position_tmp] + 1;
				place_indexX[1] <= x_tmp_1;
				place_indexY[1] <= highest_pos[position_tmp] + 2;
				place_indexX[2] <= x_tmp_1;
				place_indexY[2] <= highest_pos[position_tmp] + 3;
				place_indexX[3] <= x_tmp_1;
				place_indexY[3] <= highest_pos[position_tmp] + 4;
			end
			3'd2: begin
				place_indexX[0] <= x_tmp_1;
				place_indexY[0] <= highest;
				place_indexX[1] <= x_tmp_2;
				place_indexY[1] <= highest;
				place_indexX[2] <= x_tmp_3;
				place_indexY[2] <= highest;
				place_indexX[3] <= x_tmp_4;
				place_indexY[3] <= highest;
			end
			3'd3: begin
				place_indexX[0] <= x_tmp_1;
				place_indexY[0] <= y_tmp_3;
				place_indexX[1] <= x_tmp_2;
				place_indexY[1] <= y_tmp_3;
				place_indexX[2] <= x_tmp_2;
				place_indexY[2] <= y_tmp_3 - 1;
				place_indexX[3] <= x_tmp_2;
				place_indexY[3] <= y_tmp_3 - 2;
			end
			3'd4: begin
				place_indexX[0] <= x_tmp_1;
				place_indexY[0] <= high2;
				place_indexX[1] <= x_tmp_1;
				place_indexY[1] <= high2 - 1;
				place_indexX[2] <= x_tmp_2;
				place_indexY[2] <= high2;
				place_indexX[3] <= x_tmp_3;
				place_indexY[3] <= high2;
			end
			3'd5: begin
				place_indexX[0] <= x_tmp_1;
				place_indexY[0] <= y_tmp_1;
				place_indexX[1] <= x_tmp_2;
				place_indexY[1] <= y_tmp_1;
				place_indexX[2] <= x_tmp_1;
				place_indexY[2] <= y_tmp_1 + 1;
				place_indexX[3] <= x_tmp_1;
				place_indexY[3] <= y_tmp_1 + 2;
			end
			3'd6: begin
				place_indexX[0] <= x_tmp_1;
				place_indexY[0] <= y_tmp_4 + 1;
				place_indexX[1] <= x_tmp_1;
				place_indexY[1] <= y_tmp_4;
				place_indexX[2] <= x_tmp_2;
				place_indexY[2] <= y_tmp_4;
				place_indexX[3] <= x_tmp_2;
				place_indexY[3] <= y_tmp_4 - 1;
			end
			3'd7: begin
				place_indexX[0] <= x_tmp_1;
				place_indexY[0] <= high4 - 1;
				place_indexX[1] <= x_tmp_2;
				place_indexY[1] <= high4 - 1;
				place_indexX[2] <= x_tmp_2;
				place_indexY[2] <= high4;
				place_indexX[3] <= x_tmp_3;
				place_indexY[3] <= high4;
			end
		endcase
	end
end

//reg [3:0] map_mapping_cnt [0:14];

/* 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 
				^
				|
				|

1 2 3 4 5 6 7 8 10 11 12 13 14 15 16 <= 15 idx */


//wire tetris_tmp_control = !rst_n || fail || (count == 15);

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		tetris_tmp[0] <= 0;
		tetris_tmp[1] <= 0;
		tetris_tmp[2] <= 0;
		tetris_tmp[3] <= 0;
		tetris_tmp[4] <= 0;
		tetris_tmp[5] <= 0;
		tetris_tmp[6] <= 0;
		tetris_tmp[7] <= 0;
		tetris_tmp[8] <= 0;
		tetris_tmp[9] <= 0;
		tetris_tmp[10] <= 0;
		tetris_tmp[11] <= 0;
		tetris_tmp[12] <= 0;
		tetris_tmp[13] <= 0;
		tetris_tmp[14] <= 0;
		tetris_tmp[15] <= 0;
		tetris_tmp[16] <= 0;
		tetris_tmp[17] <= 0;
		tetris_tmp[18] <= 0;
		tetris_tmp[19] <= 0;
		tetris_tmp[20] <= 0;
		/* tetris_tmp[21] <= 0;
		tetris_tmp[22] <= 0;
		tetris_tmp[23] <= 0;
		tetris_tmp[24] <= 0;
		tetris_tmp[25] <= 0;
		tetris_tmp[26] <= 0;
		tetris_tmp[27] <= 0;
		tetris_tmp[28] <= 0;
		tetris_tmp[29] <= 0;
		tetris_tmp[30] <= 0;
		tetris_tmp[31] <= 0;
		tetris_tmp[32] <= 0;
		tetris_tmp[33] <= 0;
		tetris_tmp[34] <= 0;
		tetris_tmp[35] <= 0; */
	end
	else if(current_state == READ)  begin
		tetris_tmp[place_indexY[0]][place_indexX[0]] <= 1;
		tetris_tmp[place_indexY[1]][place_indexX[1]] <= 1;
		tetris_tmp[place_indexY[2]][place_indexX[2]] <= 1;
		tetris_tmp[place_indexY[3]][place_indexX[3]] <= 1;
	end
	else if(current_state == WAIT) begin

		case(row_kill)
		4'd1: begin
			tetris_tmp[start_idx] <= tetris_tmp[start_idx + 1];
			tetris_tmp[start_idx + 1] <= tetris_tmp[start_idx + 2];
			tetris_tmp[start_idx + 2] <= tetris_tmp[start_idx + 3];
			tetris_tmp[start_idx + 3] <= tetris_tmp[start_idx + 4];
			tetris_tmp[start_idx + 4] <= tetris_tmp[start_idx + 5];
			tetris_tmp[start_idx + 5] <= tetris_tmp[start_idx + 6];
			tetris_tmp[start_idx + 6] <= tetris_tmp[start_idx + 7];
			tetris_tmp[start_idx + 7] <= tetris_tmp[start_idx + 8];
			tetris_tmp[start_idx + 8] <= tetris_tmp[start_idx + 9];
			tetris_tmp[start_idx + 9] <= tetris_tmp[start_idx + 10];
			tetris_tmp[start_idx + 10] <= tetris_tmp[start_idx + 11];
			tetris_tmp[start_idx + 11] <= tetris_tmp[start_idx + 12];
			tetris_tmp[start_idx + 12] <= tetris_tmp[start_idx + 13];
			tetris_tmp[start_idx + 13] <= tetris_tmp[start_idx + 14];
			tetris_tmp[start_idx + 14] <= tetris_tmp[start_idx + 15];
			tetris_tmp[start_idx + 15] <= tetris_tmp[start_idx + 16];
		end
		4'd3: begin
			tetris_tmp[start_idx] <= tetris_tmp[start_idx + 2];
			tetris_tmp[start_idx + 1] <= tetris_tmp[start_idx + 3];
			tetris_tmp[start_idx + 2] <= tetris_tmp[start_idx + 4];
			tetris_tmp[start_idx + 3] <= tetris_tmp[start_idx + 5];
			tetris_tmp[start_idx + 4] <= tetris_tmp[start_idx + 6];
			tetris_tmp[start_idx + 5] <= tetris_tmp[start_idx + 7];
			tetris_tmp[start_idx + 6] <= tetris_tmp[start_idx + 8];
			tetris_tmp[start_idx + 7] <= tetris_tmp[start_idx + 9];
			tetris_tmp[start_idx + 8] <= tetris_tmp[start_idx + 10];
			tetris_tmp[start_idx + 9] <= tetris_tmp[start_idx + 11];
			tetris_tmp[start_idx + 10] <= tetris_tmp[start_idx + 12];
			tetris_tmp[start_idx + 11] <= tetris_tmp[start_idx + 13];
			tetris_tmp[start_idx + 12] <= tetris_tmp[start_idx + 14];
			tetris_tmp[start_idx + 13] <= tetris_tmp[start_idx + 15];
			tetris_tmp[start_idx + 14] <= tetris_tmp[start_idx + 16];
			tetris_tmp[start_idx + 15] <= tetris_tmp[start_idx + 17];
		end
		4'd5: begin
			tetris_tmp[start_idx] <= tetris_tmp[start_idx + 1];
			tetris_tmp[start_idx + 1] <= tetris_tmp[start_idx + 3];
			tetris_tmp[start_idx + 2] <= tetris_tmp[start_idx + 4];
			tetris_tmp[start_idx + 3] <= tetris_tmp[start_idx + 5];
			tetris_tmp[start_idx + 4] <= tetris_tmp[start_idx + 6];
			tetris_tmp[start_idx + 5] <= tetris_tmp[start_idx + 7];
			tetris_tmp[start_idx + 6] <= tetris_tmp[start_idx + 8];
			tetris_tmp[start_idx + 7] <= tetris_tmp[start_idx + 9];
			tetris_tmp[start_idx + 8] <= tetris_tmp[start_idx + 10];
			tetris_tmp[start_idx + 9] <= tetris_tmp[start_idx + 11];
			tetris_tmp[start_idx + 10] <= tetris_tmp[start_idx + 12];
			tetris_tmp[start_idx + 11] <= tetris_tmp[start_idx + 13];
			tetris_tmp[start_idx + 12] <= tetris_tmp[start_idx + 14];
			tetris_tmp[start_idx + 13] <= tetris_tmp[start_idx + 15];
			tetris_tmp[start_idx + 14] <= tetris_tmp[start_idx + 16];
			tetris_tmp[start_idx + 15] <= tetris_tmp[start_idx + 17];
		end
		4'd7: begin
			tetris_tmp[start_idx] <= tetris_tmp[start_idx + 3];
			tetris_tmp[start_idx + 1] <= tetris_tmp[start_idx + 4];
			tetris_tmp[start_idx + 2] <= tetris_tmp[start_idx + 5];
			tetris_tmp[start_idx + 3] <= tetris_tmp[start_idx + 6];
			tetris_tmp[start_idx + 4] <= tetris_tmp[start_idx + 7];
			tetris_tmp[start_idx + 5] <= tetris_tmp[start_idx + 8];
			tetris_tmp[start_idx + 6] <= tetris_tmp[start_idx + 9];
			tetris_tmp[start_idx + 7] <= tetris_tmp[start_idx + 10];
			tetris_tmp[start_idx + 8] <= tetris_tmp[start_idx + 11];
			tetris_tmp[start_idx + 9] <= tetris_tmp[start_idx + 12];
			tetris_tmp[start_idx + 10] <= tetris_tmp[start_idx + 13];
			tetris_tmp[start_idx + 11] <= tetris_tmp[start_idx + 14];
			tetris_tmp[start_idx + 12] <= tetris_tmp[start_idx + 15];
			tetris_tmp[start_idx + 13] <= tetris_tmp[start_idx + 16];
			tetris_tmp[start_idx + 14] <= tetris_tmp[start_idx + 17];
			tetris_tmp[start_idx + 15] <= tetris_tmp[start_idx + 18];
		end
		4'd9: begin
			tetris_tmp[start_idx] <= tetris_tmp[start_idx + 1];
			tetris_tmp[start_idx + 1] <= tetris_tmp[start_idx + 2];
			tetris_tmp[start_idx + 2] <= tetris_tmp[start_idx + 4];
			tetris_tmp[start_idx + 3] <= tetris_tmp[start_idx + 5];
			tetris_tmp[start_idx + 4] <= tetris_tmp[start_idx + 6];
			tetris_tmp[start_idx + 5] <= tetris_tmp[start_idx + 7];
			tetris_tmp[start_idx + 6] <= tetris_tmp[start_idx + 8];
			tetris_tmp[start_idx + 7] <= tetris_tmp[start_idx + 9];
			tetris_tmp[start_idx + 8] <= tetris_tmp[start_idx + 10];
			tetris_tmp[start_idx + 9] <= tetris_tmp[start_idx + 11];
			tetris_tmp[start_idx + 10] <= tetris_tmp[start_idx + 12];
			tetris_tmp[start_idx + 11] <= tetris_tmp[start_idx + 13];
			tetris_tmp[start_idx + 12] <= tetris_tmp[start_idx + 14];
			tetris_tmp[start_idx + 13] <= tetris_tmp[start_idx + 15];
			tetris_tmp[start_idx + 14] <= tetris_tmp[start_idx + 16];
			tetris_tmp[start_idx + 15] <= tetris_tmp[start_idx + 17];
		end
		4'd11: begin
			tetris_tmp[start_idx] <= tetris_tmp[start_idx + 2];
			tetris_tmp[start_idx + 1] <= tetris_tmp[start_idx + 4];
			tetris_tmp[start_idx + 2] <= tetris_tmp[start_idx + 5];
			tetris_tmp[start_idx + 3] <= tetris_tmp[start_idx + 6];
			tetris_tmp[start_idx + 4] <= tetris_tmp[start_idx + 7];
			tetris_tmp[start_idx + 5] <= tetris_tmp[start_idx + 8];
			tetris_tmp[start_idx + 6] <= tetris_tmp[start_idx + 9];
			tetris_tmp[start_idx + 7] <= tetris_tmp[start_idx + 10];
			tetris_tmp[start_idx + 8] <= tetris_tmp[start_idx + 11];
			tetris_tmp[start_idx + 9] <= tetris_tmp[start_idx + 12];
			tetris_tmp[start_idx + 10] <= tetris_tmp[start_idx + 13];
			tetris_tmp[start_idx + 11] <= tetris_tmp[start_idx + 14];
			tetris_tmp[start_idx + 12] <= tetris_tmp[start_idx + 15];
			tetris_tmp[start_idx + 13] <= tetris_tmp[start_idx + 16];
			tetris_tmp[start_idx + 14] <= tetris_tmp[start_idx + 17];
			tetris_tmp[start_idx + 15] <= tetris_tmp[start_idx + 18];
		end
		4'd13: begin
			tetris_tmp[start_idx] <= tetris_tmp[start_idx + 1];
			tetris_tmp[start_idx + 1] <= tetris_tmp[start_idx + 4];
			tetris_tmp[start_idx + 2] <= tetris_tmp[start_idx + 5];
			tetris_tmp[start_idx + 3] <= tetris_tmp[start_idx + 6];
			tetris_tmp[start_idx + 4] <= tetris_tmp[start_idx + 7];
			tetris_tmp[start_idx + 5] <= tetris_tmp[start_idx + 8];
			tetris_tmp[start_idx + 6] <= tetris_tmp[start_idx + 9];
			tetris_tmp[start_idx + 7] <= tetris_tmp[start_idx + 10];
			tetris_tmp[start_idx + 8] <= tetris_tmp[start_idx + 11];
			tetris_tmp[start_idx + 9] <= tetris_tmp[start_idx + 12];
			tetris_tmp[start_idx + 10] <= tetris_tmp[start_idx + 13];
			tetris_tmp[start_idx + 11] <= tetris_tmp[start_idx + 14];
			tetris_tmp[start_idx + 12] <= tetris_tmp[start_idx + 15];
			tetris_tmp[start_idx + 13] <= tetris_tmp[start_idx + 16];
			tetris_tmp[start_idx + 14] <= tetris_tmp[start_idx + 17];
			tetris_tmp[start_idx + 15] <= tetris_tmp[start_idx + 18];
		end
		4'd15: begin
			tetris_tmp[start_idx] <= tetris_tmp[start_idx + 4];
			tetris_tmp[start_idx + 1] <= tetris_tmp[start_idx + 5];
			tetris_tmp[start_idx + 2] <= tetris_tmp[start_idx + 6];
			tetris_tmp[start_idx + 3] <= tetris_tmp[start_idx + 7];
			tetris_tmp[start_idx + 4] <= tetris_tmp[start_idx + 8];
			tetris_tmp[start_idx + 5] <= tetris_tmp[start_idx + 9];
			tetris_tmp[start_idx + 6] <= tetris_tmp[start_idx + 10];
			tetris_tmp[start_idx + 7] <= tetris_tmp[start_idx + 11];
			tetris_tmp[start_idx + 8] <= tetris_tmp[start_idx + 12];
			tetris_tmp[start_idx + 9] <= tetris_tmp[start_idx + 13];
			tetris_tmp[start_idx + 10] <= tetris_tmp[start_idx + 14];
			tetris_tmp[start_idx + 11] <= tetris_tmp[start_idx + 15];
			tetris_tmp[start_idx + 12] <= tetris_tmp[start_idx + 16];
			tetris_tmp[start_idx + 13] <= tetris_tmp[start_idx + 17];
			tetris_tmp[start_idx + 14] <= tetris_tmp[start_idx + 18];
			tetris_tmp[start_idx + 15] <= tetris_tmp[start_idx + 19];
		end
		endcase
	end
	else if(game_end) begin
		tetris_tmp[0] <= 0;
		tetris_tmp[1] <= 0;
		tetris_tmp[2] <= 0;
		tetris_tmp[3] <= 0;
		tetris_tmp[4] <= 0;
		tetris_tmp[5] <= 0;
		tetris_tmp[6] <= 0;
		tetris_tmp[7] <= 0;
		tetris_tmp[8] <= 0;
		tetris_tmp[9] <= 0;
		tetris_tmp[10] <= 0;
		tetris_tmp[11] <= 0;
		tetris_tmp[12] <= 0;
		tetris_tmp[13] <= 0;
		tetris_tmp[14] <= 0;
		tetris_tmp[15] <= 0;
		tetris_tmp[16] <= 0;
		tetris_tmp[17] <= 0;
		tetris_tmp[18] <= 0;
		tetris_tmp[19] <= 0;
		tetris_tmp[20] <= 0;
		/* tetris_tmp[21] <= 0;
		tetris_tmp[22] <= 0;
		tetris_tmp[23] <= 0;
		tetris_tmp[24] <= 0;
		tetris_tmp[25] <= 0;
		tetris_tmp[26] <= 0;
		tetris_tmp[27] <= 0;
		tetris_tmp[28] <= 0;
		tetris_tmp[29] <= 0;
		tetris_tmp[30] <= 0;
		tetris_tmp[31] <= 0;
		tetris_tmp[32] <= 0;
		tetris_tmp[33] <= 0;
		tetris_tmp[34] <= 0;
		tetris_tmp[35] <= 0; */
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) start_idx <= 0;
	else if(current_state == MOVE || current_state == CHECK) begin
		if(&tetris_tmp[1]) begin
			start_idx <= 1;
		end
		else if(&tetris_tmp[2]) begin
			start_idx <= 2;
		end
		else if(&tetris_tmp[3]) begin
			start_idx <= 3;
		end
		else if(&tetris_tmp[4]) begin
			start_idx <= 4;
		end
		else if(&tetris_tmp[5]) begin
			start_idx <= 5;
		end
		else if(&tetris_tmp[6]) begin
			start_idx <= 6;
		end
		else if(&tetris_tmp[7]) begin
			start_idx <= 7;
		end
		else if(&tetris_tmp[8]) begin
			start_idx <= 8;
		end
		else if(&tetris_tmp[9]) begin
			start_idx <= 9;
		end
		else if(&tetris_tmp[10]) begin
			start_idx <= 10;
		end
		else if(&tetris_tmp[11]) begin
			start_idx <= 11;
		end
		else if(&tetris_tmp[12]) begin
			start_idx <= 12;
		end
		else if(&tetris_tmp[13]) begin
			start_idx <= 13;
		end
		else if(&tetris_tmp[14]) begin
			start_idx <= 14;
		end
		else if(&tetris_tmp[15]) begin
			start_idx <= 15;
		end
		else if(&tetris_tmp[16]) begin
			start_idx <= 16;
		end
		else begin
			start_idx <= 0;
		end
	end
	else begin
		start_idx <= 0;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) row_kill <= 0;
	else if(start_idx == 0) begin
		row_kill <= 0;
	end
	else begin
		row_kill <= {&tetris_tmp[start_idx + 3], &tetris_tmp[start_idx + 2], &tetris_tmp[start_idx + 1], &tetris_tmp[start_idx]};
	end
end



FIND_COL_TOP COL0(.clk(clk),.rst_n(rst_n),.tetris_tmp({tetris_tmp[16][0],tetris_tmp[15][0],tetris_tmp[14][0],tetris_tmp[13][0],tetris_tmp[12][0],tetris_tmp[11][0],tetris_tmp[10][0],tetris_tmp[9][0],tetris_tmp[8][0],tetris_tmp[7][0],tetris_tmp[6][0],tetris_tmp[5][0],tetris_tmp[4][0],tetris_tmp[3][0],tetris_tmp[2][0],tetris_tmp[1][0],tetris_tmp[0][0]}),.highest_pos(highest_pos[0]));
FIND_COL_TOP COL1(.clk(clk),.rst_n(rst_n),.tetris_tmp({tetris_tmp[16][1],tetris_tmp[15][1],tetris_tmp[14][1],tetris_tmp[13][1],tetris_tmp[12][1],tetris_tmp[11][1],tetris_tmp[10][1],tetris_tmp[9][1],tetris_tmp[8][1],tetris_tmp[7][1],tetris_tmp[6][1],tetris_tmp[5][1],tetris_tmp[4][1],tetris_tmp[3][1],tetris_tmp[2][1],tetris_tmp[1][1],tetris_tmp[0][1]}),.highest_pos(highest_pos[1]));
FIND_COL_TOP COL2(.clk(clk),.rst_n(rst_n),.tetris_tmp({tetris_tmp[16][2],tetris_tmp[15][2],tetris_tmp[14][2],tetris_tmp[13][2],tetris_tmp[12][2],tetris_tmp[11][2],tetris_tmp[10][2],tetris_tmp[9][2],tetris_tmp[8][2],tetris_tmp[7][2],tetris_tmp[6][2],tetris_tmp[5][2],tetris_tmp[4][2],tetris_tmp[3][2],tetris_tmp[2][2],tetris_tmp[1][2],tetris_tmp[0][2]}),.highest_pos(highest_pos[2]));
FIND_COL_TOP COL3(.clk(clk),.rst_n(rst_n),.tetris_tmp({tetris_tmp[16][3],tetris_tmp[15][3],tetris_tmp[14][3],tetris_tmp[13][3],tetris_tmp[12][3],tetris_tmp[11][3],tetris_tmp[10][3],tetris_tmp[9][3],tetris_tmp[8][3],tetris_tmp[7][3],tetris_tmp[6][3],tetris_tmp[5][3],tetris_tmp[4][3],tetris_tmp[3][3],tetris_tmp[2][3],tetris_tmp[1][3],tetris_tmp[0][3]}),.highest_pos(highest_pos[3]));
FIND_COL_TOP COL4(.clk(clk),.rst_n(rst_n),.tetris_tmp({tetris_tmp[16][4],tetris_tmp[15][4],tetris_tmp[14][4],tetris_tmp[13][4],tetris_tmp[12][4],tetris_tmp[11][4],tetris_tmp[10][4],tetris_tmp[9][4],tetris_tmp[8][4],tetris_tmp[7][4],tetris_tmp[6][4],tetris_tmp[5][4],tetris_tmp[4][4],tetris_tmp[3][4],tetris_tmp[2][4],tetris_tmp[1][4],tetris_tmp[0][4]}),.highest_pos(highest_pos[4]));
FIND_COL_TOP COL5(.clk(clk),.rst_n(rst_n),.tetris_tmp({tetris_tmp[16][5],tetris_tmp[15][5],tetris_tmp[14][5],tetris_tmp[13][5],tetris_tmp[12][5],tetris_tmp[11][5],tetris_tmp[10][5],tetris_tmp[9][5],tetris_tmp[8][5],tetris_tmp[7][5],tetris_tmp[6][5],tetris_tmp[5][5],tetris_tmp[4][5],tetris_tmp[3][5],tetris_tmp[2][5],tetris_tmp[1][5],tetris_tmp[0][5]}),.highest_pos(highest_pos[5]));




assign fail_tmp = |tetris_tmp[13] || |tetris_tmp[14] || |tetris_tmp[15] || |tetris_tmp[16];


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) fail <= 0;
	else if(current_state == OUTPUT && fail_tmp) begin
		fail <= 1;
	end
	else begin
		fail <= 0;
	end
end


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) score_tmp <= 1'b0;
	else if(game_end_tmp) begin
		score_tmp <= 1'b0;
	end
	else if(current_state == CHECK && start_idx != 0) begin
		score_tmp <= score_tmp + (&tetris_tmp[start_idx + 3] + &tetris_tmp[start_idx + 2]) + (&tetris_tmp[start_idx + 1] + &tetris_tmp[start_idx]);
	end
end

wire [31:0] score_up = (&tetris_tmp[start_idx + 3] + &tetris_tmp[start_idx + 2]) + (&tetris_tmp[start_idx + 1] + &tetris_tmp[start_idx]);

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) score <= 0;
	else if(current_state == OUTPUT) begin
		score <= score_tmp;
	end
	else begin
		score <= 0;
	end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) score_valid <= 0;
	else if(current_state == OUTPUT) begin
		score_valid <= 1;
	end
	else begin
		score_valid <= 0;
	end	
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) tetris <= 0;
	else if(current_state == OUTPUT) begin
		tetris <= {tetris_tmp[12], tetris_tmp[11], tetris_tmp[10], tetris_tmp[9], tetris_tmp[8], tetris_tmp[7], tetris_tmp[6], tetris_tmp[5], tetris_tmp[4], tetris_tmp[3], tetris_tmp[2], tetris_tmp[1]};
	end
	else begin
		tetris <= 0;
	end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) tetris_valid <= 0;
	else if(current_state == OUTPUT) begin
		tetris_valid <= 1;
	end
	else begin
		tetris_valid <= 0;
	end
end




endmodule

module FIND_COL_TOP (
	input clk,
	input rst_n,
	input [16:0] tetris_tmp,
	output reg [4:0] highest_pos
);

	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			highest_pos <= 0;
		end
		else begin
			if(tetris_tmp[16]) begin
				highest_pos <= 16;
			end
			else if(tetris_tmp[15]) begin
				highest_pos <= 15;
			end
			else if(tetris_tmp[14]) begin
				highest_pos <= 14;
			end
			else if(tetris_tmp[13]) begin
				highest_pos <= 13;
			end
			else if(tetris_tmp[12]) begin
				highest_pos <= 12;
			end
			else if(tetris_tmp[11]) begin
				highest_pos <= 11;
			end
			else if(tetris_tmp[10]) begin
				highest_pos <= 10;
			end
			else if(tetris_tmp[9]) begin
				highest_pos <= 9;
			end
			else if(tetris_tmp[8]) begin
				highest_pos <= 8;
			end
			else if(tetris_tmp[7]) begin
				highest_pos <= 7;
			end
			else if(tetris_tmp[6]) begin
				highest_pos <= 6;
			end
			else if(tetris_tmp[5]) begin
				highest_pos <= 5;
			end
			else if(tetris_tmp[4]) begin
				highest_pos <= 4;
			end
			else if(tetris_tmp[3]) begin
				highest_pos <= 3;
			end
			else if(tetris_tmp[2]) begin
				highest_pos <= 2;
			end
			else if(tetris_tmp[1]) begin
				highest_pos <= 1;
			end
			else begin
				highest_pos <= 0;
			end
		end
	end
endmodule




/* if(tetris_tmp[16][0] > tetris_tmp[15][0]) begin
			highest_pos_tmp1[0] <= 16;
		end
		else if(tetris_tmp[15][0] > tetris_tmp[14][0]) begin
			highest_pos_tmp1[0] <= 15;
		end
		else if(tetris_tmp[14][0] > tetris_tmp[13][0]) begin
			highest_pos_tmp1[0] <= 14;
		end
		else if(tetris_tmp[13][0] > tetris_tmp[12][0]) begin
			highest_pos_tmp1[0] <= 13;
		end
		else if(tetris_tmp[12][0] > tetris_tmp[11][0]) begin
			highest_pos_tmp1[0] <= 12;
		end
		else if(tetris_tmp[11][0] > tetris_tmp[10][0]) begin
			highest_pos_tmp1[0] <= 11;
		end
		else if(tetris_tmp[10][0] > tetris_tmp[9][0]) begin
			highest_pos_tmp1[0] <= 10;
		end
		else if(tetris_tmp[9][0] > tetris_tmp[8][0]) begin
			highest_pos_tmp1[0] <= 9;
		end
		else if(tetris_tmp[8][0]) begin
			highest_pos_tmp1[0] <= 8;
		end
		else begin
			highest_pos_tmp1[0] <= 0;
		end


		if(tetris_tmp[7][0] > tetris_tmp[6][0]) begin
			highest_pos_tmp2[0] <= 7;
		end
		else if(tetris_tmp[6][0] > tetris_tmp[5][0]) begin
			highest_pos_tmp2[0] <= 6;
		end
		else if(tetris_tmp[5][0] > tetris_tmp[4][0]) begin
			highest_pos_tmp2[0] <= 5;
		end
		else if(tetris_tmp[4][0] > tetris_tmp[3][0]) begin
			highest_pos_tmp2[0] <= 4;
		end
		else if(tetris_tmp[3][0] > tetris_tmp[2][0]) begin
			highest_pos_tmp2[0] <= 3;
		end
		else if(tetris_tmp[2][0] > tetris_tmp[1][0]) begin
			highest_pos_tmp2[0] <= 2;
		end
		else if(tetris_tmp[1][0] > tetris_tmp[0][0]) begin
			highest_pos_tmp2[0] <= 1;
		end
		else begin
			highest_pos_tmp2[0] <= 0;
		end

		if(highest_pos_tmp1[0] > highest_pos_tmp2[0]) begin
			highest_pos[0] <= highest_pos_tmp1[0];
		end
		else begin
			highest_pos[0] <= highest_pos_tmp2[0];
		end */




/* assign te[0][0][0] = 0;
assign te[0][0][1] = 0;
assign te[0][1][0] = 1;
assign te[0][1][1] = 0;
assign te[0][2][0] = 0;
assign te[0][2][1] = 1;
assign te[0][3][0] = 1;
assign te[0][3][1] = 1;

assign te[1][0][0] = 0;
assign te[1][0][1] = 0;
assign te[1][1][0] = 0;
assign te[1][1][1] = 1;
assign te[1][2][0] = 0;
assign te[1][2][1] = 2;
assign te[1][3][0] = 0;
assign te[1][3][1] = 3;

assign te[2][0][0] = 0;
assign te[2][0][1] = 0;
assign te[2][1][0] = 1;
assign te[2][1][1] = 0;
assign te[2][2][0] = 2;
assign te[2][2][1] = 0;
assign te[2][3][0] = 3;
assign te[2][3][1] = 0;

assign te[3][0][0] = 1;
assign te[3][0][1] = 0;
assign te[3][1][0] = 1;
assign te[3][1][1] = 1;
assign te[3][2][0] = 1;
assign te[3][2][1] = 2;
assign te[3][3][0] = 0;
assign te[3][3][1] = 2;

assign te[4][0][0] = 0;
assign te[4][0][1] = 0;
assign te[4][1][0] = 0;
assign te[4][1][1] = 1;
assign te[4][2][0] = 1;
assign te[4][2][1] = 1;
assign te[4][3][0] = 2;
assign te[4][3][1] = 1;

assign te[5][0][0] = 0;
assign te[5][0][1] = 0;
assign te[5][1][0] = 0;
assign te[5][1][1] = 1;
assign te[5][2][0] = 0;
assign te[5][2][1] = 2;
assign te[5][3][0] = 1;
assign te[5][3][1] = 0;

assign te[6][0][0] = 0;
assign te[6][0][1] = 1;
assign te[6][1][0] = 0;
assign te[6][1][1] = 2;
assign te[6][2][0] = 1;
assign te[6][2][1] = 0;
assign te[6][3][0] = 1;
assign te[6][3][1] = 1;

assign te[7][0][0] = 0;
assign te[7][0][1] = 0;
assign te[7][1][0] = 1;
assign te[7][1][1] = 0;
assign te[7][2][0] = 1;
assign te[7][2][1] = 1;
assign te[7][3][0] = 2;
assign te[7][3][1] = 1; */