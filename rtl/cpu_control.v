`default_nettype none

module cpu_control(
    input clock,
    input reset,
    input [3:0] data,
    output sync,
    output reg [2:0] cycle,
    output [3:0] inst_operand,
    output reg clear_carry,
    output reg write_carry,
    output reg clear_accumulator,
    output reg write_accumulator,
    output reg [2:0] acc_input_sel,
    output reg write_register,
    output reg reg_input_sel,
    output reg [2:0] alu_op,
    output reg [1:0] alu_in0_sel,
    output reg [1:0] alu_in1_sel,
    output reg [1:0] alu_cin_sel
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
    write_carry = 0;
    clear_accumulator = 0;
    write_accumulator = 0;
    acc_input_sel = 0;

    write_register = 0;
    reg_input_sel = 0;

    alu_op = 0;
    alu_in0_sel = 0;
    alu_in1_sel = 0;
    alu_cin_sel = 0;

    case (inst[7:4])
        4'h6: begin
            // increment the specified register
            if (cycle == 3'h5) begin
                alu_in0_sel = ALU_IN0_REG;
                alu_in1_sel = ALU_IN1_ONE;
                alu_cin_sel = ALU_CIN_ZERO;
                alu_op = ALU_OP_ADD;

                reg_input_sel = REG_IN_FROM_ALU;
                write_register = 1;
                // do not update carry
            end
        end
        4'h8: begin
            // add register to accumulator
            if (cycle == 3'h5) begin
                alu_in0_sel = ALU_IN0_REG;
                alu_in1_sel = ALU_IN1_ACC;
                alu_cin_sel = ALU_CIN_CARRY;
                alu_op = ALU_OP_ADD;

                acc_input_sel = ACC_IN_FROM_ALU;
                write_accumulator = 1;
                write_carry = 1;
            end
        end
        4'h9: begin
            // subtract register from accumulator
            if (cycle == 3'h5) begin
                alu_in0_sel = ALU_IN0_REG_INV;
                alu_in1_sel = ALU_IN1_ACC;
                alu_cin_sel = ALU_CIN_CARRY_INV;
                alu_op = ALU_OP_ADD;

                acc_input_sel = ACC_IN_FROM_ALU;
                write_accumulator = 1;
                write_carry = 1;
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
        4'ha: begin
            // load register into accumulator
            if (cycle == 3'h5) begin
                acc_input_sel = ACC_IN_FROM_REG;
                write_accumulator = 1;
            end
        end
        // carry/accumulator instructions
        4'hf: begin
            case (inst[3:0])
            4'h0: begin
                // clear the accumulator and carry
                if (cycle == 3'h5) begin
                    clear_accumulator = 1;
                    clear_carry = 1;
                end
            end
            4'h1: begin
                // clear carry
                if (cycle == 3'h5) begin
                    clear_carry = 1;
                end
            end
            4'h2: begin
                // increment the accumulator
                if (cycle == 3'h5) begin
                    alu_in0_sel = ALU_IN0_ACC;
                    alu_in1_sel = ALU_IN1_ONE;
                    alu_cin_sel = ALU_CIN_ZERO;
                    alu_op = ALU_OP_ADD;

                    acc_input_sel = ACC_IN_FROM_ALU;
                    write_accumulator = 1;
                    write_carry = 1;
                end
            end
            4'h3: begin
                // invert the carry
                if (cycle == 3'h5) begin
                    alu_cin_sel = ALU_CIN_CARRY_INV;
                    alu_op = ALU_OP_PASS;

                    write_carry = 1;
                end
            end
            4'h4: begin
                // invert the accumulator
                if (cycle == 3'h5) begin
                    alu_in0_sel = ALU_IN0_ACC_INV;
                    alu_op = ALU_OP_PASS;

                    acc_input_sel = ACC_IN_FROM_ALU;
                    write_accumulator = 1;
                end
            end
            4'h5: begin
                // rotate accumulator & carry left
                if (cycle == 3'h5) begin
                    alu_in0_sel = ALU_IN0_ACC;
                    alu_cin_sel = ALU_CIN_CARRY;

                    alu_op = ALU_OP_ROL;

                    acc_input_sel = ACC_IN_FROM_ALU;
                    write_accumulator = 1;
                    write_carry = 1;
                end
            end
            4'h6: begin
                // rotate accumulator & carry right
                if (cycle == 3'h5) begin
                    alu_in0_sel = ALU_IN0_ACC;
                    alu_cin_sel = ALU_CIN_CARRY;
                    alu_op = ALU_OP_ROR;

                    acc_input_sel = ACC_IN_FROM_ALU;
                    write_accumulator = 1;
                    write_carry = 1;
                end
            end
            4'h7: begin
                // copy carry into accumulator and reset carry
                if (cycle == 3'h5) begin
                    acc_input_sel = ACC_IN_FROM_CARRY;
                    write_accumulator = 1;
                    clear_carry = 1;
                end
            end
            4'h8: begin
                // decrement accumulator
                if (cycle == 3'h5) begin
                    alu_in0_sel = ALU_IN0_ACC;
                    // TODO: use IN1_F and CIN_ZERO?
                    alu_in1_sel = ALU_IN1_ONE_INV;
                    alu_cin_sel = ALU_CIN_ONE;
                    alu_op = ALU_OP_ADD;


                    acc_input_sel = ACC_IN_FROM_ALU;
                    write_accumulator = 1;
                    write_carry = 1;
                end
            end
            4'h9: begin
                // copy carry to accumulator for decimal subtraction
                // and reset carry
                if (cycle == 3'h5) begin
                    acc_input_sel = ACC_IN_FROM_CARRY2;
                    write_accumulator = 1;
                    clear_carry = 1;
                end
            end
            4'ha: begin
                // set carry
                if (cycle == 3'h5) begin
                    // alternative to ALU_CIN_ONE:
                    // ROL with in1[3] = 1
                    alu_cin_sel = ALU_CIN_ONE;
                    alu_op = ALU_OP_PASS;

                    write_carry = 1;
                end
            end
            4'hb: begin
                // transform accumulator for decimal addition
                if (cycle == 3'h5) begin
                    alu_in0_sel = ALU_IN0_ACC;
                    alu_cin_sel = ALU_CIN_CARRY;
                    alu_op = ALU_OP_DEC_A;

                    acc_input_sel = ACC_IN_FROM_ALU;
                    write_accumulator = 1;
                    write_carry = 1;
                end
            end
            4'hc: begin
                if (cycle == 3'h5) begin
                    alu_in0_sel = ALU_IN0_ACC;
                    alu_op = ALU_OP_LG2_1;

                    acc_input_sel = ACC_IN_FROM_ALU;
                    write_accumulator = 1;
                end
            end
            default: begin end
            endcase
        end
        default: begin end
    endcase
end

endmodule
