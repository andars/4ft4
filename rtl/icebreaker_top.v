`default_nettype none

module icebreaker_top(
    input clock,
    input test_,
    output [3:0] leds,
    input serial_rx,
    output serial_tx
);

wire reset;
wire [4*`SYSTEM_NUM_ROMS-1:0] rom_in;
wire [4*`SYSTEM_NUM_RAMS-1:0] ram_out;

assign rom_in = 0;

assign leds = ram_out[3:0];

wire [31:0] data_to_sys;
wire [31:0] data_from_sys;
wire ack;
wire [31:0] addr;
wire cyc;
wire strobe;
wire we;

// TODO: enable controlling this over uart->wishbone
wire halt;
assign halt = 1'b0;

wb_system sys(
    .clock(clock),
    .reset(reset),
    .halt(halt),
    .rom_in(rom_in),
    .ram_out(ram_out),

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
