`ifndef SOC_ENV_SV
`define SOC_ENV_SV

`include "uvm_pkg.sv"
`include "svt_uart_if.svi"
`include "svt_uart.uvm.pkg"

import uvm_pkg::*;
import svt_uvm_pkg::*;
import svt_uart_uvm_pkg::*;


`include "uvm_macros.svh"

class soc_env extends uvm_env;
    `uvm_component_utils(soc_env)

    soc_config cfg;

    // AXI agents — wired to probed interfaces in tb_top
    axi_agent core_master_agent;    // masters[0]: core2axi
    axi_agent periph_slave_agent;   // slaves[2]: peripherals

    // APB agent
    apb_agent apb_mon_agent;

    // UART TUBE monitor
    uart_monitor uart_mon;

    // Scoreboard
    soc_scoreboard scb;

    // UART VIP DCE agent (Synopsys SVT)
    svt_uart_agent               dce_agent;
    svt_uart_agent_configuration dce_cfg;
    svt_uart_vif                 dce_vif;

    function new(string name = "soc_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        virtual interface axi_if core_vif, periph_vif;
        virtual interface apb_if  apb_vif;

        super.build_phase(phase);

        // Config
        if (!uvm_config_db#(soc_config)::get(this, "", "cfg", cfg)) begin
            `uvm_info("ENV", "No config found, creating default", UVM_LOW)
            cfg = soc_config::type_id::create("cfg");
        end

        // Get virtual interfaces from tb_top (set before run_test)
        if (!uvm_config_db#(virtual interface axi_if)::get(this, "", "core_axi_vif", core_vif))
            `uvm_fatal("ENV", "Failed to get core_axi_vif")
        if (!uvm_config_db#(virtual interface axi_if)::get(this, "", "periph_axi_vif", periph_vif))
            `uvm_fatal("ENV", "Failed to get periph_axi_vif")
        if (!uvm_config_db#(virtual interface apb_if)::get(this, "", "apb_vif", apb_vif))
            `uvm_fatal("ENV", "Failed to get apb_vif")

        // Get UART VIP DCE virtual interface from tb_top
        if (!uvm_config_db#(svt_uart_vif)::get(this, "", "dce_vif", dce_vif))
            `uvm_fatal("ENV", "Failed to get dce_vif")

        // Pass interfaces to agents via config_db (wildcard scope so child components can find them)
        uvm_config_db#(virtual interface axi_if)::set(this, "core_master_agent.*",  "axi_vif", core_vif);
        uvm_config_db#(virtual interface axi_if)::set(this, "periph_slave_agent.*", "axi_vif", periph_vif);
        uvm_config_db#(virtual interface apb_if)::set(this, "apb_mon_agent.*",      "apb_vif", apb_vif);

        // Create AXI agents (only those with wired interfaces)
        core_master_agent  = axi_agent::type_id::create("core_master_agent", this);
        periph_slave_agent = axi_agent::type_id::create("periph_slave_agent", this);

        // Create APB agent
        apb_mon_agent = apb_agent::type_id::create("apb_mon_agent", this);

        // Create UART monitor
        uart_mon = uart_monitor::type_id::create("uart_mon", this);

        // Configure and create UART VIP DCE agent
        dce_cfg = svt_uart_agent_configuration::type_id::create("dce_cfg");
        dce_cfg.is_active = 1;
        dce_cfg.set_uart_if(dce_vif);
        dce_cfg.baud_divisor = 2;  // 25MHz/(16*2) = 781250 baud, matches PULPino UART_DIVISOR=31
        uvm_config_db#(svt_uart_agent_configuration)::set(this, "dce_agent", "cfg", dce_cfg);
        dce_agent = svt_uart_agent::type_id::create("dce_agent", this);

        // Create Scoreboard
        scb = soc_scoreboard::type_id::create("scb", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        // UART monitor → Scoreboard
        uart_mon.analysis_port.connect(scb.uart_imp);
    endfunction

    virtual function void report_phase(uvm_phase phase);
        uvm_report_server svr = uvm_report_server::get_server();
        `uvm_info(get_type_name(),
            $sformatf("=== ENV Summary ===\n  Errors: %0d | Fatals: %0d",
            svr.get_severity_count(UVM_ERROR), svr.get_severity_count(UVM_FATAL)), UVM_NONE)
    endfunction

endclass

`endif
