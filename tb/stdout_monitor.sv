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

    // EOT event — triggered when end-of-test character (0x04) is received
    uvm_event eot_event;

    function new(string name = "stdout_monitor", uvm_component parent = null);
        super.new(name, parent);
        info_ap = new("info_ap", this);
        event_ap = new("event_ap", this);
        stdout_str = "";
        eot_event = new("eot_event");
        `uvm_info("STDOUT_MON", "stdout_monitor created", UVM_LOW)
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual apb_if)::get(this, "", "apb_vif", vif))
            `uvm_fatal("STDOUT_MON", "Failed to get APB virtual interface")
    endfunction

    virtual task run_phase(uvm_phase phase);
        byte unsigned b;

        // Clear buffer on reset assertion
        fork
            forever begin
                @(negedge vif.rst_n);
                stdout_str = "";
                `uvm_info("STDOUT_MON", "Reset detected, clearing stdout buffer", UVM_HIGH)
            end
        join_none

        forever begin
            @(posedge vif.clk);
            // Monitor for writes to STDOUT_ADDR (0x1A111000, Debug Bus range)
            if (vif.rst_n && vif.psel && vif.penable && vif.pready && vif.pwrite &&
                vif.paddr == 32'h1A111000 && !$isunknown(vif.pwdata)) begin
                if (vif.pwdata == 32'h00000000) begin
                    // Null word - string complete, parse it
                    if (stdout_str.len() > 0)
                        parse_stdout_string(stdout_str);
                    stdout_str = "";
                end else begin
                    // Unpack 4 characters from 32-bit word (big-endian)
                    // Skip null bytes (padding) and detect EOT
                    for (int i = 3; i >= 0; i--) begin
                        b = (vif.pwdata >> (i * 8)) & 8'hFF;
                        if (b == 8'h04) begin
                            // EOT (0x04) detected
                            // Flush any accumulated string first
                            if (stdout_str.len() > 0)
                                parse_stdout_string(stdout_str);
                            stdout_str = "";
                            `uvm_info("STDOUT", "EOT detected via memory-mapped stdout", UVM_LOW)
                            eot_event.trigger();
                            break;
                        end else if (b != 0) begin
                            stdout_str = {stdout_str, string'(b)};
                        end
                    end
                end
            end
        end
    endtask

    // Parse complete string to determine if it's an event or info
    function void parse_stdout_string(input string str);
        string content;
        uvm_event event_h;
        bit is_event;
        bit is_info;

        // Skip empty strings (e.g. consecutive null words)
        if (str.len() == 0) return;

        // Check for "EVENT:" prefix (manual comparison for VCS compatibility)
        is_event = (str.len() >= 6) &&
                   (str[0] == "E") && (str[1] == "V") && (str[2] == "E") &&
                   (str[3] == "N") && (str[4] == "T") && (str[5] == ":");

        if (is_event) begin
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

        // Check for "INFO:" prefix (manual comparison for VCS compatibility)
        is_info = (str.len() >= 5) &&
                  (str[0] == "I") && (str[1] == "N") && (str[2] == "F") &&
                  (str[3] == "O") && (str[4] == ":");

        if (is_info) begin
            if (str.len() > 5)
                content = str.substr(5, str.len() - 1);
            else
                content = "";
            `uvm_info("STDOUT", $sformatf("INFO: %s", content), UVM_LOW)

            // Write to analysis port
            info_ap.write(content);
            return;
        end

        // Unknown format - report as info (not error, since firmware may send
        // raw strings without prefix)
        `uvm_info("STDOUT", $sformatf("RAW: %s", str), UVM_LOW)
    endfunction

endclass

`endif
