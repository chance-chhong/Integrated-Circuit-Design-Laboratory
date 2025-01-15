/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2023 Autumn IC Design Laboratory 
Lab10: SystemVerilog Coverage & Assertion
File Name   : CHECKER.sv
Module Name : CHECKER
Release version : v1.0 (Release Date: Nov-2023)
Author : Jui-Huang Tsai (erictsai.10@nycu.edu.tw)
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

`include "Usertype.sv"
module Checker(input clk, INF.CHECKER inf);
import usertype::*;

// integer fp_w;

// initial begin
// fp_w = $fopen("out_valid.txt", "w");
// end

/**
 * This section contains the definition of the class and the instantiation of the object.
 *  * 
 * The always_ff blocks update the object based on the values of valid signals.
 * When valid signal is true, the corresponding property is updated with the value of inf.D
 */

class Formula_and_mode;
    Formula_Type f_type;
    Mode f_mode;
endclass

Formula_and_mode fm_info = new();

parameter OUTNUM = 1;
parameter DELAY = 999;
integer   TOTAL_PATNUM = 5402;

reg[9*8:1]  reset_color       = "\033[1;0m";
reg[10*8:1] txt_black_prefix  = "\033[1;30m";
reg[10*8:1] txt_red_prefix    = "\033[1;31m";
reg[10*8:1] txt_green_prefix  = "\033[1;32m";
reg[10*8:1] txt_yellow_prefix = "\033[1;33m";
reg[10*8:1] txt_blue_prefix   = "\033[1;34m";


Formula_Type formula_type;
always_ff @(posedge clk iff inf.formula_valid) formula_type = inf.D.d_formula[0];
logic update_valid;
always_ff @(posedge clk iff inf.sel_action_valid) update_valid = (inf.D.d_act[0] === Update);


// at least number
parameter   formula_alnum = 150,
            mode_alnum = 150,
            formula_and_mode_alnum = 150,
            warnmsg_alnum = 50,
            act_alnum = 300,
            variation_alnum = 1;
// auto bin
parameter   auto_bin_max = 32;


// covergroup

covergroup cover_group_formula 
    @(posedge clk iff inf.formula_valid);
    option.at_least = formula_alnum ;
    formula: coverpoint inf.D.d_formula[0] {bins b_formula[] = {3'h0, 3'h1, 3'h2, 3'h3, 3'h4, 3'h5, 3'h6, 3'h7};}
endgroup

covergroup cover_group_mode 
    @(posedge clk iff inf.mode_valid);
    option.at_least = mode_alnum ;
    mode: coverpoint inf.D.d_mode[0] {bins b_mode[] = {2'b00, 2'b01, 2'b11};}
endgroup


covergroup cover_group_formula_and_mode 
    @(posedge clk iff inf.mode_valid);
    bformula: coverpoint formula_type {bins b_formula[] = {3'h0,3'h1,3'h2,3'h3,3'h4,3'h5,3'h6,3'h7};}
    bmode: coverpoint inf.D.d_mode[0] {bins b_mode[] = {2'b00, 2'b01, 2'b11};}
    bformula_X_bmode: cross bformula, bmode{option.at_least = formula_and_mode_alnum;}
endgroup

covergroup cover_group_warnmsg 
    @(negedge clk iff inf.out_valid);
    option.at_least = warnmsg_alnum ;
    msg: coverpoint inf.warn_msg {bins b_msg[] = {2'h0, 2'h1, 2'h2, 2'h3};}
endgroup

covergroup cover_group_act 
    @(posedge clk iff inf.sel_action_valid);
    option.at_least = act_alnum ;
    act_X_act: coverpoint inf.D.d_act[0] {bins b_act[] = ([0:2]=>[0:2]);}
endgroup

covergroup cover_group_variation 
    @(posedge clk iff (inf.index_valid && update_valid));
    option.at_least = variation_alnum;
    option.auto_bin_max = auto_bin_max;
    //bupdate: coverpoint update_valid {bins b_update = {1'b1};}
    update_variation: coverpoint inf.D.d_index[0];
    //bupdate_X_update_variation: cross bupdate, update_variation;
endgroup

//cover_group_formula cover_group_formula_inst = new();
//cover_group_mode cover_group_mode_inst = new();
cover_group_formula_and_mode cover_group_formula_and_mode_inst = new();
cover_group_warnmsg cover_group_warnmsg_inst = new();
cover_group_act cover_group_act_inst = new();
cover_group_variation cover_group_variation_inst = new();


//1. All outputs signals(Program.sv) should be zero after reset.

property SPEC_1_rst;
    @(posedge inf.rst_n) (inf.rst_n === 0) |-> (inf.out_valid === 0 && inf.complete === 0 && inf.warn_msg === 0 &&
        inf.AR_VALID === 0 && inf.R_READY === 0 && inf.AW_VALID === 0 && inf.W_VALID === 0 && inf.B_READY === 0 &&
        inf.AR_ADDR === 0 && inf.AW_ADDR === 0 && inf.W_DATA === 0);
endproperty





//2. Latency should be less than 1000 cycles for each operation.

property SPEC_2_IC;
    @(posedge clk) (inf.sel_action_valid && inf.D.d_act[0] === Index_Check) |-> ##[1:DELAY] inf.out_valid;
endproperty


property SPEC_2_U;
    @(posedge clk) (inf.sel_action_valid && inf.D.d_act[0] === Update) |-> ##[1:DELAY] inf.out_valid;
endproperty


property SPEC_2_CVD;
    @(posedge clk) (inf.sel_action_valid && inf.D.d_act[0] === Check_Valid_Date) |-> ##[1:DELAY] inf.out_valid;
endproperty




//3. If action is completed (complete=1), warn_msg should be 2'b0 (No_Warn).

property SPEC_3_warnmsg;
    @(negedge clk) (inf.out_valid && inf.complete) |-> inf.warn_msg === No_Warn; 
endproperty



//4. Next input valid will be valid 1-4 cycles after previous input valid fall.

property SPEC_4_IC;
    @(posedge clk) (inf.sel_action_valid && inf.D.d_act[0] === Index_Check) |-> ##[1:4] inf.formula_valid ##[1:4] inf.mode_valid ##[1:4] inf.date_valid ##[1:4] inf.data_no_valid ##[1:4] inf.index_valid ##[1:4] inf.index_valid ##[1:4] inf.index_valid ##[1:4] inf.index_valid;
endproperty

property SPEC_4_U;
    @(posedge clk) (inf.sel_action_valid && inf.D.d_act[0] === Update) |-> ##[1:4] inf.date_valid##[1:4] inf.data_no_valid ##[1:4] inf.index_valid ##[1:4] inf.index_valid ##[1:4] inf.index_valid ##[1:4] inf.index_valid; 
endproperty

property SPEC_4_CVD;
    @(posedge clk) (inf.sel_action_valid && inf.D.d_act[0] === Check_Valid_Date) |-> ##[1:4] inf.date_valid ##[1:4] inf.data_no_valid; 
endproperty



//5. All input valid signals won't overlap with each other. 

property SPEC_5_sel_action;
    @(posedge clk) inf.sel_action_valid |-> !(inf.formula_valid || inf.mode_valid || inf.date_valid || inf.data_no_valid || inf.index_valid); 
endproperty

property SPEC_5_formula;
    @(posedge clk) inf.formula_valid |-> !(inf.sel_action_valid || inf.mode_valid || inf.date_valid || inf.data_no_valid || inf.index_valid); 
endproperty

property SPEC_5_mode;
    @(posedge clk) inf.mode_valid |-> !(inf.sel_action_valid || inf.formula_valid || inf.date_valid || inf.data_no_valid || inf.index_valid); 
endproperty

property SPEC_5_date;
    @(posedge clk) inf.date_valid |-> !(inf.sel_action_valid || inf.formula_valid || inf.mode_valid || inf.data_no_valid || inf.index_valid); 
endproperty

property SPEC_5_data_no;
    @(posedge clk) inf.data_no_valid |-> !(inf.sel_action_valid || inf.formula_valid || inf.mode_valid || inf.date_valid || inf.index_valid); 
endproperty

property SPEC_5_index;
    @(posedge clk) inf.index_valid |-> !(inf.sel_action_valid || inf.formula_valid || inf.mode_valid || inf.date_valid || inf.data_no_valid); 
endproperty



// 6. Out_valid can only be high for exactly one cycle.

property SPEC_6_outvalid_one_cycle;
    @(posedge clk) inf.out_valid |-> ##[1:OUTNUM] (inf.out_valid === 0);
endproperty



//7. Next operation will be valid 1-4 cycles after out_valid fall.

property SPEC_7_next_opt;
    @(posedge clk) inf.out_valid |-> ##[1:4] inf.sel_action_valid; 
endproperty



//8. The input date from pattern should adhere to the real calendar. (ex: 2/29, 3/0, 4/31, 13/1 are illegal cases)

property SPEC_8_MONTH;
    @(posedge clk) inf.date_valid |-> inf.D.d_date[0].M inside {[1:12]}; 
endproperty

property SPEC_8_DAY_31;
    @(posedge clk) 
    (inf.date_valid && (inf.D.d_date[0].M === 1  ||
                        inf.D.d_date[0].M === 3  ||
                        inf.D.d_date[0].M === 5  ||
                        inf.D.d_date[0].M === 7  ||
                        inf.D.d_date[0].M === 8  ||
                        inf.D.d_date[0].M === 10 ||
                        inf.D.d_date[0].M === 12
                        )) |-> inf.D.d_date[0].D inside {[1:31]}; 
endproperty

property SPEC_8_DAY_28;
    @(posedge clk) (inf.date_valid && inf.D.d_date[0].M === 2) |-> inf.D.d_date[0].D inside {[1:28]}; 
endproperty

property SPEC_8_DAY_30;
    @(posedge clk) 
    (inf.date_valid && (inf.D.d_date[0].M === 4 ||
                        inf.D.d_date[0].M === 6 ||
                        inf.D.d_date[0].M === 9 ||
                        inf.D.d_date[0].M === 11)) |-> inf.D.d_date[0].D inside {[1:30]}; 
endproperty


//9. The AR_VALID signal should not overlap with the AW_VALID signal

property SPEC_9_AR;
    @(posedge clk) inf.AR_VALID |=> (inf.AW_VALID === 0); 
endproperty

property SPEC_9_AW;
    @(posedge clk) inf.AW_VALID |=> (inf.AR_VALID === 0); 
endproperty


assert property(SPEC_1_rst)                                                                               else print_Assertion_violate_msg("1");
assert property(SPEC_2_IC and SPEC_2_U and SPEC_2_CVD)                                                    else print_Assertion_violate_msg("2");
assert property(SPEC_3_warnmsg)                                                                           else print_Assertion_violate_msg("3");
assert property(SPEC_4_IC and SPEC_4_U and SPEC_4_CVD)                                                    else print_Assertion_violate_msg("4");
assert property(SPEC_5_sel_action and SPEC_5_formula and SPEC_5_mode and SPEC_5_data_no and SPEC_5_index) else print_Assertion_violate_msg("5");
assert property(SPEC_6_outvalid_one_cycle)                                                                else print_Assertion_violate_msg("6");
assert property(SPEC_7_next_opt)                                                                          else print_Assertion_violate_msg("7");
assert property(SPEC_8_MONTH and SPEC_8_DAY_28 and SPEC_8_DAY_30 and SPEC_8_DAY_31)                       else print_Assertion_violate_msg("8");
assert property(SPEC_9_AR and SPEC_9_AW)                                                                  else print_Assertion_violate_msg("9");

task print_Assertion_violate_msg(string Assertion_num);
    $display("\n%20sAssertion %s is violated%0s\n",txt_red_prefix, Assertion_num, reset_color);
    $fatal;
endtask

endmodule