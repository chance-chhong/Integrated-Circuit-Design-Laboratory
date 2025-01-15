`include "../00_TESTBED/pseudo_DRAM.svp"
`include "Usertype.sv"

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;
/* //================================================================
// parameters & integer
//================================================================
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";
parameter MAX_CYCLE=1000;

//================================================================
// wire & registers 
//================================================================
logic [7:0] golden_DRAM [((65536+8*256)-1):(65536+0)];   */




//======================================
//      PARAMETERS & VARIABLES
//======================================
//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
// Can be modified by user
integer   TOTAL_PATNUM = 1000;
// -------------------------------------
// [Mode]
//      0 : generate the regular dram.dat
//      1 : validate design
integer   MODE = 1;
// -------------------------------------
integer   SEED = 9999;
parameter DEBUG = 0;
parameter DRAMDAT_TO_GENERATED = "../00_TESTBED/DRAM/dram.dat";
parameter DRAMDAT_FROM_DRAM = "../00_TESTBED/DRAM/dram.dat";

//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
parameter CYCLE = 4.2;
parameter DELAY = 1000;
parameter OUTNUM = 1;

// PATTERN CONTROL
integer pat;
integer exe_lat;
integer tot_lat;

// String control
// Should use %0s
reg[9*8:1]  reset_color       = "\033[1;0m";
reg[10*8:1] txt_black_prefix  = "\033[1;30m";
reg[10*8:1] txt_red_prefix    = "\033[1;31m";
reg[10*8:1] txt_green_prefix  = "\033[1;32m";
reg[10*8:1] txt_yellow_prefix = "\033[1;33m";
reg[10*8:1] txt_blue_prefix   = "\033[1;34m";

reg[10*8:1] bkg_black_prefix  = "\033[40;1m";
reg[10*8:1] bkg_red_prefix    = "\033[41;1m";
reg[10*8:1] bkg_green_prefix  = "\033[42;1m";
reg[10*8:1] bkg_yellow_prefix = "\033[43;1m";
reg[10*8:1] bkg_blue_prefix   = "\033[44;1m";
reg[10*8:1] bkg_white_prefix  = "\033[47;1m";


//======================================
//      DATA MODEL
//======================================
// Debugging file
parameter IMAGE_ORIGINAL_FILE = "image_original.txt";
parameter IMAGE_ADJUSTED_FILE = "image_adjusted.txt";
parameter AUTO_FOCUS_FILE = "auto_focus.txt";
parameter AUTO_EXPOSURE_FILE = "auto_exposure.txt";
// Inputs
parameter NUM_OF_DATA = 512;
parameter SIZE_OF_DATA = 4;
parameter BITS_OF_ELEMENT = 8;

parameter MAX_OF_INDEX = 4096;
parameter VALID_WAIT_CYCLE = 4;


parameter START_OF_DRAM_ADDRESS = 65536;


//Data
class random_act;
    randc Action act_id;
    randc Formula_Type formula_id;
    randc Mode mode_id;
    randc Month month_id;
    randc Day day_id;
    randc Data_No data_id;
    randc Index index_id[0:3];
    randc logic signed [11:0] variation_id[0:3];
    function new (int seed);
        this.srandom(seed);  
    endfunction
    constraint range{
        act_id inside{Index_Check, Update, Check_Valid_Date};
        formula_id inside{Formula_A, Formula_B, Formula_C, Formula_D, Formula_E, Formula_F, Formula_G, Formula_H};
        mode_id inside{Insensitive, Normal, Sensitive};
        month_id inside{[1:12]};
        (month_id == 1 || month_id == 3 || month_id == 5 || month_id == 7 || month_id == 8 || month_id == 10 || month_id == 12 )->day_id inside{[1:31]};
        (month_id == 4 || month_id == 6 || month_id == 9 || month_id == 11)->day_id inside{[1:30]};
        (month_id == 2)->day_id inside{[1:28]};
    }
endclass

random_act rand_act = new(SEED);

Warn_Msg warn_msg;
logic complete;

Warn_Msg _yourWarn_msg;
logic _yourComplete;

parameter threshold_type threshold_table[0:7] = '{
    '{2047,1023,0,511},
    '{800,400,0,200},
    '{2047,1023,0,511},
    '{3,2,0,1},
    '{3,2,0,1},
    '{800,400,0,200},
    '{800,400,0,200},
    '{800,400,0,200}
};

parameter string warn_type[0:3] = {"No_Warn", "Date_Warn", "Risk_Warn", "Data_Warn"};
parameter string act_type[0:2] = {"Index_Check", "Update", "Check_Valid_Date"};

/* class random_formula;
    rand Action act_id;
    function new (int seed);
        this.srandom(seed);  
    endfunction
    constraint range{
        act_id inside{Index_Check, Update, Check_Valid_Date};
    }
endclass

random_act rand_act = new(1);
Action _act;
 */


Data_Dir Stock[0:255];

//======================================
//              MAIN
//======================================
initial begin
    exe_task;
    
end
initial begin
    forever @(posedge clk) begin
        if(inf.out_valid === 1 && (inf.sel_action_valid === 1 || inf.formula_valid === 1 || inf.mode_valid === 1 || inf.date_valid === 1 || inf.data_no_valid === 1 || inf.index_valid === 1))begin
        $display("in_valid out_valid overlap");
        $finish;
        end
    end
end

//======================================
//              TASKS
//======================================
task exe_task; begin
    case(MODE)
        'd0: generate_dram_task;
        'd1: validate_design_task;
        default: begin
            $display("[ERROR] [PARAMETER] Mode (%-d) isn't valid...", MODE);
            $finish;
        end
    endcase
end endtask

task generate_dram_task;
    integer file;
    integer _data;
    integer _col;
    random_act rand_act = new(SEED+1);
begin
    $display("[Info] Start to generate dram.dat");
    file = $fopen(DRAMDAT_TO_GENERATED, "w");
    if (file == 0) begin
        $display("[ERROR] [FILE] The file (%0s) can't be opened", DRAMDAT_TO_GENERATED);
        $finish;
    end
    for(_data=0 ; _data<NUM_OF_DATA ; _data=_data+1) begin
            $fwrite(file, "@%-5h\n", START_OF_DRAM_ADDRESS+_data*SIZE_OF_DATA);
            if(_data % 2 == 0) rand_act.randomize();
        for(_col=0 ; _col<SIZE_OF_DATA ; _col=_col+1) begin
            if(_col == 0) begin
                if(_data % 2 == 0)
                    $fwrite(file, "%02h ", rand_act.day_id);
                else
                    $fwrite(file, "%02h ", rand_act.month_id);
            end
            else $fwrite(file, "%02h ", {$random(SEED)} % 2**BITS_OF_ELEMENT); // regular
        end
            $fwrite(file, "\n");
        end
    end
    $fclose(file);
    $finish;
endtask

task validate_design_task; begin
    reset_task;
    load_data_from_dram;
    for(pat=0 ; pat<TOTAL_PATNUM ; pat=pat+1) begin
        input_task;
        cal_task;
        //$display("%d\n",warn_msg);
        wait_task;
        check_task;
        // Print Pass Info and accumulate the total latency
        $display("%0sPASS PATTERN NO.%4d %0sCycles: %3d%0s Act: %4s%0s",txt_blue_prefix, pat, txt_green_prefix, exe_lat, txt_yellow_prefix, act_type[rand_act.act_id], reset_color);
    end
    pass_task;
end endtask


task reset_task; begin
    force clk = 0;
    inf.rst_n = 1;

    inf.sel_action_valid = 0;
    inf.formula_valid = 0;
    inf.mode_valid = 0;
    inf.date_valid = 0;
    inf.data_no_valid = 0;
    inf.index_valid = 0;
    inf.D = 'bx;

    tot_lat = 0;

    repeat(5) #(CYCLE/2.0) inf.rst_n = 0;
    repeat(5) #(CYCLE/2.0) inf.rst_n = 1;
    if(inf.out_valid !== 0 || inf.complete !== 0 || inf.warn_msg !== 0 ||
       inf.AR_VALID !== 0 || inf.R_READY !== 0 || inf.AW_VALID !== 0 ||
       inf.W_VALID !== 0 || inf.B_READY !== 0 || inf.AR_ADDR !== 0 || 
       inf.AW_ADDR !== 0 || inf.W_DATA !== 0) begin
        if (inf.out_valid !== 0) $display("out_valid should be 0");
        if (inf.complete !== 0) $display("complete should be 0");
        if (inf.warn_msg !== 0) $display("warn_msg should be 0");
        if (inf.AR_VALID !== 0) $display("AR_VALID should be 0");
        if (inf.R_READY !== 0) $display("R_READY should be 0");
        if (inf.AW_VALID !== 0) $display("AW_VALID should be 0");
        if (inf.W_VALID !== 0) $display("W_VALID should be 0");
        if (inf.B_READY !== 0) $display("B_READY should be 0");
        if (inf.AR_ADDR !== 0) $display("AR_ADDR should be 0");
        if (inf.AW_ADDR !== 0) $display("AW_ADDR should be 0");
        if (inf.W_DATA !== 0) $display("W_DATA should be 0");
        $display("[ERROR] [Reset] Output signal should be 0 at %-12d ps  ", $time*1000);
        repeat(5) #(CYCLE);
        $finish;
    end
    #(CYCLE/2.0) release clk;
    repeat(1) @(negedge clk);
