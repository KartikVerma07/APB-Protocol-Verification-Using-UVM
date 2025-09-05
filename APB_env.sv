class APB_env extends uvm_env;
  `uvm_component_utils(APB_env)

  APB_w_agent   W_agent; // ACTIVE
  APB_r_agent   R_agent; // PASSIVE
  APB_scoreboard sb;
  //apb_cov        cov;

  function new(string name, uvm_component parent);
   super.new(name,parent); 
  endfunction
  
  //Build Phase
  function void build_phase(uvm_phase phase);
    W_agent = APB_w_agent  ::type_id::create("W_agent", this);
    R_agent = APB_r_agent   ::type_id::create("R_agent", this);
    sb      = APB_scoreboard::type_id::create("Scoreboard", this);
    cov     = APB_coverage_model::type_id::create("Functional_Coverage_Model", this);
  endfunction

  //Connect Phase
  function void connect_phase(uvm_phase phase);
    // To Scoreboard
    W_agent.w_mon.ap_write.connect(sb.sb_export_write);
    R_agent.r_mon.ap_read .connect(sb.sb_export_read);
    `uvm_info("ENV",$sformatf("Connected Monitor to SB"),UVM_LOW)

    // To Coverage
    W_agent.w_mon.ap_write.connect(cov.cm_export_write);
    R_agent.r_mon.ap_read .connect(cov.cm_export_read);
    `uvm_info("ENV",$sformatf("Connected Monitor to CovM"),UVM_LOW)
  endfunction
endclass