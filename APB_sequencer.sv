class APB_sequencer extends uvm_sequencer#(APB_txn);

  `uvm_component_utils(APB_sequencer)

  function new(string name, uvm_component parent); 
    super.new(name,parent); 
  endfunction
  
endclass