end endtask

task load_data_from_dram;
    integer file;
    integer status;
    string v;
    logic [7:0] a, b, c, d;
    integer _cnt;
    integer stock_idx;
begin
    file = $fopen(DRAMDAT_FROM_DRAM, "r");
    if (file == 0) begin
        $display("[ERROR] [FILE] The file (%0s) can't be opened", DRAMDAT_FROM_DRAM);
        $finish;
    end
    _cnt = 0;
    stock_idx = 0;
    while(!$feof(file))begin
        stock_idx = _cnt/2;
        if(stock_idx == 256) return;
        // Address
        status = $fscanf(file, "%s", v);
        //$display("%s", v);
        // Stock
        status = $fscanf(file, "%2h %2h %2h %2h", a, b, c, d);
        //$display("%d %d %d %d %d\n",a,b,c,d,stock_idx);
        
        if(_cnt%2 == 0) begin
            Stock[stock_idx].Index_C = {d,c[7:4]};
            Stock[stock_idx].Index_D = {c[3:0],b};
            Stock[stock_idx].D = a;
        end
        else begin
            Stock[stock_idx].Index_A = {d,c[7:4]};
            Stock[stock_idx].Index_B = {c[3:0],b};
            Stock[stock_idx].M = a;
        end
        _cnt = _cnt + 1;
    end
    $fclose(file);
end endtask

task input_task; 
    integer wait_cycle;
    logic [11:0] index;
    logic signed [11:0] variation;
    integer variation_offset = MAX_OF_INDEX / 2;
begin

    warn_msg = No_Warn;
    complete = 0;
    
    rand_act.randomize();
    
    

    wait_cycle = {$random(SEED)} % VALID_WAIT_CYCLE;
    repeat(wait_cycle) @(negedge clk);


    inf.sel_action_valid = 1;
    inf.D.d_act[0] = rand_act.act_id;
    repeat(1) @(negedge clk);
    inf.sel_action_valid = 0;
    inf.D = 'bx;
    wait_cycle = {$random(SEED)} % VALID_WAIT_CYCLE;
    repeat(wait_cycle) @(negedge clk);


    if(rand_act.act_id == Index_Check) begin
        inf.formula_valid = 1;
        inf.D.d_formula[0] = rand_act.formula_id;
        repeat(1) @(negedge clk);
        inf.formula_valid = 0;
        inf.D = 'bx;
        wait_cycle = {$random(SEED)} % VALID_WAIT_CYCLE;
        repeat(wait_cycle) @(negedge clk);

        inf.mode_valid = 1;
        inf.D.d_mode[0] = rand_act.mode_id;
        repeat(1) @(negedge clk);
        inf.mode_valid = 0;
        inf.D = 'bx;
        wait_cycle = {$random(SEED)} % VALID_WAIT_CYCLE;
        repeat(wait_cycle) @(negedge clk);
    end

    inf.date_valid = 1;
    inf.D.d_date[0].M = rand_act.month_id;
    inf.D.d_date[0].D = rand_act.day_id;
    repeat(1) @(negedge clk);
    inf.date_valid = 0;
    inf.D = 'bx;
    wait_cycle = {$random(SEED)} % VALID_WAIT_CYCLE;
    repeat(wait_cycle) @(negedge clk);


    inf.data_no_valid = 1;
    inf.D.d_data_no[0] = rand_act.data_id;
    repeat(1) @(negedge clk);
    inf.data_no_valid = 0;
    inf.D = 'bx;
    wait_cycle = {$random(SEED)} % VALID_WAIT_CYCLE;
    if(rand_act.act_id != Check_Valid_Date)
        repeat(wait_cycle) @(negedge clk);


    if(rand_act.act_id == Index_Check) begin
        inf.index_valid = 1;
        inf.D.d_index[0] = rand_act.index_id[0];
        repeat(1) @(negedge clk);
        inf.index_valid = 0;
        inf.D = 'bx;
        wait_cycle = {$random(SEED)} % VALID_WAIT_CYCLE;
        repeat(wait_cycle) @(negedge clk);

        inf.index_valid = 1;
        inf.D.d_index[0] = rand_act.index_id[1];
        repeat(1) @(negedge clk);
        inf.index_valid = 0;
        inf.D = 'bx;
        wait_cycle = {$random(SEED)} % VALID_WAIT_CYCLE;
        repeat(wait_cycle) @(negedge clk);

        inf.index_valid = 1;
        inf.D.d_index[0] = rand_act.index_id[2];
        repeat(1) @(negedge clk);
        inf.index_valid = 0;
        inf.D = 'bx;
        wait_cycle = {$random(SEED)} % VALID_WAIT_CYCLE;
        repeat(wait_cycle) @(negedge clk);

        inf.index_valid = 1;
        inf.D.d_index[0] = rand_act.index_id[3];
        repeat(1) @(negedge clk);
        inf.index_valid = 0;
        inf.D = 'bx;

    end
    else if(rand_act.act_id == Update) begin
        inf.index_valid = 1;
        inf.D.d_index[0] = rand_act.variation_id[0];
        repeat(1) @(negedge clk);
        inf.index_valid = 0;
        inf.D = 'bx;
        wait_cycle = {$random(SEED)} % VALID_WAIT_CYCLE;
        repeat(wait_cycle) @(negedge clk);

        inf.index_valid = 1;
        inf.D.d_index[0] = rand_act.variation_id[1];
        repeat(1) @(negedge clk);
        inf.index_valid = 0;
        inf.D = 'bx;
        wait_cycle = {$random(SEED)} % VALID_WAIT_CYCLE;
        repeat(wait_cycle) @(negedge clk);

        inf.index_valid = 1;
        inf.D.d_index[0] = rand_act.variation_id[2];
        repeat(1) @(negedge clk);
        inf.index_valid = 0;
        inf.D = 'bx;
        wait_cycle = {$random(SEED)} % VALID_WAIT_CYCLE;
        repeat(wait_cycle) @(negedge clk);

        inf.index_valid = 1;
        inf.D.d_index[0] = rand_act.variation_id[3];
        repeat(1) @(negedge clk);
        inf.index_valid = 0;
        inf.D = 'bx;
        
    end
