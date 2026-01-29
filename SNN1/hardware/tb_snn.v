// =============================================================================
// Testbench: tb_snn
// Description: Comprehensive testbench for XOR SNN
//              Tests all 4 XOR combinations with detailed monitoring
// Author: Senior FPGA Engineer
// Date: January 28, 2026
// =============================================================================

`timescale 1ns/1ps

module tb_snn;

    // Testbench parameters
    parameter CLK_PERIOD = 10;        // 10ns clock period (100MHz)
    parameter SPIKE_PERIOD = 6;       // Spike every 6 cycles (optimized)
    parameter THRESHOLD = 18;         // Updated to match snn_core
    parameter LEAK = 1;
    parameter POTENTIAL_WIDTH = 8;
    parameter SIM_TIME = 1000;        // 1000ns simulation time
    
    // Testbench signals
    reg clk;
    reg rst_n;
    reg switch_0;
    reg switch_1;
    wire led_out;
    
    // Test monitoring
    integer output_spike_count;
    integer test_number;
    reg [1:0] current_input;
    integer expected_output;
    
    // Instantiate the top-level SNN module
    top_snn #(
        .SPIKE_PERIOD(SPIKE_PERIOD),
        .THRESHOLD(THRESHOLD),
        .LEAK(LEAK),
        .POTENTIAL_WIDTH(POTENTIAL_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .switch_0(switch_0),
        .switch_1(switch_1),
        .led_out(led_out)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Waveform dumping
    initial begin
        $dumpfile("snn_xor_waveform.vcd");
        $dumpvars(0, tb_snn);
        // Dump internal signals for detailed analysis
        $dumpvars(0, dut.core.hidden_neuron_0.membrane_potential);
        $dumpvars(0, dut.core.hidden_neuron_1.membrane_potential);
        $dumpvars(0, dut.core.output_neuron.membrane_potential);
    end
    
    // Count output spikes
    always @(posedge clk) begin
        if (led_out) begin
            output_spike_count = output_spike_count + 1;
        end
    end
    
    // Main test sequence
    initial begin
        // Initialize
        rst_n = 0;
        switch_0 = 0;
        switch_1 = 0;
        output_spike_count = 0;
        test_number = 0;
        
        $display("\n");
        $display("========================================================================");
        $display("========================================================================");
        $display("           XOR SPIKING NEURAL NETWORK - TESTBENCH");
        $display("========================================================================");
        $display("========================================================================");
        $display("");
        $display("Simulation Parameters:");
        $display("  Clock Period: %0d ns", CLK_PERIOD);
        $display("  Spike Period: %0d cycles", SPIKE_PERIOD);
        $display("  Total Simulation Time: %0d ns", SIM_TIME);
        $display("  Neuron Threshold: %0d", THRESHOLD);
        $display("  Neuron Leak: %0d", LEAK);
        $display("");
        $display("XOR Truth Table:");
        $display("  0 XOR 0 = 0");
        $display("  0 XOR 1 = 1");
        $display("  1 XOR 0 = 1");
        $display("  1 XOR 1 = 0");
        $display("");
        $display("========================================================================");
        $display("");
        
        // Apply reset
        $display("[%0t] Applying system reset...", $time);
        #(CLK_PERIOD*3);
        rst_n = 1;
        $display("[%0t] Reset released, starting tests...", $time);
        #(CLK_PERIOD*2);
        
        // =====================================================================
        // TEST 1: 0 XOR 0 = 0
        // =====================================================================
        test_number = 1;
        current_input = 2'b00;
        expected_output = 0;
        output_spike_count = 0;
        
        $display("");
        $display("========================================================================");
        $display("TEST 1: 0 XOR 0 = 0 (Expected: NO output spikes)");
        $display("========================================================================");
        
        switch_0 = 0;
        switch_1 = 0;
        
        #150;  // Run for 150ns
        
        $display("");
        $display("------------------------------------------------------------------------");
        $display("TEST 1 RESULT:");
        $display("  Input: %0b XOR %0b", current_input[0], current_input[1]);
        $display("  Output Spikes: %0d", output_spike_count);
        $display("  Expected: 0 spikes");
        if (output_spike_count == 0) begin
            $display("  STATUS: ✓ PASS");
        end else begin
            $display("  STATUS: ✗ FAIL");
        end
        $display("------------------------------------------------------------------------");
        $display("");
        
        #(CLK_PERIOD*5);
        
        // =====================================================================
        // TEST 2: 0 XOR 1 = 1
        // =====================================================================
        test_number = 2;
        current_input = 2'b01;
        expected_output = 1;
        output_spike_count = 0;
        
        $display("");
        $display("========================================================================");
        $display("TEST 2: 0 XOR 1 = 1 (Expected: output spikes present)");
        $display("========================================================================");
        
        switch_0 = 0;
        switch_1 = 1;
        
        #170;  // Run for 170ns (increased for spike timing)
        
        $display("");
        $display("------------------------------------------------------------------------");
        $display("TEST 2 RESULT:");
        $display("  Input: %0b XOR %0b", current_input[0], current_input[1]);
        $display("  Output Spikes: %0d", output_spike_count);
        $display("  Expected: >0 spikes");
        if (output_spike_count > 0) begin
            $display("  STATUS: ✓ PASS");
        end else begin
            $display("  STATUS: ✗ FAIL");
        end
        $display("------------------------------------------------------------------------");
        $display("");
        
        #(CLK_PERIOD*5);
        
        // =====================================================================
        // TEST 3: 1 XOR 0 = 1
        // =====================================================================
        test_number = 3;
        current_input = 2'b10;
        expected_output = 1;
        output_spike_count = 0;
        
        $display("");
        $display("========================================================================");
        $display("TEST 3: 1 XOR 0 = 1 (Expected: output spikes present)");
        $display("========================================================================");
        
        switch_0 = 1;
        switch_1 = 0;
        
        #170;  // Run for 170ns
        
        $display("");
        $display("------------------------------------------------------------------------");
        $display("TEST 3 RESULT:");
        $display("  Input: %0b XOR %0b", current_input[0], current_input[1]);
        $display("  Output Spikes: %0d", output_spike_count);
        $display("  Expected: >0 spikes");
        if (output_spike_count > 0) begin
            $display("  STATUS: ✓ PASS");
        end else begin
            $display("  STATUS: ✗ FAIL");
        end
        $display("------------------------------------------------------------------------");
        $display("");
        
        #(CLK_PERIOD*10);  // Extra settling time before Test 4
        
        // =====================================================================
        // TEST 4: 1 XOR 1 = 0
        // =====================================================================
        test_number = 4;
        current_input = 2'b11;
        expected_output = 0;
        output_spike_count = 0;
        
        $display("");
        $display("========================================================================");
        $display("TEST 4: 1 XOR 1 = 0 (Expected: NO output spikes)");
        $display("========================================================================");
        
        switch_0 = 1;
        switch_1 = 1;
        
        #200;  // Run for 200ns
        
        $display("");
        $display("------------------------------------------------------------------------");
        $display("TEST 4 RESULT:");
        $display("  Input: %0b XOR %0b", current_input[0], current_input[1]);
        $display("  Output Spikes: %0d", output_spike_count);
        $display("  Expected: 0 spikes");
        if (output_spike_count == 0) begin
            $display("  STATUS: ✓ PASS");
        end else begin
            $display("  STATUS: ✗ FAIL");
        end
        $display("------------------------------------------------------------------------");
        $display("");
        
        // =====================================================================
        // Final Summary
        // =====================================================================
        #(CLK_PERIOD*10);
        
        $display("");
        $display("========================================================================");
        $display("========================================================================");
        $display("                    SIMULATION COMPLETE");
        $display("========================================================================");
        $display("========================================================================");
        $display("");
        $display("Total simulation time: %0t ns", $time);
        $display("Waveform saved to: snn_xor_waveform.vcd");
        $display("");
        $display("Next Steps:");
        $display("  1. View waveforms: gtkwave snn_xor_waveform.vcd");
        $display("  2. Verify neuron potentials and spike timing");
        $display("  3. If tests pass, proceed to synthesis");
        $display("");
        $display("========================================================================");
        $display("");
        
        $finish;
    end
    
    // Simulation timeout
    initial begin
        #SIM_TIME;
        if ($time >= SIM_TIME) begin
            $display("\n[WARNING] Simulation reached %0d ns time limit", SIM_TIME);
        end
    end
    
    // Periodic status updates
    always @(posedge clk) begin
        if ($time % 50 == 0 && $time > 0) begin
            $display("[%0t] Status: Test=%0d, SW0=%0b, SW1=%0b, LED=%0b, Spikes=%0d", 
                     $time, test_number, switch_0, switch_1, led_out, output_spike_count);
        end
    end

endmodule
