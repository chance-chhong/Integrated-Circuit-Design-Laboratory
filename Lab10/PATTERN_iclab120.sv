`include "../00_TESTBED/pseudo_DRAM.sv"
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
integer   TOTAL_PATNUM = 5402;
// -------------------------------------
// [Mode]
//      0 : generate the regular dram.dat
//      1 : validate design
integer   MODE = 1;
// -------------------------------------
integer   SEED = 121;
parameter DEBUG = 1;
parameter DRAMDAT_TO_GENERATED = "../00_TESTBED/DRAM/dram.dat";
parameter DRAMDAT_FROM_DRAM = "../00_TESTBED/DRAM/dram.dat";

//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
parameter CYCLE = 5;
parameter DELAY = 1000;
parameter OUTNUM = 1;

// PATTERN CONTROL
integer pat;
integer exe_lat;
integer tot_lat;
integer cnt;
logic flag;

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
// Inputs
parameter NUM_OF_DATA = 512;
parameter SIZE_OF_DATA = 4;
parameter BITS_OF_ELEMENT = 8;

parameter MAX_OF_INDEX = 4096;
parameter VALID_WAIT_CYCLE = 4;

parameter SIZE = 300;

parameter START_OF_DRAM_ADDRESS = 65536;

integer cnt_mode;
integer cnt_act;

Action arr[SIZE*9 + 2];
Action act;

integer data_id;

Index index[0:3];

Day day_id;

//Data
class random_act;
    randc Action act_id;
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
        month_id inside{[1:12]};
        (month_id == 1 || month_id == 3 || month_id == 5 || month_id == 7 || month_id == 8 || month_id == 10 || month_id == 12 )->day_id inside{[1:31]};
        (month_id == 4 || month_id == 6 || month_id == 9 || month_id == 11)->day_id inside{[1:30]};
        (month_id == 2)->day_id inside{[1:28]};
    }
endclass

class random_formula;
    randc Formula_Type formula_id;
    function new (int seed);
        this.srandom(seed);  
    endfunction
    constraint range{
        formula_id inside{Formula_A, Formula_B, Formula_C, Formula_D, Formula_E, Formula_F, Formula_G, Formula_H};
    }
endclass

class random_mode;
    randc Mode mode_id;
    function new (int seed);
        this.srandom(seed);  
    endfunction
    constraint range{
        mode_id inside{Insensitive, Normal, Sensitive};
    }
endclass


random_act rand_act = new(SEED);
random_formula rand_formula = new(SEED);
random_mode rand_mode = new(SEED);

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


Data_Dir Stock[0:255];

//======================================
//              MAIN
//======================================
initial begin
    exe_task; 
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
    generate_patterns;
    cnt = 0;
    flag = 0;
    for(pat=0 ; pat<TOTAL_PATNUM ; pat=pat+1) begin
        input_task;
        cal_task;
        //$display("%d\n",warn_msg);
        wait_task;
        check_task;
        // Print Pass Info and accumulate the total latency
        $display("%0sPASS PATTERN NO.%4d %0sCycles: %3d%0s Act: %4s%0s Warn: %4s%0s",txt_blue_prefix, pat, txt_green_prefix, exe_lat, txt_yellow_prefix, act_type[act], txt_red_prefix,  warn_type[_yourWarn_msg], reset_color);
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

    repeat(5) #(1) inf.rst_n = 0;
    repeat(5) #(1) inf.rst_n = 1;
    
    release clk;
    //repeat(1) @(negedge clk);
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
        // Stock
        status = $fscanf(file, "%2h %2h %2h %2h", a, b, c, d);
        //$display("%2h %2h %2h %2h %d\n",a,b,c,d,stock_idx);
        //stock_idx = _cnt/2;
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
    //logic [11:0] index;
    logic signed [11:0] variation;
    integer variation_offset = MAX_OF_INDEX / 2;
    Formula_Type formula_id;
    Mode mode_id;
begin


    warn_msg = No_Warn;
    complete = 0;
    
    rand_act.randomize();
    
    formula_id = 0;
    mode_id = 0;

    //wait_cycle = {$random(SEED)} % VALID_WAIT_CYCLE;
    //repeat(wait_cycle) @(negedge clk);

    act = (cnt_act > 2701) ? Index_Check :arr[cnt_act];

    cnt_act = cnt_act + 1;

    inf.sel_action_valid = 1;
    inf.D.d_act[0] = act;
    repeat(1) @(negedge clk);
    inf.sel_action_valid = 0;
    inf.D = 'bx;
    //wait_cycle = {$random(SEED)} % VALID_WAIT_CYCLE;
    //repeat(wait_cycle) @(negedge clk);


    if(act == Index_Check) begin
        if(cnt_mode == 0) rand_formula.randomize();
        inf.formula_valid = 1;
        inf.D.d_formula[0] = rand_formula.formula_id;
        formula_id = rand_formula.formula_id;
        repeat(1) @(negedge clk);
        inf.formula_valid = 0;
        inf.D = 'bx;
        //wait_cycle = {$random(SEED)} % VALID_WAIT_CYCLE;
        //repeat(wait_cycle) @(negedge clk);

        cnt_mode = cnt_mode + 1;
        if(cnt_mode == 3) cnt_mode = 0;

        rand_mode.randomize();
        inf.mode_valid = 1;
        inf.D.d_mode[0] = rand_mode.mode_id;
        mode_id = rand_mode.mode_id;
        repeat(1) @(negedge clk);
        inf.mode_valid = 0;
        inf.D = 'bx;
        //wait_cycle = {$random(SEED)} % VALID_WAIT_CYCLE;
        //repeat(wait_cycle) @(negedge clk);
    end

    inf.date_valid = 1;
    inf.D.d_date[0].M = rand_act.month_id;
    
    if(rand_act.month_id == 12 && rand_act.day_id == 31) begin
        inf.D.d_date[0].D = 30;
        day_id = 30;
    end
    else if(act == Index_Check && (formula_id == Formula_H) && (mode_id == Insensitive) && !flag) begin
        inf.D.d_date[0].D = 5;
        day_id = 5;
    end
    else begin
        inf.D.d_date[0].D = rand_act.day_id;
        day_id = rand_act.day_id;
    end
    repeat(1) @(negedge clk);
    inf.date_valid = 0;
    inf.D = 'bx;
    //wait_cycle = {$random(SEED)} % VALID_WAIT_CYCLE;
    //repeat(wait_cycle) @(negedge clk);


    inf.data_no_valid = 1;
    //$display("%d %d", formula_id, mode_id);
    if((act == 0) && (formula_id == 2) && (mode_id == 3) && (cnt < 50)) begin
        inf.D.d_data_no[0] = 0;
        data_id = 0;
        cnt = cnt + 1;
    end
    else if(act == Index_Check && (formula_id == Formula_H) && (mode_id == Insensitive) && !flag) begin
        inf.D.d_data_no[0] = 0;
        data_id = 0;
    end
    else if(act == Index_Check) begin
        inf.D.d_data_no[0] = 1;
        data_id = 1;
    end
    else if(act == Update) begin
        inf.D.d_data_no[0] = (rand_act.data_id == 1 || rand_act.data_id == 0) ? 4 : rand_act.data_id;
        data_id = (rand_act.data_id == 1 || rand_act.data_id == 0) ? 4 : rand_act.data_id;
    end
    else begin
        inf.D.d_data_no[0] = rand_act.data_id;
        data_id = rand_act.data_id;
    end
    repeat(1) @(negedge clk);
    inf.data_no_valid = 0;
    inf.D = 'bx;
    //wait_cycle = {$random(SEED)} % VALID_WAIT_CYCLE;
    //if(rand_act.act_id != Check_Valid_Date)
        //repeat(wait_cycle) @(negedge clk);


    if(act == Index_Check) begin
        inf.index_valid = 1;
        if(act == Index_Check && (formula_id == Formula_H) && (mode_id == Insensitive) && !flag) begin
            inf.D.d_index[0] = 4095;
            index[0] = 4095;
        end
        else begin
            inf.D.d_index[0] = rand_act.index_id[0];
            index[0] = rand_act.index_id[0];
        end
        repeat(1) @(negedge clk);
        inf.index_valid = 0;
        inf.D = 'bx;
        //wait_cycle = {$random(SEED)} % VALID_WAIT_CYCLE;
        //repeat(wait_cycle) @(negedge clk);

        inf.index_valid = 1;
        if(act == Index_Check && (formula_id == Formula_H) && (mode_id == Insensitive) && !flag) begin
            inf.D.d_index[0] = 4095;
            index[1] = 4095;
        end
        else begin
            inf.D.d_index[0] = rand_act.index_id[1];
            index[1] = rand_act.index_id[1];
        end
        repeat(1) @(negedge clk);
        inf.index_valid = 0;
        inf.D = 'bx;
        //wait_cycle = {$random(SEED)} % VALID_WAIT_CYCLE;
        //repeat(wait_cycle) @(negedge clk);

        inf.index_valid = 1;
        inf.index_valid = 1;
        if(act == Index_Check && (formula_id == Formula_H) && (mode_id == Insensitive) && !flag) begin
            inf.D.d_index[0] = 4095;
            index[2] = 4095;
        end
        else begin
            inf.D.d_index[0] = rand_act.index_id[2];
            index[2] = rand_act.index_id[2];
        end
        repeat(1) @(negedge clk);
        inf.index_valid = 0;
        inf.D = 'bx;
        //wait_cycle = {$random(SEED)} % VALID_WAIT_CYCLE;
        //repeat(wait_cycle) @(negedge clk);

        inf.index_valid = 1;
        inf.index_valid = 1;
        if(act == Index_Check && (formula_id == Formula_H) && (mode_id == Insensitive) && !flag) begin
            inf.D.d_index[0] = 4095;
            index[3] = 4095;
            flag = 1;
        end
        else begin
            inf.D.d_index[0] = rand_act.index_id[3];
            index[3] = rand_act.index_id[3];
        end
        repeat(1) @(negedge clk);
        inf.index_valid = 0;
        inf.D = 'bx;

    end
    else if(act == Update) begin
        inf.index_valid = 1;
        inf.D.d_index[0] = rand_act.variation_id[0];
        repeat(1) @(negedge clk);
        inf.index_valid = 0;
        inf.D = 'bx;
        //wait_cycle = {$random(SEED)} % VALID_WAIT_CYCLE;
        //repeat(wait_cycle) @(negedge clk);

        inf.index_valid = 1;
        inf.D.d_index[0] = rand_act.variation_id[1];
        repeat(1) @(negedge clk);
        inf.index_valid = 0;
        inf.D = 'bx;
        //wait_cycle = {$random(SEED)} % VALID_WAIT_CYCLE;
        //repeat(wait_cycle) @(negedge clk);

        inf.index_valid = 1;
        inf.D.d_index[0] = rand_act.variation_id[2];
        repeat(1) @(negedge clk);
        inf.index_valid = 0;
        inf.D = 'bx;
        //wait_cycle = {$random(SEED)} % VALID_WAIT_CYCLE;
        //repeat(wait_cycle) @(negedge clk);

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
    case(act)
        Index_Check: Index_Check_Act;
        Update: Update_Act;
        Check_Valid_Date: Check_Valid_Date_Act;
        default: begin
            $display("[ERROR] [CAL] The mode (%2d) is no valid", act);
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
    //$display("%d %d %d\n",data_id,Stock[data_id].M, Stock[data_id].D);
    //Date
    if((rand_act.month_id < Stock[data_id].M) || ((rand_act.month_id == Stock[data_id].M) && (day_id < Stock[data_id].D))) begin
        warn_msg = Date_Warn;
        //$display("%d %d %d\n",data_id,Stock[data_id].M, Stock[data_id].D);
        return;
    end
    
    //Formula

    case(rand_formula.formula_id)
        Formula_A: begin
            idx_tmp = (Stock[data_id].Index_A + Stock[data_id].Index_B + Stock[data_id].Index_C + Stock[data_id].Index_D) >> 2;
            if(idx_tmp >= threshold_table[Formula_A][rand_mode.mode_id]) begin
                warn_msg = Risk_Warn;
            end
        end
        Formula_B: begin
            idx_tmp = max(Stock[data_id].Index_A,Stock[data_id].Index_B,Stock[data_id].Index_C,Stock[data_id].Index_D) - min(Stock[data_id].Index_A,Stock[data_id].Index_B,Stock[data_id].Index_C,Stock[data_id].Index_D);
            if(idx_tmp >= threshold_table[Formula_B][rand_mode.mode_id]) begin
                warn_msg = Risk_Warn;
            end
        end
        Formula_C: begin
            idx_tmp = min(Stock[data_id].Index_A,Stock[data_id].Index_B,Stock[data_id].Index_C,Stock[data_id].Index_D);
            if(idx_tmp >= threshold_table[Formula_C][rand_mode.mode_id]) begin
                //$display("%d %d\n", idx_tmp, threshold_table[Formula_C][rand_act.mode_id]);
                warn_msg = Risk_Warn;
            end
        end
        Formula_D: begin
            idx_tmp = plus1111(Stock[data_id].Index_A,Stock[data_id].Index_B,Stock[data_id].Index_C,Stock[data_id].Index_D);
            if(idx_tmp >= threshold_table[Formula_D][rand_mode.mode_id]) begin
                warn_msg = Risk_Warn;
            end
        end
        Formula_E: begin
            idx_tmp = plus1111(Stock[data_id].Index_A,Stock[data_id].Index_B,Stock[data_id].Index_C,Stock[data_id].Index_D,index[0],index[1],index[2],index[3]);
            if(idx_tmp >= threshold_table[Formula_E][rand_mode.mode_id]) begin
                warn_msg = Risk_Warn;
            end
        end
        Formula_F: begin
            idx_tmp = plus_min3(abs(Stock[data_id].Index_A,index[0]),abs(Stock[data_id].Index_B,index[1]),abs(Stock[data_id].Index_C,index[2]),abs(Stock[data_id].Index_D,index[3]));
            if(idx_tmp >= threshold_table[Formula_F][rand_mode.mode_id]) begin
                warn_msg = Risk_Warn;
            end
        end
        Formula_G: begin
            idx_tmp = plus_min3_navg(abs(Stock[data_id].Index_A,index[0]),abs(Stock[data_id].Index_B,index[1]),abs(Stock[data_id].Index_C,index[2]),abs(Stock[data_id].Index_D,index[3]));
            if(idx_tmp >= threshold_table[Formula_G][rand_mode.mode_id]) begin
                warn_msg = Risk_Warn;
                //$display("%d %d\n", idx_tmp, threshold_table[Formula_G][rand_act.mode_id]);
            end
        end
        Formula_H: begin
            idx_tmp = (abs(Stock[data_id].Index_A,index[0]) + abs(Stock[data_id].Index_B,index[1]) + abs(Stock[data_id].Index_C,index[2]) + abs(Stock[data_id].Index_D,index[3])) >> 2;
            if(idx_tmp >= threshold_table[Formula_H][rand_mode.mode_id]) begin
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
    Stock[data_id].M = rand_act.month_id;
    Stock[data_id].D = day_id;

    //update data
    if(rand_act.variation_id[0][11]) begin
        idx_tmp = ~rand_act.variation_id[0] + 1;
        if(Stock[data_id].Index_A < idx_tmp) begin
            Stock[data_id].Index_A = 0;
            warn_msg = Data_Warn;
        end
        else begin
            Stock[data_id].Index_A = Stock[data_id].Index_A - idx_tmp;
        end
    end
    else begin
        large_idx = Stock[data_id].Index_A + rand_act.variation_id[0];
        if(large_idx > 4095) begin
            Stock[data_id].Index_A = 4095;
            warn_msg = Data_Warn;
        end
        else begin
            Stock[data_id].Index_A = Stock[data_id].Index_A + rand_act.variation_id[0];
        end
    end

    if(rand_act.variation_id[1][11]) begin
        idx_tmp = ~rand_act.variation_id[1] + 1;
        if(Stock[data_id].Index_B < idx_tmp) begin
            Stock[data_id].Index_B = 0;
            warn_msg = Data_Warn;
        end
        else begin
            Stock[data_id].Index_B = Stock[data_id].Index_B - idx_tmp;
        end
    end
    else begin
        large_idx = Stock[data_id].Index_B + rand_act.variation_id[1];
        if(large_idx > 4095) begin
            Stock[data_id].Index_B = 4095;
            warn_msg = Data_Warn;
        end
        else begin
            Stock[data_id].Index_B = Stock[data_id].Index_B + rand_act.variation_id[1];
        end
    end

    if(rand_act.variation_id[2][11]) begin
        idx_tmp = ~rand_act.variation_id[2] + 1;
        if(Stock[data_id].Index_C < idx_tmp) begin
            Stock[data_id].Index_C = 0;
            warn_msg = Data_Warn;
        end
        else begin
            Stock[data_id].Index_C = Stock[data_id].Index_C - idx_tmp;
        end
    end
    else begin
        large_idx = Stock[data_id].Index_C + rand_act.variation_id[2];
        if(large_idx > 4095) begin
            Stock[data_id].Index_C = 4095;
            warn_msg = Data_Warn;
        end
        else begin
            Stock[data_id].Index_C = Stock[data_id].Index_C + rand_act.variation_id[2];
        end
    end

    if(rand_act.variation_id[3][11]) begin
        idx_tmp = ~rand_act.variation_id[3] + 1;
        if(Stock[data_id].Index_D < idx_tmp) begin
            Stock[data_id].Index_D = 0;
            warn_msg = Data_Warn;
        end
        else begin
            Stock[data_id].Index_D = Stock[data_id].Index_D - idx_tmp;
        end
    end
    else begin
        large_idx = Stock[data_id].Index_D + rand_act.variation_id[3];
        if(large_idx > 4095) begin
            Stock[data_id].Index_D = 4095;
            warn_msg = Data_Warn;
        end
        else begin
            Stock[data_id].Index_D = Stock[data_id].Index_D + rand_act.variation_id[3];
        end
    end
    


end endtask


task Check_Valid_Date_Act;
    //Date
    if((rand_act.month_id < Stock[data_id].M) || ((rand_act.month_id == Stock[data_id].M) && (day_id < Stock[data_id].D))) begin
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

begin
    complete = (warn_msg == No_Warn);

    _yourComplete = inf.complete;
    _yourWarn_msg = inf.warn_msg;


    if(_yourComplete !== complete || _yourWarn_msg !== warn_msg) begin
        $display("********************************************************************");
        $display("\033[1;31m                   Wrong Answer\033[1;0m");
        $display("\033[1;31m                Your complete : %-d\033[1;0m", _yourComplete);
        $display("\033[1;31m                Golden complete : %-d\033[1;0m", complete);
        $display("\033[1;31m                Your warn_msg : %-s\033[1;0m", warn_type[_yourWarn_msg]);
        $display("\033[1;31m                Golden warn_msg : %-s\033[1;0m", warn_type[warn_msg]);
        $display("********************************************************************");
        $finish;
    end

    tot_lat = tot_lat + exe_lat;
    @(negedge clk);
end endtask


task pass_task; begin
    $display("********************************************************************");
    $display("\033[1;35m                       Congratulations! \033[1;0m");
    $display("\033[1;35m                You have passed all patterns! \033[1;0m");
    $display("\033[1;35m                TOTAL CYCLE IS:       %-10d\033[1;0m", tot_lat);
    $display("********************************************************************");
    $finish;
end endtask


task generate_patterns;
    
    begin
        
        for (int i = 0; i < SIZE; i++) begin
            arr[i] = 0;
        end
        
        for (int i = SIZE; i < SIZE*3; i++) begin
            arr[i] = (i % 2 == 0) ? 0 : 1;
        end
        
        for (int i = SIZE*3; i < SIZE*5; i++) begin
            arr[i] = (i % 2 == 0) ? 0 : 2;
        end
        
        for (int i = SIZE*5; i < SIZE*6; i++) begin
            arr[i] = 2;
        end
        
        for (int i = SIZE*6; i < SIZE*8; i++) begin
            arr[i] = (i % 2 == 0) ? 1 : 2;
        end
        
        for (int i = SIZE*8; i < SIZE*9; i++) begin
            arr[i] = 1;
        end
        arr[SIZE*9] = 1;
        arr[SIZE*9+1] = 2;
        cnt_act = 0;
        cnt_mode = 0;
    end
endtask

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
