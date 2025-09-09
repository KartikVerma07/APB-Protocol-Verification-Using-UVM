// Intent-only driver: converts apb_txn into APB handshakes.
// - Sequence items must NOT set PSEL/PENABLE; driver owns the protocol.
// - Reset is active-high (PRESET=1 asserted).
class APB_driver extends uvm_driver#(APB_txn);
  `uvm_component_utils(APB_driver)

  virtual APB_if vif;

  // Max cycles to wait for PREADY during ACCESS
  int unsigned ready_timeout = 1024;

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
    vif.PSTRB    <= '0;
  endtask

  // Perform exactly ONE APB transfer (write or read)
  task automatic drive_one_transfer(APB_txn tr);
    // ---- Local declarations at top to avoid mid-block decl parse issues ----
    int unsigned wait_cnt;
    // -----------------------------------------------------------------------

    // ---------------- SETUP phase ----------------
    @(posedge vif.PCLK);
    vif.PSEL     <= 1'b1;
    vif.PENABLE  <= 1'b0;
    vif.PWRITE   <= tr.write;
    vif.PADDR    <= tr.addr_byte;   // byte address (or word index if that's your convention)
    vif.PWDATA   <= tr.wdata;  // used only when PWRITE=1
    vif.PSTRB    <= (tr.write) ? tr.strb : '0;

    // ---------------- ACCESS phase ----------------
    @(posedge vif.PCLK);
    vif.PENABLE  <= 1'b1;

    // Wait for PREADY (slave may insert wait states)
    wait_cnt = 0;
    do begin
      @(posedge vif.PCLK);
      wait_cnt++;
      if (wait_cnt > ready_timeout) begin
        `uvm_error("APB_DRV",
          $sformatf("PREADY timeout after %0d cycles (addr=0x%08h, write=%0b)",
                    wait_cnt, tr.addr_byte, tr.write))
        break;
      end
    end while (!vif.PREADY);

    // Handshake happened this edge: sample/log now
    if (!tr.write) begin
      tr.rdata = vif.PRDATA;
      `uvm_info("APB_DRV",
        $sformatf("READ  @A=0x%08h -> RDATA=0x%08h", tr.addr_byte, tr.rdata), UVM_LOW)
    end else begin
      `uvm_info("APB_DRV",
        $sformatf("WRITE @A=0x%08h WDATA=0x%08h", tr.addr_byte, tr.wdata), UVM_LOW)
    end

    // ---------------- Complete: return to IDLE ----------------
    // Drop PENABLE *now* so the NEXT cycle is not another ACCESS.
    // If not doing back-to-back, also drop PSEL now.
    vif.PENABLE <= 1'b0;
    vif.PSEL    <= 1'b0;   // keep high here only if you plan back-to-back

    @(posedge vif.PCLK);   // one bubble (or next SETUP if you keep PSEL high)
  endtask

endclass
