`default_nettype none

module datapath(
    input clock,
    input reset,
    input [3:0] data,
    input clear_carry,
    input write_carry,
    input clear_accumulator,
    input write_accumulator,
    input [3:0] inst_operand,
    input [2:0] acc_input_sel,
    input write_register,
    input [1:0] reg_input_sel,
    input [2:0] alu_op,
    input [1:0] alu_in0_sel,
    input [1:0] alu_in1_sel,
    input [1:0] alu_cin_sel,
    output [3:0] regval,
    output [3:0] acc,
    output take_branch,
    output reg_is_zero
);

`include "datapath.vh"

reg [3:0] accumulator;
reg carry;

reg [3:0] registers [15:0];

assign regval = registers[inst_operand];
assign acc = accumulator;

wire [4:0] alu_result;

alu alu(
    .regval(regval),
    .acc(accumulator),
    .carry(carry),
    .alu_op(alu_op),
    .alu_in0_sel(alu_in0_sel),
    .alu_in1_sel(alu_in1_sel),
    .alu_cin_sel(alu_cin_sel),
    .result(alu_result)
);

integer i;

wire [3:0] acc_input;

assign acc_input = (acc_input_sel == ACC_IN_FROM_REG)    ? regval
                 : (acc_input_sel == ACC_IN_FROM_DATA)   ? data
                 : (acc_input_sel == ACC_IN_FROM_ALU)    ? alu_result[3:0]
                 : (acc_input_sel == ACC_IN_FROM_IMM)    ? inst_operand
                 : (acc_input_sel == ACC_IN_FROM_CARRY)  ? {3'b0, carry}
                 : (acc_input_sel == ACC_IN_FROM_CARRY2) ? (carry ? 4'ha : 4'h9)
                 : 4'bx;

wire carry_input;

assign carry_input = alu_result[4];

always @(posedge clock) begin
    if (reset) begin
        accumulator <= 0;
        carry <= 1;
    end
    else begin
        if (clear_carry) begin
            carry <= 0;
        end
        else if (write_carry) begin
            carry <= carry_input;
        end

        if (clear_accumulator) begin
            accumulator <= 0;
        end
        else if (write_accumulator) begin
            accumulator <= acc_input;
        end
    end
end

wire [3:0] reg_input;
assign reg_input = (reg_input_sel == REG_IN_FROM_ACC) ? accumulator
                 : (reg_input_sel == REG_IN_FROM_ALU) ? alu_result[3:0]
                 : (reg_input_sel == REG_IN_FROM_DATA) ? data
                 : 4'bx;

always @(posedge clock) begin
    if (reset) begin
        for (i = 0; i < 16; i++) begin
           registers[i] <= 0;
        end
    end
    else begin
        if (write_register) begin
            registers[inst_operand] <= reg_input;
        end
    end
end

reg _take_branch;
always @(*) begin
    _take_branch = 0;
    /* TODO: add test signal
    if (inst_operand[0]  && test ) begin
        _take_branch = 1;
    end
    */
    if (inst_operand[1] && carry) begin
        _take_branch = 1;
    end
    if (inst_operand[2] && (accumulator == 4'h0)) begin
        _take_branch = 1;
    end
end

assign take_branch = inst_operand[3] ? ~_take_branch : _take_branch;
assign reg_is_zero = (regval == 4'h0);

endmodule
