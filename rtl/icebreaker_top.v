`default_nettype none

module icebreaker_top(
    input clock,
    input test_,
    output [3:0] leds
);

wire reset;
wire [3:0] rom_out;

assign leds = rom_out;

wb_system sys(
    .clock(clock),
    .reset(reset),
    .rom_out(rom_out),

    // TODO: connect these to spoke
    .wb_data_i(32'h0),
    .wb_addr_i(32'h0),
    .wb_cyc_i(1'b0),
    .wb_strobe_i(1'b0),
    .wb_we_i(1'b0),
    .wb_data_o(),
    .wb_ack_o()
);

// Reset generator
reg [3:0] reset_counter = 0;
assign reset = (reset_counter < 4'hf);
always @(posedge clock) begin
    if (reset) begin
        reset_counter <= reset_counter + 1;
    end else begin
        reset_counter <= reset_counter;
    end
end

endmodule
