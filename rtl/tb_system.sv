`timescale 1ns/1ns
`default_nettype none

module tb_system();

reg clock;
reg reset;
reg test;
wire sync;
reg [31:0] cycle_counter;
wire [3:0] data;

system dut(
    .clock(clock),
    .reset(reset),
    .test(test)
);


initial begin
    clock = 0;
    reset = 0;
    test = 0;
    cycle_counter = 0;
end

always begin
    #10 clock = ~clock;
end

always @(posedge clock) begin
    if (reset) begin
        cycle_counter <= 0;
    end
    else begin
        cycle_counter <= cycle_counter + 1;
    end
end

integer i;
initial begin
    $dumpfile("waves.vcd");
    $dumpvars;
    $dumpvars(0, dut.cpu.pc_stack.program_counters[0]);

    for (i = 0; i < 16; i++) begin
        $dumpvars(0, dut.cpu.datapath.registers[i]);
    end

    reset = 1;
    repeat(2) @(posedge clock);
    reset = 0;

    repeat(512) @(posedge clock);

    $finish;
end

endmodule
