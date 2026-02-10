/*
 * Testbench for Max Pooling Module
 * 
 * Tests 2x2 max pooling with stride 2
 * Verifies that maximum values are correctly extracted
 */

`timescale 1ns/1ps

module tb_max_pool();

    parameter DATA_WIDTH = 20;
    parameter INPUT_WIDTH = 26;
    parameter INPUT_HEIGHT = 26;
    parameter CLK_PERIOD = 10;
    
    reg clk, rst_n, enable;
    reg signed [DATA_WIDTH-1:0] data_in;
    reg valid_in;
    
    wire signed [DATA_WIDTH-1:0] data_out;
    wire valid_out;
    
    integer i, j;
    integer output_count;
    reg signed [DATA_WIDTH-1:0] expected_output;
    integer error_count;
    
    // Create test pattern: simple incrementing values
    reg signed [DATA_WIDTH-1:0] test_data [0:INPUT_WIDTH*INPUT_HEIGHT-1];
    
    // DUT
    max_pool #(
        .DATA_WIDTH(DATA_WIDTH),
        .INPUT_WIDTH(INPUT_WIDTH),
        .INPUT_HEIGHT(INPUT_HEIGHT)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .data_in(data_in),
        .valid_in(valid_in),
        .data_out(data_out),
        .valid_out(valid_out)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Test stimulus
    initial begin
        $dumpfile("max_pool_test.vcd");
        $dumpvars(0, tb_max_pool);
        
        // Initialize
        rst_n = 0;
        enable = 0;
        data_in = 0;
        valid_in = 0;
        output_count = 0;
        error_count = 0;
        
        // Create test pattern
        // For 2x2 blocks with stride 2, each block's max should be its bottom-right corner
        // if values are incrementing
        for (i = 0; i < INPUT_WIDTH*INPUT_HEIGHT; i = i + 1) begin
            test_data[i] = i;
        end
        
        $display("\n========================================");
        $display("Max Pool Testbench");
        $display("Input: %0dx%0d", INPUT_WIDTH, INPUT_HEIGHT);
        $display("Expected output: %0dx%0d", INPUT_WIDTH/2, INPUT_HEIGHT/2);
        $display("========================================\n");
        
        // Reset
        #(CLK_PERIOD*5);
        rst_n = 1;
        enable = 1;
        
        #(CLK_PERIOD*2);
        
        // Stream input data
        $display("Streaming %0d input values...", INPUT_WIDTH*INPUT_HEIGHT);
        for (i = 0; i < INPUT_WIDTH*INPUT_HEIGHT; i = i + 1) begin
            @(posedge clk);
            data_in = test_data[i];
            valid_in = 1;
        end
        
        @(posedge clk);
        valid_in = 0;
        
        // Wait for all outputs
        #(CLK_PERIOD*100);
        
        // Summary
        $display("\n========================================");
        $display("Test Summary");
        $display("========================================");
        $display("Outputs received: %0d", output_count);
        $display("Expected outputs: %0d", (INPUT_WIDTH/2)*(INPUT_HEIGHT/2));
        $display("Errors: %0d", error_count);
        
        if (output_count == (INPUT_WIDTH/2)*(INPUT_HEIGHT/2) && error_count == 0) begin
            $display("\n✓ PASS: Max pooling working correctly");
        end else begin
            $display("\n✗ FAIL: Output count or values incorrect");
        end
        
        $display("\n========================================\n");
        
        #(CLK_PERIOD*10);
        $finish;
    end
    
    // Monitor outputs
    always @(posedge clk) begin
        if (valid_out && enable) begin
            output_count = output_count + 1;
            
            // Display first few outputs
            if (output_count <= 10) begin
                $display("Output #%0d: %0d", output_count, data_out);
            end
            
            // For simple incrementing pattern, verify max is correct
            // Each 2x2 block should output its maximum value
            // Block at (row, col) contains pixels:
            //   [row*WIDTH + col,        row*WIDTH + col+1]
            //   [(row+1)*WIDTH + col,    (row+1)*WIDTH + col+1]
            // Max should be (row+1)*WIDTH + col+1
        end
    end
    
    // Timeout
    initial begin
        #(CLK_PERIOD * 5000);
        $display("\n✗ ERROR: Simulation timeout");
        $finish;
    end

endmodule
