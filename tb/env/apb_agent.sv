`ifndef APB_AGENT_SV
`define APB_AGENT_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class apb_agent extends uvm_agent;
    `uvm_component_utils(apb_agent)

    apb_monitor monitor;
    uvm_analysis_port#(apb_transaction) analysis_port;

    function new(string name = "apb_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor = apb_monitor::type_id::create("monitor", this);
        analysis_port = new("analysis_port", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        monitor.analysis_port.connect(analysis_port);
    endfunction

endclass

`endif
