// Seq 2: Consecutive writes followed by consecutive reads

class APB_seq_backToBackWrThenRd extends uvm_sequence#(APB_txn);
  `uvm_object_utils(APB_seq_backToBackWrThenRd)

  // You can tweak these or set via config_db if desired.
  int unsigned NUM_WRITES = 5;
  int unsigned NUM_READS  = 5;

  function new(string name="APB_seq_backToBackWrThenRd");
    super.new(name);
  endfunction

  virtual task body();
    int unsigned max_len;
    int unsigned base_word;
    int unsigned base_addr_byte;

    max_len = (NUM_WRITES > NUM_READS) ? NUM_WRITES : NUM_READS;

    // Choose a starting word index so the whole access range stays in bounds
    base_word      = (DEPTH > max_len) ? $urandom_range(0, DEPTH - max_len) : 0;
    base_addr_byte = (base_word << ADDR_LSB);

    // ---------------------------------
    // Consecutive WRITES (back-to-back)
    // ---------------------------------
    for (int i = 0; i < NUM_WRITES; i++) begin
      APB_txn wr;
      wr = APB_txn::type_id::create($sformatf("wr_%0d", i), , get_full_name());

      start_item(wr);
        wr.write     = 1'b1;
        wr.addr_byte = base_addr_byte + (i << ADDR_LSB);
        wr.wdata     = $urandom();
      finish_item(wr);
    end

    // ---------------------------------
    // Consecutive READS from same range
    // ---------------------------------
    for (int i = 0; i < NUM_READS; i++) begin
      APB_txn rd;
      rd = APB_txn::type_id::create($sformatf("rd_%0d", i), , get_full_name());

      start_item(rd);
        rd.write     = 1'b0;
        rd.addr_byte = base_addr_byte + (i << ADDR_LSB);
      finish_item(rd);
    end
  endtask
endclass