end endtask

task cal_task;
    integer size;
begin
    //$display("%d %d %d\n",threshold_table[Formula_D][Insensitive],threshold_table[Formula_D][Normal],threshold_table[Formula_D][Sensitive]);
    //$display("%d",rand_act.act_id);
    case(rand_act.act_id)
        Index_Check: Index_Check_Act;
        Update: Update_Act;
        Check_Valid_Date: Check_Valid_Date_Act;
        default: begin
            $display("[ERROR] [CAL] The mode (%2d) is no valid", rand_act.act_id);
            $finish;
        end
    endcase
    /* if(DEBUG) begin
        clear_dump_file;
        dump_original_image;
        dump_adjusted_image;
        dump_focus;
        dump_exposure;
    end */
end endtask

task Index_Check_Act;
    logic [15:0] idx_tmp;
begin
    //today: rand_act, early: Stock[rand_act.data_id]
    //$display("%d %d %d\n",Stock[rand_act.data_id].M, Stock[rand_act.data_id].D, rand_act.data_id);
    //Date
    if((rand_act.month_id < Stock[rand_act.data_id].M) || ((rand_act.month_id == Stock[rand_act.data_id].M) && (rand_act.day_id < Stock[rand_act.data_id].D))) begin
        warn_msg = Date_Warn;
        //$display("%d %d\n",Stock[rand_act.data_id].M, Stock[rand_act.data_id].D);
        return;
    end
    
    //Formula

    case(rand_act.formula_id)
        Formula_A: begin
            idx_tmp = (Stock[rand_act.data_id].Index_A + Stock[rand_act.data_id].Index_B + Stock[rand_act.data_id].Index_C + Stock[rand_act.data_id].Index_D) >> 2;
            if(idx_tmp >= threshold_table[Formula_A][rand_act.mode_id]) begin
                warn_msg = Risk_Warn;
            end
        end
        Formula_B: begin
            idx_tmp = max(Stock[rand_act.data_id].Index_A,Stock[rand_act.data_id].Index_B,Stock[rand_act.data_id].Index_C,Stock[rand_act.data_id].Index_D) - min(Stock[rand_act.data_id].Index_A,Stock[rand_act.data_id].Index_B,Stock[rand_act.data_id].Index_C,Stock[rand_act.data_id].Index_D);
            if(idx_tmp >= threshold_table[Formula_B][rand_act.mode_id]) begin
                warn_msg = Risk_Warn;
            end
        end
        Formula_C: begin
            idx_tmp = min(Stock[rand_act.data_id].Index_A,Stock[rand_act.data_id].Index_B,Stock[rand_act.data_id].Index_C,Stock[rand_act.data_id].Index_D);
            if(idx_tmp >= threshold_table[Formula_C][rand_act.mode_id]) begin
                //$display("%d %d\n", idx_tmp, threshold_table[Formula_C][rand_act.mode_id]);
                warn_msg = Risk_Warn;
            end
        end
        Formula_D: begin
            idx_tmp = plus1111(Stock[rand_act.data_id].Index_A,Stock[rand_act.data_id].Index_B,Stock[rand_act.data_id].Index_C,Stock[rand_act.data_id].Index_D);
            if(idx_tmp >= threshold_table[Formula_D][rand_act.mode_id]) begin
                warn_msg = Risk_Warn;
            end
        end
        Formula_E: begin
            idx_tmp = plus1111(Stock[rand_act.data_id].Index_A,Stock[rand_act.data_id].Index_B,Stock[rand_act.data_id].Index_C,Stock[rand_act.data_id].Index_D,rand_act.index_id[0],rand_act.index_id[1],rand_act.index_id[2],rand_act.index_id[3]);
            if(idx_tmp >= threshold_table[Formula_E][rand_act.mode_id]) begin
                warn_msg = Risk_Warn;
            end
        end
        Formula_F: begin
            idx_tmp = plus_min3(abs(Stock[rand_act.data_id].Index_A,rand_act.index_id[0]),abs(Stock[rand_act.data_id].Index_B,rand_act.index_id[1]),abs(Stock[rand_act.data_id].Index_C,rand_act.index_id[2]),abs(Stock[rand_act.data_id].Index_D,rand_act.index_id[3]));
            if(idx_tmp >= threshold_table[Formula_F][rand_act.mode_id]) begin
                warn_msg = Risk_Warn;
            end
        end
        Formula_G: begin
            idx_tmp = plus_min3_navg(abs(Stock[rand_act.data_id].Index_A,rand_act.index_id[0]),abs(Stock[rand_act.data_id].Index_B,rand_act.index_id[1]),abs(Stock[rand_act.data_id].Index_C,rand_act.index_id[2]),abs(Stock[rand_act.data_id].Index_D,rand_act.index_id[3]));
            if(idx_tmp >= threshold_table[Formula_G][rand_act.mode_id]) begin
                warn_msg = Risk_Warn;
                //$display("%d %d\n", idx_tmp, threshold_table[Formula_G][rand_act.mode_id]);
            end
        end
        Formula_H: begin
            idx_tmp = (abs(Stock[rand_act.data_id].Index_A,rand_act.index_id[0]) + abs(Stock[rand_act.data_id].Index_B,rand_act.index_id[1]) + abs(Stock[rand_act.data_id].Index_C,rand_act.index_id[2]) + abs(Stock[rand_act.data_id].Index_D,rand_act.index_id[3])) >> 2;
            if(idx_tmp >= threshold_table[Formula_H][rand_act.mode_id]) begin
                warn_msg = Risk_Warn;
            end
        end
    endcase


