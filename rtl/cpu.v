`default_nettype none

module cpu(
    input clock,
    input reset,
`ifndef NO_TRISTATE
    inout [3:0] data,
`else
    input [3:0] data_i,
    output [3:0] data_o,
    output data_en,
`endif
    input test,
    output sync,
    output rom_cmd,
    output [3:0] ram_cmd_n
);

`ifndef NO_TRISTATE
wire [3:0] data_i;
assign data_i = data;
`endif

wire pc_enable;
wire [3:0] pc_word;
wire [11:0] pc;
wire [2:0] pc_write_enable;
wire [1:0] pc_next_sel;
wire [1:0] pc_control;

wire [2:0] cycle;

wire clear_carry;
wire write_carry;
wire clear_accumulator;
wire write_accumulator;
wire [2:0] acc_input_sel;
wire write_register;
wire [1:0] reg_input_sel;
wire [2:0] alu_op;
wire [2:0] alu_in0_sel;
wire [1:0] alu_in1_sel;
wire [1:0] alu_cin_sel;
wire [3:0] regval;
wire [3:0] acc;

wire [3:0] inst_operand;
wire take_branch;
wire reg_is_zero;

// Write the accumulator from the datapath onto the external data pins.
// This takes precedence over reg_out_enable/pc_enable if multiple are set.
wire acc_out_enable;

// Write the regval from the datapath onto the external data pins.
// This takes precedence over pc_enable if both are set.
wire reg_out_enable;

cpu_control cpu_control(
    .clock(clock),
    .reset(reset),
    .data(data_i),
    .take_branch(take_branch),
    .reg_is_zero(reg_is_zero),
    .sync(sync),
    .cycle(cycle),
    .inst_operand(inst_operand),
    .clear_carry(clear_carry),
    .write_carry(write_carry),
    .clear_accumulator(clear_accumulator),
    .write_accumulator(write_accumulator),
    .acc_input_sel(acc_input_sel),
    .write_register(write_register),
    .reg_input_sel(reg_input_sel),
    .alu_op(alu_op),
    .alu_in0_sel(alu_in0_sel),
    .alu_in1_sel(alu_in1_sel),
    .alu_cin_sel(alu_cin_sel),
    .pc_next_sel(pc_next_sel),
    .pc_write_enable(pc_write_enable),
    .pc_control(pc_control),
    .reg_out_enable(reg_out_enable),
    .acc_out_enable(acc_out_enable),
    .ram_cmd_out(ram_cmd_n),
    .rom_cmd_out(rom_cmd)
);

pc_stack pc_stack(
    .clock(clock),
    .reset(reset),
    .control(pc_control),
    .target(12'b0),
    .regval(regval),
    .data(data_i),
    .inst_operand(inst_operand),
    .pc_next_sel(pc_next_sel),
    .pc_write_enable(pc_write_enable),
    .cycle(cycle),
    .pc(pc),
    .pc_enable(pc_enable),
    .pc_word(pc_word)
);

datapath datapath(
    .clock(clock),
    .reset(reset),
    .data(data_i),
    .clear_carry(clear_carry),
    .write_carry(write_carry),
    .clear_accumulator(clear_accumulator),
    .write_accumulator(write_accumulator),
    .inst_operand(inst_operand),
    .acc_input_sel(acc_input_sel),
    .write_register(write_register),
    .reg_input_sel(reg_input_sel),
    .alu_op(alu_op),
    .alu_in0_sel(alu_in0_sel),
    .alu_in1_sel(alu_in1_sel),
    .alu_cin_sel(alu_cin_sel),
    .regval(regval),
    .acc(acc),
    .take_branch(take_branch),
    .reg_is_zero(reg_is_zero)
);


wire [3:0] data_val;

`ifndef NO_TRISTATE
wire data_en;
assign data = data_en ? data_val : 4'bz;
`else
assign data_o = data_val;
`endif

assign data_val = acc_out_enable ? acc :
                  reg_out_enable ? regval :
                  pc_enable ? pc_word : 4'h0;
assign data_en = acc_out_enable | reg_out_enable | pc_enable;

endmodule
