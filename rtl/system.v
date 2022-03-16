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

cpu cpu(
    .clock(clock),
    .reset(reset),
    .data(data),
    .test(test),
    .sync(sync),
    .rom_cmd(rom_cmd),
    .ram_cmd_n(ram_cmd_n)
);

rom rom_1(
    .clock(clock),
    .reset(reset),
    .data(data),
    .sync(sync),
    .cmd(rom_cmd),
    .io(rom_io),

    // unconnected backdoor
    .data_i(32'h0),
    .addr_i(32'h0),
    .cyc_i(1'h0),
    .strobe_i(1'h0),
    .we_i(1'h0),
    .data_o(),
    .ack_o()
);

ram ram_1(
    .clock(clock),
    .reset(reset),
    .data(data),
    .sync(sync),
    .cmd_n(ram_cmd_n[0]),
    .out(ram_out),
    .p0(1'b0),

    // unconnected backdoor
    .data_i(32'h0),
    .addr_i(32'h0),
    .cyc_i(1'h0),
    .strobe_i(1'h0),
    .we_i(1'h0),
    .data_o(),
    .ack_o()
);

ram ram_2(
    .clock(clock),
    .reset(reset),
    .data(data),
    .sync(sync),
    .cmd_n(ram_cmd_n[0]),
    .out(ram_out),
    .p0(1'b1),

    // unconnected backdoor
    .data_i(32'h0),
    .addr_i(32'h0),
    .cyc_i(1'h0),
    .strobe_i(1'h0),
    .we_i(1'h0),
    .data_o(),
    .ack_o()
);

endmodule
