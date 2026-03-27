import APB_pkg::*;  // for ADDR_LSB, DEPTH

`uvm_analysis_imp_decl(_W)
`uvm_analysis_imp_decl(_R)

class APB_coverage_model extends uvm_component;
  `uvm_component_utils(APB_coverage_model)

  // Analysis imps: write/read monitors connect here
  uvm_analysis_imp_W #(APB_txn, APB_coverage_model) cm_export_write;
  uvm_analysis_imp_R #(APB_txn, APB_coverage_model) cm_export_read;

  // ------------------------------------------------------------
  // Transaction-level coverage
  // ------------------------------------------------------------
  covergroup cg_txn with function sample(APB_txn t);
    option.per_instance = 1;

    cp_addr_word : coverpoint int'(t.addr_byte >> ADDR_LSB) {
      bins low  = {[0 : (DEPTH/3)-1]};
      bins mid  = {[DEPTH/3 : ((2*DEPTH)/3)-1]};
      bins high = {[((2*DEPTH)/3) : DEPTH-1]};
      illegal_bins illegal = {[DEPTH:$]};
    }

    cp_dir : coverpoint t.write {
      bins READ  = {0};
      bins WRITE = {1};

      // Transition coverage for transaction ordering
      bins RR = (0 => 0);
      bins RW = (0 => 1);
      bins WR = (1 => 0);
      bins WW = (1 => 1);
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

  // Base write() unused because we use separate imps
  virtual function void write(APB_txn t);
  endfunction

  virtual function void write_W(APB_txn t);
    cg_txn.sample(t);
  endfunction

  virtual function void write_R(APB_txn t);
    cg_txn.sample(t);
  endfunction

endclass