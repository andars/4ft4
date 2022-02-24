`default_nettype none

module pc_stack(
    input clock,
    input reset,
    input [1:0] control,
    input [11:0] target,
    input [3:0] regval,
    input [3:0] data,
    input [3:0] inst_operand,
    input [1:0] pc_next_sel,
    input [2:0] pc_write_enable,
    output [11:0] pc,
    input [2:0] cycle, 
    output reg pc_enable,
    output reg [3:0] pc_word
);

`include "pc_stack.vh"

reg [11:0] program_counters[3:0];
reg [1:0] index;
reg carry;

integer i;

wire [3:0] pc_next;
assign pc_next = (pc_next_sel == PC_FROM_DATA) ? data
               : (pc_next_sel == PC_FROM_REG)  ? regval
               : (pc_next_sel == PC_FROM_INST) ? inst_operand
               : 4'bx;

always @(posedge clock) begin
    if (reset) begin
        for (i = 0; i < 4; i++) begin
            program_counters[i] <= 0;
        end
        index <= 0;
        carry <= 0;
    end
    else if (cycle == 3'h0) begin
        {carry, program_counters[index][3:0]} <= program_counters[index][3:0] + 1;
    end
    else if (cycle == 3'h1) begin
        {carry, program_counters[index][7:4]} <= program_counters[index][7:4] + {3'b0, carry};
    end
    else if (cycle == 3'h2) begin
        program_counters[index][11:8] <= program_counters[index][11:8] + {3'b0, carry};
    end
    else if (pc_write_enable != 3'b0) begin
        if (pc_write_enable[0]) begin
            program_counters[index][3:0] <= pc_next;
        end
        else if (pc_write_enable[1]) begin
            program_counters[index][7:4] <= pc_next;
        end
        else begin
            program_counters[index][11:8] <= pc_next;
        end
    end
    else begin
        // store the target in the current slot
        if (0) begin
            program_counters[index] <= target;
        end
        else begin
            program_counters[index] <= program_counters[index];
        end

        // and update the slot index if needed
        if (control == 0) begin
            index <= index;
        end
        else if (control == 1) begin
            index <= index + 1;
        end
        else if (control == 2) begin
            index <= index - 1;
        end
    end
end

always @(*) begin
    case (cycle)
        3'h0: begin
            pc_word = program_counters[index][3:0];
            pc_enable = 1;
        end
        3'h1: begin
            pc_word = program_counters[index][7:4];
            pc_enable = 1;
        end
        3'h2: begin
            pc_word = program_counters[index][11:8];
            pc_enable = 1;
        end
        default: begin
            pc_word = 4'b0;
            pc_enable = 0;
        end
    endcase
end

endmodule
