`ifndef PULPINO_UART_TEST_SV
`define PULPINO_UART_TEST_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "svt_uart.uvm.pkg"

class pulpino_uart_test extends base_test;
    `uvm_component_utils(pulpino_uart_test)

    // FIFO to bridge VIP monitor's analysis port (broadcast) to blocking get
    uvm_tlm_analysis_fifo#(svt_uart_transaction) tx_xact_fifo;

    function new(string name = "pulpino_uart_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        int tmp_int;

        super.build_phase(phase);
        tx_xact_fifo = new("tx_xact_fifo", this);

        // Parse UART plusargs into soc_config
        if ($value$plusargs("UART_DATA_WIDTH=%d", tmp_int))
            cfg.uart_data_width = tmp_int;
        if ($value$plusargs("UART_PARITY_TYPE=%d", tmp_int))
            cfg.uart_parity_type = tmp_int;
        if ($value$plusargs("UART_STOP_BIT=%d", tmp_int))
            cfg.uart_stop_bit = tmp_int;
        if ($test$plusargs("UART_DISABLE_HW_HANDSHAKE"))
            cfg.uart_disable_hw_handshake = 1;

        `uvm_info(get_type_name(), $sformatf(
            "UART config: data_width=%0d, parity_type=%0d, stop_bit=%0d, disable_hw_hs=%0b",
            cfg.uart_data_width, cfg.uart_parity_type, cfg.uart_stop_bit,
            cfg.uart_disable_hw_handshake), UVM_LOW)
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        env.dce_agent.monitor.tx_xact_observed_port.connect(tx_xact_fifo.analysis_export);
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this, "pulpino_uart_test started");

        fork
            uart_loopback();
        join_none

        // Wait for scoreboard to detect EOT (uart_monitor drops objection on 0x04)
        // The scoreboard's report_phase will determine final PASS/FAIL.
        // Simulation ends when all objections are dropped.

        phase.drop_objection(this, "pulpino_uart_test finished");
    endtask

    // Loopback: VIP monitor samples DUT TX → drive back to DUT RX
    virtual task uart_loopback();
        svt_uart_transaction tx;
        uart_dce_rx_sequence rx_seq;

        forever begin
            // Block until VIP monitor observes a TX transaction (via FIFO bridge)
            `uvm_info(get_type_name(), $sformatf("UART Test: waiting for TX transaction at time %0t", $time), UVM_LOW)
            tx_xact_fifo.get(tx);
            `uvm_info(get_type_name(), $sformatf("UART Test: received TX transaction at time %0t", $time), UVM_LOW)

            // Extract received byte and drive back via sequence
            rx_seq = uart_dce_rx_sequence::type_id::create("rx_seq");
            rx_seq.payload_byte = tx.payload[0];
            rx_seq.start(env.dce_agent.sequencer);
        end
    endtask

endclass

`endif
