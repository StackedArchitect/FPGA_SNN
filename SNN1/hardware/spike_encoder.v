// =============================================================================
// Module: spike_encoder
// Description: Converts static input signal to spike train for SNN
// Author: Senior FPGA Engineer
// Date: January 28, 2026
// =============================================================================

module spike_encoder #(
    parameter SPIKE_PERIOD = 10  // Generate spike every N clock cycles
)(
    input  wire clk,             // Clock signal
    input  wire rst_n,           // Active low reset
    input  wire enable,          // Input signal (1 = encode spikes, 0 = silent)
    output reg  spike_out        // Output spike train
);

    // Counter for spike generation
    reg [$clog2(SPIKE_PERIOD):0] counter;
    
    // Display parameters at initialization
    initial begin
        $display("[SPIKE_ENCODER] Initialized with SPIKE_PERIOD = %0d", SPIKE_PERIOD);
    end
    
    // Spike generation logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            spike_out <= 1'b0;
            $display("[%0t] [SPIKE_ENCODER] Reset asserted", $time);
        end else begin
            if (enable) begin
                // Increment counter
                if (counter >= SPIKE_PERIOD - 1) begin
                    counter <= 0;
                    spike_out <= 1'b1;
                    $display("[%0t] [SPIKE_ENCODER] Spike generated (enable=1)", $time);
                end else begin
                    counter <= counter + 1;
                    spike_out <= 1'b0;
                end
            end else begin
                // No encoding when disabled
                counter <= 0;
                spike_out <= 1'b0;
            end
        end
    end

endmodule
