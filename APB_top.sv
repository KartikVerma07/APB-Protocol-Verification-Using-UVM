// APB_top.sv
`timescale 1ns/1ps
import uvm_pkg::*;

`include "APB_pkg.sv"
`include "uvm_macros.svh"
`include "APB_if.sv"
`include "APB_txn.sv"
`include "APB_sequencer.sv"
`include "APB_driver.sv"
`include "APB_wr_monitor.sv"
`include "APB_r_monitor.sv"
`include "APB_w_agent.sv"
`include "APB_r_agent.sv"
`include "APB_scoreboard.sv"
`include "APB_coverage_model.sv"
`include "APB_env.sv"

// Sequences & test
`include "APB_seq_WrData_RdData.sv"
`include "APB_seq_burstWrData_RdData.sv"
`include "APB_seq_burstDiffWrData_RdData.sv"
`include "APB_test.sv"

// DUT
`include "APB_slave_design.sv"


module APB_top;

  // Interface (no ports version; we drive clock/reset through it)
  APB_if vif();

  // ---------------- Clock ----------------
  initial begin
    vif.PCLK = 1'b0;
    forever #5 vif.PCLK = ~vif.PCLK;   // 100 MHz
  end

  // ---------------- Reset (active-high) ----------------
  initial begin
    vif.PRESET = 1'b1;                 // apply reset
    `uvm_info("APB_TOP", "RESET is applied", UVM_LOW)
    repeat (3) @(posedge vif.PCLK);
    vif.PRESET = 1'b0;                 // release reset
    `uvm_info("APB_TOP", "RESET is released", UVM_LOW)
  end

  // ---------------- DUT hookup ----------------
  // NOTE: if your DUT module name/ports differ, edit this instantiation.
  APB_slave_design dut (
    .PCLK   (vif.PCLK),
    .PRESET (vif.PRESET),   // active-high reset
    .PADDR  (vif.PADDR),
    .PWRITE (vif.PWRITE),
    .PSEL   (vif.PSEL),
    .PENABLE(vif.PENABLE),
    .PWDATA (vif.PWDATA),
    .PRDATA (vif.PRDATA),
    .PREADY (vif.PREADY)
  );

  // ---------------- UVM boot ----------------
  initial begin
    // Push virtual interface so driver/monitors can get it from the config DB
    uvm_config_db#(virtual APB_if)::set(null, "*", "vif", vif);

    // Run your consolidated test that randomly picks among the 3 sequences
    run_test("APB_test");
    $finish;
  end

endmodule
