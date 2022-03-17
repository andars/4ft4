`default_nettype none

module wb_system(
    input clock,
    input reset,
    input test,
    output [3:0] rom_out,
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

assign rom_out = rom_io;

`ifdef NO_TRISTATE
assign data = cpu_data_en ? cpu_data_o
            : rom_0_data_en ? rom_0_data_o
            : ram_0_data_en ? ram_0_data_o
            : ram_1_data_en ? ram_1_data_o
            : 4'h0;

wire [3:0] cpu_data_o;
wire cpu_data_en;
wire [3:0] rom_0_data_o;
wire rom_0_data_en;
wire [3:0] ram_0_data_o;
wire ram_0_data_en;
wire [3:0] ram_1_data_o;
wire ram_1_data_en;
`endif

cpu cpu(
    .clock(clock),
    .reset(reset),
`ifndef NO_TRISTATE
    .data(data),
`else
    .data_i(data),
    .data_o(cpu_data_o),
    .data_en(cpu_data_en),
`endif
    .test(test),
    .sync(sync),
    .rom_cmd(rom_cmd),
    .ram_cmd_n(ram_cmd_n)
);

reg rom_0_strobe_i;
wire [31:0] rom_0_wb_data_o;
wire rom_0_ack_o;

reg ram_0_strobe_i;
wire [31:0] ram_0_wb_data_o;
wire ram_0_ack_o;

reg [31:0] selected_data;
assign wb_data_o = selected_data;

always @(*) begin
    rom_0_strobe_i = 0;
    ram_0_strobe_i = 0;
    selected_data = 0;
    if (wb_addr_i[17:16] == 2'h0) begin
        rom_0_strobe_i = wb_strobe_i;
        selected_data = rom_0_wb_data_o;
    end
    else if (wb_addr_i[17:16] == 2'h1) begin
        ram_0_strobe_i = wb_strobe_i;
        selected_data = ram_0_wb_data_o;
    end
end

assign wb_ack_o = rom_0_ack_o | ram_0_ack_o;

rom rom_0(
    .clock(clock),
    .reset(reset),
    // frontdoor
`ifndef NO_TRISTATE
    .data(data),
`else
    .data_i(data),
    .data_o(rom_0_data_o),
    .data_en(rom_0_data_en),
`endif
    .sync(sync),
    .cmd(rom_cmd),
    .io(rom_io),

    // backdoor wishbone
    .wb_data_i(wb_data_i),
    .wb_addr_i(wb_addr_i),
    .wb_cyc_i(wb_cyc_i),
    .wb_strobe_i(rom_0_strobe_i),
    .wb_we_i(wb_we_i),
    .wb_data_o(rom_0_wb_data_o),
    .wb_ack_o(rom_0_ack_o)
);

ram ram_0(
    .clock(clock),
    .reset(reset),
`ifndef NO_TRISTATE
    .data(data),
`else
    .data_i(data),
    .data_o(ram_0_data_o),
    .data_en(ram_0_data_en),
`endif
    .sync(sync),
    .cmd_n(ram_cmd_n[0]),
    .out(ram_out),
    .p0(1'b0),

    // backdoor
    .wb_data_i(wb_data_i),
    .wb_addr_i(wb_addr_i),
    .wb_cyc_i(wb_cyc_i),
    .wb_strobe_i(ram_0_strobe_i),
    .wb_we_i(wb_we_i),
    .wb_data_o(ram_0_wb_data_o),
    .wb_ack_o(ram_0_ack_o)
);

ram ram_1(
    .clock(clock),
    .reset(reset),
`ifndef NO_TRISTATE
    .data(data),
`else
    .data_i(data),
    .data_o(ram_1_data_o),
    .data_en(ram_1_data_en),
`endif
    .sync(sync),
    .cmd_n(ram_cmd_n[0]),
    .out(ram_out),
    .p0(1'b1),

    // unconnected backdoor
    // TODO: connect
    .wb_data_i(32'h0),
    .wb_addr_i(32'h0),
    .wb_cyc_i(1'h0),
    .wb_strobe_i(1'h0),
    .wb_we_i(1'h0),
    .wb_data_o(),
    .wb_ack_o()
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
