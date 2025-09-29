module Lab1(
    A, B, C, Opcode, Flags,
    //seven_seg3, seven_seg2, seven_seg1, seven_seg0
);

input [15:0] A, B;         // 16 bits
input [7:0] Opcode;
output reg [15:0] C;       // 16 bits
output reg [4:0] Flags;    // 5 flags
//output reg [6:0] seven_seg3;
//output reg [6:0] seven_seg2;
//output reg [6:0] seven_seg1;
//output reg [6:0] seven_seg0;

//wire for Cin
wire Cin;
assign Cin = Flags[0];

// Opcodes
parameter ADD    = 8'b00000101;
parameter ADDI   = 8'b1010xxxx;
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

always @(A,B,Opcode) begin

	 C = 16'h0000;
	 
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
            if ($signed(A) < $signed(B)) begin
                Flags[1] = 1'b1;
                Flags[0] = 1'b0;
            end else begin
                Flags[1] = 1'b0;
                Flags[0] = 1'b1;
            end
            Flags[3] = (A == B);
            Flags[4] = ($signed(A) < $signed(B));
            Flags[2] = 1'b0;
            C = 16'b0;
        end

        CMPI: begin
            if ($signed(A) < $signed(B)) begin
                Flags[1] = 1'b1;
                Flags[0] = 1'b0;
            end else begin
                Flags[1] = 1'b0;
                Flags[0] = 1'b1;
            end
            Flags[3] = (A == B);
            Flags[4] = ($signed(A) < $signed(B));
            Flags[2] = 1'b0;
            C = 16'b0;
        end

        CMPU: begin
            if (A < B) begin
                Flags[1] = 1'b1;
                Flags[0] = 1'b0;
            end else begin
                Flags[1] = 1'b0;
                Flags[0] = 1'b1;
            end
            Flags[3] = (A == B);
            Flags[2] = 1'b0;
            Flags[4] = 1'b0;
            C = 16'b0;
        end
		  
		  CMPUI: begin
            if (A < B) begin
                Flags[1] = 1'b1;
                Flags[0] = 1'b0;
            end else begin
                Flags[1] = 1'b0;
                Flags[0] = 1'b1;
            end
            Flags[3] = (A == B);
            Flags[2] = 1'b0;
            Flags[4] = 1'b0;
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