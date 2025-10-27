module controlFSM (
	input  wire        clk,
   input  wire        rst,
   input  wire [15:0] inst,        // instruction register input (fetched instruction)

   output reg         PCe,       // PC enable
   output reg         Ren,       // regfile write enable
   output reg [3:0]   Rsrc,
   output reg [3:0]   Rdest,
   output reg         R_I,       // 0 = Register type, 1 = Immediate type
   output reg [7:0]   Opcode,
   output reg [7:0]   Imm       // Immediate value
);
	reg [2:0] state;
	
	reg        dec_R_I;
	reg [3:0]  dec_Rsrc, dec_Rdest;
	reg [7:0]  dec_Opcode, dec_Imm;
	reg        dec_is_cmp;
	reg		  dec_is_rsg;
	reg		  dec_R_ALSH;
	reg		  dec_R_ARSH;

	
 
   // FSM states
   localparam S0_FETCH  = 3'b000;
   localparam S1_DECODE = 3'b001;
	localparam S2_EXECUTE = 3'b010;
//	localparam S3_STORE = 3'b011;
//	localparam S4_LOAD = 3'b100;
//	localparam S5_DOUT = 3'b101;
//	localparam S6_BRANCH = 3'b110;
//	localparam S7_JUMP = 3'b111;

	always @(posedge clk or posedge rst) begin
	  if (rst)
			state <= S0_FETCH;
	  else begin
			case (state)
				 S0_FETCH:  state <= S1_DECODE;
				 S1_DECODE: state <= S2_EXECUTE;	// this will depend on instruction
				 S2_EXECUTE: state <= S0_FETCH; // loop until we add more stages
				 default:   state <= S0_FETCH;
			endcase
	  end
	end

	always @(posedge clk) begin
	  PCe    <= 1'b0;
	  Ren    <= 1'b0;
	  Rsrc   <= 4'bxxxx;
	  Rdest  <= 4'bxxxx;
	  R_I    <= 1'bx;
	  Opcode <= 8'h00;
	  Imm    <= 8'h00;
	
	  case (state)
			S0_FETCH: begin
				 PCe    <= 1'b1;      // increment PC
				 Ren    <= 1'b0;      // no write yet
				 Rsrc   <= 4'bxxxx;
				 Rdest  <= 4'bxxxx;
				 R_I    <= 1'bx;
				 Opcode <= 8'hxx;
				 Imm    <= 8'hxx;
			end
	
			S1_DECODE: begin
				 PCe    <= 1'b0;
				 Ren    <= 1'b0;
				 
				 
				 if (inst[15:12] == 4'b0000) begin						// if opcode is 0000, selB_imm = 0 (R_type)
					dec_R_I <= 1'b0;										// selB_imm=0   (496 line in RegALU)
					dec_Rdest <= inst[11:8];								// destination register index							
					dec_Rsrc <= inst[3:0];									// source register index
					dec_Imm <= 8'h00;										// no immediate for R-type
					dec_Opcode <= {inst[15:12], inst[7:4]};				// combine major opcode and extension
					dec_is_cmp <= (inst[7:4] == 4'b1011);				// CMP?					
				 end
				 else begin
					if(inst[15:12] == 4'b1000 && inst[7:4] == 4'b0100) begin
						dec_R_I <= 1'b0;									// LSH : 10000100, selB_imm = 0 (R_type)
					end
					
					if(inst[15:12] == 4'b1000 && inst[7:4] == 4'b1100) begin
						dec_R_I <= 1'b0;									// RSH : 10001100, selB_imm = 0 (R_type)
					end
					
					if(inst[15:12] == 4'b1000 && inst[7:4] == 4'b0010) begin
						dec_R_I <= 1'b0;									// ALSH : 10000010, selB_imm = 0 (R_type)
					end
					
					if(inst[15:12] == 4'b1000 && inst[7:4] == 4'b0011) begin
						dec_R_I <= 1'b0;									// ARSH : 10000011, selB_imm = 0 (R_type)
					end
					
					
					
					dec_R_I <= 1'b1;										// selB_imm=1 (I_type)
					dec_Rdest <= inst[11:8];								// destination register index
					dec_Rsrc <= 4'h0;										// source register not used
					dec_Imm <= inst[7:0];									// 8-bit immediate value
					dec_Opcode <= {inst[15:12], inst[11:8]};			// combine for ALU casex matching
					dec_is_cmp <= (inst[15:12] == 4'b1011);			// CMPI?
				 end
			end
			
			S2_EXECUTE: begin
				 PCe    <= 1'b1;											// Enable PC increment during the execute stage
				 R_I	  <= dec_R_I;										// Select between register or immediate operand (R/I type)
				 Rdest  <= dec_Rdest;									// Destination register index (write-back target)
				 Rsrc	  <= dec_Rsrc;										// Source register index (used if R-type)
				 Imm	  <= dec_Imm;										// Immediate value (used if I-type)
				 Opcode <= dec_Opcode;									// ALU operation code (determines the operation type)
				 Ren <= dec_is_cmp ? 1'b0 : 1'b1;					// Enable register write unless the instruction is CMP/CMPI (flags only)
			end
	  endcase
	end
	
endmodule
