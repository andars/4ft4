`default_nettype none

module rom(
    input clock,
    input reset,
`ifndef NO_TRISTATE
    inout [3:0] data,
`else
    input [3:0] data_i,
    output [3:0] data_o,
    output data_en,
`endif
    input sync,
    input cmd,
    inout [3:0] io,

    // wishbone backdoor
    input [31:0] wb_data_i,
    input [31:0] wb_addr_i,
    input wb_cyc_i,
    input wb_strobe_i,
    input wb_we_i,
    output [31:0] wb_data_o,
    output reg wb_ack_o
);

parameter CHIP_ID = 4'h0;
parameter ROM_FILE = "";

// TODO: should this be a module parameter?
`ifndef ROM_CAPACITY
`define ROM_CAPACITY (256)
`endif
localparam ADDR_BITS = $clog2(`ROM_CAPACITY);


`ifndef NO_TRISTATE
wire [3:0] data_i;
assign data_i = data;
`endif

reg [7:0] addr_lo;
reg [2:0] cycle;

reg [7:0] memory [`ROM_CAPACITY-1:0];
reg [7:0] memory_o;

wire [11:0] addr_full;
wire [ADDR_BITS-1:0] addr;

// valid only during subcycle 2
assign addr_full = {data_i, addr_lo};
assign addr = addr_full[ADDR_BITS-1:0];

always @(posedge clock) begin
    // read the memory into a register during cycle 2
    // so it is ready to output on cycle 3 & 4
    if (cycle == 3'h2) begin
        memory_o <= memory[addr];
    end
end

`ifndef ROM_HEX_FILE_BASE
`define ROM_HEX_FILE_BASE "rom.hex"
`endif

initial begin
    if (ROM_FILE != "") begin
        $readmemh(ROM_FILE, memory);
    end
end

always @(posedge clock) begin
    if (reset) begin
        cycle <= 3'b0;
    end
    else begin
        cycle <= cycle + 1;
    end
end

reg ce;
always @(posedge clock) begin
    if (reset) begin
        ce <= 0;
    end
    else begin
        if (cycle == 3'h2) begin
            ce <= (data_i == CHIP_ID);
        end
    end
end


always @(posedge clock) begin
    if (reset) begin
        addr_lo <= 0;
    end
    else begin
        addr_lo[ 3:0] <= (cycle == 3'h0) ? data_i : addr_lo[ 3:0];
        addr_lo[ 7:4] <= (cycle == 3'h1) ? data_i : addr_lo[ 7:4];
    end
end

integer i;

always @(posedge clock) begin
    if (reset) begin
        `ifdef WITH_ROM_RESET
        for (i = 0; i < `ROM_CAPACITY; i++) begin
            memory[i] <= 0;
        end
        `endif
    end
end

reg [3:0] inst;
reg inst_active;
reg src_active;
reg selected;

always @(posedge clock) begin
    if (reset) begin
        selected <= 0;
        inst <= 0;
        src_active <= 0;
        inst_active <= 0;
    end else begin
        if (cmd == 0) begin
            if (cycle == 3'h6) begin
                // SRC
                // TODO: chip id
                if (data_i[3:0] == 4'h0) begin
                    selected <= 1;
                    src_active <= 1;
                end else begin
                    selected <= 0;
                end
            end
            if ((cycle == 3'h4) && selected) begin
                inst <= data_i;
                inst_active <= 1;
            end
        end else if (cycle == 3'h7) begin
            src_active <= 0;
            inst_active <= 0;
        end
    end
end

reg [3:0] output_port;
reg write_output_port;

always @(*) begin
    write_output_port = 0;
    if (inst_active) begin
        if (cycle == 3'h6) begin
            case (inst)
            4'h2: begin
                write_output_port = 1;
            end
            default: begin
            end
            endcase
        end
    end
end

// output port register
always @(posedge clock) begin
    if (reset) begin
        output_port <= 0;
    end
    else if (write_output_port) begin
        output_port <= data_i;
    end
end

// TODO: parameter for i/o
assign io = output_port;

wire [3:0] data_val;

`ifndef NO_TRISTATE
wire data_en;
assign data = data_en ? data_val : 4'bz;
`else
assign data_o = data_val;
`endif

// write out ROM data during subcyles 3 and 4
assign data_val = (cycle == 3'h3) ? memory_o[7:4]
                  : ((cycle == 3'h4) ? memory_o[3:0]
                  : 4'b0);
assign data_en = ce && ((cycle == 3'h3) || (cycle == 3'h4));

// wishbone backdoor
always @(posedge clock) begin
    if (reset) begin
        wb_ack_o <= 0;
    end else begin
        wb_ack_o <= 0;
        if (cycle == 3'h7) begin
            if (!wb_ack_o && wb_cyc_i && wb_strobe_i && wb_we_i) begin
                // TODO: use full data_i word
                memory[wb_addr_i[ADDR_BITS+1:2]] <= wb_data_i[7:0];
                wb_ack_o <= 1;
            end
        end
    end
end
assign wb_data_o = 0;

`ifdef COCOTB_SIM
`ifdef COCOTB_SIM_ROM_TOP
initial begin
    $dumpfile("rom.vcd");
    $dumpvars;
    for (i = 0; i < 32; i++) begin
        $dumpvars(0, memory[i]);
    end
    #1;
end
`endif
`endif

endmodule
