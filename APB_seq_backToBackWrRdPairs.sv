// Seq 3: Consecutive write read pairs

class APB_seq_backToBackWrRdPairs extends uvm_sequence #(APB_txn);
  `uvm_object_utils(APB_seq_backToBackWrRdPairs)

  rand int unsigned num_pairs = 8;
  constraint c_num_pairs { num_pairs inside {[1:DEPTH]}; }

  rand int unsigned base_word;
  constraint c_base_word {
    base_word inside {[0 : DEPTH - num_pairs]};
  }

  function new(string name = "APB_seq_backToBackWrRdPairs");
    super.new(name);
  endfunction

  virtual task body();
    bit [31:0] data;

    if (!randomize())
      `uvm_fatal("SEQ", "Failed to randomize num_pairs/base_word")

    for (int i = 0; i < num_pairs; i++) begin
      APB_txn wr;
      APB_txn rd;
      int unsigned curr_addr;

      curr_addr = ((base_word + i) << ADDR_LSB);
      data      = $urandom();

      // WRITE
      wr = APB_txn::type_id::create($sformatf("wr_%0d", i), , get_full_name());
      start_item(wr);
        wr.write     = 1'b1;
        wr.addr_byte = curr_addr;
        wr.wdata     = data;
      finish_item(wr);

      // READ same location immediately
      rd = APB_txn::type_id::create($sformatf("rd_%0d", i), , get_full_name());
      start_item(rd);
        rd.write     = 1'b0;
        rd.addr_byte = curr_addr;
      finish_item(rd);
    end
  endtask
endclass