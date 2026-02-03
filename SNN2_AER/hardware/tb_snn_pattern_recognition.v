// Testbench for 3-layer SNN pattern recognition

`timescale 1ns/1ps

module tb_snn_pattern_recognition;

    // Clock and reset
    reg clk;
    reg rst_n;
    
    // Pattern stimulus (2x2 pixels)
    reg [3:0] pattern;
    reg pattern_enable;
    
    // AER encoder signals
    wire spike_in_0, spike_in_1, spike_in_2, spike_in_3;
    
    // Configurable bias signals
    reg signed [3:0] bias_output_0;
    reg signed [3:0] bias_output_1;
    reg signed [3:0] bias_output_2;
    
    // SNN outputs
    wire spike_out_0, spike_out_1, spike_out_2;
    wire [1:0] winner;
    
    // Debug signals
    wire [7:0] pot_h0, pot_h1, pot_h2, pot_h3;
    wire [7:0] pot_h4, pot_h5, pot_h6, pot_h7;
    wire [7:0] pot_o0, pot_o1, pot_o2;
    
    // Test metrics
    integer spike_count_0, spike_count_1, spike_count_2;
    integer test_num;
    reg [1:0] expected_winner;
    reg test_passed;
    integer total_tests, passed_tests;
    
    // INSTANTIATE AER PIXEL ENCODER
    
    aer_pixel_encoder #(
        .SPIKE_PERIOD(5),    // Active pixels spike every 5 cycles
        .QUIET_PERIOD(10)    // Inactive pixels spike every 10 cycles (background)
    ) aer_enc (
        .clk(clk),
        .rst_n(rst_n),
        .enable(1'b1),       // Enable encoding
        .pixel_0(pattern[0]),
        .pixel_1(pattern[1]),
        .pixel_2(pattern[2]),
        .pixel_3(pattern[3]),
        .spike_out_0(spike_in_0),
        .spike_out_1(spike_in_1),
        .spike_out_2(spike_in_2),
        .spike_out_3(spike_in_3)
    );
    
    // INSTANTIATE SNN CORE
    
    snn_core_pattern_recognition #(
        .THRESHOLD_HIDDEN(20),
        .THRESHOLD_OUTPUT(15),
        .LEAK(1),
        .POTENTIAL_WIDTH(8)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .spike_in_0(spike_in_0),
        .spike_in_1(spike_in_1),
        .spike_in_2(spike_in_2),
        .spike_in_3(spike_in_3),
        .bias_output_0(bias_output_0),
        .bias_output_1(bias_output_1),
        .bias_output_2(bias_output_2),
        .spike_out_0(spike_out_0),
        .spike_out_1(spike_out_1),
        .spike_out_2(spike_out_2),
        .winner(winner),
        .pot_h0(pot_h0), .pot_h1(pot_h1), .pot_h2(pot_h2), .pot_h3(pot_h3),
        .pot_h4(pot_h4), .pot_h5(pot_h5), .pot_h6(pot_h6), .pot_h7(pot_h7),
        .pot_o0(pot_o0), .pot_o1(pot_o1), .pot_o2(pot_o2)
    );
    
    // CLOCK GENERATION: 10MHz (100ns period)
    
    initial begin
        clk = 0;
        forever #50 clk = ~clk;
    end
    
    // SPIKE MONITORING
    
    always @(posedge clk) begin
        if (!rst_n) begin
            spike_count_0 <= 0;
            spike_count_1 <= 0;
            spike_count_2 <= 0;
        end else begin
            if (spike_out_0) spike_count_0 <= spike_count_0 + 1;
            if (spike_out_1) spike_count_1 <= spike_count_1 + 1;
            if (spike_out_2) spike_count_2 <= spike_count_2 + 1;
        end
    end
    
    // TEST TASK: Present pattern and check winner
    
    task present_pattern(
        input [3:0] test_pattern,
        input [1:0] expected,
        input [79:0] pattern_name,
        input signed [3:0] b0,
        input signed [3:0] b1,
        input signed [3:0] b2,
        input integer duration_cycles
    );
    begin
        test_num = test_num + 1;
        total_tests = total_tests + 1;
        
        $display("\n--- Test %0d: %0s ---", test_num, pattern_name);
        $display("Pattern: [%b,%b,%b,%b]", test_pattern[0], test_pattern[1], 
                 test_pattern[2], test_pattern[3]);
        $display("Expected winner: %0d", expected);
        $display("Bias signals: [%0d, %0d, %0d]", b0, b1, b2);
        
        // Reset spike counters
        spike_count_0 = 0;
        spike_count_1 = 0;
        spike_count_2 = 0;
        
        // Apply pattern and bias
        pattern = test_pattern;
        bias_output_0 = b0;
        bias_output_1 = b1;
        bias_output_2 = b2;
        expected_winner = expected;
        
        // Run for specified duration
        repeat(duration_cycles) @(posedge clk);
        
        // Check results
        $display("Spike counts: O0=%0d, O1=%0d, O2=%0d", 
                 spike_count_0, spike_count_1, spike_count_2);
        $display("Winner: %0d (O%0d)", winner, winner);
        
        if (winner == expected) begin
            $display("✓ PASS - Correct classification");
            test_passed = 1;
            passed_tests = passed_tests + 1;
        end else begin
            $display("✗ FAIL - Expected O%0d, got O%0d", expected, winner);
            test_passed = 0;
        end
        
        // Add separation time between patterns
        pattern = 4'b0000;
        repeat(50) @(posedge clk);
    end
    endtask
    
    // MAIN TEST SEQUENCE
    
    initial begin
        // Waveform dump
        $dumpfile("snn_pattern_recognition.vcd");
        $dumpvars(0, tb_snn_pattern_recognition);
        
        // Initialize signals
        rst_n = 0;
        pattern = 4'b0000;
        pattern_enable = 0;
        bias_output_0 = 0;
        bias_output_1 = 0;
        bias_output_2 = 0;
        test_num = 0;
        total_tests = 0;
        passed_tests = 0;
        
        $display("\n========================================================================");
        $display("  SNN Pattern Recognition Testbench");
        $display("========================================================================");
        $display("Testing 3-layer SNN with STDP-trained weights");
        $display("Network: 4 inputs → 8 hidden → 3 outputs\n");
        
        // Reset
        repeat(10) @(posedge clk);
        rst_n = 1;
        repeat(5) @(posedge clk);
        
        // TEST SUITE 1: Inference WITHOUT Bias (Pure STDP weights)
        
        $display("\n========================================================================");
        $display("  TEST SUITE 1: Inference Without Bias Signals (Pure STDP)");
        $display("========================================================================");
        
        // Test L-shape [1,0,1,1] → Expected O0
        present_pattern(4'b1101, 2'b00, "L-shape (no bias)", 0, 0, 0, 2000);
        
        // Test T-shape [1,1,0,1] → Expected O1
        present_pattern(4'b1011, 2'b01, "T-shape (no bias)", 0, 0, 0, 2000);
        
        // Test Cross [0,1,1,1] → Expected O2
        present_pattern(4'b1110, 2'b10, "Cross (no bias)", 0, 0, 0, 2000);
        
        // TEST SUITE 2: Inference WITH Bias Signals (Supervised inference)
        
        $display("\n========================================================================");
        $display("  TEST SUITE 2: Inference With Bias Signals (Supervised)");
        $display("========================================================================");
        $display("Using bias to compensate for teacher signal dependency");
        
        // Test L-shape with bias favoring O0
        present_pattern(4'b1101, 2'b00, "L-shape (bias O0=+3)", 3, 0, 0, 2000);
        
        // Test T-shape with bias favoring O1
        present_pattern(4'b1011, 2'b01, "T-shape (bias O1=+3)", 0, 3, 0, 2000);
        
        // Test Cross with bias favoring O2
        present_pattern(4'b1110, 2'b10, "Cross (bias O2=+3)", 0, 0, 3, 2000);
        
        // TEST SUITE 3: Pattern Variations (Noise/Occlusion)
        
        $display("\n========================================================================");
        $display("  TEST SUITE 3: Pattern Robustness (Occlusions)");
        $display("========================================================================");
        
        // L-shape with one pixel missing [1,0,0,1] (missing pixel 2)
        present_pattern(4'b1001, 2'b00, "L-shape (partial)", 2, 0, 0, 2000);
        
        // T-shape with one pixel missing [1,1,0,0] 
        present_pattern(4'b0011, 2'b01, "T-shape (partial)", 0, 2, 0, 2000);
        
        // Cross with one pixel missing [0,1,1,0]
        present_pattern(4'b0110, 2'b10, "Cross (partial)", 0, 0, 2, 2000);
        
        // TEST SUITE 4: Extended Duration (Accumulation test)
        
        $display("\n========================================================================");
        $display("  TEST SUITE 4: Extended Duration Patterns");
        $display("========================================================================");
        
        // Long presentation to test membrane potential accumulation
        present_pattern(4'b1101, 2'b00, "L-shape (5000 cycles)", 0, 0, 0, 5000);
        present_pattern(4'b1011, 2'b01, "T-shape (5000 cycles)", 0, 0, 0, 5000);
        present_pattern(4'b1110, 2'b10, "Cross (5000 cycles)", 0, 0, 0, 5000);
        
        // FINAL REPORT
        
        $display("\n========================================================================");
        $display("  FINAL TEST REPORT");
        $display("========================================================================");
        $display("Total tests: %0d", total_tests);
        $display("Passed: %0d", passed_tests);
        $display("Failed: %0d", total_tests - passed_tests);
        $display("Success rate: %0.1f%%", (passed_tests * 100.0) / total_tests);
        
        if (passed_tests == total_tests) begin
            $display("\n✓✓✓ ALL TESTS PASSED ✓✓✓");
        end else begin
            $display("\n✗✗✗ SOME TESTS FAILED ✗✗✗");
        end
        
        $display("========================================================================\n");
        
        // Run a bit longer to capture final waveforms
        repeat(100) @(posedge clk);
        
        $finish;
    end
    
    // MONITORING: Display activity every 1000 cycles
    
    integer cycle_count;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            cycle_count = 0;
        end else begin
            cycle_count = cycle_count + 1;
            
            if (cycle_count % 1000 == 0) begin
                $display("[%0t] Cycle %0d | Spikes: O0=%0d O1=%0d O2=%0d | Winner: O%0d | Potentials: O0=%0d O1=%0d O2=%0d",
                         $time, cycle_count, spike_count_0, spike_count_1, spike_count_2, 
                         winner, pot_o0, pot_o1, pot_o2);
            end
        end
    end
    
    // Timeout watchdog
    initial begin
        #50000000; // 50ms timeout
        $display("\n✗ TIMEOUT - Test exceeded maximum duration");
        $finish;
    end

endmodule
