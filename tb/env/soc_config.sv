`ifndef SOC_CONFIG_SV
`define SOC_CONFIG_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class soc_config extends uvm_object;
    `uvm_object_utils(soc_config)

    // UART monitor config
    int uart_baud_rate = 781250;
    int clk_period_ns  = 40;

    // Enable flags
    bit enable_scoreboard = 1;
    bit enable_coverage   = 1;

    function new(string name = "soc_config");
        super.new(name);
    endfunction

endclass

`endif
