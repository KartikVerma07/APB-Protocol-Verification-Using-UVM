package APB_pkg;
  

  // Shared parameters
  parameter int DATA_W   = 32;
  parameter int ADDR_LSB = $clog2(DATA_W/8); // 2 for 32b
  parameter int DEPTH    = 32;               // 32 words in model

  
endpackage
