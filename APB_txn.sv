import APB_pkg::*;

class APB_txn extends uvm_sequence_item;
  rand bit        write;       // 1=write, 0=read
  rand bit [31:0] addr_byte;   // byte address
  rand bit [31:0] wdata;
  rand bit [3:0]  strb;        // APB4: byte strobes (write only)
       bit [31:0] rdata;

  `uvm_object_utils_begin(APB_txn)
    `uvm_field_int(write,     UVM_ALL_ON)
    `uvm_field_int(addr_byte, UVM_ALL_ON)
    `uvm_field_int(wdata,     UVM_ALL_ON)
    `uvm_field_int(strb,      UVM_ALL_ON)
    `uvm_field_int(rdata,     UVM_ALL_ON | UVM_NOPRINT)  //suppresses printing of rdata in print() to keep logs tidy
  `uvm_object_utils_end

  constraint c_align { addr_byte[ADDR_LSB-1:0] == '0; }                 // word aligned
  constraint c_range { (addr_byte >> ADDR_LSB) inside {[0:DEPTH-1]}; }  //Keep random addresses within your slave’s memory depth.
                                                                        //Convert the byte address addr_byte into a word index by shifting right by ADDR_LSB 
                                                                        //(i.e., divide by bytes/word), then constrain that index to [0, DEPTH-1]
  constraint c_strb  { if (write) strb != 4'b0000; else strb == 4'h0; } // APB4: no strobes on read  

  function new(string name="APB_txn");
   super.new(name); 
  endfunction

  function string convert2string();
    return $sformatf("{%s A=0x%08h (word=%0d) WDATA=0x%08h STRB=%0h RDATA=0x%08h}",
      write ? "WR" : "RD",
      addr_byte, (addr_byte>>ADDR_LSB), wdata, strb, rdata);
  endfunction
endclass
