`timescale 1ns/1ps
module lab4TB;
  // ------------------------- Signals -------------------------
  reg  clk;
  reg  rst;
  reg  start;


  // ------------------------- DUT -----------------------------

  top dut (
    .clk   (clk),
    .rst   (rst)
  );

  // ------------------------- Clock ---------------------------
  // 100 MHz clock
  always #5 clk = ~clk;

  // Utility: 1-clock pulse on start (like your previous labs)
  task pulse_start;
    begin
      @(negedge clk);
      start <= 1'b1;
      @(negedge clk);
      start <= 1'b0;
    end
  endtask

  // --------------------- Init & Run --------------------------
  initial begin
    clk   = 1'b0;
    rst   = 1'b1;
    start = 1'b0;

    // Hold reset for 20 ns
    #20 rst = 1'b0;

    // Kick the FSM once
    pulse_start();
  end

 
  wire [15:0] pc_value  = dut.uPC.pc_value;      
  wire [15:0] inst_word = dut.uBram.q_a;         
  wire        Ren       = dut.uFSM.Ren;          
  wire [3:0]  Rdest     = dut.uFSM.Rdest;        
  wire [15:0] alu_out   = dut.uRegALU.alu_out;   

  // ------------------- R1/R2 tracking ------------------------
  reg [15:0] R1_val;
  reg [15:0] R2_val;
  integer    wb_count;


	initial begin
	R1_val = 16'h0000;
	R2_val = 16'h0000;
	wb_count = 0;
	end


	always @(posedge clk) begin
	if (!rst) begin
	if (Ren) begin
	wb_count <= wb_count + 1;
	if (Rdest == 4'd1) R1_val <= alu_out;
	if (Rdest == 4'd2) R2_val <= alu_out;
	$display("t=%0t | WB #%0d | R%0d <= 0x%04h", $time, wb_count, Rdest, alu_out);
	end
	end
	end


	// -------------------- End condition ------------------------
	// Stop after the first 4 *distinct PC fetches*
	reg [15:0] prev_pc;
	integer instr_count;


	initial begin
	prev_pc = 16'h0000;
	instr_count = 0;
	// Safety timeout (short)
	#20000 $fatal(1, "[TB] Timeout (20 us)");
	end



	initial begin
	@(negedge rst);
	prev_pc = pc_value; // baseline
	end


	// Count on PC change events
	always @(posedge clk) begin
	if (!rst) begin
	if (pc_value !== prev_pc) begin
	instr_count <= instr_count + 1;
	prev_pc <= pc_value;
	$display("t=%0t | INSTR #%0d fetched at PC=%0d", $time, instr_count, pc_value);
	if (instr_count >= 4) begin
	@(posedge clk); // settle any writeback
	$display("================ REGISTER SNAPSHOT ================");
	$display("R1 = 0x%04h (%0d)", R1_val, R1_val);
	$display("R2 = 0x%04h (%0d)", R2_val, R2_val);
	$display("===================================================");
	$finish;
	end
	end
	end
	end


	// ---------------- Console monitor (optional) ---------------
	initial begin
	$monitor("t=%0t | rst=%b start=%b | PC=%0d | inst=0x%04h | Ren=%b Rdest=%0d | R1=0x%04h R2=0x%04h",
	$time, rst, start, pc_value, inst_word, Ren, Rdest, R1_val, R2_val);
	end


	endmodule