end endtask





task Update_Act;
    Index idx_tmp;
    logic [12:0] large_idx;
begin
    //update date
    Stock[rand_act.data_id].M = rand_act.month_id;
    Stock[rand_act.data_id].D = rand_act.day_id;

    //update data
    if(rand_act.variation_id[0][11]) begin
        idx_tmp = ~rand_act.variation_id[0] + 1;
        if(Stock[rand_act.data_id].Index_A < idx_tmp) begin
            Stock[rand_act.data_id].Index_A = 0;
            warn_msg = Data_Warn;
        end
        else begin
            Stock[rand_act.data_id].Index_A = Stock[rand_act.data_id].Index_A - idx_tmp;
        end
    end
    else begin
        large_idx = Stock[rand_act.data_id].Index_A + rand_act.variation_id[0];
        if(large_idx > 4095) begin
            Stock[rand_act.data_id].Index_A = 4095;
            warn_msg = Data_Warn;
        end
        else begin
            Stock[rand_act.data_id].Index_A = Stock[rand_act.data_id].Index_A + rand_act.variation_id[0];
        end
    end

    if(rand_act.variation_id[1][11]) begin
        idx_tmp = ~rand_act.variation_id[1] + 1;
        if(Stock[rand_act.data_id].Index_B < idx_tmp) begin
            Stock[rand_act.data_id].Index_B = 0;
            warn_msg = Data_Warn;
        end
        else begin
            Stock[rand_act.data_id].Index_B = Stock[rand_act.data_id].Index_B - idx_tmp;
        end
    end
    else begin
        large_idx = Stock[rand_act.data_id].Index_B + rand_act.variation_id[1];
        if(large_idx > 4095) begin
            Stock[rand_act.data_id].Index_B = 4095;
            warn_msg = Data_Warn;
        end
        else begin
            Stock[rand_act.data_id].Index_B = Stock[rand_act.data_id].Index_B + rand_act.variation_id[1];
        end
    end

    if(rand_act.variation_id[2][11]) begin
        idx_tmp = ~rand_act.variation_id[2] + 1;
        if(Stock[rand_act.data_id].Index_C < idx_tmp) begin
            Stock[rand_act.data_id].Index_C = 0;
            warn_msg = Data_Warn;
        end
        else begin
            Stock[rand_act.data_id].Index_C = Stock[rand_act.data_id].Index_C - idx_tmp;
        end
    end
    else begin
        large_idx = Stock[rand_act.data_id].Index_C + rand_act.variation_id[2];
        if(large_idx > 4095) begin
            Stock[rand_act.data_id].Index_C = 4095;
            warn_msg = Data_Warn;
        end
        else begin
            Stock[rand_act.data_id].Index_C = Stock[rand_act.data_id].Index_C + rand_act.variation_id[2];
        end
    end

    if(rand_act.variation_id[3][11]) begin
        idx_tmp = ~rand_act.variation_id[3] + 1;
        if(Stock[rand_act.data_id].Index_D < idx_tmp) begin
            Stock[rand_act.data_id].Index_D = 0;
            warn_msg = Data_Warn;
        end
        else begin
            Stock[rand_act.data_id].Index_D = Stock[rand_act.data_id].Index_D - idx_tmp;
        end
    end
    else begin
        large_idx = Stock[rand_act.data_id].Index_D + rand_act.variation_id[3];
        if(large_idx > 4095) begin
            Stock[rand_act.data_id].Index_D = 4095;
            warn_msg = Data_Warn;
        end
        else begin
            Stock[rand_act.data_id].Index_D = Stock[rand_act.data_id].Index_D + rand_act.variation_id[3];
        end
    end
    


