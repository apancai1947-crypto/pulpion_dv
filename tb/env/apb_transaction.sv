`ifndef APB_TRANSACTION_SV
`define APB_TRANSACTION_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class apb_transaction extends uvm_sequence_item;
    `uvm_object_utils(apb_transaction)

    logic [31:0] paddr;
    logic [31:0] pwdata;
    logic [31:0] prdata;
    logic        pwrite;  // 1=write, 0=read
    logic        pslverr;

    // Timestamps
    time transfer_time;

    function new(string name = "apb_transaction");
        super.new(name);
    endfunction

    virtual function void do_copy(uvm_object rhs);
        apb_transaction rhs_;
        super.do_copy(rhs);
        if (!$cast(rhs_, rhs)) return;
        paddr      = rhs_.paddr;
        pwdata     = rhs_.pwdata;
        prdata     = rhs_.prdata;
        pwrite     = rhs_.pwrite;
        pslverr    = rhs_.pslverr;
    endfunction

    virtual function string convert2string();
        if (pwrite)
            return $sformatf("APB WR: addr=0x%08h data=0x%08h slverr=%b",
                             paddr, pwdata, pslverr);
        else
            return $sformatf("APB RD: addr=0x%08h data=0x%08h slverr=%b",
                             paddr, prdata, pslverr);
    endfunction

endclass

`endif
