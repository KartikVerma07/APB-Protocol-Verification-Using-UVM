// Intent-only driver: converts apb_txn into APB handshakes.
// - Sequence items must NOT set PSEL/PENABLE; driver owns the protocol.
// - Reset is active-high (PRESET=1 asserted).
class APB_driver extends uvm_driver#(APB_txn);
  `uvm_component_utils(APB_driver)

  virtual APB_if vif;

  function new(string name="APB_driver", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual APB_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "APB_if not set in config DB for APB_driver")
  endfunction

  task run_phase(uvm_phase phase);
    APB_txn tr;

    // Hold bus in IDLE and wait for reset deassert (active-high reset)
    drive_idle();
    if (vif.PRESET !== 1'b0) @(negedge vif.PRESET);
    @(posedge vif.PCLK);

    forever begin
      seq_item_port.get_next_item(tr);
      drive_one_transfer(tr);
      seq_item_port.item_done();
    end
  endtask

  // Keep the bus quiescent (IDLE state)
  task automatic drive_idle();
    vif.PSEL     <= 1'b0;
    vif.PENABLE  <= 1'b0;
    vif.PWRITE   <= 1'b0;
    vif.PADDR    <= '0;
    vif.PWDATA   <= '0;
  endtask

 task automatic drive_one_transfer(APB_txn tr);
  // ---------------- SETUP phase ----------------
  @(posedge vif.PCLK);
  vif.PSEL     <= 1'b1;
  vif.PENABLE  <= 1'b0;
  vif.PWRITE   <= tr.write;
  vif.PADDR    <= tr.addr_byte;
  vif.PWDATA   <= tr.wdata;

  // ---------------- ACCESS phase ----------------
  @(posedge vif.PCLK);
  vif.PENABLE  <= 1'b1;

  // Let combinational PREADY/PRDATA settle after NBA updates
  #1step;

  // Wait for completion (covers wait states too)
  while (!vif.PREADY) begin
    @(posedge vif.PCLK);
    #1step;
  end

  // Sample read data ONLY when transfer completed
  if (!tr.write) begin
    tr.rdata = vif.PRDATA;
    `uvm_info("APB_DRV",
      $sformatf("READ  @A=0x%08h -> RDATA=0x%08h (PREADY=%0b)",
                tr.addr_byte, tr.rdata, vif.PREADY), UVM_LOW)
  end else begin
    `uvm_info("APB_DRV",
      $sformatf("WRITE @A=0x%08h WDATA=0x%08h (PREADY=%0b)",
                tr.addr_byte, tr.wdata, vif.PREADY), UVM_LOW)
  end

  // IMPORTANT: end the transfer on the NEXT clock edge
  @(posedge vif.PCLK);
  vif.PSEL    <= 1'b0;
  vif.PENABLE <= 1'b0;

endtask

endclass
