`ifndef UART_MONITOR_SV
`define UART_MONITOR_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

// UART TX monitor — samples the uart_tx pin, reconstructs bytes at configured baud rate
class uart_monitor extends uvm_component;
    `uvm_component_utils(uart_monitor)

    // Configuration
    int baud_rate = 781250;  // Default from PULPino TB
    int clk_period_ns = 40;  // 25 MHz

    // Virtual interface to uart_tx pin
    virtual interface uart_if vif;

    // Analysis port — sends received bytes to scoreboard
    uvm_analysis_port#(logic [7:0]) analysis_port;

    // Statistics
    protected int char_count;
    protected int bit_period;  // Clock cycles per UART bit

    function new(string name = "uart_monitor", uvm_component parent = null);
        super.new(name, parent);
        analysis_port = new("analysis_port", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual interface uart_if)::get(this, "", "uart_vif", vif))
            `uvm_fatal("UART_MON", "Failed to get uart_if from config_db")
        // Calculate bit period in clock cycles
        bit_period = 1_000_000_000 / (baud_rate * clk_period_ns);
        `uvm_info(get_type_name(), $sformatf("UART Monitor: baud=%0d, bit_period=%0d clk cycles",
            baud_rate, bit_period), UVM_LOW)
    endfunction

    virtual task run_phase(uvm_phase phase);
        logic [7:0] rx_byte;

        `uvm_info(get_type_name(), "UART TX Monitor started, waiting for start bit...", UVM_LOW)

        forever begin
            // Wait for start bit (falling edge on uart_tx)
            @(negedge vif.tx);

            // Sample at center of start bit
            #(bit_period * clk_period_ns * 1ns / 2);

            // Verify still low (valid start bit)
            if (vif.tx != 1'b0) continue;

            // Sample 8 data bits (LSB first)
            for (int i = 0; i < 8; i++) begin
                #(bit_period * clk_period_ns * 1ns);
                rx_byte[i] = vif.tx;
            end

            // Skip stop bit
            #(bit_period * clk_period_ns * 1ns);

            char_count++;
            `uvm_info("UART_MON", $sformatf("[RX #%0d] char='0x%02h' (%s)",
                char_count, rx_byte,
                (rx_byte >= 32 && rx_byte < 127) ? string'(rx_byte) : "?"), UVM_HIGH)

            analysis_port.write(rx_byte);
        end
    endtask

    virtual function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(),
            $sformatf("\n=== UART Monitor ===\n  Chars received: %0d", char_count), UVM_LOW)
    endfunction

endclass

`endif
