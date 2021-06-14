`default_nettype none

module cpu(
    input clock,
    input reset,
    inout [3:0] data,
    input test,
    output sync,
    output rom_cmd,
    output [3:0] ram_cmd
);

wire pc_enable;
wire [3:0] pc_word;
wire [11:0] pc;

wire [2:0] cycle;

reg [7:0] inst;

cpu_control cpu_control(
    .clock(clock),
    .reset(reset),
    .sync(sync),
    .cycle(cycle)
);

pc_stack pc_stack(
    .clock(clock),
    .reset(reset),
    .control(2'b0),
    .target(12'b0),
    .cycle(cycle),
    .pc(pc),
    .pc_enable(pc_enable),
    .pc_word(pc_word)
);

assign data = pc_enable ? pc_word : 4'bz;

// read data from ROM into an internal register
// during subcycles 3 and 4
always @(posedge clock) begin
    if (reset) begin
        inst <= 0;
    end
    else if (cycle == 3'h3) begin
        inst[7:4] <= data;
    end
    else if (cycle == 3'h4) begin
        inst[3:0] <= data;
    end
end

// pulse ROM command line low in subcycle 2
assign rom_cmd = ~(cycle == 3'h2);

endmodule
