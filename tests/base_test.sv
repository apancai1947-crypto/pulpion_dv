`ifndef BASE_TEST_SV
`define BASE_TEST_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class base_test extends uvm_test;
    `uvm_component_utils(base_test)

    soc_env    env;
    soc_config cfg;

    function new(string name = "base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        cfg = soc_config::type_id::create("cfg");
        uvm_config_db#(soc_config)::set(this, "env", "cfg", cfg);

        env = soc_env::type_id::create("env", this);
    endfunction

    virtual function void report_phase(uvm_phase phase);
        uvm_report_server svr = uvm_report_server::get_server();
        super.report_phase(phase);
        if (svr.get_severity_count(UVM_ERROR) + svr.get_severity_count(UVM_FATAL) > 0)
            `uvm_info(get_type_name(), "========== TEST FAILED ==========", UVM_NONE)
        else
            `uvm_info(get_type_name(), "========== TEST PASSED ==========", UVM_NONE)
    endfunction

endclass

`endif
