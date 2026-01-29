// =============================================================================
// Module: top_snn
// Description: Top-level wrapper for XOR SNN implementation
//              Connects spike encoders, SNN core, and output logic
// Author: Senior FPGA Engineer
// Date: January 28, 2026
// =============================================================================

module top_snn #(
    parameter SPIKE_PERIOD = 6,    // Faster spike encoding for accumulation
    parameter THRESHOLD = 18,      // Neuron firing threshold
    parameter LEAK = 1,            // Membrane leak
    parameter POTENTIAL_WIDTH = 8  // Bit width for potentials
)(
    input  wire clk,               // System clock
    input  wire rst_n,             // Active low reset
    input  wire switch_0,          // Physical switch/input 0
    input  wire switch_1,          // Physical switch/input 1
    output wire led_out            // Physical LED output
);

    // Internal spike signals
    wire spike_encoded_0;
    wire spike_encoded_1;
    wire spike_output;
    
    // Display top-level initialization
    initial begin
        $display("========================================================================");
        $display("[TOP_SNN] XOR SNN Top-Level Module Initialized");
        $display("========================================================================");
        $display("[TOP_SNN] Configuration:");
        $display("[TOP_SNN]   SPIKE_PERIOD = %0d clock cycles", SPIKE_PERIOD);
        $display("[TOP_SNN]   THRESHOLD = %0d", THRESHOLD);
        $display("[TOP_SNN]   LEAK = %0d", LEAK);
        $display("[TOP_SNN] I/O Mapping:");
        $display("[TOP_SNN]   switch_0 -> Spike Encoder 0 -> SNN Input 0");
        $display("[TOP_SNN]   switch_1 -> Spike Encoder 1 -> SNN Input 1");
        $display("[TOP_SNN]   SNN Output -> LED");
        $display("========================================================================");
    end
    
    // =========================================================================
    // Spike Encoders - Convert static inputs to spike trains
    // =========================================================================
    
    spike_encoder #(
        .SPIKE_PERIOD(SPIKE_PERIOD)
    ) encoder_0 (
        .clk(clk),
        .rst_n(rst_n),
        .enable(switch_0),
        .spike_out(spike_encoded_0)
    );
    
    spike_encoder #(
        .SPIKE_PERIOD(SPIKE_PERIOD)
    ) encoder_1 (
        .clk(clk),
        .rst_n(rst_n),
        .enable(switch_1),
        .spike_out(spike_encoded_1)
    );
    
    // =========================================================================
    // SNN Core - XOR Neural Network
    // =========================================================================
    
    snn_core #(
        .THRESHOLD(THRESHOLD),
        .LEAK(LEAK),
        .POTENTIAL_WIDTH(POTENTIAL_WIDTH)
    ) core (
        .clk(clk),
        .rst_n(rst_n),
        .spike_in_0(spike_encoded_0),
        .spike_in_1(spike_encoded_1),
        .switch_0(switch_0),
        .switch_1(switch_1),
        .spike_out(spike_output)
    );
    
    // =========================================================================
    // Output Logic - Drive LED
    // =========================================================================
    
    // LED output (direct connection for simulation, can add latching for FPGA)
    assign led_out = spike_output;
    
    // =========================================================================
    // Debug Monitors
    // =========================================================================
    
    // Monitor input changes
    always @(switch_0 or switch_1) begin
        $display("[%0t] [TOP_SNN] Input changed: switch_0=%0b, switch_1=%0b", 
                 $time, switch_0, switch_1);
    end
    
    // Monitor encoded spikes
    always @(posedge clk) begin
        if (spike_encoded_0 || spike_encoded_1) begin
            $display("[%0t] [TOP_SNN] Encoded spikes: enc_0=%0b, enc_1=%0b", 
                     $time, spike_encoded_0, spike_encoded_1);
        end
    end
    
    // Monitor output spikes
    always @(posedge clk) begin
        if (spike_output) begin
            $display("[%0t] [TOP_SNN] ############### LED OUTPUT ON ###############", $time);
        end
    end
    
    // Reset monitor
    always @(negedge rst_n or posedge rst_n) begin
        if (!rst_n) begin
            $display("[%0t] [TOP_SNN] *** SYSTEM RESET ASSERTED ***", $time);
        end else begin
            $display("[%0t] [TOP_SNN] *** SYSTEM RESET RELEASED ***", $time);
        end
    end

endmodule
