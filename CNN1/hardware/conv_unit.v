/*
 * Convolution Unit - 3x3 Kernel
 * 
 * Performs 3x3 convolution: dot product of input window with kernel weights
 * 
 * Operation:
 *   output = sum(window[i] * weight[i]) + bias
 *   where i = 0..8 for 3x3 kernel
 *
 * Architecture:
 *   - 9 parallel multipliers (8-bit x 8-bit -> 16-bit)
 *   - Adder tree (3 levels for 9 inputs)
 *   - Final bias addition
 *
 * Timing: Combinational (1 cycle latency with output register)
 */

module conv_unit #(
    parameter DATA_WIDTH = 8,           // Input data width
    parameter WEIGHT_WIDTH = 8,         // Weight width
    parameter ACC_WIDTH = 20            // Accumulator width (enough for 9 mults + bias)
)(
    input  wire clk,
    input  wire rst_n,
    input  wire enable,
    
    // 3x3 window input (9 pixels)
    input  wire signed [DATA_WIDTH-1:0] window [0:8],
    
    // Kernel weights (9 weights)
    input  wire signed [WEIGHT_WIDTH-1:0] weights [0:8],
    
    // Bias
    input  wire signed [WEIGHT_WIDTH-1:0] bias,
    
    // Valid input signal
    input  wire valid_in,
    
    // Convolution result
    output reg signed [ACC_WIDTH-1:0] conv_out,
    output reg valid_out
);

    // Multiplication products
    wire signed [DATA_WIDTH+WEIGHT_WIDTH-1:0] products [0:8];
    
    // Generate 9 multipliers
    genvar i;
    generate
        for (i = 0; i < 9; i = i + 1) begin : mult_gen
            assign products[i] = window[i] * weights[i];
        end
    endgenerate
    
    // Adder tree for summing products
    // Level 1: 9 -> 5 (pairs + 1 leftover)
    wire signed [ACC_WIDTH-1:0] sum_l1 [0:4];
    assign sum_l1[0] = products[0] + products[1];
    assign sum_l1[1] = products[2] + products[3];
    assign sum_l1[2] = products[4] + products[5];
    assign sum_l1[3] = products[6] + products[7];
    assign sum_l1[4] = products[8];
    
    // Level 2: 5 -> 3
    wire signed [ACC_WIDTH-1:0] sum_l2 [0:2];
    assign sum_l2[0] = sum_l1[0] + sum_l1[1];
    assign sum_l2[1] = sum_l1[2] + sum_l1[3];
    assign sum_l2[2] = sum_l1[4];
    
    // Level 3: 3 -> 2
    wire signed [ACC_WIDTH-1:0] sum_l3 [0:1];
    assign sum_l3[0] = sum_l2[0] + sum_l2[1];
    assign sum_l3[1] = sum_l2[2];
    
    // Level 4: 2 -> 1 (final sum)
    wire signed [ACC_WIDTH-1:0] sum_products;
    assign sum_products = sum_l3[0] + sum_l3[1];
    
    // Add bias (scaled to match fixed-point format)
    wire signed [ACC_WIDTH-1:0] bias_scaled;
    assign bias_scaled = {{(ACC_WIDTH-WEIGHT_WIDTH){bias[WEIGHT_WIDTH-1]}}, bias};
    
    wire signed [ACC_WIDTH-1:0] result;
    assign result = sum_products + bias_scaled;
    
    // Register output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            conv_out <= 0;
            valid_out <= 0;
        end else if (enable) begin
            conv_out <= result;
            valid_out <= valid_in;
        end else begin
            valid_out <= 0;
        end
    end

endmodule
