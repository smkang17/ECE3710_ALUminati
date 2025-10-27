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
	
	reg [15:0] inst_reg;
	
	// Wire declared for S1
	// Fields
   wire [3:0] op    = inst_reg[15:12]; //opcode
   wire [3:0] ext   = inst_reg[7:4];	  //opcode_extension
	 			
	// Base R-type (op=0000)
	wire is_rtype_base  = (op == 4'b0000);
				
	// Cases for R-type, but op is not 0000
	// LSH(1000_0100), RSH(1000_1100; custom), ALSH(1000_0010; custom), ARSH(1000_0011; custom)
	wire is_rtype_shift = (op == 4'b1000) && (ext == 4'b0100 || ext == 4'b1100 || ext == 4'b0010 || ext == 4'b0011);

	// Final R-type decision
	wire is_rtype = is_rtype_base | is_rtype_shift;

	// CMP / CMPI detection for Ren gating
	wire is_cmp_r  = (is_rtype_base && ext == 4'b1011); // 0000_xxxx with ext=1011
	wire is_cmpi_i = (op == 4'b1011);                   // 1011_xxxx
 
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
				 S0_FETCH:   state <= S1_DECODE;
				 S1_DECODE:  state <= S2_EXECUTE;	// this will depend on instruction
				 S2_EXECUTE: state <= S0_FETCH; // loop until we add more stages
				 default:    state <= S0_FETCH;
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
				inst_reg <= inst;
				
				PCe <= 1'b0; 
				Ren <= 1'b0; // no write yet 
				Rsrc <= 4'bxxxx; 
				Rdest <= 4'bxxxx; 
				R_I <= 1'bx; 
				Opcode <= 8'hxx; 
				Imm <= 8'hxx;
				
			end
	
			S1_DECODE: begin
				PCe <= 1'b0;
				Ren <= 1'b0;

				if (is_rtype) begin
					dec_R_I    <= 1'b0;                 // use register operand for B
					dec_Rdest  <= inst_reg[11:8];
					dec_Rsrc   <= inst_reg[3:0];
					dec_Imm    <= 8'h00;
					dec_Opcode <= {op, ext};           
					dec_is_cmp <= is_cmp_r;
				end 
				else begin
					dec_R_I    <= 1'b1;                 // use immediate for B
					dec_Rdest  <= inst_reg[11:8];
					dec_Rsrc   <= 4'h0;                 // unused
					dec_Imm    <= inst_reg[7:0];
					dec_Opcode <= {op, inst_reg[11:8]};   
					dec_is_cmp <= is_cmpi_i;
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