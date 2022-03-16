`default_nettype none

module system(
    input clock,
    input reset,
    input test
);

wire [3:0] data;
wire sync;
wire rom_cmd;
wire [3:0] ram_cmd_n;
wire [3:0] rom_io;
wire [3:0] ram_out;

`ifdef NO_TRISTATE
assign data = cpu_data_en ? cpu_data_o
            : rom_1_data_en ? rom_1_data_o
            : ram_1_data_en ? ram_1_data_o
            : ram_2_data_en ? ram_2_data_o
            : 4'h0;

wire [3:0] cpu_data_o;
wire cpu_data_en;
wire [3:0] rom_1_data_o;
wire rom_1_data_en;
wire [3:0] ram_1_data_o;
wire ram_1_data_en;
wire [3:0] ram_2_data_o;
wire ram_2_data_en;
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

rom rom_1(
    .clock(clock),
    .reset(reset),
`ifndef NO_TRISTATE
    .data(data),
`else
    .data_i(data),
    .data_o(rom_1_data_o),
    .data_en(rom_1_data_en),
`endif
    .sync(sync),
    .cmd(rom_cmd),
    .io(rom_io),

    // unconnected backdoor
    .wb_data_i(32'h0),
    .wb_addr_i(32'h0),
    .wb_cyc_i(1'h0),
    .wb_strobe_i(1'h0),
    .wb_we_i(1'h0),
    .wb_data_o(),
    .wb_ack_o()
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
    .p0(1'b0),

    // unconnected backdoor
    .wb_data_i(32'h0),
    .wb_addr_i(32'h0),
    .wb_cyc_i(1'h0),
    .wb_strobe_i(1'h0),
    .wb_we_i(1'h0),
    .wb_data_o(),
    .wb_ack_o()
);

ram ram_2(
    .clock(clock),
    .reset(reset),
`ifndef NO_TRISTATE
    .data(data),
`else
    .data_i(data),
    .data_o(ram_2_data_o),
    .data_en(ram_2_data_en),
`endif
    .sync(sync),
    .cmd_n(ram_cmd_n[0]),
    .out(ram_out),
    .p0(1'b1),

    // unconnected backdoor
    .wb_data_i(32'h0),
    .wb_addr_i(32'h0),
    .wb_cyc_i(1'h0),
    .wb_strobe_i(1'h0),
    .wb_we_i(1'h0),
    .wb_data_o(),
    .wb_ack_o()
);

endmodule
