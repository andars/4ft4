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
    output reg [1:0] reg_input_sel,
    output reg [2:0] alu_op,
    output reg [1:0] alu_in0_sel,
    output reg [1:0] alu_in1_sel,
    output reg [1:0] alu_cin_sel,
    output reg [2:0] pc_write_enable
);

`include "datapath.vh"

reg [7:0] inst;

reg two_word;
reg two_word_next;

reg inst_operand_adj;

// pass out the low 4b for use in the datapath
assign inst_operand = inst[3:0] ^ {3'b0, inst_operand_adj};

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
    else if (!two_word) begin
        if (cycle == 3'h3) begin
            inst[7:4] <= data;
        end
        else if (cycle == 3'h4) begin
            inst[3:0] <= data;
        end
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

    pc_write_enable = 0;

    two_word_next = two_word;

    inst_operand_adj = 0;

    if (two_word) begin
        // control signals for the second system cycle
        // of two word instructions

        if (cycle == 3'h5) begin
            // reset the two word bit at the end of this
            // system cycle
            two_word_next = 0;
        end

        case (inst[7:4])
            4'h2: begin
                // FIM
                if (cycle == 3'h3) begin
                    reg_input_sel = REG_IN_FROM_DATA;
                    write_register = 1;
                end

                if (cycle == 3'h4) begin
                    // switch to the second register in the pair
                    inst_operand_adj = 1'b1;

                    reg_input_sel = REG_IN_FROM_DATA;
                    write_register = 1;
                end
            end
            default: begin end
        endcase
    end
    else begin
    case (inst[7:4])
        4'h2: begin
            // FIM: fetch immediate
            if (cycle == 3'h5) begin
                two_word_next = 1;
            end
        end
        4'h3: begin
            if (inst[0]) begin
                // JIN: indirect jump
                if (cycle == 3'h5) begin
                    pc_write_enable = 3'b001;
                end
                else if (cycle == 3'h6) begin
                    inst_operand_adj = 1'b1;
                    pc_write_enable = 3'b010;
                end
            end
            else begin
                // FIN: indirect fetch

                // TODO:
                // - this is a two cycle instruction
                // - PC unit needs to be disabled for the second cycle
                // - register {0,1} is sent to ROM instead of PC, and
                //   loaded into destination registers
            end
        end
        4'h6: begin
            // INC: increment the specified register
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
            // ADD: add register to accumulator
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
            // SUB: subtract register from accumulator
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
                // CLB: clear the accumulator and carry
                if (cycle == 3'h5) begin
                    clear_accumulator = 1;
                    clear_carry = 1;
                end
            end
            4'h1: begin
                // CLC: clear carry
                if (cycle == 3'h5) begin
                    clear_carry = 1;
                end
            end
            4'h2: begin
                // IAC: increment the accumulator
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
                // CMC: invert the carry
                if (cycle == 3'h5) begin
                    alu_cin_sel = ALU_CIN_CARRY_INV;
                    alu_op = ALU_OP_PASS;

                    write_carry = 1;
                end
            end
            4'h4: begin
                // CMA: invert the accumulator
                if (cycle == 3'h5) begin
                    alu_in0_sel = ALU_IN0_ACC_INV;
                    alu_op = ALU_OP_PASS;

                    acc_input_sel = ACC_IN_FROM_ALU;
                    write_accumulator = 1;
                end
            end
            4'h5: begin
                // RAL: rotate accumulator & carry left
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
                // RAR: rotate accumulator & carry right
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
                // TCC: copy carry into accumulator and reset carry
                if (cycle == 3'h5) begin
                    acc_input_sel = ACC_IN_FROM_CARRY;
                    write_accumulator = 1;
                    clear_carry = 1;
                end
            end
            4'h8: begin
                // DAC: decrement accumulator
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
                // TCS: copy carry to accumulator for decimal subtraction
                // and reset carry
                if (cycle == 3'h5) begin
                    acc_input_sel = ACC_IN_FROM_CARRY2;
                    write_accumulator = 1;
                    clear_carry = 1;
                end
            end
            4'ha: begin
                // STC: set carry
                if (cycle == 3'h5) begin
                    // alternative to ALU_CIN_ONE:
                    // ROL with in1[3] = 1
                    alu_cin_sel = ALU_CIN_ONE;
                    alu_op = ALU_OP_PASS;

                    write_carry = 1;
                end
            end
            4'hb: begin
                // DAA: transform accumulator for decimal addition
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
                // KBP
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
end

always @(posedge clock) begin
    if (reset) begin
        two_word <= 0;
    end
    else begin
        two_word <= two_word_next;
    end
end
endmodule
