module APB_slave_design
  #(parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 5) // 2^5 = 32 words
(
  input  logic                   PCLK,
  input  logic                   PRESET, 

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
  localparam int unsigned INIT_WAIT = 2;
  // Wait-state counter (how long we hold PREADY=0 in ACCESS)
  int unsigned wait_cnt;

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
      SETUP:                   ns = ACCESS;
      ACCESS: if (PREADY)      ns = (PSEL ? SETUP : IDLE);  // back-to-back or go idle
              else             ns = ACCESS;
    endcase
  end

  // Read data: combinational in ACCESS for same-cycle availability
  always_comb begin
    PRDATA = '0;
    if (PSEL && PENABLE && !PWRITE) begin
      PRDATA = mem[addr_word];
    end
  end

  // Sequential: state & writes
  always_ff @(posedge PCLK or posedge PRESET) begin
  if (PRESET) begin
    ps       <= IDLE;
    wait_cnt <= INIT_WAIT;
  end else begin
    ps <= ns;

    // Preload when entering SETUP (one cycle before ACCESS)
    if (ns == SETUP && PSEL) // we need to set the wait cnt to default value
      wait_cnt <= INIT_WAIT;
    
    // Decrement only during a *real* ACCESS cycle
    else if (ps == ACCESS && PSEL && PENABLE && wait_cnt != 0)
      wait_cnt <= wait_cnt - 1;

    // Perform write exactly on ACCESS handshake
    if (ps == ACCESS && PSEL && PENABLE && (wait_cnt == 0) && PWRITE)
      mem[addr_word] <= PWDATA;
  end
end
// READY is asserted only in ACCESS when wait_cnt == 0
  assign PREADY = PSEL && PENABLE && ((!PWRITE) || (wait_cnt == 0));

endmodule
