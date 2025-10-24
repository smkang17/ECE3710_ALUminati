module controlFSM (
	input  wire        clk,
   input  wire        rst,
   input  wire [15:0] IR,        // instruction register input (fetched instruction)

   output reg         PCe,       // PC enable
   output reg         Ren,       // regfile write enable
   output reg [3:0]   Rsrc,
   output reg [3:0]   Rdest,
   output reg         R_I,       // 0 = Register type, 1 = Immediate type
   output reg [7:0]   Opcode,
   output reg [7:0]   Imm,       // Immediate value
);
	reg [2:0] state;
	 
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
	  PCe    = 1'b0;
	  Ren    = 1'b0;
	  Rsrc   = 4'bxxxx;
	  Rdest  = 4'bxxxx;
	  R_I    = 1'bx;
	  Opcode = 8'h00;
	  Imm    = 8'h00;
	
	  case (state)
			S0_FETCH: begin
				 PCe    = 1'b1;      // increment PC
				 Ren    = 1'b0;      // no write yet
				 Rsrc   = 4'bxxxx;
				 Rdest  = 4'bxxxx;
				 R_I    = 1'bx;
				 Opcode = 8'hxx;
				 Imm    = 8'hxx;
			end
	
			S1_DECODE: begin
				 PCe    = 1'b0;
				 Ren    = 1'b0;
				 
				 // decode
				 Opcode = IR[];
				 Rdest  = IR[];
				 Rsrc   = IR[];
				 Imm    = IR[];
				 R_I    = ;
			end
			
			S2_EXECUTE: begin
				 PCe    = 1'b0;
				 Ren    = 1'b1;   // write ALU result to regfile
				 
				 // keep decoded fields stable
				 Opcode = IR[];
				 Rdest  = IR[];
				 Rsrc   = IR[];
				 Imm    = IR[];
				 R_I    = ;
			end
	  endcase
	end
	
endmodule