end endtask


task Check_Valid_Date_Act;
    //Date
    if((rand_act.month_id < Stock[rand_act.data_id].M) || ((rand_act.month_id == Stock[rand_act.data_id].M) && (rand_act.day_id < Stock[rand_act.data_id].D))) begin
        warn_msg = Date_Warn;
        //$display("%s\n",warn_type[0]);
    end
begin
    
end endtask
task wait_task; begin
    exe_lat = -1;
    while(inf.out_valid !== 1) begin
        if(inf.complete !== 0 || inf.warn_msg !== 0) begin
            $display("[ERROR] [WAIT] Output signal should be 0 at %-12d ps  ", $time*1000);
            repeat(5) @(negedge clk);
            $finish;
        end
        if(exe_lat == DELAY) begin
            $display("[ERROR] [WAIT] The execution latency at %-12d ps is over %5d cycles  ", $time*1000, DELAY);
            repeat(5) @(negedge clk);
            $finish; 
        end
        exe_lat = exe_lat + 1;
        @(negedge clk);
    end
end endtask

task check_task;
    integer out_lat;
begin
    complete = (warn_msg == No_Warn);
    out_lat = 0;
    while(inf.out_valid === 1) begin
        if(out_lat == OUTNUM) begin
            $display("[ERROR] [OUTPUT] Out cycles is more than %3d at %-12d ps", OUTNUM, $time*1000);
            repeat(5) @(negedge clk);
            $finish;
        end

        _yourComplete = inf.complete;
        _yourWarn_msg = inf.warn_msg;

        out_lat = out_lat + 1;
        @(negedge clk);
    end
    if(out_lat < OUTNUM) begin
        $display("[ERROR] [OUTPUT] Out cycles is less than %3d at %-12d ps", OUTNUM, $time*1000);
        repeat(5) @(negedge clk);
        $finish;
    end

    if(_yourComplete !== complete || _yourWarn_msg !== warn_msg) begin
        $display("[ERROR] [OUTPUT] Wrong Answer\n");
        $display("[ERROR] [OUTPUT] Your complete : %-d", _yourComplete);
        $display("[ERROR] [OUTPUT] Golden complete : %-d\n", complete);
        $display("[ERROR] [OUTPUT] Your warn_msg : %-s", warn_type[_yourWarn_msg]);
        $display("[ERROR] [OUTPUT] Golden warn_msg : %-s\n", warn_type[warn_msg]);
        repeat(5) @(negedge clk);
        $finish;
    end

    tot_lat = tot_lat + exe_lat;
end endtask


