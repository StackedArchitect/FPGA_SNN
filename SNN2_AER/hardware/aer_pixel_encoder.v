// AER encoder: 2x2 pixels to temporal spike events

`timescale 1ns/1ps

module aer_pixel_encoder #(
    parameter SPIKE_PERIOD = 5,
    parameter PIXEL_WIDTH = 1,
    parameter QUIET_PERIOD = 10
) (
    input  wire clk,
    input  wire rst_n,
    input  wire enable,
    
    input  wire [PIXEL_WIDTH-1:0] pixel_0,
    input  wire [PIXEL_WIDTH-1:0] pixel_1,
    input  wire [PIXEL_WIDTH-1:0] pixel_2,
    input  wire [PIXEL_WIDTH-1:0] pixel_3,
    
    // AER outputs (4 channels, one per pixel)
    output reg spike_out_0,
    output reg spike_out_1,
    output reg spike_out_2,
    output reg spike_out_3,
    
    // AER address output (which neuron is spiking)
    output reg [1:0] aer_addr,       // 2-bit address for 4 inputs
    output reg aer_valid             // Valid spike event on aer_addr
);

    // Spike generation counters for each pixel
    reg [7:0] counter_0, counter_1, counter_2, counter_3;
    
    // Period for each pixel based on intensity
    wire [7:0] period_0, period_1, period_2, period_3;
    
    // Determine spike period based on pixel value
    // Active pixel (1) -> fast spikes (SPIKE_PERIOD)
    // Inactive pixel (0) -> slow/no spikes (QUIET_PERIOD)
    assign period_0 = (pixel_0 > 0) ? SPIKE_PERIOD : QUIET_PERIOD;
    assign period_1 = (pixel_1 > 0) ? SPIKE_PERIOD : QUIET_PERIOD;
    assign period_2 = (pixel_2 > 0) ? SPIKE_PERIOD : QUIET_PERIOD;
    assign period_3 = (pixel_3 > 0) ? SPIKE_PERIOD : QUIET_PERIOD;
    
    // Spike generation logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_0 <= 0;
            counter_1 <= 0;
            counter_2 <= 0;
            counter_3 <= 0;
            spike_out_0 <= 0;
            spike_out_1 <= 0;
            spike_out_2 <= 0;
            spike_out_3 <= 0;
            aer_addr <= 0;
            aer_valid <= 0;
        end else if (enable) begin
            // Default: no spikes
            spike_out_0 <= 0;
            spike_out_1 <= 0;
            spike_out_2 <= 0;
            spike_out_3 <= 0;
            aer_valid <= 0;
            
            // Pixel 0 encoder
            if (counter_0 >= period_0 - 1) begin
                counter_0 <= 0;
                if (pixel_0 > 0) begin  // Only spike if pixel is active
                    spike_out_0 <= 1;
                    aer_addr <= 2'b00;
                    aer_valid <= 1;
                    $display("[%0t] [AER] Pixel 0 spike (addr=00)", $time);
                end
            end else begin
                counter_0 <= counter_0 + 1;
            end
            
            // Pixel 1 encoder
            if (counter_1 >= period_1 - 1) begin
                counter_1 <= 0;
                if (pixel_1 > 0) begin
                    spike_out_1 <= 1;
                    if (!aer_valid) begin  // Priority: first spike wins
                        aer_addr <= 2'b01;
                        aer_valid <= 1;
                    end
                    $display("[%0t] [AER] Pixel 1 spike (addr=01)", $time);
                end
            end else begin
                counter_1 <= counter_1 + 1;
            end
            
            // Pixel 2 encoder
            if (counter_2 >= period_2 - 1) begin
                counter_2 <= 0;
                if (pixel_2 > 0) begin
                    spike_out_2 <= 1;
                    if (!aer_valid) begin
                        aer_addr <= 2'b10;
                        aer_valid <= 1;
                    end
                    $display("[%0t] [AER] Pixel 2 spike (addr=10)", $time);
                end
            end else begin
                counter_2 <= counter_2 + 1;
            end
            
            // Pixel 3 encoder
            if (counter_3 >= period_3 - 1) begin
                counter_3 <= 0;
                if (pixel_3 > 0) begin
                    spike_out_3 <= 1;
                    if (!aer_valid) begin
                        aer_addr <= 2'b11;
                        aer_valid <= 1;
                    end
                    $display("[%0t] [AER] Pixel 3 spike (addr=11)", $time);
                end
            end else begin
                counter_3 <= counter_3 + 1;
            end
        end else begin
            // Disabled: reset counters
            counter_0 <= 0;
            counter_1 <= 0;
            counter_2 <= 0;
            counter_3 <= 0;
            spike_out_0 <= 0;
            spike_out_1 <= 0;
            spike_out_2 <= 0;
            spike_out_3 <= 0;
            aer_valid <= 0;
        end
    end
    
    // Statistics (optional, for debugging)
    initial begin
        $display("===================================================================");
        $display("[AER_ENCODER] Initialized with:");
        $display("  SPIKE_PERIOD  = %0d cycles (for active pixels)", SPIKE_PERIOD);
        $display("  QUIET_PERIOD  = %0d cycles (for inactive pixels)", QUIET_PERIOD);
        $display("  4 input channels (2x2 pixel grid)");
        $display("===================================================================");
    end

endmodule
