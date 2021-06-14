`default_nettype none

module cpu_control(
    input clock,
    input reset,
    output sync,
    output reg [2:0] cycle
);

always @(posedge clock) begin
    if (reset) begin
        cycle <= 3'b0;
    end
    else begin
        cycle <= cycle + 1;
    end
end

assign sync = ~(cycle == 3'b111);

endmodule


