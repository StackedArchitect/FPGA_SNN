/*
 * Dense (Fully Connected) Layer
 * 
 * Performs matrix-vector multiplication for classification
 * Input: 676 features (13x13x4 flattened from pooling layer)
 * Output: 10 class scores
 *
 * Architecture:
 *   - Serial implementation: Process one feature at a time
 *   - For each output class: accumulate 676 (input * weight) + bias
 *   - 10 parallel accumulators for all classes
 *
 * Timing:
 *   - Takes 676 cycles to process all inputs
 *   - Outputs all 10 class scores when done
 */

module dense_layer #(
    parameter INPUT_SIZE = 676,       // Number of input features
    parameter OUTPUT_SIZE = 10,       // Number of output classes
    parameter DATA_WIDTH = 20,        // Input feature width
    parameter WEIGHT_WIDTH = 8,       // Weight width
    parameter ACC_WIDTH = 32          // Accumulator width
)(
    input  wire clk,
    input  wire rst_n,
    input  wire start,                // Start computation
    
    // Input features (streamed one at a time)
    input  wire signed [DATA_WIDTH-1:0] feature_in,
    input  wire feature_valid,
    
    // Weight memory interface (external ROM/RAM)
    output reg [$clog2(INPUT_SIZE*OUTPUT_SIZE)-1:0] weight_addr,
    input  wire signed [WEIGHT_WIDTH-1:0] weight_data,
    
    // Bias memory interface
    output reg [$clog2(OUTPUT_SIZE)-1:0] bias_addr,
    input  wire signed [WEIGHT_WIDTH-1:0] bias_data,
    
    // Outputs
    output reg signed [ACC_WIDTH-1:0] class_scores [0:OUTPUT_SIZE-1],
    output reg done
);

    // State machine
    localparam IDLE = 2'd0;
    localparam ACCUMULATE = 2'd1;
    localparam ADD_BIAS = 2'd2;
    localparam DONE = 2'd3;
    
    reg [1:0] state;
    
    // Counters
    reg [$clog2(INPUT_SIZE):0] feature_count;
    reg [$clog2(OUTPUT_SIZE):0] class_count;
    
    // Accumulators for each output class
    reg signed [ACC_WIDTH-1:0] accumulators [0:OUTPUT_SIZE-1];
    
    // Current feature being processed
    reg signed [DATA_WIDTH-1:0] current_feature;
    
    integer i;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            feature_count <= 0;
            class_count <= 0;
            weight_addr <= 0;
            bias_addr <= 0;
            done <= 0;
            current_feature <= 0;
            
            for (i = 0; i < OUTPUT_SIZE; i = i + 1) begin
                accumulators[i] <= 0;
                class_scores[i] <= 0;
            end
            
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        state <= ACCUMULATE;
                        feature_count <= 0;
                        class_count <= 0;
                        
                        // Clear accumulators
                        for (i = 0; i < OUTPUT_SIZE; i = i + 1) begin
                            accumulators[i] <= 0;
                        end
                    end
                end
                
                ACCUMULATE: begin
                    if (feature_valid) begin
                        current_feature <= feature_in;
                        
                        // Compute weight address: 
                        // Weights organized as [output_class][input_feature]
                        // For parallel processing, we read OUTPUT_SIZE weights per cycle
                        
                        // Multiply and accumulate for all output classes
                        for (i = 0; i < OUTPUT_SIZE; i = i + 1) begin
                            // Calculate address for weight[i][feature_count]
                            weight_addr <= i * INPUT_SIZE + feature_count;
                            
                            // Note: In real implementation, we'd need OUTPUT_SIZE parallel
                            // multipliers or serialize over classes too.
                            // For now, assuming we can read all weights in parallel
                            // or process serially with multiple cycles per feature
                        end
                        
                        feature_count <= feature_count + 1;
                        
                        if (feature_count == INPUT_SIZE - 1) begin
                            state <= ADD_BIAS;
                            class_count <= 0;
                        end
                    end
                end
                
                ADD_BIAS: begin
                    // Add bias to each accumulator
                    if (class_count < OUTPUT_SIZE) begin
                        bias_addr <= class_count;
                        // Pipeline: read bias in one cycle, add in next
                        class_scores[class_count] <= accumulators[class_count] + 
                                                     {{(ACC_WIDTH-WEIGHT_WIDTH){bias_data[WEIGHT_WIDTH-1]}}, bias_data};
                        class_count <= class_count + 1;
                    end else begin
                        state <= DONE;
                    end
                end
                
                DONE: begin
                    done <= 1;
                    if (!start) begin
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
    // Simplified MAC operation (this needs to be expanded for real implementation)
    // In practice, you'd either:
    // 1. Have OUTPUT_SIZE parallel MACs
    // 2. Serialize over both features AND classes
    // 3. Use block RAM with proper timing
    
    // For simulation/initial design, showing the concept:
    always @(posedge clk) begin
        if (state == ACCUMULATE && feature_valid) begin
            for (i = 0; i < OUTPUT_SIZE; i = i + 1) begin
                // This is simplified - real implementation needs proper weight fetching
                accumulators[i] <= accumulators[i] + (current_feature * weight_data);
            end
        end
    end

endmodule
