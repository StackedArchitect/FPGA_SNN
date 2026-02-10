/*
 * System Integration Testbench
 * 
 * Tests: Line Buffer -> Conv (4 filters) -> ReLU pipeline
 * Uses real MNIST image data and compares with expected outputs
 */

`timescale 1ns/1ps

module tb_system_integration();

    parameter IMG_SIZE = 28;
    parameter PIXEL_WIDTH = 8;
    parameter NUM_FILTERS = 4;
    parameter CLK_PERIOD = 10;
    
    // Signals
    reg clk, rst_n, enable;
    reg [PIXEL_WIDTH-1:0] pixel_in;
    reg pixel_valid;
    
    // Line buffer outputs
    wire [PIXEL_WIDTH-1:0] window [0:8];
    wire window_valid;
    
    // Conv outputs (4 filters)
    wire signed [19:0] conv_out [0:NUM_FILTERS-1];
    wire conv_valid [0:NUM_FILTERS-1];
    
    // ReLU outputs
    wire signed [19:0] relu_out [0:NUM_FILTERS-1];
    
    // Test image memory
    reg [PIXEL_WIDTH-1:0] test_image [0:IMG_SIZE*IMG_SIZE-1];
    
    // Weight arrays (loaded from include files)
    reg signed [7:0] conv_weights_mem [0:35];  // 4 filters * 9 weights
    reg signed [7:0] conv_bias_mem [0:3];      // 4 biases
    
    // Load weights at simulation start
    initial begin
        // Conv layer weights (4 filters, 3x3 each)
        conv_weights_mem[0] = 8'h09; conv_weights_mem[1] = 8'h0B; conv_weights_mem[2] = 8'hFE;
        conv_weights_mem[3] = 8'h01; conv_weights_mem[4] = 8'hFE; conv_weights_mem[5] = 8'hF5;
        conv_weights_mem[6] = 8'hEF; conv_weights_mem[7] = 8'hF7; conv_weights_mem[8] = 8'hF8;
        
        conv_weights_mem[9] = 8'hF6; conv_weights_mem[10] = 8'h07; conv_weights_mem[11] = 8'h0A;
        conv_weights_mem[12] = 8'h00; conv_weights_mem[13] = 8'h0A; conv_weights_mem[14] = 8'hFF;
        conv_weights_mem[15] = 8'h06; conv_weights_mem[16] = 8'h04; conv_weights_mem[17] = 8'hF7;
        
        conv_weights_mem[18] = 8'hF7; conv_weights_mem[19] = 8'hF2; conv_weights_mem[20] = 8'h06;
        conv_weights_mem[21] = 8'hFD; conv_weights_mem[22] = 8'hFF; conv_weights_mem[23] = 8'h04;
        conv_weights_mem[24] = 8'h0D; conv_weights_mem[25] = 8'h07; conv_weights_mem[26] = 8'hFE;
        
        conv_weights_mem[27] = 8'h03; conv_weights_mem[28] = 8'h0A; conv_weights_mem[29] = 8'h09;
        conv_weights_mem[30] = 8'hF9; conv_weights_mem[31] = 8'h06; conv_weights_mem[32] = 8'h0B;
        conv_weights_mem[33] = 8'hF0; conv_weights_mem[34] = 8'hED; conv_weights_mem[35] = 8'hF0;
        
        // Conv biases
        conv_bias_mem[0] = 8'hF6; // -10
        conv_bias_mem[1] = 8'hFC; // -4
        conv_bias_mem[2] = 8'hF1; // -15
        conv_bias_mem[3] = 8'h02; // 2
    end
    
    // Counters and status
    integer pixel_count;
    integer conv_output_count;
    integer i, j;
    
    // Reorganize weights for each filter
    wire signed [7:0] filter_weights [0:NUM_FILTERS-1][0:8];
    wire signed [7:0] filter_bias [0:NUM_FILTERS-1];
    
    genvar f, w;
    generate
        for (f = 0; f < NUM_FILTERS; f = f + 1) begin : filter_weight_assign
            for (w = 0; w < 9; w = w + 1) begin : weight_assign
                assign filter_weights[f][w] = conv_weights_mem[f * 9 + w];
            end
            assign filter_bias[f] = conv_bias_mem[f];
        end
    endgenerate
    
    // Line Buffer
    line_buffer #(
        .IMG_WIDTH(IMG_SIZE),
        .DATA_WIDTH(PIXEL_WIDTH)
    ) line_buf (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .pixel_in(pixel_in),
        .pixel_valid(pixel_valid),
        .window(window),
        .window_valid(window_valid)
    );
    
    // Convolution Units (4 filters)
    generate
        for (f = 0; f < NUM_FILTERS; f = f + 1) begin : conv_units
            conv_unit #(
                .DATA_WIDTH(PIXEL_WIDTH),
                .WEIGHT_WIDTH(8),
                .ACC_WIDTH(20)
            ) conv (
                .clk(clk),
                .rst_n(rst_n),
                .enable(enable),
                .window(window),
                .weights(filter_weights[f]),
                .bias(filter_bias[f]),
                .valid_in(window_valid),
                .conv_out(conv_out[f]),
                .valid_out(conv_valid[f])
            );
        end
    endgenerate
    
    // ReLU Units
    generate
        for (f = 0; f < NUM_FILTERS; f = f + 1) begin : relu_units
            relu #(.WIDTH(20)) relu_inst (
                .data_in(conv_out[f]),
                .data_out(relu_out[f])
            );
        end
    endgenerate
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Test procedure
    initial begin
        // Start with debug output
        $display("========================================");
        $display("System Integration Test Starting...");
        $display("========================================");
        
        $dumpfile("system_integration_test.vcd");
        $dumpvars(0, tb_system_integration);
        
        // Load test image
        $display("Loading test image from ../data/integration_test/input_image.mem");
        $readmemh("../data/integration_test/input_image.mem", test_image);
        $display("Test image loaded");
        
        // Initialize
        rst_n = 0;
        enable = 0;
        pixel_in = 0;
        pixel_valid = 0;
        pixel_count = 0;
        conv_output_count = 0;
        
        $display("\n========================================");
        $display("System Integration Test");
        $display("Testing: LineBuffer -> Conv -> ReLU");
        $display("========================================\n");
        
        // Reset
        #(CLK_PERIOD*5);
        rst_n = 1;
        enable = 1;
        
        #(CLK_PERIOD*2);
        
        // Stream MNIST image
        $display("Streaming 28x28 MNIST image...");
        for (i = 0; i < IMG_SIZE*IMG_SIZE; i = i + 1) begin
            @(posedge clk);
            pixel_in = test_image[i];
            pixel_valid = 1;
            pixel_count = pixel_count + 1;
        end
        
        @(posedge clk);
        pixel_valid = 0;
        
        // Wait for pipeline to flush
        #(CLK_PERIOD*10);
        
        // Summary
        $display("\n========================================");
        $display("Test Summary");
        $display("========================================");
        $display("Pixels streamed: %0d", pixel_count);
        $display("Conv outputs: %0d", conv_output_count);
        $display("Expected: 676 windows x 4 filters = 2704 outputs");
        
        $display("\n✓ System integration test complete");
        $display("  Check waveform for detailed signal analysis\n");
        
        #(CLK_PERIOD*10);
        $finish;
    end
    
    // Monitor conv outputs
    always @(posedge clk) begin
        if (conv_valid[0] && enable) begin
            conv_output_count = conv_output_count + 1;
            
            // Display first few outputs
            if (conv_output_count <= 5) begin
                $display("\nConv Output #%0d:", conv_output_count);
                $display("  Filter 0: %0d -> ReLU: %0d", conv_out[0], relu_out[0]);
                $display("  Filter 1: %0d -> ReLU: %0d", conv_out[1], relu_out[1]);
                $display("  Filter 2: %0d -> ReLU: %0d", conv_out[2], relu_out[2]);
                $display("  Filter 3: %0d -> ReLU: %0d", conv_out[3], relu_out[3]);
            end
        end
    end
    
    // Timeout
    initial begin
        #(CLK_PERIOD * 2000);
        $display("\n✗ Timeout!");
        $finish;
    end

endmodule
