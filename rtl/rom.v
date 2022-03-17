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

// TODO: should this be a module parameter?
`ifndef ROM_CAPACITY
`define ROM_CAPACITY (4096)
`endif
localparam ADDR_BITS = $clog2(`ROM_CAPACITY);


`ifndef NO_TRISTATE
wire [3:0] data_i;
assign data_i = data;
`endif

reg [11:0] address;
reg [2:0] cycle;

reg [7:0] memory [`ROM_CAPACITY-1:0];

wire [ADDR_BITS-1:0] addr;
assign addr = address[ADDR_BITS-1:0];

`ifndef ROM_HEX_FILE
`define ROM_HEX_FILE "rom.hex"
`endif

initial begin
    $readmemh(`ROM_HEX_FILE, memory);
end

always @(posedge clock) begin
    if (reset) begin
        cycle <= 3'b0;
    end
    else begin
        cycle <= cycle + 1;
    end
end

always @(posedge clock) begin
    if (reset) begin
        address <= 0;
    end
    else begin
        address[ 3:0] <= (cycle == 3'h0) ? data_i : address[ 3:0];
        address[ 7:4] <= (cycle == 3'h1) ? data_i : address[ 7:4];
        address[11:8] <= (cycle == 3'h2) ? data_i : address[11:8];
    end
end

integer i;

always @(posedge clock) begin
    if (reset) begin
        for (i = 0; i < 256; i++) begin
            //memory[i] <= 8'hff - i[7:0];
        end
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
assign data_val = (cycle == 3'h3) ? memory[addr][7:4]
                  : ((cycle == 3'h4) ? memory[addr][3:0]
                  : 4'b0);
assign data_en = (cycle == 3'h3) || (cycle == 3'h4);

// wishbone backdoor
always @(posedge clock) begin
    if (reset) begin
        wb_ack_o <= 0;
    end else begin
        wb_ack_o <= 0;
        if (cycle == 3'h7) begin
            if (!wb_ack_o && wb_cyc_i && wb_strobe_i && wb_we_i) begin
                // TODO: use full data_i word
                memory[wb_addr_i[ADDR_BITS-1:0]] <= wb_data_i[7:0];
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
