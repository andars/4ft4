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
    .io(rom_io)
);

ram ram_1(
    .clock(clock),
    .reset(reset),
    .data(data),
    .sync(sync),
    .cmd_n(ram_cmd_n[0]),
    .out(ram_out),
    .p0(1'b0)
);

ram ram_2(
    .clock(clock),
    .reset(reset),
    .data(data),
    .sync(sync),
    .cmd_n(ram_cmd_n[0]),
    .out(ram_out),
    .p0(1'b1)
);

endmodule
