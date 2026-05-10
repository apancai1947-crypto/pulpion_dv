`ifndef PULPINO_SPI_TEST_SV
`define PULPINO_SPI_TEST_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
`ifdef SPI_VIP_EN
import svt_spi_uvm_pkg::*;
`endif

class pulpino_spi_test extends base_test;
    `uvm_component_utils(pulpino_spi_test)

    uvm_tlm_analysis_fifo #(logic [31:0]) ref_fifo;
`ifdef SPI_VIP_EN
    uvm_tlm_analysis_fifo #(uvm_sequence_item) vip_fifo;
    uvm_tlm_analysis_fifo #(svt_spi_transaction) tx_vip_fifo;
    uvm_tlm_analysis_fifo #(svt_spi_transaction) rx_vip_fifo;
`endif

    function new(string name = "pulpino_spi_test", uvm_component parent = null);
        super.new(name, parent);
        ref_fifo = new("ref_fifo", this);
`ifdef SPI_VIP_EN
        vip_fifo = new("vip_fifo", this);
        tx_vip_fifo = new("tx_vip_fifo", this);
        rx_vip_fifo = new("rx_vip_fifo", this);
`endif
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info(get_type_name(), "SPI test build_phase complete", UVM_LOW)
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        // Connect generic data bridge to ref_fifo
        env.stdout_mon.ref_data_ap.connect(ref_fifo.analysis_export);
        
`ifdef SPI_VIP_EN
        // Connect SPI VIP monitor ports
        if (env.spi_master_agent != null) begin
            env.spi_master_agent.txrx_mon.item_observed_port.connect(vip_fifo.analysis_export);
            env.spi_master_agent.txrx_mon.tx_xact_observed_port.connect(tx_vip_fifo.analysis_export);
            env.spi_master_agent.txrx_mon.rx_xact_observed_port.connect(rx_vip_fifo.analysis_export);
        end
`endif
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this, "pulpino_spi_test started");

        fork
            // Comparison logic
            forever begin
                logic [31:0] ref_val;
`ifdef SPI_VIP_EN
                uvm_sequence_item vip_item;
                svt_spi_transaction vip_tr;
`endif
                
                // Wait for reference data from firmware
                ref_fifo.get(ref_val);
                `uvm_info("SELF_CHECK", $sformatf("Reference data received: 0x%08h", ref_val), UVM_MEDIUM)
                
`ifdef SPI_VIP_EN
                if (env.spi_master_agent != null) begin
                    `uvm_info("SELF_CHECK", "Waiting for VIP RX data (MOSI captured by Slave monitor)...", UVM_MEDIUM)

                    // In Passive Slave mode: RX direction = data sampled from MOSI
                    // TX direction = MISO (zeros, not useful here)
                    fork : wait_vip_rx
                        begin
                            rx_vip_fifo.get(vip_item);
                            `uvm_info("SELF_CHECK", "VIP RX data received", UVM_MEDIUM)
                            disable wait_vip_rx;
                        end
                        begin
                            #2ms;
                            `uvm_error("SELF_CHECK", "Timeout waiting for VIP RX data!")
                            disable wait_vip_rx;
                        end
                    join

                    if (vip_item != null) begin
                        if (!$cast(vip_tr, vip_item)) begin
                            `uvm_fatal("SELF_CHECK", "Failed to cast vip_item to svt_spi_transaction")
                        end

                        `uvm_info("SELF_CHECK", $sformatf("VIP RX transaction, data size: %0d", vip_tr.data.size()), UVM_MEDIUM)

                        if (vip_tr.data.size() > 0) begin
                            logic [31:0] vip_data = vip_tr.data[0];

                            `uvm_info("SELF_CHECK", $sformatf("VIP=0x%08h  REF=0x%08h", vip_data, ref_val), UVM_MEDIUM)

                            if (vip_data !== ref_val) begin
                                `uvm_error("SELF_CHECK", $sformatf("Mismatch! REF=0x%08h, VIP=0x%08h", ref_val, vip_data))
                            end else begin
                                `uvm_info("SELF_CHECK", $sformatf("COMPARE_PASS: 0x%08h", ref_val), UVM_LOW)
                            end
                        end else begin
                            `uvm_warning("SELF_CHECK", "VIP RX transaction has NO data!")
                        end
                    end
                end
`endif
            end
        join_none

        // Wait for EOT from memory-mapped stdout monitor
        `uvm_info(get_type_name(), "Waiting for EOT from stdout monitor...", UVM_LOW)
        env.stdout_mon.eot_event.wait_trigger();
        `uvm_info(get_type_name(), "EOT received, ending test", UVM_LOW)

        #100ns;
        phase.drop_objection(this, "pulpino_spi_test finished");
    endtask

endclass

`endif
