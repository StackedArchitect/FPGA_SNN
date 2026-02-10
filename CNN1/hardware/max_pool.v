/*
 * Max Pooling Module - 2x2 Window (SIMPLIFIED VERSION)
 * 
 * Performs 2x2 max pooling with stride 2
 * Takes streaming input from conv layer (26x26)
 * Outputs pooled result (13x13)
 *
 * Operation:
 *   - Buffers one complete row
 *   - When second row arrives, processes pairs of columns
 *   - Outputs max of each 2x2 block
 *   - Stride of 2 means non-overlapping windows
 *
 * Timing:
 *   - Needs to buffer first row (26 pixels)
 *   - Then outputs 13 values per row pair
 *   - Total: 26 input rows -> 13 output rows
 */

module max_pool #(
    parameter DATA_WIDTH = 20,        // Input data width (from conv output)
    parameter INPUT_WIDTH = 26,       // Input feature map width after conv
    parameter INPUT_HEIGHT = 26       // Input feature map height
)(
    input  wire clk,
    input  wire rst_n,
    input  wire enable,
    
    input  wire signed [DATA_WIDTH-1:0] data_in,
    input  wire valid_in,
    
    output reg signed [DATA_WIDTH-1:0] data_out,
    output reg valid_out
);

    // Row buffer to store one complete row
    reg signed [DATA_WIDTH-1:0] row_buffer [0:INPUT_WIDTH-1];
    
    // Counters
    reg [$clog2(INPUT_WIDTH+1)-1:0] col_in;    // Input column counter (0-25)
    reg [$clog2(INPUT_HEIGHT+1)-1:0] row_in;   // Input row counter (0-25)
    reg odd_row;                                 // Track odd/even rows
    
    // Temporary storage for 2x2 window
    reg signed [DATA_WIDTH-1:0] top_left, top_right, bottom_left;
    
    // Max computation
    wire signed [DATA_WIDTH-1:0] max_top, max_bottom, max_final;
    assign max_top = (top_left > top_right) ? top_left : top_right;
    assign max_bottom = (bottom_left > data_in) ? bottom_left : data_in;
    assign max_final = (max_top > max_bottom) ? max_top : max_bottom;
    
    integer i;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            col_in <= 0;
            row_in <= 0;
            odd_row <= 0;
            data_out <= 0;
            valid_out <= 0;
            top_left <= 0;
            top_right <= 0;
            bottom_left <= 0;
            
            for (i = 0; i < INPUT_WIDTH; i = i + 1) begin
                row_buffer[i] <= 0;
            end
            
        end else if (enable && valid_in) begin
            
            if (odd_row) begin
                // Even row index (0, 2, 4, ...) - just buffer it
                row_buffer[col_in] <= data_in;
                valid_out <= 0;
                
                col_in <= col_in + 1;
                if (col_in == INPUT_WIDTH - 1) begin
                    col_in <= 0;
                    row_in <= row_in + 1;
                    odd_row <= ~odd_row;
                end
                
            end else begin
                // Odd row index (1, 3, 5, ...) - process with buffered row
                
                if (col_in[0] == 0) begin
                    // Even column (0, 2, 4, ...) - load 2x2 window top half
                    top_left <= row_buffer[col_in];
                    top_right <= row_buffer[col_in + 1];
                    bottom_left <= data_in;
                    valid_out <= 0;
                    
                end else begin
                    // Odd column (1, 3, 5, ...) - complete window and output max
                    // data_in is bottom_right
                    data_out <= max_final;
                    valid_out <= 1;
                end
                
                // Update buffer with current row
                row_buffer[col_in] <= data_in;
                
                col_in <= col_in + 1;
                if (col_in == INPUT_WIDTH - 1) begin
                    col_in <= 0;
                    row_in <= row_in + 1;
                    odd_row <= ~odd_row;
                    
                    if (row_in == INPUT_HEIGHT - 1) begin
                        // Done processing all rows
                        row_in <= 0;
                    end
                end
            end
            
        end else begin
            valid_out <= 0;
        end
    end

endmodule
