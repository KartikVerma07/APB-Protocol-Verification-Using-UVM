class APB_driver extends uvm_driver #(APB_txn);
  `uvm_component_utils(APB_driver)

  virtual APB_if vif;

  function new(string name = "APB_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual APB_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "APB_if not set in config DB for APB_driver")
  endfunction

  task run_phase(uvm_phase phase);
    APB_txn tr;
    APB_txn next_tr;

    // Drive bus idle initially
    drive_idle();

    // Wait for reset deassert (active-high reset)
    if (vif.PRESET !== 1'b0)
      @(negedge vif.PRESET);

    @(posedge vif.PCLK);

    forever begin
      // Bootstrap the first/current transfer
      seq_item_port.get_next_item(tr);

      // Keep chaining as long as another item is immediately available
      forever begin
        drive_setup(tr);
        drive_access_and_wait(tr);
        seq_item_port.item_done();

        next_tr = null;
        seq_item_port.try_next_item(next_tr);

        if (next_tr == null) begin
          // No immediate next item: insert idle on next cycle
          @(posedge vif.PCLK);
          drive_idle();
          break;
        end

        // Back-to-back: next item becomes current item
        tr = next_tr;
      end
    end
  endtask

  // ----------------------------------------
  // Drive bus to APB IDLE
  // ----------------------------------------
  task automatic drive_idle();
    vif.PSEL    <= 1'b0;
    vif.PENABLE <= 1'b0;
    vif.PWRITE  <= 1'b0;
    vif.PADDR   <= '0;
    vif.PWDATA  <= '0;
  endtask

  // ----------------------------------------
  // Drive APB SETUP phase
  // ----------------------------------------
  task automatic drive_setup(APB_txn tr);
    @(posedge vif.PCLK);
    vif.PSEL    <= 1'b1;
    vif.PENABLE <= 1'b0;
    vif.PWRITE  <= tr.write;
    vif.PADDR   <= tr.addr_byte;
    vif.PWDATA  <= tr.wdata;
  endtask

  // ----------------------------------------
  // Drive APB ACCESS phase and wait for ready
  // ----------------------------------------
  task automatic drive_access_and_wait(APB_txn tr);
    @(posedge vif.PCLK);
    vif.PENABLE <= 1'b1;

    // Allow combinational PRDATA/PREADY to settle
    #1step;

    // Hold ACCESS phase during wait states
    while (!vif.PREADY) begin
      @(posedge vif.PCLK);
      #1step;
    end

    // Sample read data only when transfer completes
    if (!tr.write) begin
      tr.rdata = vif.PRDATA;
      `uvm_info("APB_DRV",
        $sformatf("READ  @A=0x%08h -> RDATA=0x%08h (PREADY=%0b)",
                  tr.addr_byte, tr.rdata, vif.PREADY), UVM_LOW)
    end
    else begin
      `uvm_info("APB_DRV",
        $sformatf("WRITE @A=0x%08h WDATA=0x%08h (PREADY=%0b)",
                  tr.addr_byte, tr.wdata, vif.PREADY), UVM_LOW)
    end
  endtask

endclass