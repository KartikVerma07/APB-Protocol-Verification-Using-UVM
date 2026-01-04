import APB_pkg::*;  // for ADDR_LSB, DEPTH

`uvm_analysis_imp_decl(_W)
`uvm_analysis_imp_decl(_R)

class APB_coverage_model extends uvm_component;
  `uvm_component_utils(APB_coverage_model)

  // Analysis imps: hook write/read monitors directly
  uvm_analysis_imp_W #(APB_txn, APB_coverage_model) cm_export_write;
  uvm_analysis_imp_R #(APB_txn, APB_coverage_model) cm_export_read;

  // ----------------- Transaction-level coverage -----------------
  covergroup cg_txn with function sample (APB_txn t);
    option.per_instance = 1;

    cp_addr_word: coverpoint (t.addr_byte >> ADDR_LSB) {
      bins min      = {0};
      bins max      = {DEPTH-1};
      bins middle[] = {[1:(DEPTH-2)]};
      bins illegal  = {[DEPTH:$]};     // out-of-range
    }

    cp_dir: coverpoint t.write { bins READ={0}; bins WRITE={1}; }

    cp_wdata: coverpoint t.wdata iff (t.write) {
      bins w_min  = {32'h0};
      bins w_max  = {32'hFFFF_FFFF};
      bins w_8    = {[32'h00000000 : 32'h000000FF]};
      bins w_16   = {[32'h00000100 : 32'h0000FFFF]};
      bins w_24   = {[32'h00010000 : 32'h00FFFFFF]};
      bins w_32   = {[32'h01000000 : 32'hFFFFFFFF]};
    }

    cp_rdata: coverpoint t.rdata iff (!t.write) {
      bins r_min  = {32'h0};
      bins r_max  = {32'hFFFF_FFFF};
      bins r_8    = {[32'h00000000 : 32'h000000FF]};
      bins r_16   = {[32'h00000100 : 32'h0000FFFF]};
      bins r_24   = {[32'h00010000 : 32'h00FFFFFF]};
      bins r_32   = {[32'h01000000 : 32'hFFFFFFFF]};
    }

    x_dir_addr : cross cp_dir, cp_addr_word;
  endgroup

  function new(string name="APB_coverage_model", uvm_component parent=null);
    super.new(name, parent);
    cg_txn = new();
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    cm_export_write = new("cm_export_write", this);
    cm_export_read  = new("cm_export_read",  this);
  endfunction

  // Keep base write() unused (two distinct analysis imps)
  virtual function void write(APB_txn t); endfunction

  virtual function void write_W(APB_txn t);
    cg_txn.sample(t);
  endfunction

  virtual function void write_R(APB_txn t);
    cg_txn.sample(t);
  endfunction

endclass
