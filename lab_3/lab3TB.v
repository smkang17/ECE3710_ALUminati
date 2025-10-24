`timescale 1ns/1ps
module lab3TB;
  reg  clk;
  reg  rst;
  reg  start;            
  wire [6:0] HEX0, HEX1, HEX2, HEX3;
  
  // DUT instantiation
  TOP dut (
    .clk   (clk),
    .rst   (rst),
    .start (start),
    .HEX0  (HEX0),
    .HEX1  (HEX1),
    .HEX2  (HEX2),
    .HEX3  (HEX3)
  );
  
  // 100 MHz clock 
  always #5 clk = ~clk;
  
  // Utility: 1-clock pulse on start
  task pulse_start;
    begin
      @(negedge clk);
      start <= 1'b1;
      @(negedge clk);
      start <= 1'b0;
    end
  endtask
  
  // Initialization & Scenario
  initial begin
    // Init signals
    clk   = 1'b0;
    rst   = 1'b1;
    start = 1'b0;
    
    // Hold reset for 20 ns
    #20 rst = 1'b0;
    
    // One start pulse to kick off FSM
    pulse_start();
    
    // Let FSM run for enough cycles to complete (safe margin)
    #500;
    
    $finish;
  end
  
  // Hierarchical monitoring (for debug visibility)
  wire [15:0] display_value = dut.fsm_inst.display_value;
  wire        done          = dut.fsm_inst.done;
  wire        error         = dut.fsm_inst.error;
  wire [15:0] q_a           = dut.q_a;
  wire [9:0]  addr_a        = dut.addr_a;
  wire [15:0] q_b   = dut.q_b;
  wire [9:0]  addr_b= dut.addr_b;
  
  // Print important signals to the console
  initial begin
    $monitor("t=%0t | rst=%b start=%b | addr_a=%0d | q_a=0x%04h | addr_b=%0d | q_b=0x%04h | display=0x%04h | done=%b error=%b",
             $time, rst, start, addr_a, q_a, addr_b, q_b, display_value, done, error);
  end
endmodule