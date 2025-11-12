module RegALU(
    input         clk,
    input         reset,
    input         wEnable,        // global write enable
    input  [3:0]  ra_idx,         // read A index (also write destination index)
    input  [3:0]  rb_idx,         // read B index
    input  [7:0]  opcode,         // ALU opcode
    input  [15:0] immB,           // immediate value for B
    input         selB_imm,       // 1: ALU.B <- immB, 0: ALU.B <- reg
	 input  [15:0] wb_data,        //data to write back
	 input         flags_en,	    //flag enable
	 output [15:0] busA_out,		 //regbank output A dest
	 output [15:0] busB_out,		 //regbank output B src
    output [15:0] alu_out,        // ALU result (also written back)
    output [4:0]  flags           // ALU flags (current cycle)
);

	 //wire for flags from alu
	 wire [4:0] alu_flags;

    // One-hot write enable (destination = ra_idx)
    wire [15:0] regEnable = wEnable ? (16'h0001 << ra_idx) : 16'h0000;

    // Register bank (sync write, sync read)
    wire [15:0] busA, busB_reg;
	 
	 //add output wires to send to memory
	 assign busA_out = busA;
	 assign busB_out = busB_reg;
	 
    RegBank uRegBank (
        .clk       (clk),
        .reset     (reset),
        .wData     (wb_data),
        .regEnable (regEnable),
        .ra_idx    (ra_idx),
        .rb_idx    (rb_idx),
        .busA      (busA),
        .busB_reg  (busB_reg)
    );
	 
	 
	 
	 //flags
	 reg [4:0] flags_reg;
	 always @(posedge clk or posedge reset)  begin
		if (reset) flags_reg <= 5'b0;
		else if (flags_en) flags_reg <= alu_flags;
	 end
	 
	 assign flags = flags_reg;
	 

    // Select B operand (reg or immediate)
    wire [15:0] B_sel = selB_imm ? immB : busB_reg;

    // Always feed previous carry into ALU.Cin.
    // ALU will use it only for ADDC/ADDCI/ADDCU/ADDCUI opcodes internally.
    wire cin_to_alu = flags_reg[0];

    // ALU core
    ALU uALU (
        .A      (busA),
        .B      (B_sel),
        .Cin    (cin_to_alu),
        .Opcode (opcode),
        .C      (alu_out),
        .Flags  (alu_flags)
    );

endmodule