`default_nettype none

module cpu_control(
    input clock,
    input reset,
    input [3:0] data,
    output sync,
    output reg [2:0] cycle,
    output [3:0] inst_operand,
    output reg clear_carry,
    output reg clear_accumulator,
    output reg write_accumulator,
    output reg [1:0] acc_input_sel,
    output reg write_register,
    output reg reg_input_sel
);

`include "datapath.vh"

reg [7:0] inst;

// pass out the low 4b for use in the datapath
assign inst_operand = inst[3:0];

always @(posedge clock) begin
    if (reset) begin
        cycle <= 3'b0;
    end
    else begin
        cycle <= cycle + 1;
    end
end

assign sync = ~(cycle == 3'b111);

// read data from ROM into an internal register
// during subcycles 3 and 4
always @(posedge clock) begin
    if (reset) begin
        inst <= 0;
    end
    else if (cycle == 3'h3) begin
        inst[7:4] <= data;
    end
    else if (cycle == 3'h4) begin
        inst[3:0] <= data;
    end
end

always @(*) begin
    clear_carry = 0;
    clear_accumulator = 0;
    write_accumulator = 0;
    acc_input_sel = 0;

    write_register = 0;
    reg_input_sel = 0;

    case (inst[7:4])
        4'h8: begin
            // add register to accumulator
            if (cycle == 3'h5) begin
                acc_input_sel = ACC_IN_FROM_ALU;
                write_accumulator = 1;
            end
        end
        4'hb: begin
            // swap values in register and accumulator
            if (cycle == 3'h5) begin
                acc_input_sel = ACC_IN_FROM_REG;
                write_accumulator = 1;

                reg_input_sel = REG_IN_FROM_ACC;
                write_register = 1;
            end
        end
        4'hd: begin
            // load immediate into accumulator
            if (cycle == 3'h5) begin
                acc_input_sel = ACC_IN_FROM_IMM;
                write_accumulator = 1;
            end
        end
        // carry/accumulator instructions
        4'hf: begin
            case (inst[3:0])
            4'h0: begin
                if (cycle == 3'h5) begin
                    clear_carry = 1;
                    clear_accumulator = 1;
                end
            end
            4'h1: begin
                if (cycle == 3'h5) begin
                    clear_carry = 1;
                end
            end
            default: begin end
            endcase
        end
        default: begin end
    endcase
end

endmodule
