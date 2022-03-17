`default_nettype none

module icebreaker_top(
    input clock,
    input test_,
    output [3:0] leds,
    input serial_rx,
    output serial_tx
);

wire reset;
wire [3:0] rom_out;

assign leds = rom_out;

wire [31:0] data_to_sys;
wire [31:0] data_from_sys;
wire ack;
wire [31:0] addr;
wire cyc;
wire strobe;
wire we;

wb_system sys(
    .clock(clock),
    .reset(reset),
    .rom_out(rom_out),

    .wb_data_i(data_to_sys),
    .wb_addr_i(addr),
    .wb_cyc_i(cyc),
    .wb_strobe_i(strobe),
    .wb_we_i(we),
    .wb_data_o(data_from_sys),
    .wb_ack_o(ack)
);

uart_wb_master wb_master(
    .clock(clock),
    .reset(reset),
    .serial_rx(serial_rx),
    .serial_tx(serial_tx),
    .data_in(data_from_sys),
    .data_out(data_to_sys),
    .ack_in(ack),
    .addr_out(addr),
    .cyc_out(cyc),
    .strobe_out(strobe),
    .we_out(we)
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
