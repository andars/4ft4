`default_nettype none

module ram(
    input clock,
    input reset,
    inout [3:0] data,
    input sync,
    input cmd_n,
    input p0,
    output [3:0] out
);

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
                if (data[3:2] == {1'b0, p0}) begin
                    selected <= 1;
                    reg_addr <= data[1:0];
                    src_active <= 1;
                end else begin
                    selected <= 0;
                end
            end
            if ((cycle == 3'h4) && selected) begin
                inst <= data;
                inst_active <= 1;
            end
        end else if (cycle == 3'h7) begin
            if (src_active) begin
                // SRC
                char_addr <= data;
                src_active <= 0;
            end
            inst_active <= 0;
        end
    end
end

reg write_ram;
reg ram_to_data;

always @(*) begin
    write_ram = 0;
    ram_to_data = 0;
    if (inst_active) begin
        if (cycle == 3'h6) begin
            case (inst)
            4'h0: begin
                write_ram = 1;
            end
            4'h9: begin
                ram_to_data = 1;
            end
            4'hb: begin
                ram_to_data = 1;
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
        for (i = 0; i < 64; i++) begin
            memory[i] <= 0;
        end
    end else if (write_ram) begin
        memory[reg_addr * 16 + char_addr] <= data;
    end
end

assign data = ram_to_data ? memory[reg_addr * 16 + char_addr] : 4'hz;

endmodule
