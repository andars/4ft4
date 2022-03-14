`default_nettype none

module rom(
    input clock,
    input reset,
    inout [3:0] data,
    input sync,
    input cmd,
    inout [3:0] io
);

reg [11:0] address;
reg [2:0] cycle;

reg [7:0] memory [4095:0];

initial begin
    $readmemh("rom.hex", memory);
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
        address <= 12'b0;
    end
    else begin
        address[ 3:0] <= (cycle == 3'h0) ? data : address[ 3:0];
        address[ 7:4] <= (cycle == 3'h1) ? data : address[ 7:4];
        address[11:8] <= (cycle == 3'h2) ? data : address[11:8];
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
                if (data[3:0] == 4'h0) begin
                    selected <= 1;
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
        output_port <= data;
    end
end

// TODO: parameter for i/o
assign io = output_port;

// write out ROM data during subcyles 3 and 4
assign data = (cycle == 3'h3) ? memory[address][7:4]
            : ((cycle == 3'h4) ? memory[address][3:0]
            : 4'bz);

endmodule
