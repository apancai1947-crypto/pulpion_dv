`ifndef AXI_AGENT_SV
`define AXI_AGENT_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class axi_agent extends uvm_agent;
    `uvm_component_utils(axi_agent)

    axi_monitor monitor;
    uvm_analysis_port#(axi_transaction) analysis_port;

    function new(string name = "axi_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor = axi_monitor::type_id::create("monitor", this);
        analysis_port = new("analysis_port", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        monitor.analysis_port.connect(analysis_port);
    endfunction

endclass

`endif
