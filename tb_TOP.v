`timescale 1ns/1ps
module tb_TOP;
  reg  clk;
  reg  rst;
  reg  start;            // Button substitute
  wire [6:0] HEX0, HEX1, HEX2, HEX3;
  
  // DUT
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
    clk   = 1'b0;
    rst   = 1'b1;
    start = 1'b0;
    
    // Release reset
    #20 rst = 1'b0;
    
    // Observe step-by-step progression 
    // Press several times to see stages
    repeat (10) begin
      pulse_start();
      // Wait briefly after each step
      #20;
    end
    
    // For automatic progression use this
    // pulse_start();
    // #2000;
    
    #200 $finish;
  end
  
  // Display some internal signals via hierarchical reference: display_value/done/error, BRAM q_a, addr_a
  wire [15:0] display_value = dut.fsm_inst.display_value;
  wire        done          = dut.fsm_inst.done;
  wire        error         = dut.fsm_inst.error;
  wire [15:0] q_a           = dut.q_a;
  wire [9:0]  addr_a        = dut.addr_a;
  
  initial begin
    $monitor("t=%0t | rst=%b start=%b | addr_a=%0d | q_a=0x%04h | display=0x%04h | done=%b error=%b",
             $time, rst, start, addr_a, q_a, display_value, done, error);
  end
endmodule
