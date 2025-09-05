class APB_r_agent extends uvm_component;
  `uvm_component_utils(APB_r_agent)

  APB_r_monitor r_mon;

  function new(string name, uvm_component parent);
   super.new(name,parent); 
  endfunction

  function void build_phase(uvm_phase phase);
    r_mon = APB_r_monitor::type_id::create("r_mon", this);
  endfunction
endclass
