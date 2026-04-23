`ifndef APB_MONITOR_SV
`define APB_MONITOR_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class apb_monitor extends uvm_monitor;
    `uvm_component_utils(apb_monitor)

    virtual interface apb_if vif;
    uvm_analysis_port#(apb_transaction) analysis_port;

    protected int transfer_count;

    function new(string name = "apb_monitor", uvm_component parent = null);
        super.new(name, parent);
        analysis_port = new("analysis_port", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual interface apb_if)::get(this, "", "apb_vif", vif))
            `uvm_fatal("APB_MON", "Failed to get apb_if from config_db")
    endfunction

    virtual task run_phase(uvm_phase phase);
        apb_transaction tx;
        `uvm_info(get_type_name(), "APB Monitor started", UVM_LOW)
        forever begin
            @(posedge vif.clk);
            if (vif.rst_n && vif.psel && vif.penable && vif.pready) begin
                transfer_count++;
                tx = apb_transaction::type_id::create("tx");
                tx.paddr       = vif.paddr;
                tx.pwrite      = vif.pwrite;
                tx.pslverr     = vif.pslverr;
                tx.transfer_time = $time;
                if (vif.pwrite)
                    tx.pwdata = vif.pwdata;
                else
                    tx.prdata = vif.prdata;

                analysis_port.write(tx);
                `uvm_info("APB_MON", $sformatf("[#%0d] %s", transfer_count, tx.convert2string()), UVM_HIGH)
            end
        end
    endtask

    virtual function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(),
            $sformatf("\n=== APB Monitor ===\n  Transfers: %0d", transfer_count), UVM_LOW)
    endfunction

endclass

`endif
