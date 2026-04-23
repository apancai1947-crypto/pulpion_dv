`ifndef BASE_SEQ_SV
`define BASE_SEQ_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class base_seq extends uvm_sequence #(uvm_sequence_item);
    `uvm_object_utils(base_seq)

    function new(string name = "base_seq");
        super.new(name);
    endfunction

    virtual task body();
        `uvm_info(get_type_name(), "Base sequence body — override in subclass", UVM_LOW)
    endtask
endclass

`endif
