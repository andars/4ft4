module system(
    input clock,
    input reset,
    input test
);

wire [3:0] data;
wire sync;
wire rom_cmd;
wire [3:0] ram_cmd;

cpu cpu(
    .clock(clock),
    .reset(reset),
    .data(data),
    .test(test),
    .sync(sync),
    .rom_cmd(rom_cmd),
    .ram_cmd(ram_cmd)
);

rom rom_1(
    .clock(clock),
    .reset(reset),
    .data(data),
    .sync(sync)
);

endmodule
