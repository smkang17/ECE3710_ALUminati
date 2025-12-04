//=========================================================
// CPU_Control
// - CPU core control + memory interface (BRAM port A)
// - No PS2, no BRAM instantiation inside
// - ps2_data is forwarded into RegALU, which exposes it as R15
//=========================================================
module CPU_Control (
    input  wire        clk,
    input  wire        rst,

    // New PS2 data input (mapped as "virtual" register R15)
    input  wire [15:0] ps2_data,

    // External memory interface (BRAM port A)
    output reg  [15:0] mem_addr,   // Memory address (PC or load/store)
    output wire [15:0] mem_din,    // Data to write to memory
    input  wire [15:0] mem_dout,   // Data read from memory
    output wire        mem_WE      // Memory write enable
);

    //=====================================================
    // Internal CPU wires
    //=====================================================
    wire [15:0] PC_value;
    wire        PCe;               // PC enable
    wire        Ren;               // Register write enable
    wire [3:0]  Rsrc;              // Source register index
    wire [3:0]  Rdest;             // Destination register index
    wire        R_I;               // Reg/Imm select
    wire [7:0]  Opcode;            // ALU opcode
    wire [7:0]  Imm;               // Immediate value
    wire [15:0] alu_out;
    wire [4:0]  flags;
    wire [15:0] busA_out;
    wire [15:0] busB_out;
    wire        LSCntl;            // Load/Store control (0: PC, 1: data addr)
    wire [1:0]  ALU_MUX_Cntl;      // Write-back mux control
    wire        flags_en;

    wire [1:0]  PCsrc;             // PC source select
    wire [15:0] branch_disp;       // Branch displacement

    //=====================================================
    // PC next value logic
    //=====================================================
    wire [15:0] branch_PC = PC_value + branch_disp;
    wire [15:0] inc_PC    = PC_value + 16'h0001;

    reg  [15:0] PC_next;

    always @(*) begin
        case (PCsrc)
            2'b00:   PC_next = inc_PC;       // PC + 1
            2'b01:   PC_next = branch_PC;    // PC + displacement
            2'b10:   PC_next = busB_out;     // Jump to register value
            default: PC_next = inc_PC;
        endcase
    end

    //=====================================================
    // Memory address mux (instruction fetch vs data access)
    //=====================================================
    always @(*) begin
        case (LSCntl)
            1'b0:    mem_addr = PC_value;    // Instruction fetch
            1'b1:    mem_addr = busB_out;    // Load/Store address
            default: mem_addr = 16'h0000;
        endcase
    end

    //=====================================================
    // Write-back data mux (ALU / memory / PC)
    //=====================================================
    reg [15:0] wb_data;

    always @(*) begin
        case (ALU_MUX_Cntl)
            2'b00:   wb_data = alu_out;      // ALU result
            2'b01:   wb_data = mem_dout;     // Loaded from memory
            2'b10:   wb_data = PC_value;     // Save PC (e.g. for call/ret)
            default: wb_data = 16'h0000;
        endcase
    end

    //=====================================================
    // Program Counter
    //=====================================================
    pc uPC (
        .clk      (clk),
        .rst      (rst),
        .PCe      (PCe),
        .PC_in    (PC_next),
        .PC_value (PC_value)
    );

    //=====================================================
    // Control FSM (decodes instruction from memory)
    //  NOTE: inst = mem_dout here; if you move instructions
    //        to a dedicated ROM, change this wiring accordingly.
//=====================================================
    controlFSM uFSM (
        .clk          (clk),
        .rst          (rst),
        .inst         (mem_dout),    // Instruction from memory
        .flags        (flags),
        .PCe          (PCe),
        .PCsrc        (PCsrc),
        .branch_disp  (branch_disp),
        .Ren          (Ren),
        .Rsrc         (Rsrc),
        .Rdest        (Rdest),
        .R_I          (R_I),
        .Opcode       (Opcode),
        .Imm          (Imm),
        .mem_WE       (mem_WE),
        .LSCntl       (LSCntl),
        .ALU_MUX_Cntl (ALU_MUX_Cntl),
        .flags_en     (flags_en)
    );

    //=====================================================
    // Register file + ALU
    //  - ps2_data is injected as "virtual" R15 inside RegALU
    //=====================================================
    RegALU uRegALU (
        .clk       (clk),
        .reset     (rst),
        .wEnable   (Ren),
        .ra_idx    (Rdest),
        .rb_idx    (Rsrc),
        .opcode    (Opcode),
        .immB      ({8'h00, Imm}),   // Zero-extended immediate
        .selB_imm  (R_I),
        .wb_data   (wb_data),
        .flags_en  (flags_en),
        .busA_out  (busA_out),
        .busB_out  (busB_out),
        .alu_out   (alu_out),
        .flags     (flags),

        .ps2_data  (ps2_data)       // ★ NEW: PS2 into RegALU
    );

    //=====================================================
    // Memory write data (STORE)
    //=====================================================
    assign mem_din = busA_out;     // Data written on STORE

endmodule
