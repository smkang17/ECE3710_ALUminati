module controlFSM (
	input  wire        clk,
   input  wire        rst,
   input  wire [15:0] inst,        // instruction register input (fetched instruction)

   output reg         PCe,         // PC enable
   output reg         Ren,         // regfile write enable
   output reg [3:0]   Rsrc,
   output reg [3:0]   Rdest,
   output reg         R_I,         // 0 = Register type, 1 = Immediate type
   output reg [7:0]   Opcode,
   output reg [7:0]   Imm,          // Immediate value
	
	output reg         mem_WE,			// Memory write-enable for STORE 
	
	output reg      	 LSCntl,			
	output reg			 ALU_MUX_Cntl
);
	reg [2:0] state;
	
	reg        dec_R_I;
	reg [3:0]  dec_Rsrc, dec_Rdest;
	reg [7:0]  dec_Opcode, dec_Imm;
	reg        dec_is_cmp;
	reg        dec_is_nop;          // NOP for gating in EXEC
	reg        dec_is_store;        
	reg        dec_is_load;         
	
	reg [15:0] inst_reg; //IR
	
	
	// Wire declared for S1
	// Fields (decoded from latched instruction)
   wire [3:0] op    = inst_reg[15:12]; //opcode
   wire [3:0] ext   = inst_reg[7:4];   //opcode_extension
	 			
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

	// NOP detection (treat 0x0000 as NOP: no register write)
	wire is_nop    = (is_rtype_base && ext == 4'b0000); 
	
	// NEW: Memory type detection (no need to change in ALU)
	// LOAD : OP=0100 & EXT=0000
   // STOR : OP=0100 & EXT=0100
   wire is_load  = (op == 4'b0100) && (ext == 4'b0000);
   wire is_store = (op == 4'b0100) && (ext == 4'b0100);
	
	
	
    // FSM states
    localparam S0_FETCH   = 3'b000;
    localparam S1_DECODE  = 3'b001;
	 localparam S2_EXECUTE = 3'b010;
	 localparam S3_STORE  = 3'b011;
	 localparam S4_LOAD   = 3'b100;
	 localparam S5_DOUT   = 3'b101;
//	 localparam S6_BRANCH = 3'b110;
//	 localparam S7_JUMP   = 3'b111;

	always @(posedge clk or posedge rst) begin
	  if (rst)
			state <= S0_FETCH;
	  else begin
			case (state)
             S0_FETCH:  state <= S1_DECODE;
             S1_DECODE : begin
               if (is_store)      state <= S3_STORE;
               else if (is_load)  state <= S4_LOAD;
               else               state <= S2_EXECUTE; // R/I-type
               end
             S2_EXECUTE: state <= S0_FETCH; // loop until we add more stages
             S3_STORE  : state <= S0_FETCH; // STORE finish after write
             S4_LOAD   : state <= S5_DOUT;   
             S5_DOUT   : state <= S0_FETCH;
				 default:   state <= S0_FETCH; 
			endcase
	  end
	end

	always @(posedge clk) begin
	  // safe defaults each cycle
	  PCe    <= 1'b0;
	  Ren    <= 1'b0;
	  Rsrc   <= 4'bxxxx;
	  Rdest  <= 4'bxxxx;
	  R_I    <= 1'bx;
	  Opcode <= 8'h00;
	  Imm    <= 8'h00;
	  mem_WE     <= 1'b0;  // 1 for store at s3, else 0    
	  LSCntl <= 2'b00;
	  ALU_MUX_Cntl <= 1'b0;

	
	  case (state)
			S0_FETCH: begin
				// latch raw instruction from memory
				inst_reg <= inst;
				
				PCe   <= 1'b0; 
				Ren   <= 1'b0; // no write yet 
				Rsrc  <= 4'bxxxx; 
				Rdest <= 4'bxxxx; 
				R_I   <= 1'bx; 
				Opcode<= 8'hxx; 
				Imm   <= 8'hxx;
				mem_WE     <= 1'b0;  
			end
	
			S1_DECODE: begin
				PCe <= 1'b0;
				Ren <= 1'b0;
				mem_WE  <= 1'b0;
				
				// STORE takes: addr <- Rdest, data <- Rsrc (top will map ra_idx/rb_idx)
				if (is_store) begin
					dec_R_I      <= 1'b0;      // keep register path
					///// Not used in ISA; should use R_addr instead, dec_Rdest <= inst_reg[11:8];
					dec_Rdest  <= inst_reg[11:8];
					dec_Rsrc   <= inst_reg[3:0];
					dec_Imm      <= 8'h00;
					dec_Opcode   <= 8'hxx;     // don't care for STORE
					dec_is_cmp   <= 1'b0;
					dec_is_nop   <= 1'b0;
					dec_is_store <= 1'b1;
					dec_is_load  <= 1'b0;
				end
				// LOAD: present address next state (S4), data arrives following state (S5)
				else if (is_load) begin
					dec_R_I      <= 1'b0;      // keep register path
					dec_Rdest  <= inst_reg[11:8];
					dec_Rsrc   <= inst_reg[3:0];
					///// Not used in ISA; should use R_addr instead, dec_Rsrc <= inst_reg[3:0];
					dec_Imm      <= 8'h00;
					dec_Opcode   <= 8'hxx;     // don't care for LOAD
					dec_is_cmp   <= 1'b0;
					dec_is_nop   <= 1'b0;
					dec_is_store <= 1'b0;
					dec_is_load  <= 1'b1;
				end
				else if (is_rtype) begin
					dec_R_I    <= 1'b0;                  // use register operand for B
					dec_Rdest  <= inst_reg[11:8];
					dec_Rsrc   <= inst_reg[3:0];
					dec_Imm    <= 8'h00;
					dec_Opcode <= {op, ext};
					dec_is_cmp <= is_cmp_r;
					dec_is_store <= 1'b0;
					dec_is_load  <= 1'b0;
					dec_is_nop <= is_nop;                // Remember NOP
				end 
				else begin
					dec_R_I    <= 1'b1;                  // use immediate for B
					dec_Rdest  <= inst_reg[11:8];
					dec_Rsrc   <= 4'h0;                  // unused
					dec_Imm    <= inst_reg[7:0];
					dec_Opcode <= {op, inst_reg[11:8]};
					dec_is_cmp <= is_cmpi_i;
					dec_is_nop <= 1'b0;                  // I-type is never NOP
					dec_is_store <= 1'b0;
					dec_is_load  <= 1'b0;
				end
			end

			S2_EXECUTE: begin
				 PCe    <= 1'b1;                        // Enable PC increment during the execute stage
				 R_I    <= dec_R_I;                     // Select between register or immediate operand (R/I type)
				 Rdest  <= dec_Rdest;                   // Destination register index (write-back target)
				 Rsrc   <= dec_Rsrc;                    // Source register index (used if R-type)
				 Imm    <= dec_Imm;                     // Immediate value (used if I-type)
				 Opcode <= dec_Opcode;                  // ALU operation code (determines the operation type)

				 // Enable register write unless the instruction is CMP/CMPI or NOP
				 Ren <= (dec_is_cmp || dec_is_nop) ? 1'b0 : 1'b1; 
				 
				 ALU_MUX_Cntl <= 1'b0;						 // writeback from ALU
			end
			
			
			
			// NEW: STORE 
			S3_STORE: begin
			// Perform one memory write cycle using BRAM port-B.
			// At the top level:
			//   addr_b <- RegA(out_busA) = Raddr
			//   data_b <- RegB(out_busB) = Rsrc
			//   we_b   <- WE (asserted high for this state)
				PCe    <= 1'b1;                        // Increment PC after STORE is done
				Ren    <= 1'b0;                        // No register write during STORE
				mem_WE <= 1'b1;                        // Enable memory write
				R_I    <= 1'b0;                        // Keep register path (ALU not used)
				Rdest  <= dec_Rdest;                   // ra_idx = Raddr (address register)
				Rsrc   <= dec_Rsrc;                    // rb_idx = Rsrc (data register)
				Opcode <= 8'hxx; 								// Don't care
				Imm    <= 8'h00;								// Not used
				LSCntl <= 1'b1;								// addr from busA (Rdest)
				ALU_MUX_Cntl <= 1'b0;						// irrelevant
			end
        
        // NEW: LOAD
        S4_LOAD: begin
		  // Places memory address (from Rsrc) on the address bus
		  // No write, memory is read only
          PCe    <= 1'b0;									// Hold PC
          Ren    <= 1'b0;									// No reg write yet
          mem_WE <= 1'b0;								   // Read mode only
          R_I    <= 1'b0;									// Reg addressing
          Rdest  <= dec_Rdest;							// Dest reg for loaded data
          Rsrc   <= dec_Rsrc;								// Address reg
          Opcode <= 8'hxx;									// ALU not used
          Imm    <= 8'h00;									// Not used
			 LSCntl <= 2'b1;									// choose addr source
			 ALU_MUX_Cntl <= 1'b0;							// still ALU path
        end

        // NEW: DOUT
        S5_DOUT: begin
		  // Memory data is now valid
		  // Writes the fetched data back into the dest reg
          PCe    <= 1'b1;									// Increment PC after load completes
          Ren    <= 1'b1;									// Enable reg write
          mem_WE <= 1'b0;								   // Still in read mode
			 R_I	  <= 1'b0;									// Reg path
          Rdest  <= dec_Rdest;							// Dest reg for loaded data
          Rsrc   <= dec_Rsrc;								// Write dest reg
          Opcode <= 8'hxx;									// ALU not used
          Imm    <= 8'h00;							// Not used
			 LSCntl <= 2'b1;
			 ALU_MUX_Cntl <= 1'b1;							// reg write from memory
        end      
                  	
	  endcase
	end
	
endmodule