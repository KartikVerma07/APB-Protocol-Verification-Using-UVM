class APB_r_monitor extends uvm_component;
  `uvm_component_utils(APB_r_monitor)
  virtual APB_if vif;

  uvm_analysis_port#(APB_txn) ap_read;

  function new(string name, uvm_component parent);
    super.new(name,parent);
    ap_read = new("ap_read", this);
  endfunction

  //Build Phase
  function void build_phase(uvm_phase phase);
    if(!uvm_config_db#(virtual APB_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF","APB_if not set for r_monitor")
  endfunction

  //Run Phase
  task run_phase(uvm_phase phase);
    APB_txn t;
    wait(vif.PRESET==1'b0);
    forever begin
      @(posedge vif.PCLK);
      if (vif.PSEL && vif.PENABLE && (vif.PREADY===1'b1) && (vif.PWRITE==1'b0)) begin
        t = APB_txn::type_id::create("rd_t");
        t.write     = 1'b0;
        t.addr_byte = vif.PADDR;
        t.rdata     = vif.PRDATA;
        ap_read.write(t);
        `uvm_info("RdMON",
          $sformatf("READ  @A=0x%08h (word=%0d) RdDATA=0x%08h",
                    t.addr_byte, (t.addr_byte >> ADDR_LSB), t.rdata),
          UVM_LOW)
      end
    end
  endtask
endclass
