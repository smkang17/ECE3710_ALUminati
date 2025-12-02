module TOP (
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
	 wire [1:0]  ALU_MUX_Cntl; 
	 wire        flags_en;
	 wire	[1:0]	 PCsrc;
	 wire	[15:0] branch_disp;
	 wire [15:0] bport_q;
    wire [9:0]  vga_addr;
	 wire        bport_we;
	 wire [9:0]  bport_addr;
	 wire [5:0]  ps2_status;
	 
	 
	 
	 //temp
	 wire ms;
	 assign ms = 1'b0;
	 
	 //PC logic outside of PC mux
	 wire [15:0] branch_PC;
	 wire [15:0] inc_PC;
	 assign branch_PC = PC_value + branch_disp;
	 assign inc_PC    = PC_value + 16'h0001;
	 
	 // LSCntl MUX
    reg [15:0] mem_addr;
    always @(LSCntl or PC_value or busB_out) begin
        case (LSCntl)
            1'b0:    mem_addr = PC_value;               // instruction fetch
            1'b1:    mem_addr = busB_out;               // simulated reg value
            default: mem_addr = 16'h0000;
        endcase
    end
	 
	 
	 //ALU_MUX_Cntl MUX
	 reg [15:0] wb_data;
	 always @(ALU_MUX_Cntl or alu_out or mem_dout or PC_value) begin
        case (ALU_MUX_Cntl)
            2'b00:   wb_data = alu_out;                // instruction fetch
            2'b01:   wb_data = mem_dout;               // simulated reg value
				2'b10:   wb_data = PC_value;
            default: wb_data = 16'h0000;
        endcase
    end
	 
	 // PC_mux
	 reg [15:0] PC_next;
	always @(PCsrc or branch_disp or busB_out or PC_value) begin
		case (PCsrc)
			2'b00:   PC_next = inc_PC;
			2'b01:   PC_next = branch_PC;
			2'b10:   PC_next = busB_out;
			default: PC_next = inc_PC;
		endcase
	end
	 
	 
	 
    pc uPC (
        .clk(clk),
        .rst(rst),
        .PCe(PCe),
		  .PC_in(PC_next),
        .PC_value(PC_value)
    );

    controlFSM uFSM (
        .clk(clk),
        .rst(rst),
        .inst(mem_dout),
		  .flags(flags),
        .PCe(PCe),
		  .PCsrc(PCsrc),
		  .branch_disp(branch_disp),
        .Ren(Ren),
        .Rsrc(Rsrc),
        .Rdest(Rdest),
        .R_I(R_I),
        .Opcode(Opcode),
        .Imm(Imm),
		  .mem_WE(mem_WE),
		  .LSCntl(LSCntl),
		  .ALU_MUX_Cntl(ALU_MUX_Cntl),
		  .flags_en(flags_en)
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
		  .wb_data(wb_data),
		  .flags_en(flags_en)
    );

	 
	 //b not used yet
	 Bram uBram (
        .data_a(busA_out),   	// data stored from Rsrc during store inst
        .data_b(ps2_status),		
        .addr_a(mem_addr),    // instruction address = PC
        .addr_b(bport_addr),
        .we_a(mem_WE),
        .we_b(bport_we),			// FSM controls WE
        .clk(clk),
        .q_a(mem_dout),
        .q_b(bport_q)
    );
	 
	 topVGA utopVGA (
		  .bram_q(bport_q),
		  .bram_addr(vga_addr)
	 );
	 
	 PS2 uPS2 (
		  .key_status_out(ps2_status)
	 );
	 
	 ps2_vga_mux ups2_vga_mux (
		  .mux_sel(ms),
		  .vga_addr(vga_addr),
		  .addr(bport_addr),
		  .We(bport_we)
	 );

endmodule


