module ALU(
    A, B, C, Cin, Opcode, Flags,
    //seven_seg3, seven_seg2, seven_seg1, seven_seg0
);

input [15:0] A, B;         // 16 bits A = Dest, B = source
input [7:0] Opcode;
output reg [15:0] C;       // 16 bits
output reg [4:0] Flags;    // 5 flags
//output reg [6:0] seven_seg3;
//output reg [6:0] seven_seg2;
//output reg [6:0] seven_seg1;
//output reg [6:0] seven_seg0;

input Cin;


// Opcodes
parameter ADD    = 8'b00000101;
parameter ADDI   = 8'b0101xxxx;
parameter ADDU   = 8'b00000110;
parameter ADDUI  = 8'b0110xxxx;
parameter ADDC   = 8'b00000111;
parameter ADDCU  = 8'b00001000; //not in ISA
parameter ADDCUI = 8'b1101xxxx; //replaced 'MOVI' in ISA
parameter ADDCI  = 8'b0111xxxx;
parameter SUB    = 8'b00001001;
parameter SUBI   = 8'b1001xxxx;
parameter CMP    = 8'b00001011;
parameter CMPI   = 8'b1011xxxx;
parameter CMPU   = 8'b00001111; //not in ISA
parameter CMPUI  = 8'b1110xxxx; //replaced 'MULI' in ISA
parameter AND    = 8'b00000001;
parameter ANDI   = 8'b0001xxxx; 
parameter OR     = 8'b00000010;
parameter XOR    = 8'b00000011;
parameter NOT    = 8'b00000100; //not in ISA
parameter LSH    = 8'b10000100;
parameter LSHI   = 8'b1000000x;
parameter RSH    = 8'b10001100; //not in ISA
parameter RSHI   = 8'b1000100x; //not in ISA
parameter ALSH   = 8'b10000010; //not in ISA
parameter ARSH   = 8'b10000011; //not in ISA
parameter NOP    = 8'b00000000;

/* FLAGS (bit):
   [4]: Negative
   [3]: Z (zero)
   [2]: Flag
   [1]: Low
   [0]: Carry
*/

