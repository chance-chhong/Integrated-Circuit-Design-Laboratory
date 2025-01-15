module BB(
    //Input Ports
    input clk,
    input rst_n,
    input in_valid,
    input [1:0] inning,   // Current inning number
    input half,           // 0: top of the inning, 1: bottom of the inning
    input [2:0] action,   // Action code

    //Output Ports
    output reg out_valid,  // Result output valid
    output reg [7:0] score_A,  // Score of team A (guest team)
    output reg [7:0] score_B,  // Score of team B (home team)
    output reg [1:0] result    // 0: Team A wins, 1: Team B wins, 2: Darw
);

//==============================================//
//             Action Memo for Students         //
// Action code interpretation:
// 3’d0: Walk         (BB)
// 3’d1: 1H           (single hit)
// 3’d2: 2H           (double hit)
// 3’d3: 3H           (triple hit)
// 3’d4: HR           (home run)
// 3’d5: Bunt         (short hit)
// 3’d6: Ground ball
// 3’d7: Fly ball
//==============================================//

//==============================================//
//             Parameter and Integer            //
//==============================================//
// State declaration for FSM
// Example: parameter IDLE = 3'b000;



enum logic[2:0] {
    IDLE =    3'd0,
    OUT_0 =   3'd1,
    OUT_1 =   3'd2,
    OUT_2 =   3'd3,
    OUTPUT =  3'd4
    } current_state,next_state;


enum logic[2:0] {
    Walk         ,
    H_1          ,
    H_2          ,
    H_3          ,
    HR           ,
    Bunt         ,
    Gb           ,
    Fb
    } action_REG;

//==============================================//
//                 reg declaration              //
//==============================================//

reg [7:0] base;
reg half_reg;
reg [1:0] inning_reg;

always @(posedge clk) begin
    if(in_valid) action_REG <= action;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) half_reg <= 0;
    else half_reg <= half;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) inning_reg <= 0;
    else inning_reg <= inning;
end
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
            if(in_valid) next_state = OUT_0;
            else next_state = IDLE;
        end
        OUT_0: begin
            case(action_REG)
                3'd5: next_state = OUT_1;
                3'd6: next_state = base[1] ? OUT_2 : OUT_1;
                3'd7: next_state = OUT_1;
                default: next_state = OUT_0;
            endcase
        end
        OUT_1: begin
            case(action_REG)
                3'd5: next_state = OUT_2;
                3'd6: next_state = base[1] ? ((half_reg && inning_reg == 3) ? OUTPUT : OUT_0) : OUT_2;
                3'd7: next_state = OUT_2;
                default: next_state = OUT_1;
            endcase
        end
        OUT_2: begin
            case(action_REG)
                3'd5: next_state = (half_reg && inning_reg == 3) ? OUTPUT : OUT_0;
                3'd6: next_state = (half_reg && inning_reg == 3) ? OUTPUT : OUT_0;
                3'd7: next_state = (half_reg && inning_reg == 3) ? OUTPUT : OUT_0;
                default: next_state = OUT_2;
            endcase
        end
        OUTPUT: begin
            next_state = IDLE;
        end
        default: next_state = IDLE; // illegal state
    endcase
end

//==============================================//
//             Base and Score Logic             //
//==============================================//
// Handle base runner movements and score calculation.
// Update bases and score depending on the action:
// Example: Walk, Hits (1H, 2H, 3H), Home Runs, etc.

