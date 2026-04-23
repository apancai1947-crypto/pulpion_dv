`ifndef AXI_IF_SV
`define AXI_IF_SV

// Simplified AXI4 interface for UVM monitor probing
// Carries flat signals for one AXI port (master or slave)
interface axi_if (
    input logic clk,
    input logic rst_n
);

    // Write Address Channel
    logic [31:0] aw_addr;
    logic [ 7:0] aw_len;
    logic [ 2:0] aw_size;
    logic [ 1:0] aw_burst;
    logic [ 1:0] aw_id;
    logic        aw_valid;
    logic        aw_ready;

    // Write Data Channel
    logic [31:0] w_data;
    logic [ 3:0] w_strb;
    logic        w_valid;
    logic        w_ready;

    // Write Response Channel
    logic [ 1:0] b_resp;
    logic        b_valid;
    logic        b_ready;

    // Read Address Channel
    logic [31:0] ar_addr;
    logic [ 7:0] ar_len;
    logic [ 2:0] ar_size;
    logic [ 1:0] ar_burst;
    logic [ 1:0] ar_id;
    logic        ar_valid;
    logic        ar_ready;

    // Read Data Channel
    logic [31:0] r_data;
    logic [ 1:0] r_resp;
    logic        r_valid;
    logic        r_ready;

endinterface

`endif
