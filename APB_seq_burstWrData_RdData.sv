

class APB_seq_burstWrData_RdData extends uvm_sequence#(APB_txn);
  `uvm_object_utils(APB_seq_burstWrData_RdData)

  // You can tweak these or set via config_db if desired.
  int unsigned WRITE_BURST_LENGTH = 5;
  int unsigned READ_BURST_LENGTH  = 5;

  function new(string name="APB_seq_burstWrData_RdData");
    super.new(name);
  endfunction

  virtual task body();
    int unsigned max_len  = (WRITE_BURST_LENGTH > READ_BURST_LENGTH)
                            ? WRITE_BURST_LENGTH : READ_BURST_LENGTH;

    // Choose a starting *word* index so the whole burst fits in 0..DEPTH-1
    int unsigned base_word = (DEPTH > max_len) ? $urandom_range(0, DEPTH - max_len) : 0;
    int unsigned base_addr_byte = base_word << ADDR_LSB;  // convert to byte address

    // -----------------------------
    // Write burst (consecutive words)
    // -----------------------------
    for (int i = 0; i < WRITE_BURST_LENGTH; i++) begin
      APB_txn wr = APB_txn::type_id::create($sformatf("wr_%0d", i), , get_full_name());

      start_item(wr);
        wr.write = 1'b1;
        // Each step is one word => shift by ADDR_LSB (e.g., +4 for 32-bit words)
        wr.addr_byte  = base_addr_byte + (i << ADDR_LSB);
        wr.wdata = $urandom();
        // APB4 full-word write; if your bus is APB3, field is ignored by driver/monitor
        wr.strb  = 4'hF;
      finish_item(wr);
    end

    // -----------------------------
    // Read back the same locations
    // -----------------------------
    for (int i = 0; i < READ_BURST_LENGTH; i++) begin
      APB_txn rd = APB_txn::type_id::create($sformatf("rd_%0d", i), , get_full_name());

      start_item(rd);
        rd.write = 1'b0;
        rd.addr_byte  = base_addr_byte + (i << ADDR_LSB);
        rd.strb  = '0;  // ignored for reads
      finish_item(rd);
    end
  endtask
endclass