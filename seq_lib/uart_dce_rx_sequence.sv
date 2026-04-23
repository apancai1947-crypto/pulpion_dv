`ifndef UART_DCE_RX_SEQUENCE_SV
`define UART_DCE_RX_SEQUENCE_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "svt_uart.uvm.pkg"

class uart_dce_rx_sequence extends svt_uart_dce_base_sequence;
    `uvm_object_utils(uart_dce_rx_sequence)

    // Byte to drive back to DUT RX (set by caller before start)
    bit [7:0] payload_byte = 8'h00;

    function new(string name = "uart_dce_rx_sequence");
        super.new(name);
    endfunction

    virtual task body();
        svt_uart_transaction req;

        req = svt_uart_transaction::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {
            packet_count == 1;
            payload.size() == 1;
            payload[0] == local::payload_byte;
        });
        finish_item(req);
    endtask

endclass

`endif
