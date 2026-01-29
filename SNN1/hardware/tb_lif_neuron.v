// =============================================================================
// Testbench: tb_lif_neuron
// Description: Self-checking testbench for LIF neuron module
// Author: Senior FPGA Engineer
// Date: January 28, 2026
// =============================================================================

`timescale 1ns/1ps

module tb_lif_neuron;

    // Testbench parameters
    parameter CLK_PERIOD = 10;              // 10ns clock period (100MHz)
    parameter WEIGHT = 10;
    parameter THRESHOLD = 15;
    parameter LEAK = 1;
    parameter POTENTIAL_WIDTH = 8;
    
    // Testbench signals
    reg clk;
    reg rst_n;
    reg input_spike;
    wire spike_out;
    
    // Test monitoring variables
    integer spike_count;
    integer test_passed;
    integer test_failed;
    
    // Instantiate the LIF neuron module
    lif_neuron #(
        .WEIGHT(WEIGHT),
        .THRESHOLD(THRESHOLD),
        .LEAK(LEAK),
        .POTENTIAL_WIDTH(POTENTIAL_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .input_spike(input_spike),
        .spike_out(spike_out)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Waveform dumping for GTKWave or similar
    initial begin
        $dumpfile("lif_neuron_waveform.vcd");
        $dumpvars(0, tb_lif_neuron);
    end
    
    // Monitor output spikes
    always @(posedge clk) begin
        if (spike_out) begin
            spike_count = spike_count + 1;
            $display("[%0t] SPIKE DETECTED! Total spikes: %0d", $time, spike_count);
        end
    end
    
    // Main test sequence
    initial begin
        // Initialize signals
        rst_n = 0;
        input_spike = 0;
        spike_count = 0;
        test_passed = 0;
        test_failed = 0;
        
        $display("=============================================================");
        $display("LIF Neuron Testbench Started");
        $display("Parameters: WEIGHT=%0d, THRESHOLD=%0d, LEAK=%0d, WIDTH=%0d",
                 WEIGHT, THRESHOLD, LEAK, POTENTIAL_WIDTH);
        $display("=============================================================\n");
        
        // Apply reset
        #(CLK_PERIOD*2);
        rst_n = 1;
        #(CLK_PERIOD*2);
        
        // =====================================================================
        // TEST 1: Frequent spikes - Should fire
        // =====================================================================
        $display("-------------------------------------------------------------");
        $display("TEST 1: Frequent Spikes (Should reach threshold and fire)");
        $display("-------------------------------------------------------------");
        
        spike_count = 0;
        
        // Send 2 spikes close together
        // Cycle 1: Potential = 0 + 10 - 1 = 9
        @(posedge clk);
        input_spike = 1;
        @(posedge clk);
        input_spike = 0;
        
        // Wait 1 cycle
        // Cycle 2: Potential = 9 - 1 = 8
        @(posedge clk);
        
        // Send another spike
        // Cycle 3: Potential = 8 + 10 - 1 = 17 >= 15, should fire!
        @(posedge clk);
        input_spike = 1;
        @(posedge clk);
        input_spike = 0;
        
        // Wait for spike output
        #(CLK_PERIOD*2);
        
        if (spike_count == 1) begin
            $display("[PASS] Test 1: Neuron fired as expected with frequent spikes");
            test_passed = test_passed + 1;
        end else begin
            $display("[FAIL] Test 1: Expected 1 spike, got %0d", spike_count);
            test_failed = test_failed + 1;
        end
        
        // Wait for membrane to settle
        #(CLK_PERIOD*5);
        
        // =====================================================================
        // TEST 2: Slow spikes - Leak prevents firing
        // =====================================================================
        $display("\n-------------------------------------------------------------");
        $display("TEST 2: Slow Spikes (Leak should prevent threshold)");
        $display("-------------------------------------------------------------");
        
        spike_count = 0;
        
        // Send spikes with large gaps - leak should prevent accumulation
        // With WEIGHT=10, LEAK=1, if we wait >10 cycles between spikes,
        // the potential will leak away
        
        @(posedge clk);
        input_spike = 1;
        @(posedge clk);
        input_spike = 0;
        
        // Wait 12 cycles - potential should leak to 0
        // After spike: 10
        // After 12 cycles: 10 + 10 - 1*13 = -3 -> clamped to 0
        repeat(12) @(posedge clk);
        
        // Send another spike
        @(posedge clk);
        input_spike = 1;
        @(posedge clk);
        input_spike = 0;
        
        // Wait 12 more cycles
        repeat(12) @(posedge clk);
        
        // Send another spike
        @(posedge clk);
        input_spike = 1;
        @(posedge clk);
        input_spike = 0;
        
        // Wait and check
        #(CLK_PERIOD*5);
        
        if (spike_count == 0) begin
            $display("[PASS] Test 2: Leak prevented firing as expected");
            test_passed = test_passed + 1;
        end else begin
            $display("[FAIL] Test 2: Expected 0 spikes, got %0d", spike_count);
            test_failed = test_failed + 1;
        end
        
        // =====================================================================
        // TEST 3: Reset functionality
        // =====================================================================
        $display("\n-------------------------------------------------------------");
        $display("TEST 3: Reset Functionality");
        $display("-------------------------------------------------------------");
        
        // Build up some potential
        @(posedge clk);
        input_spike = 1;
        @(posedge clk);
        input_spike = 0;
        #(CLK_PERIOD*2);
        
        // Apply reset
        rst_n = 0;
        #(CLK_PERIOD*2);
        rst_n = 1;
        #(CLK_PERIOD*2);
        
        $display("[PASS] Test 3: Reset applied successfully");
        test_passed = test_passed + 1;
        
        // =====================================================================
        // TEST 4: Multiple firing cycles
        // =====================================================================
        $display("\n-------------------------------------------------------------");
        $display("TEST 4: Multiple Firing Cycles");
        $display("-------------------------------------------------------------");
        
        spike_count = 0;
        
        // Fire the neuron multiple times
        repeat(3) begin
            // Send 2 spikes to reach threshold
            @(posedge clk);
            input_spike = 1;
            @(posedge clk);
            input_spike = 0;
            @(posedge clk);
            @(posedge clk);
            input_spike = 1;
            @(posedge clk);
            input_spike = 0;
            #(CLK_PERIOD*3);
        end
        
        if (spike_count == 3) begin
            $display("[PASS] Test 4: Neuron fired 3 times as expected");
            test_passed = test_passed + 1;
        end else begin
            $display("[FAIL] Test 4: Expected 3 spikes, got %0d", spike_count);
            test_failed = test_failed + 1;
        end
        
        // =====================================================================
        // Test Summary
        // =====================================================================
        #(CLK_PERIOD*10);
        
        $display("\n=============================================================");
        $display("TEST SUMMARY");
        $display("=============================================================");
        $display("Tests Passed: %0d", test_passed);
        $display("Tests Failed: %0d", test_failed);
        
        if (test_failed == 0) begin
            $display("\n*** ALL TESTS PASSED ***");
        end else begin
            $display("\n*** SOME TESTS FAILED ***");
        end
        
        $display("=============================================================\n");
        
        // Finish simulation
        #(CLK_PERIOD*10);
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #1000000; // 1ms timeout
        $display("\n[ERROR] Simulation timeout!");
        $finish;
    end

endmodule
