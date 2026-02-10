/*
 * Max Pooling Module - 2x2 Window
 * 
 * Performs 2x2 max pooling with stride 2
 * Takes streaming input from conv layer (26x26x4)
 * Outputs pooled result (13x13x4)
 *
 * Operation:
 *   - Collects 2x2 blocks of pixels
 *   - Outputs the maximum value in each block
 *   - Stride of 2 means non-overlapping windows
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

    // State machine for collecting 2x2 blocks
    localparam IDLE = 2'd0;
    localparam COLLECT = 2'd1;
    localparam OUTPUT = 2'd2;
    
    reg [1:0] state;
    
    // Buffer to store one row (needed for 2x2 window)
    reg signed [DATA_WIDTH-1:0] row_buffer [0:INPUT_WIDTH-1];
    
    // Current 2x2 window
    reg signed [DATA_WIDTH-1:0] window [0:3];  // [0 1]
                                                // [2 3]
    
    // Counters
    reg [$clog2(INPUT_WIDTH):0] col_count;
    reg [$clog2(INPUT_HEIGHT):0] row_count;
    reg [1:0] window_pos;  // Position within 2x2 window (0-3)
    
    // Max finding
    wire signed [DATA_WIDTH-1:0] max_01, max_23, max_final;
    assign max_01 = (window[0] > window[1]) ? window[0] : window[1];
    assign max_23 = (window[2] > window[3]) ? window[2] : window[3];
    assign max_final = (max_01 > max_23) ? max_01 : max_23;
    
    integer i;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            col_count <= 0;
            row_count <= 0;
            window_pos <= 0;
            data_out <= 0;
            valid_out <= 0;
            
            for (i = 0; i < INPUT_WIDTH; i = i + 1) begin
                row_buffer[i] <= 0;
            end
            
            for (i = 0; i < 4; i = i + 1) begin
                window[i] <= 0;
            end
            
        end else if (enable && valid_in) begin
            case (state)
                IDLE: begin
                    state <= COLLECT;
                    window_pos <= 0;
                    valid_out <= 0;
                end
                
                COLLECT: begin
                    // Collect 2x2 window
                    // First row: positions 0,1 (from buffer and current)
                    // Second row: positions 2,3 (from buffer and current)
                    
                    if (row_count == 0) begin
                        // First row - just buffer
                        row_buffer[col_count] <= data_in;
                        col_count <= col_count + 1;
                        
                        if (col_count == INPUT_WIDTH - 1) begin
                            col_count <= 0;
                            row_count <= 1;
                        end
                        valid_out <= 0;
                        
                    end else begin
                        // Subsequent rows - form 2x2 windows
                        case (window_pos)
                            2'd0: begin  // Top-left
                                window[0] <= row_buffer[col_count];
                                window_pos <= 2'd1;
                                valid_out <= 0;
                            end
                            
                            2'd1: begin  // Top-right
                                window[1] <= row_buffer[col_count];
                                window[2] <= data_in;  // Bottom-left (previous col)
                                row_buffer[col_count] <= data_in;
                                window_pos <= 2'd2;
                                valid_out <= 0;
                            end
                            
                            2'd2: begin  // Bottom-right (actually comes next clock)
                                window[3] <= data_in;
                                row_buffer[col_count] <= data_in;
                                window_pos <= 2'd3;
                                valid_out <= 0;
                            end
                            
                            2'd3: begin  // Output max
                                data_out <= max_final;
                                valid_out <= 1;
                                window_pos <= 2'd0;
                                
                                col_count <= col_count + 1;
                                if (col_count >= INPUT_WIDTH - 2) begin
                                    col_count <= 0;
                                    row_count <= row_count + 1;
                                    if (row_count >= INPUT_HEIGHT - 1) begin
                                        row_count <= 0;
                                        state <= IDLE;
                                    end
                                end
                            end
                        endcase
                    end
                end
                
                default: state <= IDLE;
            endcase
            
        end else begin
            valid_out <= 0;
        end
    end

endmodule
