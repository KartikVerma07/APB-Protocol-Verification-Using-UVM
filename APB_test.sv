// APB_test.sv
import uvm_pkg::*; 
`include "uvm_macros.svh"

class APB_test extends uvm_test;
  `uvm_component_utils(APB_test)

  // Environment
  APB_env env;

  // 3 sequences
  APB_seq_WrData_RdData         seq_wr_rd;
  APB_seq_backToBackWrThenRd    seq_b2b_wr_then_rd;
  APB_seq_backToBackWrRdPairs   seq_b2b_wr_rd_pairs;

  // Knobs
  int unsigned iterations          = 10;
  int unsigned wt_wr_rd            = 3;
  int unsigned wt_b2b_wr_then_rd   = 2;
  int unsigned wt_b2b_wr_rd_pairs  = 2;

  function new(string name="APB_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Allow overrides from TB/config_db
    void'(uvm_config_db#(int unsigned)::get(this, "", "iterations",         iterations));
    void'(uvm_config_db#(int unsigned)::get(this, "", "wt_wr_rd",           wt_wr_rd));
    void'(uvm_config_db#(int unsigned)::get(this, "", "wt_b2b_wr_then_rd",  wt_b2b_wr_then_rd));
    void'(uvm_config_db#(int unsigned)::get(this, "", "wt_b2b_wr_rd_pairs", wt_b2b_wr_rd_pairs));

    env = APB_env::type_id::create("env", this);

    // Create sequences
    seq_wr_rd           = APB_seq_WrData_RdData       ::type_id::create("seq_wr_rd");
    seq_b2b_wr_then_rd  = APB_seq_backToBackWrThenRd  ::type_id::create("seq_b2b_wr_then_rd");
    seq_b2b_wr_rd_pairs = APB_seq_backToBackWrRdPairs ::type_id::create("seq_b2b_wr_rd_pairs");
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
    `uvm_info(get_full_name(), "End of elaboration", UVM_LOW)
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    for (int i = 0; i < iterations; i++) begin
      randcase
        wt_wr_rd: begin
          `uvm_info("TEST", "Starting APB_seq_WrData_RdData", UVM_LOW)
          seq_wr_rd.start(env.W_agent.seqr);
          `uvm_info("TEST", "Done APB_seq_WrData_RdData", UVM_LOW)
        end

        wt_b2b_wr_then_rd: begin
          `uvm_info("TEST", "Starting APB_seq_backToBackWrThenRd", UVM_LOW)
          seq_b2b_wr_then_rd.start(env.W_agent.seqr);
          `uvm_info("TEST", "Done APB_seq_backToBackWrThenRd", UVM_LOW)
        end

        wt_b2b_wr_rd_pairs: begin
          `uvm_info("TEST", "Starting APB_seq_backToBackWrRdPairs", UVM_LOW)
          seq_b2b_wr_rd_pairs.start(env.W_agent.seqr);
          `uvm_info("TEST", "Done APB_seq_backToBackWrRdPairs", UVM_LOW)
        end
      endcase

      // Optional gap between iterations
      #50ns;
    end

    // Let monitor / scoreboard drain
    repeat (10) @(posedge env.W_agent.w_mon.vif.PCLK);

    phase.drop_objection(this);
  endtask
endclass