wire change = half_reg ^ half;
wire early_run = (current_state == OUT_2) ? 1 : 0;
wire base_control = !rst_n || current_state == IDLE || change == 1;
always @(posedge clk) begin
    if(base_control) begin
        base <= 8'b0000000;
    end
    else begin
        case(action_REG)
            3'd0: begin
                base[7:5] <= 0;
                base[4] <= (base[2] && base[1]) ? base[3] : 0;
                base[3] <= (base[2] && base[1]) ? 1 : base[3];
                base[2] <= base[1] ? 1 : base[2];
                base[1] <= 1;
            end
            3'd1: begin
                base[7:6] <= 0;
                base[5] <= early_run == 0 ? 0 : base[3];
                base[4+early_run] <= base[3];
                base[3+early_run] <= base[2];
                base[2+early_run] <= base[1];
                base[1+early_run] <= (early_run) ? 0 : 1 ;
                base[0+early_run] <= (early_run) ? 1 : 0 ;
            end
            3'd2: begin
                if (early_run) begin
                    base[7] <= 0;
                    base[5+early_run] <= base[3];
                    base[4+early_run] <= base[2];
                    base[3+early_run] <= base[1];
                    base[2+early_run] <= (early_run) ? 0 : 1 ;
                    base[1+early_run] <= (early_run) ? 1 : 0 ;
                    base[0+early_run] <= 0;
                end
                else begin
                    base[7:6] <= 0;
                    base[5+early_run] <= base[3];
                    base[4+early_run] <= base[2];
                    base[3+early_run] <= base[1];
                    base[2+early_run] <= (early_run) ? 0 : 1 ;
                    base[1+early_run] <= (early_run) ? 1 : 0 ;
                    base[0+early_run] <= 0;
                end
            end
            3'd3: begin
                base[7] <= 0;
                base[6] <= base[3];
                base[5] <= base[2];
                base[4] <= base[1];
                base[3] <= 1;
                base[2] <= 0;
                base[1] <= 0;
                base[0] <= 0;
            end
            3'd4: begin
                base[7] <= base[3];
                base[6] <= base[2];
                base[5] <= base[1];
                base[4] <= 1;
                base[3] <= 0;
                base[2] <= 0;
                base[1] <= 0;
            end
            3'd5: begin
                base[7:5] <= 0;
                base[4] <= base[3];
                base[3] <= base[2];
                base[2] <= base[1];
                base[1] <= 0;
            end
            3'd6: begin
                base[7:5] <= 0;
                base[4] <= base[3];
                base[3] <= base[2];
                base[2] <= 0;
                base[1] <= 0;
            end
            3'd7: begin
                base[7:5] <= 0;
                base[4] <= base[3];
                base[3] <= 0;
            end
        endcase
    end
end

reg No_update_flag;
wire No_update_flag_control = change && (inning_reg==3) && (score_B[3:0] > score_A[3:0]);
//wire flag_control = out_valid || !rst_n;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        No_update_flag <= 0;
    end
    else if(out_valid) begin
        No_update_flag <= 0;
    end
    else if(No_update_flag_control) begin
        No_update_flag <= 1;
    end
end

//wire score_control = !rst_n || out_valid;

reg [2:0] base_value;
always @(*) begin
    case(base[7:4])
        4'b0000: base_value = 0;
        4'b0001: base_value = 1;
        4'b0010: base_value = 1;
        4'b0011: base_value = 2;
        4'b0100: base_value = 1;
        4'b0101: base_value = 2;
        4'b0110: base_value = 2;
        4'b0111: base_value = 3;
        4'b1000: base_value = 1;
        4'b1001: base_value = 2;
        4'b1010: base_value = 2;
        4'b1011: base_value = 3;
        4'b1100: base_value = 2;
        4'b1101: base_value = 3;
        4'b1110: base_value = 3;
        4'b1111: base_value = 4;
        default: base_value = 0;
    endcase
end

wire [3:0] score_B_tmp = No_update_flag ? score_B[3:0] : score_B[3:0] + base_value;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        score_A <= 0;
        score_B <= 0;
    end
    else if(next_state != IDLE) begin
        if(half_reg) begin
            score_B[3:0] <= score_B_tmp;
        end
        else begin
            score_A[3:0] <= score_A[3:0] + base_value;
        end
    end
    else if(out_valid) begin
        score_A <= 0;
        score_B <= 0;
    end
    
end

//==============================================//
//                Output Block                  //
//==============================================//
// Decide when to set out_valid high, and output score_A, score_B, and result.


always @(posedge clk or negedge rst_n) begin

    if(!rst_n) out_valid <= 0;
    else if(next_state == OUTPUT) begin
        out_valid <= 1;
    end
    else begin
        out_valid <= 0;
    end

end

always @(posedge clk or negedge rst_n) begin

    if(!rst_n) result <= 0;
    else if(score_A == score_B_tmp) begin
        result <= 2;
    end
    else if(score_A > score_B_tmp) begin
        result <= 0;
    end
    else begin
        result <= 1;
    end

end


//==============================================//
//             DEBUG                            //
//==============================================//





endmodule
