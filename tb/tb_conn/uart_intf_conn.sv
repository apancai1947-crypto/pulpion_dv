    svt_uart_if        uart_dce_if(clk);

    /** Instantiate UART BFM Wrapper acting as DCE*/
    svt_uart_bfm_wrapper  #(.UV_DEVICE_TYPE(`UV_DCE)) Bfm1 (uart_dce_if);

    assign uart_dce_if.rst = (~rst_n);
    assign uart_dce_if.sout = uart_tx ;
    assign uart_rx  = uart_dce_if.sin  ;

    assign uart_dce_if.dtr  = uart_dtr  ;
    assign uart_dsr  = uart_dce_if.dsr  ;

    assign uart_cts  = uart_dce_if.rts  ;
    assign uart_dce_if.cts  = uart_rts  ;

    /** Set the DCE BFM Port Interface to factory */
    initial begin
        uvm_config_db#(virtual interface svt_uart_if)::set(uvm_root::get(), "uvm_test_top.env", "dce_vif", uart_dce_if);
    end