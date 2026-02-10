/*
 * Simplified System Integration Testbench
 * Tests: Line Buffer -> Single Conv Unit -> ReLU
 * Using real MNIST image data  
 */

`timescale 1ns/1ps

module tb_system_simple();

    parameter IMG_SIZE = 28;
    parameter PIXEL_WIDTH = 8;
    parameter CLK_PERIOD = 10;
    
    // Signals
    reg clk, rst_n, enable;
    reg [PIXEL_WIDTH-1:0] pixel_in;
    reg pixel_valid;
    
    // Line buffer outputs
    wire [PIXEL_WIDTH-1:0] window [0:8];
    wire window_valid;
    
    // Conv output (filter 0 only)
    wire signed [19:0] conv_out;
    wire conv_valid;
    
    // ReLU output
    wire signed [19:0] relu_out;
    
    // Test image memory
    reg [PIXEL_WIDTH-1:0] test_image [0:IMG_SIZE*IMG_SIZE-1];
    
    // Filter 0 weights (hardcoded from generated files)
    wire signed [7:0] filter0_weights [0:8];
    reg signed [7:0] filter0_bias;
    
    assign filter0_weights[0] = 8'sh09;
    assign filter0_weights[1] = 8'sh0B;
    assign filter0_weights[2] = 8'shFE;
    assign filter0_weights[3] = 8'sh01;
    assign filter0_weights[4] = 8'shFE;
    assign filter0_weights[5] = 8'shF5;
    assign filter0_weights[6] = 8'shEF;
    assign filter0_weights[7] = 8'shF7;
    assign filter0_weights[8] = 8'shF8;
    
    initial filter0_bias = 8'shF6;  // -10
    
    // Counters
    integer pixel_count;
    integer conv_output_count;
    integer i;
    
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
    
    // Convolution Unit (filter 0)
    conv_unit #(
        .DATA_WIDTH(PIXEL_WIDTH),
        .WEIGHT_WIDTH(8),
        .ACC_WIDTH(20)
    ) conv (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .window(window),
        .weights(filter0_weights),
        .bias(filter0_bias),
        .valid_in(window_valid),
        .conv_out(conv_out),
        .valid_out(conv_valid)
    );
    
    // ReLU
    relu #(.WIDTH(20)) relu_inst (
        .data_in(conv_out),
        .data_out(relu_out)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Test procedure
    initial begin
        $display("========================================");
        $display("System Integration Test");
        $display("Testing: LineBuffer -> Conv -> ReLU");
        $display("========================================");
        
        $dumpfile("system_integration_test.vcd");
        $dumpvars(0, tb_system_simple);
        
        // Load test image
        $display("\nLoading test image...");
        $readmemh("../data/integration_test/input_image.mem", test_image);
        $display("Test image loaded (784 pixels)");
        
        // Initialize
        rst_n = 0;
        enable = 0;
        pixel_in = 0;
        pixel_valid = 0;
        pixel_count = 0;
        conv_output_count = 0;
        
        // Reset
        #(CLK_PERIOD*5);
        rst_n = 1;
        enable = 1;
        
        #(CLK_PERIOD*2);
        
        // Stream MNIST image
        $display("\nStreaming 28x28 MNIST image...");
        for (i = 0; i < IMG_SIZE*IMG_SIZE; i = i + 1) begin
            @(posedge clk);
            pixel_in = test_image[i];
            pixel_valid = 1;
            pixel_count = pixel_count + 1;
        end
        
        @(posedge clk);
        pixel_valid = 0;
        
        // Wait for pipeline to flush
        repeat(5) @(posedge clk);
        
        // Summary
        $display("\n========================================");
        $display("Test Summary");
        $display("========================================");
        $display("Pixels streamed: %0d", pixel_count);
        $display("Conv outputs (filter 0): %0d", conv_output_count);
        $display("Expected: 676 (26x26 windows)");
        
        if (conv_output_count == 676) begin
            $display("\n✓ PASS: Correct number of outputs");
        end else begin
            $display("\n✗ FAIL: Output count mismatch");
        end
        
        $display("\n✓ System integration test complete");
        $display("  Waveform: system_integration_test.vcd");
        $display("  Compare with expected_conv_filter0.txt\n");
        
        #(CLK_PERIOD*10);
        $finish;
    end
    
    // Monitor conv outputs
    always @(posedge clk) begin
        if (conv_valid && enable) begin            
            conv_output_count = conv_output_count + 1;
            
            // Display first few and last few outputs
            if (conv_output_count <= 5 || conv_output_count > 671) begin
                $display("Output #%04d: Conv=%6d  ReLU=%6d", 
                         conv_output_count, conv_out, relu_out);
            end
        end
    end
    
    // Timeout
    initial begin
        #(CLK_PERIOD * 2000);
        $display("\n✗ ERROR: Simulation timeout");
        $finish;
    end

endmodule
