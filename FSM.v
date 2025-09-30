module FSM #(
  parameter DATA_WIDTH = 16,
  parameter ADDR_WIDTH = 10,
  parameter REG_IDX_W  = 4,
  parameter ALU_OP_W   = 8
)(
  input  wire                    clk,
  input  wire                    rst,
  input  wire                    start,          

  // BRAM Port A 
  output reg  [ADDR_WIDTH-1:0]   addr_a,
  output reg  [DATA_WIDTH-1:0]   data_a,
  output reg                     we_a,
  input  wire [DATA_WIDTH-1:0]   q_a,

  // BRAM Port B 
  output reg  [ADDR_WIDTH-1:0]   addr_b,
  output reg  [DATA_WIDTH-1:0]   data_b,
  output reg                     we_b,
  input  wire [DATA_WIDTH-1:0]   q_b,           

  // RegALU interface
  output reg                     wEnable,
  output reg  [REG_IDX_W-1:0]    ra_idx,
  output reg  [REG_IDX_W-1:0]    rb_idx,
  output reg  [REG_IDX_W-1:0]    rd_idx,
  output reg  [ALU_OP_W-1:0]     opcode,
  output reg                     cin,
  output reg  [DATA_WIDTH-1:0]   immB,
  output reg                     selB_imm,

  // RegALU result feedback
  input  wire [DATA_WIDTH-1:0]   alu_out,
  input  wire [4:0]              flags,

  // Final outputs
  output reg  [DATA_WIDTH-1:0]   display_value,
  output reg                     done,
  output reg                     error
);

  // State encoding
  localparam S0 = 3'd0;  // Write initial value into BRAM
  localparam S1 = 3'd1;  // Read value from BRAM
  localparam S2 = 3'd2;  // Modify value using ALU
  localparam S3 = 3'd3;  // Write modified value back to BRAM
  localparam S4 = 3'd4;  // Re-read and verify correctness
  localparam S5 = 3'd5;  // Display result on 7-segment

  reg [2:0] prev, next;
  reg [DATA_WIDTH-1:0] temp_val;

  // === State transition (sequential logic) ===
  always @(posedge clk or posedge rst) begin
    if (rst) 
		prev <= S0;
    else     
		prev <= next;
  end

  // === Next state logic (combinational) ===
  always @(prev) begin
    case (prev)
      S0: next = S1;
      S1: next = S2;
      S2: next = S3;
      S3: next = S4;
      S4: next = S5;
      S5: next = S5;   // Stay in final state
      default: next = S0;
    endcase
  end

  // === Output logic (combinational, based on state) ===
  always @(prev) begin
    // Default assignments
    addr_a = 0; data_a = 0; we_a = 0;
    addr_b = 0; data_b = 0; we_b = 0;
    wEnable = 0; ra_idx = 0; rb_idx = 0; rd_idx = 0;
    opcode = 0; cin = 0; immB = 0; selB_imm = 0;
    done = 0; error = 0; display_value = 0;

    case (prev)
      S0: begin
        // Write initial value into BRAM
        addr_a = 10'd0;
        data_a = 16'h0005;
        we_a   = 1;
      end

      S1: begin
        // Read value from BRAM
        addr_a   = 10'd0;
        we_a     = 0;
        temp_val = q_a;
      end

      S2: begin
        // Modify value with ALU (example: +1)
        immB      = 16'h0001;
        selB_imm  = 1;
        ra_idx    = 0; 
        rd_idx    = 1; 
        wEnable   = 1;
        opcode    = 8'b00000101; // Example: ADD
      end

      S3: begin
        // Write modified value back to BRAM
        addr_a = 10'd0;
        data_a = alu_out;
        we_a   = 1;
      end

      S4: begin
        // Re-read from BRAM and verify correctness
        addr_a = 10'd0;
        we_a   = 0;
        if (q_a != alu_out) error = 1;
      end

      S5: begin
        // Display final value
        display_value = q_a;
        done          = 1;
      end
    endcase
  end

endmodule
