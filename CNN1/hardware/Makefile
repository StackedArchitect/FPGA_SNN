# Makefile for CNN Hardware Simulation
# Uses Icarus Verilog and Verilator for simulation

# Tools
IVERILOG = iverilog
VVP = vvp
GTKWAVE = gtkwave
VERILATOR = verilator

# Directories
SRC_DIR = .
TB_DIR = .
BUILD_DIR = build
VLT_DIR = $(BUILD_DIR)/verilator

# Create build directory
$(shell mkdir -p $(BUILD_DIR))
$(shell mkdir -p $(VLT_DIR))

# Compilation flags
VFLAGS = -Wall -g2012
VLINT_FLAGS = --lint-only -Wall --timing

# Default target
all: help

help:
	@echo "========================================="
	@echo "CNN Hardware Simulation Makefile"
	@echo "========================================="
	@echo ""
	@echo "Icarus Verilog targets:"
	@echo "  make test_line_buffer  - Test line buffer module"
	@echo "  make test_conv_unit    - Test convolution unit"
	@echo "  make test_relu         - Test ReLU module"
	@echo "  make test_max_pool     - Test max pooling module"
	@echo "  make test_system       - System integration test"
	@echo "  make test_all          - Run all tests"
	@echo ""
	@echo "Verilator targets:"
	@echo "  make lint_all          - Lint all modules with Verilator"
	@echo "  make lint_max_pool     - Lint max_pool module"
	@echo "  make lint_line_buffer  - Lint line_buffer module"
	@echo ""
	@echo "Utility:"
	@echo "  make clean             - Clean build files"
	@echo "  make wave_*            - View waveforms"
	@echo ""

# Line Buffer Test
test_line_buffer: $(BUILD_DIR)/tb_line_buffer
	@echo "\n========================================="
	@echo "Running Line Buffer Test"
	@echo "========================================="
	$(VVP) $(BUILD_DIR)/tb_line_buffer
	@echo "\n✓ Line buffer simulation complete"
	@echo "  Waveform: line_buffer_test.vcd"
	@echo "  View with: make wave_line_buffer\n"

$(BUILD_DIR)/tb_line_buffer: $(TB_DIR)/tb_line_buffer.v $(SRC_DIR)/line_buffer.v
	$(IVERILOG) $(VFLAGS) -o $@ $^

# Convolution Unit Test
test_conv_unit: $(BUILD_DIR)/tb_conv_unit
	@echo "\n========================================="
	@echo "Running Convolution Unit Test"
	@echo "========================================="
	$(VVP) $(BUILD_DIR)/tb_conv_unit
	@echo "\n✓ Conv unit simulation complete"
	@echo "  Waveform: conv_unit_test.vcd"
	@echo "  View with: make wave_conv_unit\n"

$(BUILD_DIR)/tb_conv_unit: $(TB_DIR)/tb_conv_unit.v $(SRC_DIR)/conv_unit.v
	$(IVERILOG) $(VFLAGS) -o $@ $^

# ReLU Test (simple, can add if needed)
test_relu:
	@echo "ReLU is combinational - testing in other modules"

# Max Pool Test
test_max_pool: $(BUILD_DIR)/tb_max_pool
	@echo "\n========================================="
	@echo "Running Max Pool Test"
	@echo "========================================="
	$(VVP) $(BUILD_DIR)/tb_max_pool
	@echo "\n✓ Max pool simulation complete"
	@echo "  Waveform: max_pool_test.vcd"
	@echo "  View with: make wave_max_pool\n"

$(BUILD_DIR)/tb_max_pool: $(TB_DIR)/tb_max_pool.v $(SRC_DIR)/max_pool.v
	$(IVERILOG) $(VFLAGS) -o $@ $^

# System Integration Test
test_system: $(BUILD_DIR)/tb_system_simple
	@echo "\n========================================="
	@echo "Running System Integration Test"
	@echo "========================================="
	$(VVP) $(BUILD_DIR)/tb_system_simple
	@echo "\n✓ System integration simulation complete"
	@echo "  Waveform: system_integration_test.vcd\n"

$(BUILD_DIR)/tb_system_simple: $(TB_DIR)/tb_system_simple.v $(SRC_DIR)/line_buffer.v $(SRC_DIR)/conv_unit.v $(SRC_DIR)/relu.v
	$(IVERILOG) $(VFLAGS) -o $@ $^

# Run all tests
test_all: test_line_buffer test_conv_unit test_system
	@echo "\n========================================="
	@echo "All tests complete!"
	@echo "========================================="

# Waveform viewers
wave_line_buffer:
	$(GTKWAVE) line_buffer_test.vcd &

wave_conv_unit:
	$(GTKWAVE) conv_unit_test.vcd &

wave_max_pool:
	$(GTKWAVE) max_pool_test.vcd &

# Verilator Lint Targets
lint_line_buffer:
	@echo "\n========================================="
	@echo "Linting line_buffer.v with Verilator"
	@echo "========================================="
	$(VERILATOR) $(VLINT_FLAGS) --top-module line_buffer $(SRC_DIR)/line_buffer.v
	@echo "✓ Lint complete\n"

lint_conv_unit:
	@echo "\n========================================="
	@echo "Linting conv_unit.v with Verilator"
	@echo "========================================="
	$(VERILATOR) $(VLINT_FLAGS) --top-module conv_unit $(SRC_DIR)/conv_unit.v
	@echo "✓ Lint complete\n"

lint_max_pool:
	@echo "\n========================================="
	@echo "Linting max_pool.v with Verilator"
	@echo "========================================="
	$(VERILATOR) $(VLINT_FLAGS) --top-module max_pool $(SRC_DIR)/max_pool.v
	@echo "✓ Lint complete\n"

lint_relu:
	@echo "\n========================================="
	@echo "Linting relu.v with Verilator"
	@echo "========================================="
	$(VERILATOR) $(VLINT_FLAGS) --top-module relu $(SRC_DIR)/relu.v
	@echo "✓ Lint complete\n"

lint_dense:
	@echo "\n========================================="
	@echo "Linting dense_layer.v with Verilator"
	@echo "========================================="
	$(VERILATOR) $(VLINT_FLAGS) --top-module dense_layer $(SRC_DIR)/dense_layer.v
	@echo "✓ Lint complete\n"

lint_all: lint_line_buffer lint_conv_unit lint_relu lint_max_pool lint_dense
	@echo "\n========================================="
	@echo "All modules linted successfully!"
	@echo "========================================="

# Clean
clean:
	rm -rf $(BUILD_DIR)
	rm -f *.vcd
	rm -f *.out
	@echo "✓ Cleaned build files"

.PHONY: all help test_line_buffer test_conv_unit test_relu test_max_pool test_system test_all clean wave_line_buffer wave_conv_unit wave_max_pool lint_line_buffer lint_conv_unit lint_max_pool lint_relu lint_dense lint_all
