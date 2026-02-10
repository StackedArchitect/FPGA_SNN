/*
 * Line Buffer for Sliding Window Generation
 * 
 * Generates a 3x3 sliding window from a streaming input image
 * For MNIST: 28x28 input, produces 26x26 valid windows (no padding)
 *
 * The module buffers 2 complete rows to form 3x3 windows
 * 
 * Timing:
 *   - Pixels stream in one per clock cycle
 *   - After 2 rows + 2 pixels, outputs valid 3x3 windows
 *   - window_valid goes high when a complete 3x3 window is available
 */

module line_buffer #(
    parameter IMG_WIDTH = 28,      // Image width (MNIST = 28)
    parameter DATA_WIDTH = 8       // Pixel bit width  
)(
    input  wire clk,
    input  wire rst_n,
    input  wire enable,
    
    input  wire [DATA_WIDTH-1:0] pixel_in,   // Streaming pixel input
    input  wire pixel_valid,                  // Input pixel valid signal
    
    output reg [DATA_WIDTH-1:0] window [0:8], // 3x3 window output (row-major)
                                               // [0 1 2]
                                               // [3 4 5]
                                               // [6 7 8]
    output reg window_valid                   // Output window valid signal
);

    // Row buffers: store previous 2 rows
    reg [DATA_WIDTH-1:0] row_buf_0 [0:IMG_WIDTH-1];  // Row n-2
    reg [DATA_WIDTH-1:0] row_buf_1 [0:IMG_WIDTH-1];  // Row n-1    
    reg [DATA_WIDTH-1:0] row_buf_2 [0:IMG_WIDTH-1];  // Row n (current)
    
    // Pixel position counters
    reg [$clog2(IMG_WIDTH)-1:0] x;  // Column (0 to IMG_WIDTH-1)
    reg [$clog2(IMG_WIDTH)-1:0] y;  // Row (0 to IMG_WIDTH-1)
    
    integer i, j;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x <= 0;
            y <= 0;
            window_valid <= 0;
            
            for (i = 0; i < IMG_WIDTH; i = i + 1) begin
                row_buf_0[i] <= 0;
                row_buf_1[i] <= 0;
                row_buf_2[i] <= 0;
            end
            
            for (i = 0; i < 9; i = i + 1) begin
                window[i] <= 0;
            end
            
        end else if (enable && pixel_valid) begin
            // Store incoming pixel in current row buffer
            row_buf_2[x] <= pixel_in;
            
            // Form 3x3 window when we have enough data
            // Need y >= 2 (have 2 complete previous rows) AND x >= 2 (have 2 pixels in current row)
            if (y >= 2 && x >= 2) begin
                // Window center is at (y-1, x-1)
                // Top row (y-2)
                window[0] <= row_buf_0[x-2];
                window[1] <= row_buf_0[x-1];
                window[2] <= row_buf_0[x];
                
                // Middle row (y-1)
                window[3] <= row_buf_1[x-2];
                window[4] <= row_buf_1[x-1];
                window[5] <= row_buf_1[x];
                
                // Bottom row (y)  
                window[6] <= row_buf_2[x-2];
                window[7] <= row_buf_2[x-1];
                window[8] <= pixel_in;  // Current pixel
                
                window_valid <= 1;
            end else begin
                window_valid <= 0;
            end
            
            // Update position counters
            if (x == IMG_WIDTH - 1) begin
                x <= 0;
                y <= y + 1;  // Allow y to increment beyond IMG_WIDTH-1 for proper counting
                
                // Shift row buffers at end of each row
                for (j = 0; j < IMG_WIDTH; j = j + 1) begin
                    row_buf_0[j] <= row_buf_1[j];
                    row_buf_1[j] <= row_buf_2[j];
                end
            end else begin
                x <= x + 1;
            end
        end
        // Don't reset window_valid when pixel_valid is low
        // This allows the last window to be captured
    end

endmodule