task pass_task; begin
    $display("\033[1;33m                `oo+oy+`                            \033[1;35m Congratulations!!! \033[1;0m                                   ");
    $display("\033[1;33m               /h/----+y        `+++++:             \033[1;35m PASS This Lab........Maybe \033[1;0m                          ");
    $display("\033[1;33m             .y------:m/+ydoo+:y:---:+o             \033[1;35m Total Latency : %-10d\033[1;0m                                ", tot_lat);
    $display("\033[1;33m              o+------/y--::::::+oso+:/y                                                                                     ");
    $display("\033[1;33m              s/-----:/:----------:+ooy+-                                                                                    ");
    $display("\033[1;33m             /o----------------/yhyo/::/o+/:-.`                                                                              ");
    $display("\033[1;33m            `ys----------------:::--------:::+yyo+                                                                           ");
    $display("\033[1;33m            .d/:-------------------:--------/--/hos/                                                                         ");
    $display("\033[1;33m            y/-------------------::ds------:s:/-:sy-                                                                         ");
    $display("\033[1;33m           +y--------------------::os:-----:ssm/o+`                                                                          ");
    $display("\033[1;33m          `d:-----------------------:-----/+o++yNNmms                                                                        ");
    $display("\033[1;33m           /y-----------------------------------hMMMMN.                                                                      ");
    $display("\033[1;33m           o+---------------------://:----------:odmdy/+.                                                                    ");
    $display("\033[1;33m           o+---------------------::y:------------::+o-/h                                                                    ");
    $display("\033[1;33m           :y-----------------------+s:------------/h:-:d                                                                    ");
    $display("\033[1;33m           `m/-----------------------+y/---------:oy:--/y                                                                    ");
    $display("\033[1;33m            /h------------------------:os++/:::/+o/:--:h-                                                                    ");
    $display("\033[1;33m         `:+ym--------------------------://++++o/:---:h/                                                                     ");
    $display("\033[1;31m        `hhhhhoooo++oo+/:\033[1;33m--------------------:oo----\033[1;31m+dd+                                                 ");
    $display("\033[1;31m         shyyyhhhhhhhhhhhso/:\033[1;33m---------------:+/---\033[1;31m/ydyyhs:`                                              ");
    $display("\033[1;31m         .mhyyyyyyhhhdddhhhhhs+:\033[1;33m----------------\033[1;31m:sdmhyyyyyyo:                                            ");
    $display("\033[1;31m        `hhdhhyyyyhhhhhddddhyyyyyo++/:\033[1;33m--------\033[1;31m:odmyhmhhyyyyhy                                            ");
    $display("\033[1;31m        -dyyhhyyyyyyhdhyhhddhhyyyyyhhhs+/::\033[1;33m-\033[1;31m:ohdmhdhhhdmdhdmy:                                           ");
    $display("\033[1;31m         hhdhyyyyyyyyyddyyyyhdddhhyyyyyhhhyyhdhdyyhyys+ossyhssy:-`                                                           ");
    $display("\033[1;31m         `Ndyyyyyyyyyyymdyyyyyyyhddddhhhyhhhhhhhhy+/:\033[1;33m-------::/+o++++-`                                            ");
    $display("\033[1;31m          dyyyyyyyyyyyyhNyydyyyyyyyyyyhhhhyyhhy+/\033[1;33m------------------:/ooo:`                                         ");
    $display("\033[1;31m         :myyyyyyyyyyyyyNyhmhhhyyyyyhdhyyyhho/\033[1;33m-------------------------:+o/`                                       ");
    $display("\033[1;31m        /dyyyyyyyyyyyyyyddmmhyyyyyyhhyyyhh+:\033[1;33m-----------------------------:+s-                                      ");
    $display("\033[1;31m      +dyyyyyyyyyyyyyyydmyyyyyyyyyyyyyds:\033[1;33m---------------------------------:s+                                      ");
    $display("\033[1;31m      -ddhhyyyyyyyyyyyyyddyyyyyyyyyyyhd+\033[1;33m------------------------------------:oo              `-++o+:.`             ");
    $display("\033[1;31m       `/dhshdhyyyyyyyyyhdyyyyyyyyyydh:\033[1;33m---------------------------------------s/            -o/://:/+s             ");
    $display("\033[1;31m         os-:/oyhhhhyyyydhyyyyyyyyyds:\033[1;33m----------------------------------------:h:--.`      `y:------+os            ");
    $display("\033[1;33m         h+-----\033[1;31m:/+oosshdyyyyyyyyhds\033[1;33m-------------------------------------------+h//o+s+-.` :o-------s/y  ");
    $display("\033[1;33m         m:------------\033[1;31mdyyyyyyyyymo\033[1;33m--------------------------------------------oh----:://++oo------:s/d  ");
    $display("\033[1;33m        `N/-----------+\033[1;31mmyyyyyyyydo\033[1;33m---------------------------------------------sy---------:/s------+o/d  ");
    $display("\033[1;33m        .m-----------:d\033[1;31mhhyyyyyyd+\033[1;33m----------------------------------------------y+-----------+:-----oo/h  ");
    $display("\033[1;33m        +s-----------+N\033[1;31mhmyyyyhd/\033[1;33m----------------------------------------------:h:-----------::-----+o/m  ");
    $display("\033[1;33m        h/----------:d/\033[1;31mmmhyyhh:\033[1;33m-----------------------------------------------oo-------------------+o/h  ");
    $display("\033[1;33m       `y-----------so /\033[1;31mNhydh:\033[1;33m-----------------------------------------------/h:-------------------:soo  ");
    $display("\033[1;33m    `.:+o:---------+h   \033[1;31mmddhhh/:\033[1;33m---------------:/osssssoo+/::---------------+d+//++///::+++//::::::/y+`  ");
    $display("\033[1;33m   -s+/::/--------+d.   \033[1;31mohso+/+y/:\033[1;33m-----------:yo+/:-----:/oooo/:----------:+s//::-.....--:://////+/:`    ");
    $display("\033[1;33m   s/------------/y`           `/oo:--------:y/-------------:/oo+:------:/s:                                                 ");
    $display("\033[1;33m   o+:--------::++`              `:so/:-----s+-----------------:oy+:--:+s/``````                                             ");
    $display("\033[1;33m    :+o++///+oo/.                   .+o+::--os-------------------:oy+oo:`/o+++++o-                                           ");
    $display("\033[1;33m       .---.`                          -+oo/:yo:-------------------:oy-:h/:---:+oyo                                          ");
    $display("\033[1;33m                                          `:+omy/---------------------+h:----:y+//so                                         ");
    $display("\033[1;33m                                              `-ys:-------------------+s-----+s///om                                         ");
    $display("\033[1;33m                                                 -os+::---------------/y-----ho///om                                         ");
    $display("\033[1;33m                                                    -+oo//:-----------:h-----h+///+d                                         ");
    $display("\033[1;33m                                                       `-oyy+:---------s:----s/////y                                         ");
    $display("\033[1;33m                                                           `-/o+::-----:+----oo///+s                                         ");
    $display("\033[1;33m                                                               ./+o+::-------:y///s:                                         ");
    $display("\033[1;33m                                                                   ./+oo/-----oo/+h                                          ");
    $display("\033[1;33m                                                                       `://++++syo`                                          ");
    $display("\033[1;0m"); 
    repeat(5) @(negedge clk);
    $finish;
