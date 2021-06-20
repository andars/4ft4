`default_nettype none

module datapath(
    input clock,
    input reset,
    input clear_carry,
    input clear_accumulator,
    input write_accumulator,
    input [3:0] inst_operand,
    input acc_input_sel,
    input write_register,
    input reg_input_sel
);

reg [3:0] accumulator;
reg carry;

reg [3:0] registers [15:0];

wire [3:0] alu_result;

integer i;

wire [3:0] acc_input;

assign acc_input = (acc_input_sel ? registers[inst_operand]
                                  : inst_operand);

always @(posedge clock) begin
    if (reset) begin
        accumulator <= 0;
        carry <= 1;
    end
    else begin
        if (clear_carry) begin
            carry <= 0;
        end

        if (clear_accumulator) begin
            accumulator <= 0;
        end
        else if (write_accumulator) begin
            accumulator <= acc_input;
        end
    end
end

wire [3:0] reg_input;
assign reg_input = (reg_input_sel ? 4'bx : accumulator);

always @(posedge clock) begin
    if (reset) begin
        for (i = 0; i < 16; i++) begin
           registers[i] <= 0;
        end
    end
    else begin
        if (write_register) begin
            registers[inst_operand] <= reg_input;
        end
    end
end

endmodule
