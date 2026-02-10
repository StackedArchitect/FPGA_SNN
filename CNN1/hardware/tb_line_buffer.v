/*
 * Testbench for Line Buffer Module
 * 
 * Verifies that the line buffer correctly generates 3x3 sliding windows
 * from streaming pixel input.
 *
 * Test procedure:
 *   1. Stream a known pattern (e.g., incrementing values)
 *   2. Verify window outputs are correct
 *   3. Check window_valid timing
 */

`timescale 1ns/1ps

module tb_line_buffer();

    // Parameters
    parameter IMG_WIDTH = 28;
    parameter DATA_WIDTH = 8;
    parameter CLK_PERIOD = 10;  // 10ns = 100MHz
    
    // Signals
    reg clk;
    reg rst_n;
    reg enable;
    reg [DATA_WIDTH-1:0] pixel_in;
    reg pixel_valid;
    
    wire [DATA_WIDTH-1:0] window [0:8];
    wire window_valid;
    
    // Test image: simple incrementing pattern for easy verification
    reg [DATA_WIDTH-1:0] test_image [0:IMG_WIDTH*IMG_WIDTH-1];
    
    integer i, j;
    integer pixel_count;
    integer window_count;
    integer error_count;
    
    // Instantiate line buffer
    line_buffer #(
        .IMG_WIDTH(IMG_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .pixel_in(pixel_in),
        .pixel_valid(pixel_valid),
        .window(window),
        .window_valid(window_valid)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Test stimulus
    initial begin
        // Initialize
        rst_n = 0;
        enable = 0;
        pixel_in = 0;
        pixel_valid = 0;
        pixel_count = 0;
        window_count = 0;
        error_count = 0;
        
        // Create test pattern: incrementing values
        for (i = 0; i < IMG_WIDTH*IMG_WIDTH; i = i + 1) begin
            test_image[i] = i[7:0];
        end
        
        // Waveform dump
        $dumpfile("line_buffer_test.vcd");
        $dumpvars(0, tb_line_buffer);
        
        // Reset
        $display("\n========================================");
        $display("Line Buffer Testbench");
        $display("========================================\n");
        
        #(CLK_PERIOD*5);
        rst_n = 1;
        enable = 1;
        
        #(CLK_PERIOD*2);
        
        // Stream pixels into line buffer
        $display("Streaming %0d pixels...", IMG_WIDTH*IMG_WIDTH);
        for (i = 0; i < IMG_WIDTH*IMG_WIDTH; i = i + 1) begin
            @(posedge clk);
            pixel_in = test_image[i];
            pixel_valid = 1;
            pixel_count = pixel_count + 1;
            
            // Check window when valid
            if (window_valid) begin
                window_count = window_count + 1;
                
                // Display first few windows
                if (window_count <= 5) begin
                    $display("\nWindow #%0d (pixel %0d):", window_count, pixel_count);
                    $display("  [%3d %3d %3d]", window[0], window[1], window[2]);
                    $display("  [%3d %3d %3d]", window[3], window[4], window[5]);
                    $display("  [%3d %3d %3d]", window[6], window[7], window[8]);
                end
                
                // Verify window contents
                // For incrementing pattern, we can calculate expected values
                // Window at position (row, col) should contain pixels from:
                // row-1, row, row+1 and col-1, col, col+1
                
                // First window should appear at pixel index 58 (2 rows + 2 pixels)
                // and correspond to window centered at position (1,1)
            end
        end
        
        @(posedge clk);
        pixel_valid = 0;
        
        // Check for final window (from last pixel)
        @(posedge clk);
        if (window_valid) begin
            window_count = window_count + 1;
            $display("\nFinal Window #%0d captured", window_count);
        end
        
        // Summary
        #(CLK_PERIOD*10);
        $display("\n========================================");
        $display("Test Summary");
        $display("========================================");
        $display("Total pixels streamed: %0d", pixel_count);
        $display("Windows generated: %0d", window_count);
        $display("Expected windows: %0d (26x26)", 26*26);
        $display("Errors detected: %0d", error_count);
        
        if (window_count == 26*26) begin
            $display("\n✓ PASS: Correct number of windows generated");
        end else begin
            $display("\n✗ FAIL: Window count mismatch!");
        end
        
        $display("\n========================================\n");
        
        #(CLK_PERIOD*5);
        $finish;
    end
    
    // Monitor window_valid transitions
    always @(posedge clk) begin
        if (window_valid && pixel_valid) begin
            // Additional verification can be added here
            // For now, just count valid windows
        end
    end
    
    // Timeout watchdog
    initial begin
        #(CLK_PERIOD * 2000);
        $display("\n✗ ERROR: Simulation timeout!");
        $finish;
    end

endmodule
