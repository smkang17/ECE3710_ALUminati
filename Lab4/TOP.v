module top (
    input  wire clk,
    input  wire rst
);

    wire [15:0] PC_value;
    wire [15:0] mem_dout; // use this in IR module as an input
    wire [15:0] data_dout; // Data output from memory
    wire        PCe;        // PC enable
    wire        Ren;        // Register write enable
    wire [3:0]  Rsrc;       // Source reg index
    wire [3:0]  Rdest;      // Destination reg index
    wire        R_I;        // Reg/Imm select
    wire [7:0]  Opcode;     // ALU opcode
    wire [7:0]  Imm;        // Immediate value
	 wire 		 mem_WE;		 // Memory write enable (for STORE)
    wire [15:0] alu_out;
    wire [4:0]  flags;

	 wire	[1:0]	 LSCntl; 
	 wire 		 ALU_MUX_Cntl; 

	 
    pc uPC (
        .clk(clk),
        .rst(rst),
        .PCe(PCe),
        .pc_value(PC_value)
    );

    controlFSM uFSM (
        .clk(clk),
        .rst(rst),
        .inst(mem_dout),
        .PCe(PCe),
        .Ren(Ren),
        .Rsrc(Rsrc),
        .Rdest(Rdest),
        .R_I(R_I),
        .Opcode(Opcode),
        .Imm(Imm),
		  .mem_WE(mem_WE),
		  .LSCntl(LSCntl),
		  .ALU_MUX_Cntl(ALU_MUX_Cntl)
    );

    RegALU uRegALU (
        .clk(clk),
        .reset(rst),
        .wEnable(Ren),         // from FSM
        .ra_idx(Rdest),
        .rb_idx(Rsrc),         // for now, same as source — can adjust if you have Rb field
        .opcode(Opcode),
        //.cin(1'b0),         
        .immB({8'h00, Imm}),   // zero-extend immediate
        .selB_imm(R_I),
        .alu_out(alu_result),
        .flags(flags)
    );

	 assign alu_out = alu_result;

    // LSCntl MUX
    reg [15:0] mem_addr;
    always @(*) begin
        case (LSCntl)
            2'b00: mem_addr = PC_value;               // instruction fetch
            2'b01: mem_addr = {12'b0, Rdest};         // simulated reg value
            2'b10: mem_addr = {12'b0, Rsrc};          // simulated reg value
            default: mem_addr = 16'h0000;
        endcase
    end

    // write back MUX
    wire [15:0] wb_data = (ALU_MUX_Cntl) ? data_dout : alu_out;

	 Bram uBram (
        .data_a(16'h0000),    // no writeback to memory yet
        .data_b(alu_out),		// data to store (RegB)
        .addr_a(PC_value),    // instruction address = PC
        .addr_b(mem_addr),
        .we_a(1'b0),
        .we_b(mem_WE),			// FSM controls WE
        .clk(clk),
        .q_a(mem_dout),
        .q_b(data_dout)
    );

endmodule
