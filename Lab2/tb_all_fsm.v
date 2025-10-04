`timescale 1ns/1ps

module tb_all_fsm;

  reg clk = 0;
  always #5 clk = ~clk;

  reg rst;
  wire [15:0] alu_out;
  wire [4:0]  flags;

  // DUT
  ALL_FSM dut (
    .clk    (clk),
    .rst    (rst),
    .alu_out(alu_out),
    .flags  (flags)
  );

  // Capture ALU result at end of READ phase
  reg [15:0] alu_out_read;
  always @(negedge clk) begin
    alu_out_read <= alu_out;
  end

  integer cycles;

  initial begin
    rst = 1'b1;
    cycles = 0;
    repeat (4) @(posedge clk);
    rst = 1'b0;

    forever begin
      @(posedge clk);
      cycles = cycles + 1;

      // Print only when a write occurs (the value computed in previous READ)
      if (dut.wEnable) begin
        $display("%0t ns : R%0d <= %0d (0x%04h)",
                 $time, dut.ra_idx, alu_out_read, alu_out_read);
      end

      // Simple timeout
      if (cycles > 1000) begin
        $display("[TB-INFO] Done/Timeout at cycle %0d", cycles);
        $finish;
      end
    end
  end

endmodule
