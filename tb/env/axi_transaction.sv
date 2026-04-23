`ifndef AXI_TRANSACTION_SV
`define AXI_TRANSACTION_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class axi_transaction extends uvm_sequence_item;
    `uvm_object_utils(axi_transaction)

    // Address phase
    rand logic [31:0] aw_addr;
    rand logic [31:0] ar_addr;
    rand logic [ 7:0] aw_len;
    rand logic [ 7:0] ar_len;
    rand logic [ 2:0] aw_size;
    rand logic [ 2:0] ar_size;
    rand logic [ 1:0] aw_burst;
    rand logic [ 1:0] ar_burst;
    rand logic [ 1:0] aw_id;
    rand logic [ 1:0] ar_id;

    // Write data
    rand logic [31:0] w_data;
    rand logic [ 3:0] w_strb;

    // Read data
    logic [31:0] r_data;

    // Response
    logic [1:0] b_resp;
    logic [1:0] r_resp;
    logic [1:0] r_id;

    // Direction
    bit is_write;  // 1=write, 0=read

    // Timestamps
    time addr_phase_time;
    time data_phase_time;

    function new(string name = "axi_transaction");
        super.new(name);
    endfunction

    virtual function void do_copy(uvm_object rhs);
        axi_transaction rhs_;
        super.do_copy(rhs);
        if (!$cast(rhs_, rhs)) return;
        aw_addr    = rhs_.aw_addr;
        ar_addr    = rhs_.ar_addr;
        aw_len     = rhs_.aw_len;
        ar_len     = rhs_.ar_len;
        aw_size    = rhs_.aw_size;
        ar_size    = rhs_.ar_size;
        aw_burst   = rhs_.aw_burst;
        ar_burst   = rhs_.ar_burst;
        w_data     = rhs_.w_data;
        w_strb     = rhs_.w_strb;
        r_data     = rhs_.r_data;
        b_resp     = rhs_.b_resp;
        r_resp     = rhs_.r_resp;
        is_write   = rhs_.is_write;
    endfunction

    virtual function string convert2string();
        if (is_write)
            return $sformatf("AXI WR: addr=0x%08h data=0x%08h strb=%b bresp=%b",
                             aw_addr, w_data, w_strb, b_resp);
        else
            return $sformatf("AXI RD: addr=0x%08h data=0x%08h rresp=%b",
                             ar_addr, r_data, r_resp);
    endfunction

endclass

`endif
