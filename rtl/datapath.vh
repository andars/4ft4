//`ifndef _DATAPATH_VH
//`define _DATAPATH_VH

localparam REG_IN_FROM_ACC  = 2'b00;
localparam REG_IN_FROM_ALU  = 2'b01;
localparam REG_IN_FROM_DATA = 2'b10;

localparam ACC_IN_FROM_IMM    = 3'b000;
localparam ACC_IN_FROM_REG    = 3'b001;
localparam ACC_IN_FROM_ALU    = 3'b010;
localparam ACC_IN_FROM_CARRY  = 3'b011;
localparam ACC_IN_FROM_CARRY2 = 3'b100;

localparam ALU_OP_ADD    = 3'b000;
localparam ALU_OP_ROL    = 3'b001;
localparam ALU_OP_ROR    = 3'b010;
localparam ALU_OP_PASS   = 3'b011;
localparam ALU_OP_DEC_A  = 3'b100;
localparam ALU_OP_LG2_1  = 3'b101;

localparam ALU_IN0_ACC     = 2'b00;
localparam ALU_IN0_REG     = 2'b01;
localparam ALU_IN0_ACC_INV = 2'b10;
localparam ALU_IN0_REG_INV = 2'b11;

localparam ALU_IN1_ACC     = 2'b00;
localparam ALU_IN1_REG     = 2'b01;
localparam ALU_IN1_ONE     = 2'b10;
localparam ALU_IN1_ONE_INV = 2'b11;

localparam ALU_CIN_ZERO      = 2'b00;
localparam ALU_CIN_ONE       = 2'b01;
localparam ALU_CIN_CARRY     = 2'b10;
localparam ALU_CIN_CARRY_INV = 2'b11;

//`endif
