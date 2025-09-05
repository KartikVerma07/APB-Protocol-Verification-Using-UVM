module APB_slave_design
  #(parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 5) // 2^5 = 32 words
(
  input  logic                   PCLK,
  input  logic                   PRESETn,   // active-low

  input  logic                   PSEL,
  input  logic                   PENABLE,
  input  logic [31:0]            PADDR,     // byte address
  input  logic                   PWRITE,
  input  logic [DATA_WIDTH-1:0]  PWDATA,

  output logic [DATA_WIDTH-1:0]  PRDATA,
  output logic                   PREADY
  // , output logic               PSLVERR  // (optional)
);

  // Word-aligned addressing: LSB = log2(bytes per word)
  localparam int ADDR_LSB = $clog2(DATA_WIDTH/8);  // 2 for 32b words
  localparam int DEPTH    = (1 << ADDR_WIDTH);

  // Simple 32x32 memory
  logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

  // State machine
  typedef enum logic [1:0] {IDLE, SETUP, ACCESS} state_e;
  state_e ps, ns;

  // Decode word index from byte address
  wire [ADDR_WIDTH-1:0] addr_word = PADDR[ADDR_LSB +: ADDR_WIDTH]; // // == PADDR[6:2]

  // Next-state logic
  always_comb begin
    ns = ps;
    unique case (ps)
      IDLE:   if (PSEL)        ns = SETUP;
      SETUP:                    ns = ACCESS;
      ACCESS: ns = (PSEL ? SETUP : IDLE);  // back-to-back or go idle
    endcase
  end

  // Ready: single-cycle data phase (no wait states)
  assign PREADY = (ps == ACCESS);

  // Read data: combinational in ACCESS for same-cycle availability
  always_comb begin
    PRDATA = '0;
    if ((ps == ACCESS) && !PWRITE) begin
      PRDATA = mem[addr_word];
    end
  end

  // Sequential: state & writes
  always_ff @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
      ps <= IDLE;
      // optional: clear mem with a for-loop if you want defined reset contents
    end else begin
      ps <= ns;

      // Perform the write at the ACCESS handshake
      if ((ps == ACCESS) && PSEL && PENABLE && PWRITE) begin
        mem[addr_word] <= PWDATA;
      end
    end
  end

endmodule
