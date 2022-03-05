`default_nettype none

module ram(
    input clock,
    input reset,
    inout [3:0] data,
    input sync,
    input cmd_n,
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

reg [3:0] inst;
reg inst_active;

always @(posedge clock) begin
    if (reset) begin
        reg_addr <= 2'h3;
        char_addr <= 4'hf;
        selected <= 0;
        inst <= 0;
        inst_active <= 0;
    end else begin
        if (cmd) begin
            if (cycle == 3'h6) begin
                // SRC
                // TODO: chip id
                selected <= 1;
                reg_addr <= data[1:0];
            end
            if (cycle == 3'h4) begin
                inst <= data;
                inst_active <= 1;
            end
        end else if (cycle == 3'h7) begin
            if (selected) begin
                // SRC
                char_addr <= data;
            end
            selected <= 0;
            inst_active <= 0;
        end
    end
end

reg write_ram;

always @(*) begin
    write_ram = 0;
    if (inst_active) begin
        if (cycle == 3'h6) begin
            case (inst)
            4'h0: begin
                write_ram = 1;
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

endmodule
