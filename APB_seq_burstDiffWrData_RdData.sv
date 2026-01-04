//Back-to-back writes followed by reads.

class APB_seq_burstDiffWrData_RdData extends uvm_sequence#(APB_txn);
  `uvm_object_utils(APB_seq_burstDiffWrData_RdData)

  // How many transfers in the burst (writes then reads back)
  rand int unsigned burst_len = 8;
  constraint c_len { burst_len inside {[1:64]}; }  // tune as you like

  // Choose a base word index so the whole burst stays in range
  rand int unsigned base_word;
  constraint c_base {
    base_word inside {[0 : DEPTH-burst_len]}; 
    //base_word + (burst_len - 1) ≤ DEPTH - 1
  }

  // pick data sizes from this set (in bits)
  static const int sizes[$] = '{8,16,24,32};

  function new(string name="APB_seq_burstDiffWrData_RdData");
    super.new(name);
  endfunction

  virtual task body();
    bit [31:0] data;
    bit [31:0] mask;
    
    // -------- WRITES: back-to-back intent with varying data widths ----------
    for (int i = 0; i < burst_len; i++) begin
      APB_txn wr = APB_txn::type_id::create($sformatf("wr_%0d", i), , get_full_name());
      int unsigned sz_bits = sizes[$urandom_range(0, sizes.size()-1)];

      // Random data, masked to sz_bits so successive writes differ in value/width
      data = $urandom();
      mask = (sz_bits == 32) ? 32'hFFFF_FFFF : ((32'h1 << sz_bits) - 1);
      data &= mask;

      // Drive intent only; driver will convert to SETUP/ACCESS and wait PREADY
      start_item(wr);
      wr.write     = 1;
      wr.addr_byte = ( (base_word + i) << ADDR_LSB ); // byte address
      wr.wdata     = data;
      finish_item(wr);
    end

    // -------- READBACK: same addresses, confirm latest values ----------
    for (int i = 0; i < burst_len; i++) begin
      APB_txn rd = APB_txn::type_id::create($sformatf("rd_%0d", i), , get_full_name());
      start_item(rd);
      rd.write     = 0;
      rd.addr_byte = ( (base_word + i) << ADDR_LSB );
      finish_item(rd);
    end
  endtask
endclass