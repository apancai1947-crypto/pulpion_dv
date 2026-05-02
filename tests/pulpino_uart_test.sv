`ifndef PULPINO_UART_TEST_SV
`define PULPINO_UART_TEST_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "svt_uart.uvm.pkg"

class pulpino_uart_test extends base_test;
    `uvm_component_utils(pulpino_uart_test)

    // FIFO to bridge VIP monitor's analysis port (broadcast) to blocking get
    uvm_tlm_analysis_fifo#(svt_uart_transaction) rx_xact_fifo;

    function new(string name = "pulpino_uart_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        int tmp_int;

        super.build_phase(phase);
        rx_xact_fifo = new("rx_xact_fifo", this);

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
        env.dce_agent.monitor.rx_xact_observed_port.connect(rx_xact_fifo.analysis_export);
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this, "pulpino_uart_test started");

        fork
            uart_loopback();
        join_none

        // Wait for EOT from memory-mapped stdout monitor
        `uvm_info(get_type_name(), "Waiting for EOT from stdout monitor...", UVM_LOW)
        env.stdout_mon.eot_event.wait_trigger();
        `uvm_info(get_type_name(), "EOT received from stdout monitor, ending test", UVM_LOW)

        // Small delay to let last UVM messages flush
        #100ns;

        phase.drop_objection(this, "pulpino_uart_test finished");
    endtask

    // Loopback: VIP monitor samples DUT TX → drive back to DUT RX
    virtual task uart_loopback();
        svt_uart_transaction tx;
        uart_dce_rx_sequence rx_seq;

        forever begin
            // Block until VIP monitor observes a TX transaction (via FIFO bridge)
            `uvm_info(get_type_name(), $sformatf("UART Test: waiting for TX transaction at time %0t", $time), UVM_LOW)
            rx_xact_fifo.get(tx);
            `uvm_info(get_type_name(), $sformatf("UART Test: received TX transaction at time %0t", $time), UVM_LOW)

            // Extract received byte and drive back via sequence
            rx_seq = uart_dce_rx_sequence::type_id::create("rx_seq");
            rx_seq.payload_byte = tx.payload[0];
            rx_seq.start(env.dce_agent.sequencer);
        end
    endtask

endclass

`endif
