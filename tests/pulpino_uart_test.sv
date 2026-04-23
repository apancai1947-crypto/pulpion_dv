`ifndef PULPINO_UART_TEST_SV
`define PULPINO_UART_TEST_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "svt_uart.uvm.pkg"

class pulpino_uart_test extends base_test;
    `uvm_component_utils(pulpino_uart_test)

    function new(string name = "pulpino_uart_test", uvm_component parent = null);
        super.new(name, parent);
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
            // Block until VIP monitor observes a TX transaction
            env.dce_agent.monitor.tx_xact_observed_port.get(tx);

            // Extract received byte and drive back via sequence
            rx_seq = uart_dce_rx_sequence::type_id::create("rx_seq");
            rx_seq.payload_byte = tx.received_packet[0][7:0];
            rx_seq.start(env.dce_agent.sequencer);
        end
    endtask

endclass

`endif
