/*
 * CNN Top Module - MNIST Digit Classifier
 * 
 * Complete pipeline:
 *   Input (28x28) -> LineBuffer -> Conv (4 filters) -> ReLU -> MaxPool -> Dense -> Output (10)
 *
 * Data Flow:
 *   1. 28x28 image pixels streamed in (1 pixel/cycle)
 *   2. Line buffer creates 3x3 windows -> 26x26 valid positions
 *   3. 4 parallel conv units process each window -> 26x26x4
 *   4. ReLU activation on each output
 *   5. Max pooling (2x2, stride 2) -> 13x13x4 = 676 features
 *   6. Fully connected layer -> 10 class scores
 *   7. Output: 10 scores, highest indicates predicted digit
 *
 * Timing:
 *   - Input: 784 cycles (28x28)
 *   - Processing: ~800-1000 cycles total
 *   - Output: 10 class scores with done signal
 */

module cnn_top #(
    parameter IMG_SIZE = 28,
    parameter PIXEL_WIDTH = 8,
    parameter NUM_FILTERS = 4,
    parameter NUM_CLASSES = 10
)(
    input  wire clk,
    input  wire rst_n,
    input  wire start,              // Start processing
    
    // Input image stream
    input  wire [PIXEL_WIDTH-1:0] pixel_in,
    input  wire pixel_valid,
    
    // Output class scores
    output wire signed [31:0] class_scores [0:NUM_CLASSES-1],
    output wire [3:0] predicted_class,  // 0-9
    output wire done
);

    // ========================================================================
    // Line Buffer - Generates 3x3 sliding windows
    // ========================================================================
    wire [PIXEL_WIDTH-1:0] window_3x3 [0:8];
    wire window_valid;
    
    line_buffer #(
        .IMG_WIDTH(IMG_SIZE),
        .DATA_WIDTH(PIXEL_WIDTH)
    ) line_buf (
        .clk(clk),
        .rst_n(rst_n),
        .enable(start),
        .pixel_in(pixel_in),
        .pixel_valid(pixel_valid),
        .window(window_3x3),
        .window_valid(window_valid)
    );
    
    // ========================================================================
    // Convolution Layer - 4 filters processing in parallel
    // ========================================================================
    
    // Load conv weights and biases from include files
    `include "conv_weights.vh"
    `include "conv_bias.vh"
    
    // Reorganize weights for each filter
    // CONV_WEIGHTS is flat array, need to split into 4 filters of 9 weights each
    wire signed [7:0] filter_weights [0:NUM_FILTERS-1][0:8];
    wire signed [7:0] filter_bias [0:NUM_FILTERS-1];
    
    genvar f, w;
    generate
        for (f = 0; f < NUM_FILTERS; f = f + 1) begin : filter_weight_assign
            for (w = 0; w < 9; w = w + 1) begin : weight_assign
                assign filter_weights[f][w] = CONV_WEIGHTS[f * 9 + w];
            end
            assign filter_bias[f] = CONV_BIAS[f];
        end
    endgenerate
    
    // Convolution outputs
    wire signed [19:0] conv_out [0:NUM_FILTERS-1];
    wire conv_valid [0:NUM_FILTERS-1];
    
    // Instantiate 4 conv units (one per filter)
    generate
        for (f = 0; f < NUM_FILTERS; f = f + 1) begin : conv_units
            conv_unit #(
                .DATA_WIDTH(PIXEL_WIDTH),
                .WEIGHT_WIDTH(8),
                .ACC_WIDTH(20)
            ) conv (
                .clk(clk),
                .rst_n(rst_n),
                .enable(start),
                .window(window_3x3),
                .weights(filter_weights[f]),
                .bias(filter_bias[f]),
                .valid_in(window_valid),
                .conv_out(conv_out[f]),
                .valid_out(conv_valid[f])
            );
        end
    endgenerate
    
    // ========================================================================
    // ReLU Activation
    // ========================================================================
    wire signed [19:0] relu_out [0:NUM_FILTERS-1];
    
    generate
        for (f = 0; f < NUM_FILTERS; f = f + 1) begin : relu_units
            relu #(.WIDTH(20)) relu_inst (
                .data_in(conv_out[f]),
                .data_out(relu_out[f])
            );
        end
    endgenerate
    
    // ========================================================================
    // Max Pooling - Process each filter output separately
    // ========================================================================
    wire signed [19:0] pool_out [0:NUM_FILTERS-1];
    wire pool_valid [0:NUM_FILTERS-1];
    
    generate
        for (f = 0; f < NUM_FILTERS; f = f + 1) begin : pool_units
            max_pool #(
                .DATA_WIDTH(20),
                .INPUT_WIDTH(26),
                .INPUT_HEIGHT(26)
            ) pool (
                .clk(clk),
                .rst_n(rst_n),
                .enable(start),
                .data_in(relu_out[f]),
                .valid_in(conv_valid[f]),
                .data_out(pool_out[f]),
                .valid_out(pool_valid[f])
            );
        end
    endgenerate
    
    // ========================================================================
    // Feature Collection Buffer
    // Collect all 13x13x4 = 676 features before FC layer
    // ========================================================================
    reg signed [19:0] feature_buffer [0:675];  // 13*13*4 features
    reg [9:0] feature_write_addr;
    reg features_ready;
    
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            feature_write_addr <= 0;
            features_ready <= 0;
            for (i = 0; i < 676; i = i + 1) begin
                feature_buffer[i] <= 0;
            end
        end else if (start) begin
            // Collect pooled features
            // Each filter produces 13x13 = 169 values
            // Total: 169 * 4 = 676 features
            if (pool_valid[0]) begin
                // Store features from all filters
                // Simplified: assumes all filters valid simultaneously
                feature_buffer[feature_write_addr] <= pool_out[0];
                feature_buffer[feature_write_addr + 169] <= pool_out[1];
                feature_buffer[feature_write_addr + 338] <= pool_out[2];
                feature_buffer[feature_write_addr + 507] <= pool_out[3];
                
                if (feature_write_addr == 168) begin
                    features_ready <= 1;
                    feature_write_addr <= 0;
                end else begin
                    feature_write_addr <= feature_write_addr + 1;
                end
            end
        end else begin
            features_ready <= 0;
        end
    end
    
    // ========================================================================
    // Fully Connected Layer
    // ========================================================================
    
    // Load FC weights and biases
    `include "fc_weights.vh"
    `include "fc_bias.vh"
    
    // Simplified dense layer implementation
    // For full implementation, this needs proper weight memory and MAC units
    
    reg fc_start;
    reg [9:0] fc_feature_idx;
    wire signed [19:0] fc_feature;
    assign fc_feature = feature_buffer[fc_feature_idx];
    
    wire signed [7:0] fc_weight;
    wire [$clog2(6760)-1:0] fc_weight_addr;
    assign fc_weight = FC_WEIGHTS[fc_weight_addr];
    
    wire signed [7:0] fc_bias_val;
    wire [$clog2(10)-1:0] fc_bias_addr;
    assign fc_bias_val = FC_BIAS[fc_bias_addr];
    
    dense_layer #(
        .INPUT_SIZE(676),
        .OUTPUT_SIZE(NUM_CLASSES),
        .DATA_WIDTH(20),
        .WEIGHT_WIDTH(8),
        .ACC_WIDTH(32)
    ) fc (
        .clk(clk),
        .rst_n(rst_n),
        .start(fc_start),
        .feature_in(fc_feature),
        .feature_valid(1'b1),
        .weight_addr(fc_weight_addr),
        .weight_data(fc_weight),
        .bias_addr(fc_bias_addr),
        .bias_data(fc_bias_val),
        .class_scores(class_scores),
        .done(done)
    );
    
    // Control logic for FC layer
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fc_start <= 0;
        end else if (features_ready && !done) begin
            fc_start <= 1;
        end else if (done) begin
            fc_start <= 0;
        end
    end
    
    // ========================================================================
    // Output - Find maximum class score (argmax)
    // ========================================================================
    reg [3:0] max_class;
    reg signed [31:0] max_score;
    
    always @(*) begin
        max_class = 0;
        max_score = class_scores[0];
        for (i = 1; i < NUM_CLASSES; i = i + 1) begin
            if (class_scores[i] > max_score) begin
                max_score = class_scores[i];
                max_class = i[3:0];
            end
        end
    end
    
    assign predicted_class = max_class;

endmodule
