interface APB_if #(parameter DATA_W = 32) ();
  logic        PCLK;
  logic        PRESET;                 // active-high reset
  // APB signals
  logic        PSEL;
  logic        PENABLE;
  logic [31:0] PADDR;                  // byte address
  logic        PWRITE;
  logic [DATA_W-1:0] PWDATA;
  logic [DATA_W-1:0] PRDATA;
  logic        PREADY;
  logic [DATA_W/8-1:0] PSTRB;       // uncomment if you have APB4 strobes

  modport master (output PSEL, PENABLE, PADDR, PWRITE, PWDATA,
                  input  PRDATA, PREADY);
  modport slave  (input  PSEL, PENABLE, PADDR, PWRITE, PWDATA,
                  output PRDATA, PREADY);
endinterface
