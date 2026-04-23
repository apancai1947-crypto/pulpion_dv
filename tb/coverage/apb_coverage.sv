`ifndef APB_COVERAGE_SV
`define APB_COVERAGE_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class apb_coverage extends uvm_component;
    `uvm_component_utils(apb_coverage)

    logic [31:0] paddr;
    bit          pwrite;

    covergroup apb_cg;
        option.per_instance = 1;

        cp_rw: coverpoint pwrite {
            bins READ  = {0};
            bins WRITE = {1};
        }

        cp_peripheral: coverpoint paddr {
            bins UART        = {[32'h1A10_0000 : 32'h1A10_0FFF]};
            bins GPIO        = {[32'h1A10_1000 : 32'h1A10_1FFF]};
            bins SPI_MASTER  = {[32'h1A10_2000 : 32'h1A10_2FFF]};
            bins TIMER       = {[32'h1A10_3000 : 32'h1A10_3FFF]};
            bins EVENT_UNIT  = {[32'h1A10_4000 : 32'h1A10_4FFF]};
            bins I2C         = {[32'h1A10_5000 : 32'h1A10_5FFF]};
            bins FLL         = {[32'h1A10_6000 : 32'h1A10_6FFF]};
            bins SOC_CTRL    = {[32'h1A10_7000 : 32'h1A10_7FFF]};
            bins DEBUG       = {[32'h1A10_8000 : 32'h1A11_FFFF]};
            bins OTHERS      = default;
        }

        cross_periph_rw: cross cp_peripheral, cp_rw;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        apb_cg = new();
    endfunction

    function void sample(logic [31:0] addr, bit wr);
        this.paddr  = addr;
        this.pwrite = wr;
        apb_cg.sample();
    endfunction

endclass

`endif
