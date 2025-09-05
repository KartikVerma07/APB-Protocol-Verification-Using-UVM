// APB_test.sv
import uvm_pkg::*; `include "uvm_macros.svh"

class APB_test extends uvm_test;
  `uvm_component_utils(APB_test)

  // Environment
  APB_env env;

  // The 3 sequences I have
  APB_seq_WrData_RdData           seq_wr_rd;
  APB_seq_burstWrData_RdData      seq_burst;
  APB_seq_burstDiffWrData_RdData  seq_diff;

  // Knobs (can override via config_db or factory)
  int unsigned iterations = 10;
  int unsigned wt_wr_rd   = 3;   // weights for randcase
  int unsigned wt_burst   = 2;
  int unsigned wt_diff    = 2;

  function new(string name="APB_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Allow overrides from the testbench, if set
    void'(uvm_config_db#(int unsigned)::get(this, "", "iterations", iterations));
    void'(uvm_config_db#(int unsigned)::get(this, "", "wt_wr_rd",   wt_wr_rd));
    void'(uvm_config_db#(int unsigned)::get(this, "", "wt_burst",   wt_burst));
    void'(uvm_config_db#(int unsigned)::get(this, "", "wt_diff",    wt_diff));

    env       = APB_env::type_id::create("env", this);

    // Create the sequences (factory-friendly)
    seq_wr_rd = APB_seq_WrData_RdData          ::type_id::create("seq_wr_rd");
    seq_burst = APB_seq_burstWrData_RdData     ::type_id::create("seq_burst");
    seq_diff  = APB_seq_burstDiffWrData_RdData ::type_id::create("seq_diff");
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
    `uvm_info(get_full_name(), "End of elaboration", UVM_LOW)
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    // Driver waits for reset internally; we can start straight away.
    for (int i = 0; i < iterations; i++) begin
      randcase
        wt_wr_rd: begin
          `uvm_info("TEST", "Starting APB_seq_WrData_RdData", UVM_LOW)
          seq_wr_rd.start(env.W_agent.seqr); // or env.wagent.sqr if that's your name
          `uvm_info("TEST", "Done APB_seq_WrData_RdData", UVM_LOW)
        end
        wt_burst: begin
          `uvm_info("TEST", "Starting APB_seq_burstWrData_RdData", UVM_LOW)
          seq_burst.start(env.W_agent.seqr);
          `uvm_info("TEST", "Done APB_seq_burstWrData_RdData", UVM_LOW)
        end
        wt_diff: begin
          `uvm_info("TEST", "Starting APB_seq_burstDiffWrData_RdData", UVM_LOW)
          seq_diff.start(env.W_agent.seqr);
          `uvm_info("TEST", "Done APB_seq_burstDiffWrData_RdData", UVM_LOW)
        end
      endcase

      // Small quiesce between iterations (optional)
      #50ns;
    end

    // Drain a few clocks so monitors/scoreboard finish
    repeat (10) @(posedge env.W_agent.w_mon.vif.PCLK);

    phase.drop_objection(this);
  endtask
endclass
