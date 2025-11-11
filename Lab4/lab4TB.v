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

 
  wire [15:0] PC_value  = dut.uPC.PC_value;      
  wire [15:0] inst_word = dut.uBram.q_a;         
  wire        Ren       = dut.uFSM.Ren;          
  wire [3:0]  Rdest     = dut.uFSM.Rdest;
  wire [3:0]  Rsrc      = dut.uFSM.Rsrc;
  wire [7:0]  Opcode    = dut.uFSM.Opcode;
  wire [15:0] alu_out   = dut.uRegALU.alu_out;
  wire [7:0]  Imm       = dut.uFSM.Imm;
  wire [15:0] mem_dout  = dut.mem_dout;
  wire [9:0]  addr_a    = dut.uBram.addr_a;
  wire [15:0] InstR     = dut.uFSM.inst_reg;
  wire [15:0] R0_val    = dut.uRegALU.uRegBank.reg_data[0];
  wire [15:0] R1_val    = dut.uRegALU.uRegBank.reg_data[1];
  wire [15:0] R2_val    = dut.uRegALU.uRegBank.reg_data[2];
  wire [15:0] R3_val    = dut.uRegALU.uRegBank.reg_data[3];
  wire [3:0] state      = dut.uFSM.state;
  wire [15:0] wb        = dut.uRegALU.wb_data;



  wire [15:0] wb_data = (dut.uFSM.state == 3'b101) ? dut.uBram.q_b : alu_out;
  integer    wb_count;

  
	// Improved for LOAD
	/*
	always @(posedge clk) begin
		if (!rst) begin
			if (Ren) begin
				wb_count <= wb_count + 1;

				$display("t=%0t | WB #%0d | R%0d <= 0x%04h", $time, wb_count, Rdest, wb_data);
			end
		end
	end
	*/
  
  
  
  
  
		// tb instruction print
		always @(posedge clk) begin
		  if (!rst) begin
			 // ALU / I-type writeback
			 if (state == 3'b010) begin
				$display("R/I   EXECUTED | PC=%0d  IR=0x%04h | R0=0x%04h R1=0x%04h R2=0x%04h R3=0x%04h",
							PC_value, InstR, R0_val, R1_val, R2_val, R3_val);
			 end

			 // LOAD writeback
			 if (state == 3'b101) begin
				$display("LOAD  EXECUTED | PC=%0d  IR=0x%04h | R0=0x%04h R1=0x%04h R2=0x%04h R3=0x%04h",
							PC_value, InstR, R0_val, R1_val, R2_val, R3_val);
			 end

			 // STORE (memory side-effect)
			 if (state == 3'b011) begin
				$display("STORE EXECUTED | PC=%0d  IR=0x%04h | R0=0x%04h R1=0x%04h R2=0x%04h R3=0x%04h",
							PC_value, InstR, R0_val, R1_val, R2_val, R3_val);
			 end
		  end
		end
  

	// -------------------- End condition ------------------------
	// Stop after the first x *distinct PC fetches*
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
	prev_pc = PC_value; // baseline
	end



	// Count on PC change events
	always @(posedge clk) begin
		if (!rst) begin
			if (PC_value !== prev_pc) begin
			instr_count <= instr_count + 1;
			prev_pc <= PC_value;
			//$display("t=%0t | INSTR #%0d fetched at PC=%0d", $time, instr_count, pc_value);
				if (instr_count == 15) begin
					@(posedge clk); // settle any writeback
					$display("================ REGISTER SNAPSHOT ================");
					$display("R0 = 0x%04h (%0d)", R0_val, R0_val);
					$display("R1 = 0x%04h (%0d)", R1_val, R1_val);
					$display("R2 = 0x%04h (%0d)", R2_val, R2_val);
					$display("R3 = 0x%04h (%0d)", R3_val, R3_val);
					$display("===================================================");
					$finish;
				end
			end
		end
	end


	// ---------------- Console monitor --------------- // old test bnech
	/*
	initial begin
	$monitor("t=%0t | rst=%b start=%b | PC=%0d | memdout=0x%04h | IR=0x%04h | Ren=%b Rdest=%0d Rsrc=%0d Opcode=%0b Imm=%0h | R0=0x%04h R1=0x%04h R2=0x%04h R3=0x%04h",
	$time, rst, start, addr_a, mem_dout, InstR, Ren, Rdest, Rsrc, Opcode, Imm, R0_val, R1_val, R2_val, R3_val);
	end
	*/

	endmodule