end endtask


//======================================
//                FUNC
//======================================

//Formula_B
function automatic Index max(input Index a, b, c, d);
    Index max_val;
    max_val = a; 
    if (b > max_val) max_val = b;
    if (c > max_val) max_val = c;
    if (d > max_val) max_val = d;
    return max_val;
endfunction

//Formula_B, //Formula_C
function automatic Index min(input Index a, b, c, d);
    Index min_val;
    min_val = a; 
    if (b < min_val) min_val = b;
    if (c < min_val) min_val = c;
    if (d < min_val) min_val = d;
    return min_val;
endfunction

//Formula_D, Formula_E
function automatic Index plus1111(input Index a, b, c, d, e = MAX_OF_INDEX/2-1, f = MAX_OF_INDEX/2-1, g = MAX_OF_INDEX/2-1, h = MAX_OF_INDEX/2-1);
    Index out;
    out = 0; 
    if (a >= e) out = out + 1;
    if (b >= f) out = out + 1;
    if (c >= g) out = out + 1;
    if (d >= h) out = out + 1;
    return out;
endfunction

//abs
function automatic Index abs(input Index a, b);
    Index out;
    
    if(a > b) out = a - b;
    else out = b - a;

    return out;
endfunction

//Formula_F
function automatic Index plus_min3(input Index a, b, c, d);
    Index out;
    Index max_val;
    logic [31:0] sum_tmp;

    max_val = a; 
    if (b > max_val) max_val = b;
    if (c > max_val) max_val = c;
    if (d > max_val) max_val = d;

    sum_tmp = (a + b + c + d - max_val) / 3;
    out = sum_tmp;

    return out;
endfunction

//Formula_G
function automatic Index plus_min3_navg(input Index a, b, c, d);
    Index out;
    Index idx_tmp[0:3];

    idx_tmp[0] = a;
    idx_tmp[1] = b;
    idx_tmp[2] = c;
    idx_tmp[3] = d;

    for (int i = 0; i < 3; i++) begin
        for (int j = 0; j < 3 - i; j++) begin
            if (idx_tmp[j] > idx_tmp[j + 1]) begin
                Index swap = idx_tmp[j];
                idx_tmp[j] = idx_tmp[j + 1];
                idx_tmp[j + 1] = swap;
            end
        end
    end

    out = (idx_tmp[0] >> 1) + (idx_tmp[1] >> 2) + (idx_tmp[2] >> 2);

    return out;
endfunction


endprogram
