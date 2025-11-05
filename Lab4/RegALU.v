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
	 output [15:0] busA_out,		 //regbank output A dest
	 output [15:0] busB_out,		 //regbank output B src
    output [15:0] alu_out,        // ALU result (also written back)
    output [4:0]  flags           // ALU flags (current cycle)
);

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

    // Previous flags (latched each cycle) — used as carry-in source
    reg [4:0] prev_flags;
    always @(posedge clk or posedge reset) begin
        if (reset) prev_flags <= 5'b0;
        else       prev_flags <= flags;  // capture ALU flags from prior cycle
    end

    // Select B operand (reg or immediate)
    wire [15:0] B_sel = selB_imm ? immB : busB_reg;

    // Always feed previous carry into ALU.Cin.
    // ALU will use it only for ADDC/ADDCI/ADDCU/ADDCUI opcodes internally.
    wire cin_to_alu = prev_flags[0];

    // ALU core
    ALU uALU (
        .A      (busA),
        .B      (B_sel),
        .Cin    (cin_to_alu),
        .Opcode (opcode),
        .C      (alu_out),
        .Flags  (flags)
    );

endmodule