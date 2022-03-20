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

`ifndef SYSTEM_NUM_ROMS
`define SYSTEM_NUM_ROMS 1
`endif

`ifndef SYSTEM_NUM_RAMS
`define SYSTEM_NUM_RAMS 2
`endif

wire sync;
wire rom_cmd;
wire [3:0] ram_cmd_n;
wire [3:0] rom_io;
wire [3:0] ram_out;

assign rom_out = rom_io;

`ifdef NO_TRISTATE
reg [3:0] data;

integer x, y;
always @(*) begin
    data = 0;
    if (cpu_data_en) begin
        data = cpu_data_o;
    end
    for (x = 0; x < `SYSTEM_NUM_ROMS; x++) begin
        if (rom_data_en[x]) begin
            data = rom_data_o[x];
        end
    end
    for (y = 0; y < `SYSTEM_NUM_ROMS; y++) begin
        if (ram_data_en[y]) begin
            data = ram_data_o[y];
        end
    end
end

wire [3:0] cpu_data_o;
wire cpu_data_en;

wire [3:0] rom_data_o[`SYSTEM_NUM_ROMS-1:0];
wire [`SYSTEM_NUM_ROMS:0] rom_data_en;

wire [3:0] ram_data_o[`SYSTEM_NUM_RAMS-1:0];
wire [`SYSTEM_NUM_RAMS-1:0] ram_data_en;
`else
wire [3:0] data;
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

`ifdef COCOTB_SIM
`ifdef COCOTB_SIM_WB_SYSTEM_TOP
integer i;
initial begin
    $dumpfile("wb_system.vcd");
    #10;
    $dumpvars;
    for (i = 0; i < 4; i++) begin
        $dumpvars(0, cpu.pc_stack.program_counters[i]);
    end
    #1;
end
`endif
`endif

reg [`SYSTEM_NUM_ROMS-1:0] rom_strobe_i;
wire [31:0] rom_wb_data_o [`SYSTEM_NUM_ROMS-1:0];
wire [`SYSTEM_NUM_ROMS-1:0] rom_wb_ack_o;

reg [`SYSTEM_NUM_RAMS-1:0] ram_strobe_i;
wire [31:0] ram_wb_data_o [`SYSTEM_NUM_RAMS-1:0];
wire [`SYSTEM_NUM_RAMS-1:0] ram_wb_ack_o;

reg [31:0] selected_data;
assign wb_data_o = selected_data;

integer ri;
integer rj;
integer k;
integer r;

always @(*) begin
    for (k = 0; k < `SYSTEM_NUM_ROMS; k++) begin
        rom_strobe_i[k] = 0;
    end
    for (r = 0; r < `SYSTEM_NUM_RAMS; r++) begin
        ram_strobe_i[r] = 0;
    end

    selected_data = 0;

    if (wb_addr_i[17:16] == 2'h0) begin
        for (ri = 0; ri < `SYSTEM_NUM_ROMS; ri++) begin
            if (wb_addr_i[13:10] == ri[3:0]) begin
                rom_strobe_i[ri] = wb_strobe_i;
                selected_data = rom_wb_data_o[ri];
            end
        end
    end
    else if (wb_addr_i[17:16] == 2'h1) begin
        for (rj = 0; rj < `SYSTEM_NUM_RAMS; rj++) begin
            if (wb_addr_i[12:9] == rj[3:0]) begin
                ram_strobe_i[rj] = wb_strobe_i;
                selected_data = ram_wb_data_o[rj];
            end
        end
    end
end

assign wb_ack_o = (|rom_wb_ack_o) | (|ram_wb_ack_o);

genvar ii;
generate for (ii = 0; ii < `SYSTEM_NUM_ROMS; ii = ii + 1) begin

    rom #(.CHIP_ID(ii), .ROM_FILE({`ROM_FILE_BASE, "_", "0" + {4'h0, ii[3:0]}, ".hex"})) rom_ii (
        .clock(clock),
        .reset(reset),
        // frontdoor
    `ifndef NO_TRISTATE
        .data(data),
    `else
        .data_i(data),
        .data_o(rom_data_o[ii]),
        .data_en(rom_data_en[ii]),
    `endif
        .sync(sync),
        .cmd(rom_cmd),
        .io(rom_io),

        // backdoor wishbone
        .wb_data_i(wb_data_i),
        .wb_addr_i(wb_addr_i),
        .wb_cyc_i(wb_cyc_i),
        .wb_strobe_i(rom_strobe_i[ii]),
        .wb_we_i(wb_we_i),
        .wb_data_o(rom_wb_data_o[ii]),
        .wb_ack_o(rom_wb_ack_o[ii])
    );

`ifdef COCOTB_SIM
`ifdef COCOTB_SIM_WB_SYSTEM_TOP
    initial begin
        #10;
        for (i = 0; i < 64; i++) begin
            $dumpvars(0, rom_ii.memory[i]);
        end
        #1;
    end
`endif
`endif

end endgenerate

genvar j;
generate for (j = 0; j < `SYSTEM_NUM_RAMS; j = j + 1) begin
    wire ram_cmd_n_j;
    assign ram_cmd_n_j = (j[3:2] == 0) ? ram_cmd_n[0] :
                         (j[3:2] == 1) ? ram_cmd_n[1] :
                         (j[3:2] == 2) ? ram_cmd_n[2] :
                         (j[3:2] == 3) ? ram_cmd_n[3] : 0;

    ram #(.CHIP_ID(j[1])) ram_j(
        .clock(clock),
        .reset(reset),
    `ifndef NO_TRISTATE
        .data(data),
    `else
        .data_i(data),
        .data_o(ram_data_o[j]),
        .data_en(ram_data_en[j]),
    `endif
        .sync(sync),
        .cmd_n(ram_cmd_n_j),
        .out(ram_out),
        .p0(j[0]),

        // backdoor
        .wb_data_i(wb_data_i),
        .wb_addr_i(wb_addr_i),
        .wb_cyc_i(wb_cyc_i),
        .wb_strobe_i(ram_strobe_i[j]),
        .wb_we_i(wb_we_i),
        .wb_data_o(ram_wb_data_o[j]),
        .wb_ack_o(ram_wb_ack_o[j])
    );

`ifdef COCOTB_SIM
`ifdef COCOTB_SIM_WB_SYSTEM_TOP
    initial begin
        #10;
        for (i = 0; i < 64; i++) begin
            $dumpvars(0, ram_j.memory[i]);
        end
        for (i = 0; i < 16; i++) begin
            $dumpvars(0, ram_j.status[i]);
        end
        #1;
    end
`endif
`endif
end endgenerate

endmodule
