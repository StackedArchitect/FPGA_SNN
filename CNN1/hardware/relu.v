/*
 * ReLU Activation Module
 * 
 * Simple rectified linear unit: output = max(0, input)
 * For signed numbers, if MSB (sign bit) is 1 (negative), output 0
 * Otherwise, pass the input through unchanged
 *
 * Parameters:
 *   WIDTH - Bit width of the data (default 8)
 */

module relu #(
    parameter WIDTH = 8
)(
    input  wire signed [WIDTH-1:0] data_in,
    output wire signed [WIDTH-1:0] data_out
);

    // If input is negative (MSB = 1), output 0, else pass through
    assign data_out = data_in[WIDTH-1] ? {WIDTH{1'b0}} : data_in;

endmodule