always @(A,B,Opcode, Cin) begin

	 C = 16'h0000;
	 Flags = 5'b0;
	 
    casex (Opcode)
	 
        ADD: begin
            {Flags[0], C} = A + B;
            if (C == 16'h0000) Flags[3] = 1'h1;
            else Flags[3] = 1'h0;
            if ((~A[15] & ~B[15] & C[15]) | (A[15] & B[15] & ~C[15]))
                Flags[2] = 1'h1;
            else
                Flags[2] = 1'h0;
            Flags[4] = C[15];
            Flags[1] = 1'h0;
        end

        ADDI: begin
            {Flags[0], C} = A + B;
            if (C == 16'h0000) Flags[3] = 1'h1;
            else Flags[3] = 1'h0;
            if ((~A[15] & ~B[15] & C[15]) | (A[15] & B[15] & ~C[15]))
                Flags[2] = 1'h1;
            else
                Flags[2] = 1'h0;
            Flags[4] = C[15];
            Flags[1:0] = 2'h0;
        end

        ADDU: begin
            {Flags[0], C} = A + B;
            if (C == 16'h0000) Flags[3] = 1'h1;
            else Flags[3] = 1'h0;
            Flags[4] = 1'h0;
            Flags[2:1] = 2'h0;
        end

        ADDUI: begin
            {Flags[0], C} = A + B;
            if (C == 16'h0000) Flags[3] = 1'h1;
            else Flags[3] = 1'h0;
            Flags[4] = 1'h0;
            Flags[2:1] = 2'h0;
        end

        ADDC: begin
            {Flags[0], C} = A + B + Cin;
            if (C == 16'h0000) Flags[3] = 1'h1;
            else Flags[3] = 1'h0;
            if ((~A[15] & ~B[15] & C[15]) | (A[15] & B[15] & ~C[15]))
                Flags[2] = 1'h1;
            else
                Flags[2] = 1'h0;
            Flags[4] = C[15];
            Flags[1:0] = 2'h0;
        end

        ADDCU: begin
            {Flags[0], C} = A + B + Cin;
            if (C == 16'h0000) Flags[3] = 1'h1;
            else Flags[3] = 1'h0;
            Flags[4] = 1'h0;
            Flags[2:1] = 2'h0;
        end

        ADDCUI: begin
            {Flags[0], C} = A + B + Cin;
            Flags[3] = (C == 16'b0);
            Flags[4] = C[15];
            Flags[2:1] = 2'b00;
        end

        ADDCI: begin
            {Flags[0], C} = A + B + Cin;
            Flags[3] = (C == 16'b0);
            Flags[4] = C[15];
            if ((A[15] == B[15]) && (A[15] != C[15]))
                Flags[2] = 1'b1;
            else
                Flags[2] = 1'b0;
            Flags[1] = 1'b0;
        end

        SUB: begin
            C = A - B;
            Flags[3] = (C == 16'b0);
            Flags[4] = C[15];
            if ((A[15] != B[15]) && (C[15] != A[15]))
                Flags[2] = 1'b1;
            else
                Flags[2] = 1'b0;
            Flags[1] = (A < B);
            Flags[0] = (A >= B);
        end

        SUBI: begin
            C = A - B;
            Flags[3] = (C == 16'b0);
            Flags[4] = C[15];
            if ((A[15] != B[15]) && (C[15] != A[15]))
                Flags[2] = 1'b1;
            else
                Flags[2] = 1'b0;
            Flags[1] = (A < B);
            Flags[0] = (A >= B);
        end

		  CMP: begin
		 	 Flags[3] = (A == B);                 // Z
			 Flags[1] = (A < B);                  // L (unsigned borrow)
			 Flags[4] = Flags[1] ^ (A[15] ^ B[15]); // N = L ^ (signA ^ signB)

			 C = 16'b0;                           // no write-back result
		  end

		  CMPI: begin
		 	 Flags[3] = (A == B);                 
			 Flags[1] = (A < B);                  
			 Flags[4] = Flags[1] ^ (A[15] ^ B[15]); 

			 C = 16'b0;                           
		  end

		  CMPU: begin
		 	 Flags[3] = (A == B);                 
			 Flags[1] = (A < B);                  
			 Flags[4] = Flags[1] ^ (A[15] ^ B[15]); 

			 C = 16'b0;                           
		  end

		  CMPUI: begin
		 	 Flags[3] = (A == B);                 
			 Flags[1] = (A < B);                  
			 Flags[4] = Flags[1] ^ (A[15] ^ B[15]);

			 C = 16'b0;                         
		  end

        AND: begin
            C = A & B;
            Flags[4] = C[15];
            Flags[3] = (C == 16'h0000);
            Flags[2] = 1'b0;
            Flags[1] = 1'b0;
            Flags[0] = 1'b0;
        end
		  
		  		  
		  ANDI: begin
	         C = A & B;
            Flags[4] = C[15];
            Flags[3] = (C == 16'h0000);
            Flags[2] = 1'b0;
            Flags[1] = 1'b0;
            Flags[0] = 1'b0;
		  end

        OR: begin
            C = A | B;
            Flags[4] = C[15];
            Flags[3] = (C == 16'h0000);
            Flags[2] = 1'b0;
            Flags[1] = 1'b0;
            Flags[0] = 1'b0;
        end

        XOR: begin
            C = A ^ B;
            Flags[4] = C[15];
            Flags[3] = (C == 16'h0000);
            Flags[2] = 1'b0;
            Flags[1] = 1'b0;
            Flags[0] = 1'b0;
        end

        NOT: begin
            C = ~A;
            Flags[4] = C[15];
            Flags[3] = (C == 16'h0000);
            Flags[2] = 1'b0;
            Flags[1] = 1'b0;
            Flags[0] = 1'b0;
        end

        LSH: begin
            C = A << B[4:0];
            Flags[4] = 1'b0;
            Flags[3] = (C == 16'h0000);
            Flags[2] = 1'b0;
            Flags[1] = 1'b0;
            Flags[0] = 1'b0;
        end

        LSHI: begin
            C = A << B[4:0];
            Flags[4] = 1'b0;
            Flags[3] = (C == 16'h0000);
            Flags[2] = 1'b0;
            Flags[1] = 1'b0;
            Flags[0] = 1'b0;
        end

        RSH: begin
            C = A >> B[4:0];
            Flags[4] = 1'b0;
            Flags[3] = (C == 16'h0000);
            Flags[2] = 1'b0;
            Flags[1] = 1'b0;
            Flags[0] = 1'b0;
        end

        RSHI: begin
            C = A >> B[4:0];
            Flags[4] = 1'b0;
            Flags[3] = (C == 16'h0000);
            Flags[2] = 1'b0;
            Flags[1] = 1'b0;
            Flags[0] = 1'b0;
        end

        ALSH: begin
            C = A << B[4:0];
            Flags[4] = C[15];
            Flags[3] = (C == 16'h0000);
            Flags[2] = 1'b0;
            Flags[1] = 1'b0;
            Flags[0] = 1'b0;
        end

        ARSH: begin
            C = $signed(A) >>> B[4:0];
            Flags[4] = C[15];
            Flags[3] = (C == 16'h0000);
            Flags[2] = 1'b0;
            Flags[1] = 1'b0;
            Flags[0] = 1'b0;
        end

        NOP: begin
            C = A;
            Flags = 5'b00000;
        end

    endcase
end

/*
function [6:0] hex7seg_ah;
    input [3:0] n;
    begin
        case (n)
            4'b0000: hex7seg_ah = 7'b0111111;
            4'b0001: hex7seg_ah = 7'b0000110;
            4'b0010: hex7seg_ah = 7'b1011011;
            4'b0011: hex7seg_ah = 7'b1001111;
            4'b0100: hex7seg_ah = 7'b1100110;
            4'b0101: hex7seg_ah = 7'b1101101;
            4'b0110: hex7seg_ah = 7'b1111101;
            4'b0111: hex7seg_ah = 7'b0000111;
            4'b1000: hex7seg_ah = 7'b1111111;
            4'b1001: hex7seg_ah = 7'b1100111;
            4'b1010: hex7seg_ah = 7'b1110111; // A
            4'b1011: hex7seg_ah = 7'b1111100; // b
            4'b1100: hex7seg_ah = 7'b0111001; // C
            4'b1101: hex7seg_ah = 7'b1011110; // d
            4'b1110: hex7seg_ah = 7'b1111001; // E
            4'b1111: hex7seg_ah = 7'b1110001; // F
            default: hex7seg_ah = 7'b0000000;
        endcase
    end
endfunction

wire [3:0] bcd4 = C[15:12];
wire [3:0] bcd3 = C[11:8];
wire [3:0] bcd2 = C[7:4];
wire [3:0] bcd1 = C[3:0];

always @(*) begin
    seven_seg3 = ~hex7seg_ah(bcd4);
    seven_seg2 = ~hex7seg_ah(bcd3);
    seven_seg1 = ~hex7seg_ah(bcd2);
    seven_seg0 = ~hex7seg_ah(bcd1);
end
*/
endmodule


module Register(
    input  [15:0] D_in,
    input         wEnable,
    input         reset,
    input         clk,
    output reg [15:0] r
);
    always @(posedge clk) begin
        if (reset)        r <= 16'h0000;
        else if (wEnable) r <= D_in;
    end
endmodule




module RegBank(
    input         clk,
    input         reset,
    input  [15:0] wData,         
    input  [15:0] regEnable,     
    input  [3:0]  ra_idx,        
    input  [3:0]  rb_idx,        
    output reg [15:0] busA,
    output reg [15:0] busB_reg
);
    wire [15:0] reg_data [0:15];

    genvar i;
    generate
        for (i=0; i<16; i=i+1) begin : GEN_REG
            Register u_reg (
                .D_in    (wData),
                .wEnable (regEnable[i]),
                .reset   (reset),
                .clk     (clk),
                .r       (reg_data[i])
            );
        end
    endgenerate

    always @(ra_idx, rb_idx, reset) begin
        if (reset) begin
            busA     = 16'h0000;
            busB_reg = 16'h0000;
        end else begin
            case (ra_idx)
                4'd0:  busA = reg_data[0];
                4'd1:  busA = reg_data[1];
                4'd2:  busA = reg_data[2];
                4'd3:  busA = reg_data[3];
                4'd4:  busA = reg_data[4];
                4'd5:  busA = reg_data[5];
                4'd6:  busA = reg_data[6];
                4'd7:  busA = reg_data[7];
                4'd8:  busA = reg_data[8];
                4'd9:  busA = reg_data[9];
                4'd10: busA = reg_data[10];
                4'd11: busA = reg_data[11];
                4'd12: busA = reg_data[12];
                4'd13: busA = reg_data[13];
                4'd14: busA = reg_data[14];
                4'd15: busA = reg_data[15];
                default: busA = 16'h0000;
            endcase

            case (rb_idx)
                4'd0:  busB_reg = reg_data[0];
                4'd1:  busB_reg = reg_data[1];
                4'd2:  busB_reg = reg_data[2];
                4'd3:  busB_reg = reg_data[3];
                4'd4:  busB_reg = reg_data[4];
                4'd5:  busB_reg = reg_data[5];
                4'd6:  busB_reg = reg_data[6];
                4'd7:  busB_reg = reg_data[7];
                4'd8:  busB_reg = reg_data[8];
                4'd9:  busB_reg = reg_data[9];
                4'd10: busB_reg = reg_data[10];
                4'd11: busB_reg = reg_data[11];
                4'd12: busB_reg = reg_data[12];
                4'd13: busB_reg = reg_data[13];
                4'd14: busB_reg = reg_data[14];
                4'd15: busB_reg = reg_data[15];
                default: busB_reg = 16'h0000;
            endcase
        end
    end
endmodule


module mux(
  input  [15:0] in0,
  input  [15:0] in1,
  input         sel,
  output [15:0] out
);
  assign out = sel ? in1 : in0;
endmodule




module RegALU(
    input         clk,
    input         reset,
    input         wEnable,        // global write enable
    input  [3:0]  ra_idx,         // read A index (also write destination index)
    input  [3:0]  rb_idx,         // read B index
    input  [7:0]  opcode,         // ALU opcode
    input  [15:0] immB,           // immediate value for B
    input         selB_imm,       // 1: ALU.B <- immB, 0: ALU.B <- reg
    input  [15:0] wb_data,        // data to write back
    input         flags_en,       // flag enable

    // Outputs to rest of CPU
    output [15:0] busA_out,       // A-operand (may be PS2 if ra_idx==15)
    output [15:0] busB_out,       // B-operand (may be PS2 if rb_idx==15)
    output [15:0] alu_out,        // ALU result
    output [4:0]  flags,          // Latched ALU flags

    // NEW: PS2 data, exposed as "virtual" register R15
    input  [15:0] ps2_data
);

    //=====================================================
    // Register bank
    //=====================================================
    wire [15:0] busA_reg;
    wire [15:0] busB_reg;

    // One-hot write enable (destination = ra_idx)
    wire [15:0] regEnable = wEnable ? (16'h0001 << ra_idx) : 16'h0000;

    RegBank uRegBank (
        .clk       (clk),
        .reset     (reset),
        .wData     (wb_data),
        .regEnable (regEnable),
        .ra_idx    (ra_idx),
        .rb_idx    (rb_idx),
        .busA      (busA_reg),
        .busB_reg  (busB_reg)
    );

    //=====================================================
    // PS2 as "virtual R15"
    //  - If ra_idx == 15, busA_out sees ps2_data
    //  - If rb_idx == 15, busB_out / ALU.B sees ps2_data
    //  - We NEVER write ps2_data into the physical registers
    //=====================================================
    wire [15:0] busA_eff = (ra_idx == 4'd15) ? ps2_data : busA_reg;
    wire [15:0] busB_eff = (rb_idx == 4'd15) ? ps2_data : busB_reg;

    assign busA_out = busA_eff;
    assign busB_out = busB_eff;

    //=====================================================
    // Flags register
    //=====================================================
    wire [4:0] alu_flags;
    reg  [4:0] flags_reg;

    always @(posedge clk or posedge reset) begin
        if (reset)
            flags_reg <= 5'b0;
        else if (flags_en)
            flags_reg <= alu_flags;
    end

    assign flags = flags_reg;

    //=====================================================
    // Select B operand (reg or immediate)
    //=====================================================
    wire [15:0] B_sel = selB_imm ? immB : busB_eff;

    // Previous carry (C flag) into ALU.Cin
    wire cin_to_alu = flags_reg[0];

    //=====================================================
    // ALU core
    //  - A input: busA_eff (may be PS2 if ra_idx==15)
//  - B input: B_sel (either immB or busB_eff)
//=====================================================
    ALU uALU (
        .A      (busA_eff),
        .B      (B_sel),
        .Cin    (cin_to_alu),
        .Opcode (opcode),
        .C      (alu_out),
        .Flags  (alu_flags)
    );

endmodule
