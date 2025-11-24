module controlFSM (
	input  wire        clk,
   input  wire        rst,
   input  wire [15:0] inst,        // instruction register input (fetched instruction)
	
	
	input  wire [4:0]  flags,       // New : N,Z,F,L,C flags from RegALU

   output reg         PCe,         // PC enable
	
	output reg  [1:0]  PCsrc,       // New: 00: PC+1, 01: PC+disp, 10: Rtarget
   output reg [15:0]  branch_disp, // New: sign-extended disp for branch
	
	
	
   output reg         Ren,         // regfile write enable
   output reg [3:0]   Rsrc,
   output reg [3:0]   Rdest,
   output reg         R_I,         // 0 = Register type, 1 = Immediate type
   output reg [7:0]   Opcode,
   output reg [7:0]   Imm,          // Immediate value
	
	output reg         mem_WE,			// Memory write-enable for STORE 
	
	output reg      	 LSCntl,			
	output reg [1:0]   ALU_MUX_Cntl,
	
	output reg         flags_en      //wire for flags to update
);
	reg [2:0] state;
	
	reg        dec_R_I;
	reg [3:0]  dec_Rsrc, dec_Rdest;
	reg [7:0]  dec_Opcode, dec_Imm;
	reg        dec_is_cmp;
	reg        dec_is_nop;          // NOP for gating in EXEC
	reg        dec_is_store;        
	reg        dec_is_load;         
	
	
	// New: Branch / Jump
   reg        dec_is_branch;
   reg        dec_is_jump;
   reg [3:0]  dec_cond;      // cond field
   reg [7:0]  dec_disp8;     // Bcond disp (8-bit)
   reg [3:0]  dec_jtarget;   // Jcond Rtarget (reg index)
	reg 		  branch_reset;  // set when branch is taken to fix bug
	reg 		  next_branch_reset;
	
	
	//for IR 
	reg prev_mem_we, prev_LSCntl; //for ir_en
	reg [15:0] inst_reg; //IR
	wire ir_en;
	
	
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
	
	// Memory type detection (no need to change in ALU)
	// LOAD : OP=0100 & EXT=0000
   // STOR : OP=0100 & EXT=0100
   wire is_load  = (op == 4'b0100) && (ext == 4'b0000);
   wire is_store = (op == 4'b0100) && (ext == 4'b0100);
	
	
	// NEW: Branch / Jump 
   wire is_branch = (op == 4'b1100);                     // Bcond disp
   wire is_jump   = (op == 4'b0100) && (ext == 4'b1100); // Jcond Rtarget
	wire is_storePC    = (op == 4'b0100) && (ext == 4'b1000); //store PC
	
	
	
	

 // New: cond_true: cond + flags({N,Z,F,L,C}) 

    function automatic cond_true;
        input [3:0] cond;
        input [4:0] flags_in;
        reg N,Z,F,L,C;
        begin
            N = flags_in[4];
            Z = flags_in[3];
            F = flags_in[2];
            L = flags_in[1];
            C = flags_in[0];

            case (cond)
                4'b0000: cond_true = (Z == 1'b1);                       // EQ
                4'b0001: cond_true = (Z == 1'b0);                       // NE
                4'b0010: cond_true = (C == 1'b1);                       // CS
                4'b0011: cond_true = (C == 1'b0);                       // CC
                4'b0100: cond_true = (L == 1'b1);                       // HI
                4'b0101: cond_true = (L == 1'b0);                       // LS
                4'b0110: cond_true = (N == 1'b1);                       // GT
                4'b0111: cond_true = (N == 1'b0);                       // LE
                4'b1000: cond_true = (F == 1'b1);                       // FS
                4'b1001: cond_true = (F == 1'b0);                       // FC
                4'b1010: cond_true = (L == 1'b0 && Z == 1'b0);          // LO
                4'b1011: cond_true = (L == 1'b1 || Z == 1'b1);          // HS
                4'b1100: cond_true = (N == 1'b0 && Z == 1'b0);          // LT
                4'b1101: cond_true = (N == 1'b1 || Z == 1'b1);          // GE
                4'b1110: cond_true = 1'b1;                              // UC
                4'b1111: cond_true = 1'b0;                              // Never
                default: cond_true = 1'b0;
            endcase
        end
    endfunction
	
	
	
	
    // FSM states
    localparam S0_FETCH   = 3'b000;
    localparam S1_DECODE  = 3'b001;
	 localparam S2_EXECUTE = 3'b010;
	 localparam S3_STORE  = 3'b011;
	 localparam S4_LOAD   = 3'b100;
	 localparam S5_DOUT   = 3'b101;
	 

	always @(posedge clk or posedge rst) begin
	  if (rst)
			state <= S0_FETCH;
	  else begin
			case (state)
             S0_FETCH:  state <= ir_en ? S1_DECODE : S0_FETCH; // <-- STALL until IR latched
             S1_DECODE : begin
               if (is_store)      state <= S3_STORE;
               else if (is_load)  state <= S4_LOAD;
               else               state <= S2_EXECUTE; // R/I-type + Bcond Jcond
               end
             S2_EXECUTE: state <= S0_FETCH; // loop until we add more stages
             S3_STORE  : state <= S0_FETCH; // STORE finish after write
             S4_LOAD   : state <= S5_DOUT;   
             S5_DOUT   : state <= S0_FETCH;
				 default:   state <= S0_FETCH; 
			endcase
	  end
	end
	
	
	//--------- IR -----------------------------------------------------------
	
	//make sure the btis that will corrupt IR are not set
	always @(posedge clk or posedge rst) begin
	  if (rst) begin
		 prev_mem_we  <= 1'b0;
		 prev_LSCntl  <= 1'b0;
	  end else begin
		 prev_mem_we  <= mem_WE;
		 prev_LSCntl  <= LSCntl;
	  end
	end
	
	
	//IR only enable when safe
   assign ir_en = (state == S0_FETCH) 
		&& !prev_mem_we      //ensure nothing is writing to bram 
		&& !prev_LSCntl;		//ensure address is from PC
	
	// Changed to fix branch bug
	always @(posedge clk or posedge rst) begin
	  if (rst) begin
			inst_reg <= 16'h0000;
			branch_reset <= 1'b0;
	  end else begin
			// If we are fetching but previous instruction was a branch,
			// write a NOP instead of the memory output
			if (ir_en) begin
				if (branch_reset || next_branch_reset) begin
					inst_reg	<= 16'h0000;
					branch_reset <= 1'b0;
				end else begin
					inst_reg <= inst;
					branch_reset <= next_branch_reset;	// latch new request
				end
			end else begin
				branch_reset <= branch_reset | next_branch_reset;
			end
		end
	end
				
	//---------------------------------------------------------------------------------
	
	
	
	
	always @(posedge clk) begin
	  // safe defaults each cycle
	  PCe    <= 1'b0;
	  flags_en <= 1'b0;
	  
	  PCsrc         <= 2'b00;  
     branch_disp   <= 16'h0000;
	  next_branch_reset  <= 1'b0; 
				
	  Ren    <= 1'b0;
	  Rsrc   <= 4'b0000;
	  Rdest  <= 4'b0000;
	  R_I    <= 1'b0;
	  Opcode <= 8'h00;
	  Imm    <= 8'h00;
	  mem_WE     <= 1'b0;  // 1 for store at s3, else 0    
	  LSCntl <= 1'b0;
	  ALU_MUX_Cntl <= 1'b0;

	
	  case (state)
			S0_FETCH: begin
				// latch raw instruction from memory
				ALU_MUX_Cntl <= 1'b0;
				LSCntl <= 1'b0;
				PCe    <= 1'b0; 
				Ren    <= 1'b0; // no write yet 
				Rsrc   <= 4'b0000; 
				Rdest  <= 4'b0000; 
				R_I    <= 1'b0; 
				Opcode <= 8'h00; 
				Imm    <= 8'h00;
				mem_WE <= 1'b0;
				flags_en <= 1'b0;	
			end
	
			S1_DECODE: begin

				PCe <= 1'b0;
				Ren <= 1'b0;
				mem_WE  <= 1'b0;
				flags_en <= 1'b0;
				
				
				// clear
            dec_is_store <= 1'b0;
            dec_is_load  <= 1'b0;
            dec_is_cmp   <= 1'b0;
            dec_is_nop   <= 1'b0;
				
				
				
				// STORE takes: addr <- Rdest, data <- Rsrc (top will map ra_idx/rb_idx)
				if (is_store) begin
					dec_R_I      <= 1'b0;      // keep register path
					///// Not used in ISA; should use R_addr instead, dec_Rdest <= inst_reg[11:8];
					dec_Rdest  <= inst_reg[11:8];
					dec_Rsrc   <= inst_reg[3:0];
					dec_Imm      <= 8'h00;
					dec_Opcode   <= 8'h00;     // don't care for STORE
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
					dec_Opcode   <= 8'h00;     // don't care for LOAD
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
				
				// Branch / Jump
				else if (is_branch || is_jump) begin
			      dec_R_I      <= 1'b0;
				   dec_Rdest    <= 4'h0;
			      dec_Rsrc   <= (is_jump) ? inst_reg[3:0] : 4'h0; // prepare jump target reg
			  	   dec_Imm    <= inst_reg[7:0];                   // save disp for branch
				   dec_Opcode   <= 8'h00;
				   dec_is_cmp   <= 1'b0;
				   dec_is_nop   <= 1'b0;
					dec_is_store <= 1'b0;
					dec_is_load  <= 1'b0;
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
				 PCsrc  <= 2'b00;          // PC+1
				 R_I    <= dec_R_I;                     // Select between register or immediate operand (R/I type)
				 Rdest  <= dec_Rdest;                   // Destination register index (write-back target)
				 Rsrc   <= dec_Rsrc;                    // Source register index (used if R-type)
				 Imm    <= dec_Imm;                     // Immediate value (used if I-type)
				 Opcode <= dec_Opcode;                  // ALU operation code (determines the operation type)
				 branch_disp <= {{8{dec_Imm[7]}}, dec_Imm}; // sign-extend disp
				 flags_en <= 1'b1;
				 next_branch_reset  <= 1'b0;
				 
				 // Enable register write unless the instruction is CMP/CMPI or NOP
				 Ren <= (dec_is_cmp || dec_is_nop) ? 1'b0 : 1'b1; 
				 

			
				 if (is_branch) begin
                    Ren <= 1'b0;
						  // Bcond disp: cond=inst_reg[11:8], disp=inst_reg[7:0]
                    if (cond_true(inst_reg[11:8], flags)) begin
                        PCe         <= 1'b1;
                        PCsrc       <= 2'b01; // PC + disp
                        branch_disp <= {{8{inst_reg[7]}}, inst_reg[7:0]};
								next_branch_reset <= 1'b1;
                    end else begin
                        PCe   <= 1'b1;
                        PCsrc <= 2'b00;       // PC + 1
                    end
                    // no Ren/mem_WE
                end
              if (is_jump) begin
				        Ren <= 1'b0;
                    // Jcond Rtarget: cond=inst_reg[11:8], Rtarget=inst_reg[3:0]
                    if (cond_true(inst_reg[11:8], flags)) begin
                        PCe   <= 1'b1;
                        PCsrc <= 2'b10;       // Rtarget
                        Rsrc  <= inst_reg[3:0];          // rb_idx=Rsrc -> busB_out = Rtarget1;
								next_branch_reset <= 1'b1;
                    end else begin
                        PCe   <= 1'b1;
                        PCsrc <= 2'b00;       // PC + 1
                    end
                    // no Ren/mem_WE
              end
				  if (is_storePC) begin
						  PCe          <= 1'b1;
						  PCsrc <= 2'b00;
						  ALU_MUX_Cntl <= 2'b10;
				
				  end else begin
						  ALU_MUX_Cntl <= 2'b00;						 // writeback from ALU
				  end
		
			end
			
			
			
			// STORE 
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
				Opcode <= 8'h00; 								// Don't care
				Imm    <= 8'h00;								// Not used
				LSCntl <= 1'b1;								// addr from busA (Rdest)
				ALU_MUX_Cntl <= 1'b00;						// irrelevant
				flags_en <= 1'b0;
			end
        
        // LOAD
        S4_LOAD: begin
		  // Places memory address (from Rsrc) on the address bus
		  // No write, memory is read only
          PCe    <= 1'b0;									// Hold PC
          Ren    <= 1'b0;									// No reg write yet
          mem_WE <= 1'b0;								   // Read mode only
          R_I    <= 1'b0;									// Reg addressing
          Rdest  <= dec_Rdest;							// Dest reg for loaded data
          Rsrc   <= dec_Rsrc;								// Address reg
          Opcode <= 8'h00;									// ALU not used
          Imm    <= 8'h00;									// Not used
			 LSCntl <= 1'b1;									// choose addr source
			 ALU_MUX_Cntl <= 1'b00;							// still ALU path
			 flags_en <= 1'b0;
        end

        // DOUT
        S5_DOUT: begin
		  // Memory data is now valid
		  // Writes the fetched data back into the dest reg
          PCe    <= 1'b1;									// Increment PC after load completes
          Ren    <= 1'b1;									// Enable reg write
          mem_WE <= 1'b0;								   // Still in read mode
			 R_I	  <= 1'b0;									// Reg path
          Rdest  <= dec_Rdest;							// Dest reg for loaded data
          Rsrc   <= dec_Rsrc;								// Write dest reg
          Opcode <= 8'h00;									// ALU not used
          Imm    <= 8'h00;							// Not used
			 LSCntl <= 1'b0;
			 ALU_MUX_Cntl <= 1'b01;							// reg write from memory
			 flags_en <= 1'b0;
        end      
                  	
	  endcase
	end
	
endmodule

