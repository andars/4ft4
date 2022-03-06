`default_nettype none

module alu(
    input [3:0] regval,
    input [3:0] acc,
    input [3:0] data,
    input carry,
    input [2:0] alu_op,
    input [2:0] alu_in0_sel,
    input [1:0] alu_in1_sel,
    input [1:0] alu_cin_sel,
    output [4:0] result
);

`include "datapath.vh"

wire [3:0] alu_in0;
wire [3:0] alu_in1;
wire alu_cin;

reg [3:0] lg2_plus_1;
reg [4:0] dec_adjust;

assign alu_in0 = (alu_in0_sel == ALU_IN0_ACC) ? acc
               : (alu_in0_sel == ALU_IN0_ACC_INV) ? ~acc
               : (alu_in0_sel == ALU_IN0_REG) ? regval
               : (alu_in0_sel == ALU_IN0_REG_INV) ? ~regval
               : (alu_in0_sel == ALU_IN0_DATA) ? data
               : 4'bx;

assign alu_in1 = (alu_in1_sel == ALU_IN1_ACC) ? acc
               : (alu_in1_sel == ALU_IN1_REG) ? regval
               : (alu_in1_sel == ALU_IN1_ONE) ? 4'b1
               : (alu_in1_sel == ALU_IN1_ONE_INV) ? 4'b1110
               : 4'bx;

assign alu_cin = (alu_cin_sel == ALU_CIN_ZERO) ? 1'b0
               : (alu_cin_sel == ALU_CIN_ONE) ? 1'b1
               : (alu_cin_sel == ALU_CIN_CARRY) ? carry
               : (alu_cin_sel == ALU_CIN_CARRY_INV) ? ~carry
               : 1'bx;

assign result = (alu_op == ALU_OP_ADD)   ? (alu_in0 + alu_in1 + {4'b0, alu_cin})
              : (alu_op == ALU_OP_ROL)   ? {alu_in0[3:0], alu_cin}
              : (alu_op == ALU_OP_ROR)   ? {alu_in0[0], alu_cin, alu_in0[3:1]}
              : (alu_op == ALU_OP_PASS)  ? {alu_cin, alu_in0}
              : (alu_op == ALU_OP_DEC_A) ? dec_adjust
              : (alu_op == ALU_OP_LG2_1) ? {1'b0, lg2_plus_1}
              : 5'bx;

// decimal adjust lookup
always @(*) begin
    if (alu_cin) begin
        case (alu_in0)
            4'h0: dec_adjust = {alu_cin, 4'h6};
            4'h1: dec_adjust = {alu_cin, 4'h7};
            4'h2: dec_adjust = {alu_cin, 4'h8};
            4'h3: dec_adjust = {alu_cin, 4'h9};
            4'h4: dec_adjust = {alu_cin, 4'ha};
            4'h5: dec_adjust = {alu_cin, 4'hb};
            4'h6: dec_adjust = {alu_cin, 4'hc};
            4'h7: dec_adjust = {alu_cin, 4'hd};
            4'h8: dec_adjust = {alu_cin, 4'he};
            4'h9: dec_adjust = {alu_cin, 4'hf};
            4'ha: dec_adjust = {1'b1,    4'h0};
            4'hb: dec_adjust = {1'b1,    4'h1};
            4'hc: dec_adjust = {1'b1,    4'h2};
            4'hd: dec_adjust = {1'b1,    4'h3};
            4'he: dec_adjust = {1'b1,    4'h4};
            4'hf: dec_adjust = {1'b1,    4'h5};
        endcase
    end
    else begin
        case (alu_in0)
            default: dec_adjust = {alu_cin, alu_in0};
            4'ha: dec_adjust = {1'b1, 4'h0};
            4'hb: dec_adjust = {1'b1, 4'h1};
            4'hc: dec_adjust = {1'b1, 4'h2};
            4'hd: dec_adjust = {1'b1, 4'h3};
            4'he: dec_adjust = {1'b1, 4'h4};
            4'hf: dec_adjust = {1'b1, 4'h5};
        endcase
    end
end

// lookup for log2 + 1
always @(*) begin
    case (alu_in0)
        4'h0:    lg2_plus_1 = 4'h0;
        4'h1:    lg2_plus_1 = 4'h1;
        4'h2:    lg2_plus_1 = 4'h2;
        4'h4:    lg2_plus_1 = 4'h3;
        4'h8:    lg2_plus_1 = 4'h4;
        default: lg2_plus_1 = 4'hf;
    endcase
end

endmodule
