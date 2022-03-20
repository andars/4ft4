`default_nettype none

module ram(
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
    input cmd_n,
    input p0,
    output reg [3:0] out,

    // wishbone backdoor
    input [31:0] wb_data_i,
    input [31:0] wb_addr_i,
    input wb_cyc_i,
    input wb_strobe_i,
    input wb_we_i,
    output reg [31:0] wb_data_o,
    output reg wb_ack_o
);

`ifndef NO_TRISTATE
wire [3:0] data_i;
assign data_i = data;
`endif

wire cmd;
assign cmd = !cmd_n;

reg [2:0] cycle;
always @(posedge clock) begin
    if (reset) begin
        cycle <= 3'b0;
    end
    else begin
        cycle <= cycle + 1;
    end
end

reg [1:0] reg_addr;
reg [3:0] char_addr;
reg selected;
reg src_active;

reg [3:0] inst;
reg inst_active;

always @(posedge clock) begin
    if (reset) begin
        reg_addr <= 2'h3;
        char_addr <= 4'hf;
        selected <= 0;
        inst <= 0;
        src_active <= 0;
        inst_active <= 0;
    end else begin
        if (cmd) begin
            if (cycle == 3'h6) begin
                // SRC
                if (data_i[3:2] == {1'b0, p0}) begin
                    selected <= 1;
                    reg_addr <= data_i[1:0];
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
            if (src_active) begin
                // SRC
                char_addr <= data_i;
                src_active <= 0;
            end
            inst_active <= 0;
        end
    end
end

reg write_ram;
reg ram_to_data;

reg write_status;
reg [1:0] status_idx;
reg status_to_data;

reg write_output_port;

always @(*) begin
    write_ram = 0;
    ram_to_data = 0;
    write_status = 0;
    status_idx = 0;
    status_to_data = 0;
    write_output_port = 0;
    if (inst_active) begin
        if (cycle == 3'h6) begin
            case (inst)
            4'h0: begin
                write_ram = 1;
            end
            4'h1: begin
                write_output_port = 1;
            end
            4'h4, 4'h5, 4'h6, 4'h7: begin
                write_status = 1;
                status_idx = inst[1:0];
            end
            4'h8, 4'h9, 4'hb: begin
                ram_to_data = 1;
            end
            4'hc, 4'hd, 4'he, 4'hf: begin
                status_to_data = 1;
                status_idx = inst[1:0];
            end
            default: begin
            end
            endcase
        end
    end
end

reg [3:0] memory [63:0];
reg [3:0] status [15:0];

integer i;

always @(posedge clock) begin
    if (reset) begin
        `ifndef NO_RAM_RESET
        for (i = 0; i < 64; i++) begin
            memory[i] <= 0;
        end
        `endif
    end else if (write_ram) begin
        memory[reg_addr * 16 + char_addr] <= data_i;
    end
end

always @(posedge clock) begin
    if (reset) begin
        for (i = 0; i < 16; i++) begin
            status[i] <= 0;
        end
    end else if (write_status) begin
        status[reg_addr * 4 + status_idx] <= data_i;
    end
end

always @(posedge clock) begin
    if (reset) begin
        out <= 0;
    end else if (write_output_port) begin
        out <= data_i;
    end
end

reg [3:0] memory_o;

always @(posedge clock) begin
    memory_o <= memory[reg_addr * 16 + char_addr];
end

wire [3:0] data_val;
`ifndef NO_TRISTATE
wire data_en;
assign data = data_en ? data_val : 4'bz;
`else
assign data_o = data_val;
`endif
assign data_val = ram_to_data ? memory_o
                : status_to_data ? status[reg_addr * 4 + status_idx]
                : 4'h0;
assign data_en = ram_to_data | status_to_data;

// wishbone backdoor
// TODO: enable reading from output port register
always @(posedge clock) begin
    if (reset) begin
        wb_ack_o <= 0;
    end else begin
        wb_ack_o <= 0;
        if (cycle == 3'h7) begin
            if (!wb_ack_o && wb_cyc_i && wb_strobe_i) begin
                // TODO: use full 32b word to read/write multiple 4b values
                wb_data_o <= {28'h0, wb_addr_i[6] ? status[wb_addr_i[3:0]] : memory[wb_addr_i[5:0]]};
                if (wb_we_i) begin
                    if (wb_addr_i[6] == 0) begin
                        memory[wb_addr_i[5:0]] <= wb_data_i[3:0];
                    end
                    else begin
                        status[wb_addr_i[3:0]] <= wb_data_i[3:0];
                    end
                end
                wb_ack_o <= 1;
            end
        end
    end
end

`ifdef COCOTB_SIM
`ifdef COCOTB_SIM_RAM_TOP
initial begin
    $dumpfile("ram.vcd");
    $dumpvars;
    for (i = 0; i < 64; i++) begin
        $dumpvars(0, memory[i]);
    end
    for (i = 0; i < 16; i++) begin
        $dumpvars(0, status[i]);
    end
    #1;
end
`endif
`endif

endmodule
