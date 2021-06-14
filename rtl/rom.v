`default_nettype none

module rom(
    input clock,
    input reset,
    inout [3:0] data,
    input sync
);

reg [7:0] address;
reg [2:0] cycle;

reg [7:0] memory [255:0];

initial begin
    $readmemh("add.hex", memory);
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
        address <= 8'b0;
    end
    else begin
        address[3:0] <= (cycle == 3'h0) ? data : address[3:0];
        address[7:4] <= (cycle == 3'h1) ? data : address[7:4];
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

// write out ROM data during subcyles 3 and 4
assign data = (cycle == 3'h3) ? memory[address][7:4]
            : ((cycle == 3'h4) ? memory[address][3:0]
            : 4'bz);

endmodule