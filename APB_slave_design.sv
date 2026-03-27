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
);

  // Word-aligned addressing: LSB = log2(bytes per word)
  localparam int ADDR_LSB = $clog2(DATA_WIDTH/8);  // 2 for 32b words
  localparam int DEPTH    = (1 << ADDR_WIDTH);
  
  // Simple 32x32 memory
  logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

  logic busy;
  logic [3:0] delay_cnt;

  logic [ADDR_WIDTH-1:0] addr_q;
  logic                  write_q;
  logic [DATA_WIDTH-1:0] wdata_q;

  wire setup_phase;
  wire access_phase;
  wire transfer_done;

  assign setup_phase   = PSEL && !PENABLE;
  assign access_phase  = PSEL && PENABLE;
  assign transfer_done = access_phase && PREADY;

  always_ff @(posedge PCLK or posedge PRESET) begin
    if (PRESET) begin
      busy      <= 1'b0;
      delay_cnt <= '0;
      addr_q    <= '0;
      write_q   <= 1'b0;
      wdata_q   <= '0;
    end
    else begin
      // latch request in setup phase once
      if (setup_phase && !busy) begin
        busy      <= 1'b1;                // remember that one APB transfer has already been accepted and is still waiting to complete
        addr_q    <= PADDR[ADDR_LSB +: ADDR_WIDTH];
        write_q   <= PWRITE;
        wdata_q   <= PWDATA;
        delay_cnt <= $urandom_range(0, 3); // simulation only
      end
      else if (busy && access_phase) begin
        if (delay_cnt != 0)
          delay_cnt <= delay_cnt - 1'b1;
        else begin
          // complete transfer this cycle
          if (write_q)
            mem[addr_q] <= wdata_q;

          busy <= 1'b0;
        end
      end
    end
  end

  always_comb begin
    PRDATA = '0;
    if (access_phase && busy && (delay_cnt == 0) && !write_q)
      PRDATA = mem[addr_q];
  end

  assign PREADY = access_phase && busy && (delay_cnt == 0);

endmodule