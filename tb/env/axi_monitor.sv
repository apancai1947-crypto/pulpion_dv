`ifndef AXI_MONITOR_SV
`define AXI_MONITOR_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class axi_monitor extends uvm_monitor;
    `uvm_component_utils(axi_monitor)

    // Virtual interface — hierarchical path to DUT AXI signals
    virtual interface axi_if vif;

    // Analysis port
    uvm_analysis_port#(axi_transaction) analysis_port;

    // Statistics
    protected int aw_count, w_count, b_count, ar_count, r_count;

    function new(string name = "axi_monitor", uvm_component parent = null);
        super.new(name, parent);
        analysis_port = new("analysis_port", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual interface axi_if)::get(this, "", "axi_vif", vif))
            `uvm_fatal("AXI_MON", "Failed to get axi_if from config_db")
    endfunction

    virtual task run_phase(uvm_phase phase);
        fork
            monitor_aw();
            monitor_ar();
        join_none
    endtask

    // Monitor Write Address channel
    virtual task monitor_aw();
        axi_transaction tx;
        forever begin
            @(posedge vif.clk);
            if (vif.rst_n && vif.aw_valid && vif.aw_ready) begin
                aw_count++;
                tx = axi_transaction::type_id::create("tx");
                tx.is_write      = 1;
                tx.aw_addr       = vif.aw_addr;
                tx.aw_len        = vif.aw_len;
                tx.aw_size       = vif.aw_size;
                tx.aw_burst      = vif.aw_burst;
                tx.aw_id         = vif.aw_id;
                tx.addr_phase_time = $time;

                // Wait for W channel data
                fork begin
                    @(posedge vif.clk);
                    while (!(vif.w_valid && vif.w_ready))
                        @(posedge vif.clk);
                    w_count++;
                    tx.w_data = vif.w_data;
                    tx.w_strb = vif.w_strb;
                    tx.data_phase_time = $time;

                    // Wait for B response
                    while (!(vif.b_valid && vif.b_ready))
                        @(posedge vif.clk);
                    b_count++;
                    tx.b_resp = vif.b_resp;

                    analysis_port.write(tx);
                    `uvm_info("AXI_MON", $sformatf("[WR #%0d] %s", aw_count, tx.convert2string()), UVM_HIGH)
                end join_none
            end
        end
    endtask

    // Monitor Read Address channel
    virtual task monitor_ar();
        axi_transaction tx;
        forever begin
            @(posedge vif.clk);
            if (vif.rst_n && vif.ar_valid && vif.ar_ready) begin
                ar_count++;
                tx = axi_transaction::type_id::create("tx");
                tx.is_write      = 0;
                tx.ar_addr       = vif.ar_addr;
                tx.ar_len        = vif.ar_len;
                tx.ar_size       = vif.ar_size;
                tx.ar_burst      = vif.ar_burst;
                tx.ar_id         = vif.ar_id;
                tx.addr_phase_time = $time;

                // Wait for R channel data
                fork begin
                    while (!(vif.r_valid && vif.r_ready))
                        @(posedge vif.clk);
                    r_count++;
                    tx.r_data = vif.r_data;
                    tx.r_resp = vif.r_resp;
                    tx.data_phase_time = $time;

                    analysis_port.write(tx);
                    `uvm_info("AXI_MON", $sformatf("[RD #%0d] %s", ar_count, tx.convert2string()), UVM_HIGH)
                end join_none
            end
        end
    endtask

    virtual function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(),
            $sformatf("\n=== AXI Monitor ===\n  AW: %0d | W: %0d | B: %0d | AR: %0d | R: %0d",
            aw_count, w_count, b_count, ar_count, r_count), UVM_LOW)
    endfunction

endclass

`endif
