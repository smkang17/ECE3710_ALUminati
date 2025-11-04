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
  wire [3:0]  Rsrc      = dut.uFSM.Rsrc;
  wire [7:0]  Opcode    = dut.uFSM.Opcode;
  wire [15:0] alu_out   = dut.uRegALU.alu_out;
  wire [7:0]  Imm       = dut.uFSM.Imm;


  // ------------------- R1/R2 tracking ------------------------
  reg [15:0] R1_val;
  reg [15:0] R2_val;
  wire [15:0] wb_data = (dut.uFSM.state == 3'b101) ? dut.uBram.q_b : alu_out;
  integer    wb_count;


	initial begin
	R1_val = 16'h0000;
	R2_val = 16'h0000;
	wb_count = 0;
	end

	// Improved for LOAD
	always @(posedge clk) begin
	if (!rst) begin
	if (Ren) begin
		wb_count <= wb_count + 1;
		if (Rdest == 4'd1) R1_val <= wb_data;
		if (Rdest == 4'd2) R2_val <= wb_data;
		$display("t=%0t | WB #%0d | R%0d <= 0x%04h", $time, wb_count, Rdest, wb_data);
	end
	end
	end

	
	
  // -------------------- State-change logger ------------------
  // Prints once per state entry (uses your controlFSM encoding: 000=FETCH, 001=DECODE, 010=EXECUTE)
//	reg [2:0] prev_state;
//	initial prev_state = 3'bxxx;
//
//	 always @(posedge clk) begin
//	   if (!rst) begin
//		  if (dut.uFSM.state !== prev_state) begin
//		 	prev_state <= dut.uFSM.state;
//		 	case (dut.uFSM.state)
//			  3'b000: $display("t=%0t | STATE -> FETCH",   $time);
//			  3'b001: $display("t=%0t | STATE -> DECODE",  $time);
//			  3'b010: $display("t=%0t | STATE -> EXECUTE", $time);
//			  3'b011: $display("t=%0t | STATE -> STORE",   $time);
//			  3'b100: $display("t=%0t | STATE -> LOAD",    $time);
//			  3'b101: $display("t=%0t | STATE -> DOUT",    $time);
//			  default: $display("t=%0t | STATE -> %b",     $time, dut.uFSM.state);
//			endcase
//		  end
//	   end
//	 end
  
  

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
	//$display("t=%0t | INSTR #%0d fetched at PC=%0d", $time, instr_count, pc_value);
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
	$monitor("t=%0t | rst=%b start=%b | PC=%0d | inst=0x%04h | Ren=%b Rdest=%0d Rsrc=%0d Opcode=%0b Imm=%0h | R1=0x%04h R2=0x%04h",
	$time, rst, start, pc_value, inst_word, Ren, Rdest, Rsrc, Opcode, Imm, R1_val, R2_val);
	end


	endmodule

