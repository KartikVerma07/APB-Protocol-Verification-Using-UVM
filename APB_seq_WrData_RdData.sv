class APB_seq_WrData_RdData extends uvm_sequence#(APB_txn);
  `uvm_object_utils(APB_seq_WrData_RdData)

  function new(string name="APB_seq_WrData_RdData");
    super.new(name);
  endfunction

  virtual task body();
    APB_txn wr; 
    APB_txn rd;
    int unsigned last_addr;

    // ----------------
    // WRITE (intent only)
    // ----------------
    wr = APB_txn::type_id::create("wr", , get_full_name());

    start_item(wr);
      // Command (driver will generate PSEL/PENABLE)
      wr.write = 1'b1;

      // Randomize address/data; keep the whole thing legal & aligned
      //  - word-aligned: PADDR[ADDR_LSB-1:0] == 0 (e.g., [1:0]==0 for 32-bit)
      //  - in range:     (PADDR >> ADDR_LSB) inside [0:DEPTH-1]
      //  - data: random
      assert( wr.randomize() with {
        addr_byte[ADDR_LSB-1:0] == '0;
        (addr_byte >> ADDR_LSB) inside {[0:DEPTH-1]};
      });

      // If you support APB4 strobes, drive full-word by default
      wr.strb = 4'hF;
    finish_item(wr);

    // Keep the exact address for readback
    last_addr = wr.addr_byte;

    // ----------------
    // READ (same address)
    // ----------------
    rd = APB_txn::type_id::create("rd", , get_full_name());

    start_item(rd);
      rd.write = 1'b0;
      rd.addr_byte  = last_addr;   // read back what we just wrote
      rd.strb  = '0;          // ignored on reads
    finish_item(rd);
  endtask
endclass
