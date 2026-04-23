`ifndef APB_IF_SV
`define APB_IF_SV

// APB interface for UVM monitor probing
interface apb_if (
    input logic clk,
    input logic rst_n
);

    logic [31:0] paddr;
    logic [31:0] pwdata;
    logic [31:0] prdata;
    logic        pwrite;
    logic        psel;
    logic        penable;
    logic        pready;
    logic        pslverr;

endinterface

`endif
