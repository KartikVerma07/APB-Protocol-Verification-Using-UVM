// Seq 1: Single write followed by readback 

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
    // Single WRITE
    // ----------------
    wr = APB_txn::type_id::create("wr", , get_full_name());

    start_item(wr);
      wr.write = 1'b1;

      assert(wr.randomize() with {
        addr_byte[ADDR_LSB-1:0] == '0;
        (addr_byte >> ADDR_LSB) inside {[0:DEPTH-1]};
      });
    finish_item(wr);

    // Save address for readback
    last_addr = wr.addr_byte;

    // ----------------
    // Single READ
    // ----------------
    rd = APB_txn::type_id::create("rd", , get_full_name());

    start_item(rd);
      rd.write     = 1'b0;
      rd.addr_byte = last_addr;
    finish_item(rd);
  endtask
endclass