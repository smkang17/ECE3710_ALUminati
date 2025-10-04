`timescale 1ns/1ps

module tb_fib_regalu;

  reg clk = 0;
  always #5 clk = ~clk;

  reg rst;
  wire [15:0] alu_out;
  wire [4:0]  flags;

  Fib_FSM dut (
    .clk    (clk),
    .rst    (rst),
    .alu_out(alu_out),
    .flags  (flags)
  );

  // latch the value during READ (negedge) and print it at the WRITE edge
  reg [15:0] alu_out_read;

  // sample combinational ALU result late in the READ half-cycle
  always @(negedge clk) begin
    alu_out_read <= alu_out;
  end

  integer cycles;

  initial begin
    $dumpfile("tb_fib_regalu");
    $dumpvars(0, tb_fib_regalu);

    rst = 1'b1;
    cycles = 0;
    repeat (4) @(posedge clk);
    rst = 1'b0;

    // print only when write-enable is asserted; show the value that was computed in READ
    forever begin
      @(posedge clk);
      cycles = cycles + 1;

      if (dut.wEnable) begin
        $display("%0t ns : R%0d <= %0d (0x%04h)",
                 $time, dut.ra_idx, alu_out_read, alu_out_read);
        if (dut.ra_idx == 4'd15) begin
          #10 $finish;
        end
      end

      if (cycles > 1000) begin
        $display("[TB-ERR] Timeout");
        $finish;
      end
    end
  end

endmodule
