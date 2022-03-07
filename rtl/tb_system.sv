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
integer j;

initial begin
    $dumpfile("waves.vcd");
    $dumpvars;
    for (i = 0; i < 3; i++) begin
        $dumpvars(0, dut.cpu.pc_stack.program_counters[i]);
    end

    for (i = 0; i < 16; i++) begin
        $dumpvars(0, dut.cpu.datapath.registers[i]);
    end

    for (i = 0; i < 64; i++) begin
        $dumpvars(0, dut.ram_1.memory[i]);
    end
    for (i = 0; i < 16; i++) begin
        $dumpvars(0, dut.ram_1.status[i]);
    end

    reset = 1;
    repeat(2) @(posedge clock);
    reset = 0;

    i = 0;
    while ((dut.cpu.pc_stack.program_counters[dut.cpu.pc_stack.index] < `ROM_SIZE)) begin
        repeat(8) @(posedge clock);
        i++;
    end

    $display("Finished.");
    $display(" accumulator: 0x%0x", dut.cpu.datapath.accumulator);
    for (i = 0; i < 8; i++) begin
        $display(" register %2d: 0x%0x | register %2d: 0x%0x",
                 2*i, dut.cpu.datapath.registers[2*i],
                 2*i+1, dut.cpu.datapath.registers[2*i + 1]);
    end
    $display(" carry: %0d", dut.cpu.datapath.carry);
    $display(" pc: 0x%0x", dut.cpu.pc_stack.program_counters[0]);
    $display(" stack pointer: 0x%0x", dut.cpu.pc_stack.index);
    for (i = 0; i < 4; i++) begin
        $display(" stack %1d: 0x%0x", i, dut.cpu.pc_stack.program_counters[i]);
    end
    for (i = 0; i < 4; i++) begin
        $write(" ram 0 reg %1d:", i);
        for (j = 0; j < 16; j++) begin
            $write(" %1x", dut.ram_1.memory[16*i + j]);
        end
        $write(" | ram 0 reg %1d status:", i);
        for (j = 0; j < 4; j++) begin
            $write(" %1x", dut.ram_1.status[4*i + j]);
        end
        $write("\n");
    end
    for (i = 0; i < 4; i++) begin
        $write(" ram 1 reg %1d:", i);
        for (j = 0; j < 16; j++) begin
            $write(" %1x", dut.ram_2.memory[16*i + j]);
        end
        $write("\n");
    end

    $finish;
end

endmodule
