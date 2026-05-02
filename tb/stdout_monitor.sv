`ifndef STDOUT_MONITOR_SV
`define STDOUT_MONITOR_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

// tb/stdout_monitor.sv — UVM monitor for memory-mapped stdout
// Monitors APB bus for writes to STDOUT_REG, parses strings,
// and triggers UVM events for EVENT: prefixed messages

class stdout_monitor extends uvm_monitor;
    `uvm_component_utils(stdout_monitor)

    // Virtual interface to APB bus
    virtual apb_if vif;

    // Analysis port for scoreboard
    uvm_analysis_port #(string) info_ap;
    uvm_analysis_port #(string) event_ap;

    // String accumulation buffer
    string stdout_str;

    function new(string name = "stdout_monitor", uvm_component parent = null);
        super.new(name, parent);
        info_ap = new("info_ap", this);
        event_ap = new("event_ap", this);
        stdout_str = "";
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual apb_if)::get(this, "", "apb_vif", vif))
            `uvm_fatal("STDOUT_MON", "Failed to get APB virtual interface")
    endfunction

    virtual task run_phase(uvm_phase phase);
        // Clear buffer on reset deassertion
        fork
            forever begin
                @(negedge vif.rst_n);
                stdout_str = "";
                `uvm_info("STDOUT_MON", "Reset detected, clearing stdout buffer", UVM_HIGH)
            end
        join_none

        forever begin
            @(posedge vif.clk);
            // Monitor for writes to STDOUT_ADDR (0x1A118000)
            if (vif.rst_n && vif.psel && vif.penable && vif.pready && vif.pwrite &&
                vif.paddr == 32'h1A118000) begin
                if (vif.pwdata == 32'h00000000) begin
                    // Null word - string complete, parse it
                    parse_stdout_string(stdout_str);
                    stdout_str = "";
                end else begin
                    // Unpack 4 characters from 32-bit word (little-endian)
                    stdout_str = {stdout_str,
                                  string'(vif.pwdata[7:0]),
                                  string'(vif.pwdata[15:8]),
                                  string'(vif.pwdata[23:16]),
                                  string'(vif.pwdata[31:24])};
                end
            end
        end
    endtask

    // Parse complete string to determine if it's an event or info
    function void parse_stdout_string(input string str);
        int found;
        string content;
        uvm_event event_h;

        // Skip empty strings (e.g. consecutive null words)
        if (str.len() == 0) return;

        // Check for "EVENT:" prefix
        found = str.find("EVENT:");
        if (found == 0) begin
            if (str.len() > 6)
                content = str.substr(6, str.len() - 1);
            else
                content = "";
            `uvm_info("STDOUT", $sformatf("EVENT triggered: %s", content), UVM_LOW)

            // Get UVM event from event pool and trigger it
            event_h = uvm_event_pool::get_global(content);
            event_h.trigger();

            // Write to analysis port
            event_ap.write(content);
            return;
        end

        // Check for "INFO:" prefix
        found = str.find("INFO:");
        if (found == 0) begin
            if (str.len() > 5)
                content = str.substr(5, str.len() - 1);
            else
                content = "";
            `uvm_info("STDOUT", $sformatf("INFO: %s", content), UVM_LOW)

            // Write to analysis port
            info_ap.write(content);
            return;
        end

        // Unknown format - report error
        `uvm_error("STDOUT", $sformatf("Unknown stdout format: %s", str))
    endfunction

endclass

`endif
