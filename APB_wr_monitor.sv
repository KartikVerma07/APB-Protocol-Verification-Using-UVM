class APB_wr_monitor extends uvm_component;
  `uvm_component_utils(APB_wr_monitor)
  virtual APB_if vif;

  uvm_analysis_port#(APB_txn) ap_write;

  function new(string name, uvm_component parent);
    super.new(name,parent);
    ap_write = new("ap_write", this);
  endfunction

  //Build Phase
  function void build_phase(uvm_phase phase);
    if(!uvm_config_db#(virtual APB_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOV IF","APB_if not set for wr_monitor")
  endfunction

  //Run Phase
  task run_phase(uvm_phase phase);
    APB_txn t;
    wait(vif.PRESET==1'b0);
    forever begin
      @(posedge vif.PCLK);
      if (vif.PSEL && vif.PENABLE && (vif.PREADY===1'b1) && (vif.PWRITE==1'b1)) begin
        t = APB_txn::type_id::create("wr_t");
        t.write     = 1'b1;
        t.addr_byte = vif.PADDR;
        t.wdata     = vif.PWDATA;
        t.strb      = vif.PSTRB; 

        ap_write.write(t);

        `uvm_info("WrMON", $sformatf("WRITE @A=0x%08h (word=%0d) WrDATA=0x%08h",
                t.addr_byte, (t.addr_byte>>ADDR_LSB), t.wdata), UVM_LOW)
      end
    end
  endtask
endclass
