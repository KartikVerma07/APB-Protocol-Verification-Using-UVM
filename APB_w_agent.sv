class APB_w_agent extends uvm_component;
  `uvm_component_utils(APB_w_agent)

  APB_sequencer  seqr;
  APB_driver     drv;
  APB_wr_monitor  w_mon;

  function new(string name, uvm_component parent);
   super.new(name,parent); 
  endfunction

  function void build_phase(uvm_phase phase);
    seqr  = APB_sequencer ::type_id::create("seqr",  this);
    drv   = APB_driver    ::type_id::create("drv",   this);
    w_mon = APB_wr_monitor ::type_id::create("w_mon", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass
