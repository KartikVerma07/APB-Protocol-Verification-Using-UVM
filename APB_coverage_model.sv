
import APB_pkg::*;  // for ADDR_LSB, DEPTH

// Declare distinct analysis imps once per TB
`uvm_analysis_imp_decl(_W)
`uvm_analysis_imp_decl(_R)

class APB_coverage_model extends uvm_component;
  `uvm_component_utils(APB_coverage_model)

  // From env via config_db
  virtual APB_if vif;

  // Analysis imps: hook write/read monitors directly
  uvm_analysis_imp_W #(APB_txn, APB_coverage_model) cm_export_write;
  uvm_analysis_imp_R #(APB_txn, APB_coverage_model) cm_export_read;

  // ----------- Internal snapshot for protocol coverage -----------
  // We’ll measure PREADY wait cycles and direction at handshake completion.
  bit          dir_snap;         // 1=write, 0=read
  int unsigned latency_snap;     // cycles from ACCESS start to PREADY==1

  // ----------------- Transaction-level coverage -----------------
  // Sampled with the APB_txn item delivered by monitors
  covergroup cg_txn with function sample (APB_txn t);
    option.per_instance = 1;

    // Map byte address to *word* index for bins
    cp_addr_word: coverpoint (t.addr_byte >> ADDR_LSB) {
      bins min      = {0};
      bins max      = {DEPTH-1};
      bins middle[] = {[1: (DEPTH-2)]};         // auto-splits if DEPTH>2
      bins illegal  = {[DEPTH:$]};              // out-of-range addresses
    }

    cp_dir: coverpoint t.write { bins READ={0}; bins WRITE={1}; }

    // APB4 strobes (only meaningful on writes). If you don't use PSTRB, this
    // will still compile; the monitor should set t.strb=0 on reads.
    cp_strb: coverpoint t.strb iff (t.write) {
      bins st_8  = {4'b0001};
      bins st_16 = {4'b0011};
      bins st_24 = {4'b0111};
      bins st_32 = {4'b1111};
      bins others = default;   // catch unexpected patterns
    }

    // Data ranges written (masking is done by the sequence; we just bin ranges)
    cp_wdata: coverpoint t.wdata iff (t.write) {
      bins w_min  = {32'h0};
      bins w_max  = {32'hFFFF_FFFF};
      bins w_8    = {[32'h00000000 : 32'h000000FF]};
      bins w_16   = {[32'h00000100 : 32'h0000FFFF]};
      bins w_24   = {[32'h00010000 : 32'h00FFFFFF]};
      bins w_32   = {[32'h01000000 : 32'hFFFFFFFF]};
    }

    // Data ranges read back
    cp_rdata: coverpoint t.rdata iff (!t.write) {
      bins r_min  = {32'h0};
      bins r_max  = {32'hFFFF_FFFF};
      bins r_8    = {[32'h00000000 : 32'h000000FF]};
      bins r_16   = {[32'h00000100 : 32'h0000FFFF]};
      bins r_24   = {[32'h00010000 : 32'h00FFFFFF]};
      bins r_32   = {[32'h01000000 : 32'hFFFFFFFF]};
    }

    // Useful crosses
    x_dir_addr : cross cp_dir, cp_addr_word;   // reads & writes across map
    x_strb_dir : cross cp_strb, cp_dir;        // ensure strobes only with writes
  endgroup

  // ----------------- Protocol-level coverage -----------------
  // Sampled when a transfer *completes* (ACCESS with PREADY==1).
  covergroup cg_proto with function sample (bit dir, int unsigned lat);
    option.per_instance = 1;

    cp_dir: coverpoint dir { bins READ={0}; bins WRITE={1}; }

    // PREADY wait-state latency in ACCESS phase
    cp_latency: coverpoint lat {
      bins l0 = {0};           // no wait states
      bins l1 = {1};
      bins l2 = {2};
      bins l3_4 = {[3:4]};
      bins l5p = {[5:$]};      // long stalls
    }

    x_dir_lat: cross cp_dir, cp_latency;
  endgroup

  function new(string name="APB_coverage_model", uvm_component parent=null);
    super.new(name, parent);
    cg_txn   = new();
    cg_proto = new();
  endfunction

  // Build: get vif and create analysis imps
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual APB_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "APB_if not set for coverage model")

    cm_export_write = new("cm_export_write", this);
    cm_export_read  = new("cm_export_read",  this);
  endfunction

  // ----------------- Analysis imp callbacks -----------------
  // (We keep the standard write() unused so both W and R can map cleanly.)
  virtual function void write(APB_txn t); endfunction

  // From WRITE monitor
  virtual function void write_W(APB_txn t);
    `uvm_info("COV", "Got WRITE txn for coverage", UVM_LOW)
    cg_txn.sample(t);
  endfunction

  // From READ monitor
  virtual function void write_R(APB_txn t);
    `uvm_info("COV", "Got READ txn for coverage", UVM_LOW)
    cg_txn.sample(t);
  endfunction

  // ----------------- Protocol latency tracker -----------------
  // Count cycles from ACCESS start (PSEL=1,PENABLE=1) until PREADY==1.
  bit          in_access;
  int unsigned wait_cnt;

  task run_phase(uvm_phase phase);
    // Wait for reset deassert (active-high reset assumed)
    if (vif.PRESET !== 1'b0) @(negedge vif.PRESET);
    wait_cnt = 0;

    forever begin
      @(posedge vif.PCLK);

      // Re-check reset synchronously; clear counters if asserted
      if (vif.PRESET) begin
        wait_cnt = 0;
        continue;
      end

      // Detect SETUP (PSEL=1,PENABLE=0): next cycle is ACCESS, reset counter
      if (vif.PSEL && !vif.PENABLE)
        wait_cnt = 0;

      // ACCESS (PSEL=1,PENABLE=1): count until PREADY==1, then sample
      if (vif.PSEL && vif.PENABLE) begin
        if (!vif.PREADY) begin
          wait_cnt++;
        end
        else begin
          // Transfer completes this cycle
          cg_proto.sample(vif.PWRITE, wait_cnt);
          wait_cnt = 0;
        end
      end
    end
  endtask

endclass

