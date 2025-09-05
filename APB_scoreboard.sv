`uvm_analysis_imp_decl(_wr)
`uvm_analysis_imp_decl(_rd)

class APB_scoreboard extends uvm_component;
  `uvm_component_utils(APB_scoreboard)

  uvm_analysis_imp_wr#(APB_txn, APB_scoreboard) sb_export_write;
  uvm_analysis_imp_rd#(APB_txn, APB_scoreboard) sb_export_read;

  bit [DATA_W-1:0] model[int unsigned]; // word-indexed ref model

  function new(string name, uvm_component parent);
    super.new(name,parent);
    sb_export_write = new("sb_export_write", this);
    sb_export_read  = new("sb_export_read",  this);
  endfunction

  function int unsigned word_index(bit [31:0] addr_byte);
    return addr_byte >> ADDR_LSB;
  endfunction

  // from W_monitor
  function void write_wr(APB_txn t);
    model[word_index(t.addr_byte)] = t.wdata;
    `uvm_info("SB-W", $sformatf("W @%0d <= 0x%08h", word_index(t.addr_byte), t.wdata), UVM_MEDIUM)
  endfunction

  // from R_monitor
  function void write_rd(APB_txn t);
    int unsigned w = word_index(t.addr_byte);
    bit [DATA_W-1:0] exp = model.exists(w) ? model[w] : '0;
    if (t.rdata !== exp)
      `uvm_error("SB-R", $sformatf("R @%0d got 0x%08h exp 0x%08h", w, t.rdata, exp))
    else
      `uvm_info("SB-R", $sformatf("R @%0d == 0x%08h (OK)", w, t.rdata), UVM_LOW)
  endfunction
endclass
