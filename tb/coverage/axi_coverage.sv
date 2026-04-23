`ifndef AXI_COVERAGE_SV
`define AXI_COVERAGE_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class axi_coverage extends uvm_component;
    `uvm_component_utils(axi_coverage)

    logic [31:0] addr;
    logic [ 2:0] size;
    logic [ 1:0] resp;
    bit          is_write;

    covergroup axi_cg;
        option.per_instance = 1;

        cp_rw: coverpoint is_write {
            bins READ  = {0};
            bins WRITE = {1};
        }

        cp_addr_region: coverpoint addr {
            bins INSTR_MEM   = {[32'h0000_0000 : 32'h000F_FFFF]};
            bins DATA_MEM    = {[32'h0010_0000 : 32'h001F_FFFF]};
            bins UART        = {32'h1A10_0000, 32'h1A10_0004, 32'h1A10_0008, 32'h1A10_000C};
            bins GPIO        = {[32'h1A10_1000 : 32'h1A10_1FFF]};
            bins SPI         = {[32'h1A10_2000 : 32'h1A10_2FFF]};
            bins TIMER       = {[32'h1A10_3000 : 32'h1A10_3FFF]};
            bins EVENT_UNIT  = {[32'h1A10_4000 : 32'h1A10_4FFF]};
            bins I2C         = {[32'h1A10_5000 : 32'h1A10_5FFF]};
            bins FLL         = {[32'h1A10_6000 : 32'h1A10_6FFF]};
            bins SOC_CTRL    = {[32'h1A10_7000 : 32'h1A10_7FFF]};
            bins DEBUG       = {[32'h1A10_8000 : 32'h1A11_FFFF]};
            bins OTHERS      = default;
        }

        cp_size: coverpoint size {
            bins BYTE    = {3'b000};
            bins HALF    = {3'b001};
            bins WORD    = {3'b010};
        }

        cross_addr_rw: cross cp_addr_region, cp_rw;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        axi_cg = new();
    endfunction

    function void sample(logic [31:0] a, logic [2:0] s, logic [1:0] r, bit w);
        this.addr     = a;
        this.size     = s;
        this.resp     = r;
        this.is_write = w;
        axi_cg.sample();
    endfunction

endclass

`endif
