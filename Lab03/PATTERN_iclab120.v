/**************************************************************************/
// Copyright (c) 2024, OASIS Lab
// MODULE: PATTERN
// FILE NAME: PATTERN.v
// VERSRION: 1.0
// DATE: August 15, 2024
// AUTHOR: Yu-Hsuan Hsu, NYCU IEE
// DESCRIPTION: ICLAB2024FALL / LAB3 / PATTERN
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/

`ifdef RTL
    `define CYCLE_TIME 3.6
`endif
`ifdef GATE
    `define CYCLE_TIME 3.6
`endif

module PATTERN(
	//OUTPUT
	rst_n,
	clk,
	in_valid,
	tetrominoes,
	position,
	//INPUT
	tetris_valid,
	score_valid,
	fail,
	score,
	tetris
);

//---------------------------------------------------------------------
//   PORT DECLARATION          
//---------------------------------------------------------------------
output reg			rst_n, clk, in_valid;
output reg	[2:0]	tetrominoes;
output reg  [2:0]	position;
input 				tetris_valid, score_valid, fail;
input 		[3:0]	score;
input		[71:0]	tetris;

//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------
integer total_latency, latency, in_read, out_file, i_pat, PAT_NUM, i, j, k, tmp, tmp1, golden_score, golden_fail, tetrominoes_tmp, position_tmp, height_tmp, m, n, p, q;
integer golden_tetris[16][6] , te[8][4][2];
real CYCLE = `CYCLE_TIME;
			
//---------------------------------------------------------------------
//   REG & WIRE DECLARATION
//---------------------------------------------------------------------
reg score_valid_tmp, tetris_valid_tmp;

//---------------------------------------------------------------------
//  CLOCK
//---------------------------------------------------------------------
always #(CYCLE/2.0) clk = ~clk;
//---------------------------------------------------------------------
//  SIMULATION
//---------------------------------------------------------------------

// execute once
initial begin
    set_tetetrominoes;
    in_read = $fopen("../00_TESTBED/input.txt", "r");
    out_file = $fopen("../00_TESTBED/out.txt", "w");
    reset_signal_task;
    total_latency = 0;
    $fscanf(in_read, "%d", PAT_NUM);
    for (i_pat = 0; i_pat < PAT_NUM; i_pat = i_pat + 1) begin
        reset_golden_task;
        input_task;
		total_latency = total_latency + latency;
        $display("PASS PATTERN NO.%4d", i_pat);
    end
    $fclose(in_read);
    $fclose(out_file);
    YOU_PASS_task;
end

// reset signal
task reset_signal_task; begin
    // initialize all signals
    rst_n = 'b1;
    in_valid = 'b0;
	score_valid_tmp = 'b0;
	tetris_valid_tmp = 'b0;
    tetrominoes = 'bx;
    position = 'bx;
	force clk =0;
	#(0.5); rst_n= 1'b0;
	#(100);

    // SPEC-4: All output signals should be reset.
    if(tetris_valid !== 0 || score_valid !== 0 || fail  !== 0 || score !== 0 || tetris !== 0) begin
        $display("                    SPEC-4 FAIL                   ");
        $finish;
    end
	#(10); rst_n= 1'b1;
	#(CYCLE); release clk;
end
endtask

task reset_golden_task; begin
    golden_score = 0;
    golden_fail = 0;
    for(p = 0; p < 16; p = p + 1) begin
        for(q = 0; q < 6; q = q + 1) begin
            golden_tetris[p][q] = 0;
        end
    end  
end
endtask

//
task set_tetetrominoes; begin
    te[0][0][0] = 0;
    te[0][0][1] = 0;
    te[0][1][0] = 1;
    te[0][1][1] = 0;
    te[0][2][0] = 0;
    te[0][2][1] = 1;
    te[0][3][0] = 1;
    te[0][3][1] = 1;

    te[1][0][0] = 0;
    te[1][0][1] = 0;
    te[1][1][0] = 0;
    te[1][1][1] = 1;
    te[1][2][0] = 0;
    te[1][2][1] = 2;
    te[1][3][0] = 0;
    te[1][3][1] = 3;

    te[2][0][0] = 0;
    te[2][0][1] = 0;
    te[2][1][0] = 1;
    te[2][1][1] = 0;
    te[2][2][0] = 2;
    te[2][2][1] = 0;
    te[2][3][0] = 3;
    te[2][3][1] = 0;

    te[3][0][0] = 1;
    te[3][0][1] = 0;
    te[3][1][0] = 1;
    te[3][1][1] = 1;
    te[3][2][0] = 1;
    te[3][2][1] = 2;
    te[3][3][0] = 0;
    te[3][3][1] = 2;

    te[4][0][0] = 0;
    te[4][0][1] = 0;
    te[4][1][0] = 0;
    te[4][1][1] = 1;
    te[4][2][0] = 1;
    te[4][2][1] = 1;
    te[4][3][0] = 2;
    te[4][3][1] = 1;

    te[5][0][0] = 0;
    te[5][0][1] = 0;
    te[5][1][0] = 0;
    te[5][1][1] = 1;
    te[5][2][0] = 0;
    te[5][2][1] = 2;
    te[5][3][0] = 1;
    te[5][3][1] = 0;

    te[6][0][0] = 0;
    te[6][0][1] = 1;
    te[6][1][0] = 0;
    te[6][1][1] = 2;
    te[6][2][0] = 1;
    te[6][2][1] = 0;
    te[6][3][0] = 1;
    te[6][3][1] = 1;

    te[7][0][0] = 0;
    te[7][0][1] = 0;
    te[7][1][0] = 1;
    te[7][1][1] = 0;
    te[7][2][0] = 1;
    te[7][2][1] = 1;
    te[7][3][0] = 2;
    te[7][3][1] = 1;
end
endtask

task input_task; begin
    $fscanf(in_read, "%d", tmp);
	for(i = 0; i < 16; i = i + 1) begin
        if(golden_fail === 1) begin
            total_latency = total_latency + latency;
            $display("PASS PATTERN NO.%4d", i_pat);
            reset_golden_task;
            i_pat = i_pat + 1;
            if(i_pat == PAT_NUM) begin
                YOU_PASS_task;
            end
            for(j = 0; j < 16 - i; j = j + 1) begin
                $fscanf(in_read, "%d %d", tmp, tmp1);
            end
            $fscanf(in_read, "%d", tmp);
            i = 0;
        end
        in_valid = 1'b1;
        $fscanf(in_read, "%d %d", tetrominoes, position);
        tetrominoes_tmp = tetrominoes;
        position_tmp = position;
        latency = 0;
        @(negedge clk);
        while(score_valid !== 1) begin
            if(latency === 1000) begin
                $display("                    SPEC-6 FAIL                   ");
                $finish;
            end
		    latency = latency + 1;
            in_valid = 1'b0;
            tetrominoes = 'bx;
            position = 'bx;
            @(negedge clk);
        end
        total_latency = total_latency + latency;
        check_ans_task;
        if(golden_fail) begin
            repeat(1) @(negedge clk);
        end
        else begin
            repeat(4) @(negedge clk);
        end
	end
end
endtask

//SPEC-5: The signals score, fail, and tetris_valid must be 0 when the score_valid is low. And the tetris must be reset when tetris_valid is low.
always @(negedge clk) begin
    if((score_valid === 0 && (score !== 0 || fail !== 0 || tetris_valid !== 0)) || (tetris_valid === 0 && tetris !== 0)) begin
        $display("                    SPEC-5 FAIL                   ");
        $finish;
    end
end

// SPEC-6: The latency of each inputs set is limited in 1000 cycles.
/* task wait_score_valid_task; begin
    latency = 0;
    while(score_valid !== 1'b1) begin
        if(latency === 1000) begin
            $display("                    SPEC-6 FAIL                   ");
            $finish;
        end
		latency = latency + 1;
        @(negedge clk);
    end
	total_latency = total_latency + latency;
end
endtask */


//SPEC-7: The score and fail should be correct when score_valid is high. The tetris must be correct when the tetris_valid is high.
task check_ans_task; begin
    height_tmp = 11;
    while(golden_tetris[height_tmp + te[tetrominoes_tmp][0][1]][position_tmp + te[tetrominoes_tmp][0][0]] === 0
      &&  golden_tetris[height_tmp + te[tetrominoes_tmp][1][1]][position_tmp + te[tetrominoes_tmp][1][0]] === 0
      &&  golden_tetris[height_tmp + te[tetrominoes_tmp][2][1]][position_tmp + te[tetrominoes_tmp][2][0]] === 0
      &&  golden_tetris[height_tmp + te[tetrominoes_tmp][3][1]][position_tmp + te[tetrominoes_tmp][3][0]] === 0) begin
        height_tmp = height_tmp - 1;
    end
    height_tmp = height_tmp + 1;
    golden_tetris[height_tmp + te[tetrominoes_tmp][0][1]][position_tmp + te[tetrominoes_tmp][0][0]] = 1;
    golden_tetris[height_tmp + te[tetrominoes_tmp][1][1]][position_tmp + te[tetrominoes_tmp][1][0]] = 1;
    golden_tetris[height_tmp + te[tetrominoes_tmp][2][1]][position_tmp + te[tetrominoes_tmp][2][0]] = 1;
    golden_tetris[height_tmp + te[tetrominoes_tmp][3][1]][position_tmp + te[tetrominoes_tmp][3][0]] = 1;

    height_tmp = 0;
    for(m = 0; m < 16; m = m + 1) begin
        while(golden_tetris[m + height_tmp][0] === 1 && golden_tetris[m + height_tmp][1] === 1 && golden_tetris[m + height_tmp][2] === 1 && golden_tetris[m + height_tmp][3] === 1 && golden_tetris[m + height_tmp][4] === 1 && golden_tetris[m + height_tmp][5] === 1) begin
            golden_tetris[m + height_tmp][0] = 0;
            golden_tetris[m + height_tmp][1] = 0;
            golden_tetris[m + height_tmp][2] = 0;
            golden_tetris[m + height_tmp][3] = 0;
            golden_tetris[m + height_tmp][4] = 0;
            golden_tetris[m + height_tmp][5] = 0;
            golden_score = golden_score + 1;
            height_tmp = height_tmp + 1;
        end
        if(height_tmp !== 0) begin
            for(k = m; k < 16 - height_tmp; k = k + 1) begin
                for(n = 0; n < 6; n = n + 1) begin
                    golden_tetris[k][n] = golden_tetris[k + height_tmp][n];
                    golden_tetris[k + height_tmp][n] = 0;
                    //$display("%d %d %d %d %d %d",golden_tetris[m+ height_tmp][0],golden_tetris[m+ height_tmp][1],golden_tetris[m+ height_tmp][2],golden_tetris[m+ height_tmp][3],golden_tetris[m+ height_tmp][4],golden_tetris[m+ height_tmp][5]);
                end
            end
        end
        height_tmp = 0;
    end

    for(m = 12; m < 16; m = m + 1) begin
        for(n = 0; n < 6; n = n + 1) begin
            if(golden_tetris[m][n] === 1) begin
                golden_fail = 1;
                break;
            end
        end
        if(golden_tetris[m][n] === 1) begin
            break;
        end
    end

    /* $display("golden\n");
    for(m = 15; m >= 0; m = m - 1) begin
        $fdisplay(out_file, "%d %d %d %d %d %d\n",  golden_tetris[m][0],  golden_tetris[m][1],  golden_tetris[m][2],  golden_tetris[m][3],  golden_tetris[m][4],  golden_tetris[m][5]);
    end

    $display("true\n");
    for(m = 11; m >= 0; m = m - 1) begin
        $fdisplay(out_file, "%d %d %d %d %d %d\n",  tetris[6 * m],  tetris[6 * m + 1],  tetris[6 * m + 2],  tetris[6 * m + 3],  tetris[6 * m + 4],  tetris[6 * m + 5]);
    end */
    
    if(score_valid === 1 && (score !== golden_score || fail !== golden_fail)) begin
        $display("                    SPEC-7 FAIL                   ");
        $finish;
    end
    else if(tetris_valid === 1) begin
        for(m = 0; m < 12; m = m + 1) begin
            for(n = 0; n < 6; n = n + 1) begin
                if(tetris[m * 6 + n] !== golden_tetris[m][n]) begin
                    $display("                    SPEC-7 FAIL                   ");
                    $finish;
                end
            end
        end
    end
    //@(negedge clk) golden_score = 0;
end
endtask

//SPEC-8: The score_valid and the tetris_valid cannot be high for more than 1 cycle.
always @(negedge clk) begin
	score_valid_tmp <= score_valid;
	tetris_valid_tmp <= tetris_valid;
    if((score_valid === 1 && score_valid_tmp === 1) || (tetris_valid === 1 && tetris_valid_tmp === 1)) begin
        $display("                    SPEC-8 FAIL                   ");
        $finish;
    end
end


task YOU_PASS_task; begin
	$display("                  Congratulations!               ");
	$display("              execution cycles = %7d", total_latency);
	$display("              clock period = %4fns", CYCLE);
    $finish;
end endtask


endmodule
// for spec check
// $display("                    SPEC-4 FAIL                   ");
// $display("                    SPEC-5 FAIL                   ");
// $display("                    SPEC-6 FAIL                   ");
// $display("                    SPEC-7 FAIL                   ");
// $display("                    SPEC-8 FAIL                   ");
// for successful design
// $display("                  Congratulations!               ");
// $display("              execution cycles = %7d", total_latency);
// $display("              clock period = %4fns", CYCLE);