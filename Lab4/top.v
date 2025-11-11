module top (
    input  wire clk,
    input  wire rst
);

    wire [15:0] PC_value;
    wire [15:0] mem_dout;   // use this in IR module as an input
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
	 wire [15:0] busA_out;   
	 wire [15:0] busB_out;
	 wire	    	 LSCntl; 
	 wire 		 ALU_MUX_Cntl; 
	 
	 wire	[1:0]	 PCsrc;
	 wire	[15:0] branch_disp;
	 
	 // LSCntl MUX
    reg [15:0] mem_addr;
    always @(LSCntl or PC_value or busB_out) begin
        case (LSCntl)
            1'b0: mem_addr = PC_value;               // instruction fetch
            1'b1: mem_addr = busB_out;               // simulated reg value
            default: mem_addr = 16'h0000;
        endcase
    end
	 
	 
	 //ALU_MUX_Cntl MUX
	 reg [15:0] wb_data;
	 always @(ALU_MUX_Cntl or alu_out or mem_dout) begin
        case (ALU_MUX_Cntl)
            1'b0: wb_data = alu_out;               // instruction fetch
            1'b1: wb_data = mem_dout;               // simulated reg value
            default: wb_data = 16'h0000;
        endcase
    end
	 
	 
	 
    pc uPC (
        .clk(clk),
        .rst(rst),
        .PCe(PCe),
		  .PCsrc(PCsrc),
		  .branch_disp(branch_disp),
		  .Rtarget(busB_out),
        .pc_value(PC_value)
    );

    controlFSM uFSM (
        .clk(clk),
        .rst(rst),
        .inst(mem_dout),
		  .flags(flags)
        .PCe(PCe),
		  .PCsrc(Pcsrc),
		  .branch_disp(branch_disp),
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
        .alu_out(alu_out),
        .flags(flags),
		  .busA_out(busA_out),
		  .busB_out(busB_out),
		  .wb_data(wb_data)
    );

	 
	 //b not used yet
	 Bram uBram (
        .data_a(busA_out),   	// data stored from Rsrc during store inst
        .data_b(16'h0000),		
        .addr_a(mem_addr),    // instruction address = PC
        .addr_b(1'b0),
        .we_a(mem_WE),
        .we_b(1'b0),			// FSM controls WE
        .clk(clk),
        .q_a(mem_dout),
        .q_b()
    );

endmodule
