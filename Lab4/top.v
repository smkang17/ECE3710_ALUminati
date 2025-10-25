module top (
    input  wire clk,
    input  wire rst
);

    wire [15:0] PC_value;
    wire [15:0] mem_dout; // use this in IR module as an input
    wire [15:0] IR_out; // IR MODULE
    wire        PCe;        // PC enable
    wire        Ren;        // Register write enable
    wire [3:0]  Rsrc;       // Source reg index
    wire [3:0]  Rdest;      // Destination reg index
    wire        R_I;        // Reg/Imm select
    wire [7:0]  Opcode;     // ALU opcode
    wire [7:0]  Imm;        // Immediate value
    wire [15:0] alu_out;
    wire [4:0]  flags;

	 
    pc uPC (
        .clk(clk),
        .rst(rst),
        .PCe(PCe),
        .pc_value(PC_value)
    );

    Bram uBram (
        .data_a(16'h0000),    // no writeback to memory yet
        .data_b(16'h0000),
        .addr_a(PC_value),    // instruction address = PC
        .addr_b(10'b0),
        .we_a(1'b0),
        .we_b(1'b0),
        .clk(clk),
        .q_a(mem_dout),
        .q_b()                // unused
    );


    ControlFSM uFSM (
        .clk(clk),
        .rst(rst),
        .IR(IR_out),	// we need IR module
        .PCe(PCe),
        .Ren(Ren),
        .Rsrc(Rsrc),
        .Rdest(Rdest),
        .R_I(R_I),
        .Opcode(Opcode),
        .Imm(Imm)
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
        .flags(flags)
    );

endmodule
