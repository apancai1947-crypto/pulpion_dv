`ifndef SOC_SCOREBOARD_SV
`define SOC_SCOREBOARD_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class soc_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(soc_scoreboard)

    uvm_analysis_imp#(logic [7:0], soc_scoreboard) uart_imp;

    protected string line_buf = "";
    protected int char_count = 0;
    protected int line_count = 0;
    protected int pass_count = 0;
    protected int fail_count = 0;

    function new(string name = "soc_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        uart_imp = new("uart_imp", this);
    endfunction

    virtual function void write(logic [7:0] c);
        char_count++;

        if (c == 8'h04) begin // EOT
            if (line_buf != "") process_line();
            `uvm_info("SB", "EOT detected in scoreboard.", UVM_LOW)
            return;
        end

        if (c == 8'h0A || c == 8'h0D) begin
            if (line_buf != "") process_line();
        end else begin
            line_buf = {line_buf, string'(c)};
        end
    endfunction

    protected function void process_line();
        line_count++;
        `uvm_info("SB", $sformatf("[LINE #%0d] %s", line_count, line_buf), UVM_LOW)

        if (contains(line_buf, "TEST PASSED"))
            pass_count++;
        else if (contains(line_buf, "TEST FAILED"))
            fail_count++;
        else if (contains(line_buf, "FATAL"))
            `uvm_fatal("SB_TUBE", line_buf)
        else if (contains(line_buf, "UVM_ERROR"))
            `uvm_error("SB_TUBE", line_buf)

        line_buf = "";
    endfunction

    // Simple substring search
    protected function bit contains(string haystack, string needle);
        int hlen = haystack.len();
        int nlen = needle.len();
        if (hlen < nlen) return 0;
        for (int i = 0; i <= hlen - nlen; i++)
            if (haystack.substr(i, i + nlen - 1) == needle) return 1;
        return 0;
    endfunction

    virtual function void report_phase(uvm_phase phase);
        uvm_report_server svr = uvm_report_server::get_server();
        `uvm_info(get_type_name(),
            $sformatf("\n=== Scoreboard Summary ===\n  Chars: %0d | Lines: %0d | PASS: %0d | FAIL: %0d\n  UVM Errors: %0d | UVM Fatals: %0d",
            char_count, line_count, pass_count, fail_count,
            svr.get_severity_count(UVM_ERROR), svr.get_severity_count(UVM_FATAL)), UVM_NONE)

        if (fail_count > 0 || svr.get_severity_count(UVM_ERROR) > 0 || svr.get_severity_count(UVM_FATAL) > 0)
            `uvm_info(get_type_name(), "========== TEST FAILED ==========", UVM_NONE)
        else if (pass_count > 0)
            `uvm_info(get_type_name(), "========== TEST PASSED ==========", UVM_NONE)
        else
            `uvm_info(get_type_name(), "========== TEST COMPLETE (no explicit pass/fail) ==========", UVM_NONE)
    endfunction

endclass

`endif
