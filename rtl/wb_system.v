`default_nettype none

module wb_system(
    input clock,
    input reset,
    input test,
    input [31:0] wb_data_i,
    input [31:0] wb_addr_i,
    input wb_cyc_i,
    input wb_strobe_i,
    input wb_we_i,
    output [31:0] wb_data_o,
    output wb_ack_o
);

wire [3:0] data;
wire sync;
wire rom_cmd;
wire [3:0] ram_cmd_n;
wire [3:0] rom_io;
wire [3:0] ram_out;

cpu cpu(
    .clock(clock),
    .reset(reset),
    .data(data),
    .test(test),
    .sync(sync),
    .rom_cmd(rom_cmd),
    .ram_cmd_n(ram_cmd_n)
);

reg rom_0_strobe_i;
wire [31:0] rom_0_data_o;
wire rom_0_ack_o;

reg ram_0_strobe_i;
wire [31:0] ram_0_data_o;
wire ram_0_ack_o;

reg [31:0] selected_data;
assign wb_data_o = selected_data;

always @(*) begin
    rom_0_strobe_i = 0;
    ram_0_strobe_i = 0;
    selected_data = 0;
    if (wb_addr_i[17:16] == 2'h0) begin
        rom_0_strobe_i = wb_strobe_i;
        selected_data = rom_0_data_o;
    end
    else if (wb_addr_i[17:16] == 2'h0) begin
        ram_0_strobe_i = wb_strobe_i;
        selected_data = ram_0_data_o;
    end
end

assign wb_ack_o = rom_0_ack_o | ram_0_ack_o;

rom rom_0(
    .clock(clock),
    .reset(reset),
    // frontdoor
    .data(data),
    .sync(sync),
    .cmd(rom_cmd),
    .io(rom_io),

    // backdoor wishbone
    .data_i(wb_data_i),
    .addr_i(wb_addr_i),
    .cyc_i(wb_cyc_i),
    .strobe_i(rom_0_strobe_i),
    .we_i(wb_we_i),
    .data_o(rom_0_data_o),
    .ack_o(rom_0_ack_o)
);

ram ram_0(
    .clock(clock),
    .reset(reset),
    .data(data),
    .sync(sync),
    .cmd_n(ram_cmd_n[0]),
    .out(ram_out),
    .p0(1'b0),

    // backdoor
    .data_i(wb_data_i),
    .addr_i(wb_addr_i),
    .cyc_i(wb_cyc_i),
    .strobe_i(ram_0_strobe_i),
    .we_i(wb_we_i),
    .data_o(ram_0_data_o),
    .ack_o(ram_0_ack_o)
);

ram ram_1(
    .clock(clock),
    .reset(reset),
    .data(data),
    .sync(sync),
    .cmd_n(ram_cmd_n[0]),
    .out(ram_out),
    .p0(1'b1),

    // unconnected backdoor
    // TODO: connect
    .data_i(32'h0),
    .addr_i(32'h0),
    .cyc_i(1'h0),
    .strobe_i(1'h0),
    .we_i(1'h0),
    .data_o(),
    .ack_o()
);

`ifdef COCOTB_SIM
`ifdef COCOTB_SIM_WB_SYSTEM_TOP
integer i;
initial begin
    $dumpfile("wb_system.vcd");
    $dumpvars;
    for (i = 0; i < 4; i++) begin
        $dumpvars(0, cpu.pc_stack.program_counters[i]);
    end
    for (i = 0; i < 64; i++) begin
        $dumpvars(0, rom_0.memory[i]);
    end
    for (i = 0; i < 64; i++) begin
        $dumpvars(0, ram_0.memory[i]);
    end
    for (i = 0; i < 16; i++) begin
        $dumpvars(0, ram_0.status[i]);
    end
    #1;
end
`endif
`endif

endmodule
