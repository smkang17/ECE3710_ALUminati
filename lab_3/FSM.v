module FSM #(
  parameter DATA_WIDTH = 16,
  parameter ADDR_WIDTH = 10
)(
  input  wire                  clk,
  input  wire                  rst,
  input  wire                  start,

  // BRAM Port A
  output reg  [ADDR_WIDTH-1:0] addr_a,
  output reg  [DATA_WIDTH-1:0] data_a,
  output reg                   we_a,
  input  wire [DATA_WIDTH-1:0] q_a,

  // BRAM Port B
  output reg  [ADDR_WIDTH-1:0] addr_b,
  output reg  [DATA_WIDTH-1:0] data_b,
  output reg                   we_b,
  input  wire [DATA_WIDTH-1:0] q_b,

  // Outputs
  output reg  [DATA_WIDTH-1:0] display_value,
  output reg                   done,
  output reg                   error
);

  // --- State encoding ---
  localparam S0_INIT          = 4'd0;
  localparam S1_READ_A        = 4'd1;
  localparam S2_EXEC_A        = 4'd2;
  localparam S3_WRITE_A       = 4'd3;
  localparam S4_VERIFY_A      = 4'd4;
  localparam S5_READ_B        = 4'd5;
  localparam S6_EXEC_B        = 4'd6;
  localparam S7_WRITE_B       = 4'd7;
  localparam S8_VERIFY_B      = 4'd8;

  reg [3:0] prev, next;
  reg [DATA_WIDTH-1:0] temp_a, temp_b;

  // --- State register ---
  always @(posedge clk or posedge rst) begin
    if (rst) prev <= S0_INIT;
    else prev <= next;
  end

  // --- Next state logic ---
  always @(*) begin
    case(prev)
      S0_INIT:       next = start ? S1_READ_A : S0_INIT;
      S1_READ_A:     next = S2_EXEC_A;
      S2_EXEC_A:     next = S3_WRITE_A;
      S3_WRITE_A:    next = S4_VERIFY_A;
      S4_VERIFY_A:   next = S5_READ_B;
      S5_READ_B:     next = S6_EXEC_B;
      S6_EXEC_B:     next = S7_WRITE_B;
      S7_WRITE_B:    next = S8_VERIFY_B;
      S8_VERIFY_B:   next = start ? S8_VERIFY_B : S0_INIT;
      default:       next = S0_INIT;
    endcase
  end

  // --- Compute incremented values ---
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      temp_a <= 16'h0000;
      temp_b <= 16'h0000;
    end
    else begin
      if (prev == S2_EXEC_A) temp_a <= q_a + 16'h0001;
      if (prev == S6_EXEC_B) temp_b <= q_b + 16'h0001;
    end
  end

  // --- Error flag ---
  always @(posedge clk or posedge rst) begin
    if (rst) error <= 1'b0;
    else if (prev == S4_VERIFY_A && q_a != temp_a) error <= 1'b1;
    else if (prev == S8_VERIFY_B && q_b != temp_b) error <= 1'b1;
  end

  // --- Output logic ---
  always @(*) begin
    // defaults
    addr_a = 10'd0; data_a = 16'h0000; we_a = 1'b0;
    addr_b = 10'd0; data_b = 16'h0000; we_b = 1'b0;
    display_value = 16'h0000; done = 1'b0;

    case(prev)
      // Port A sequence
      S1_READ_A:     begin addr_a = 10'd0; display_value = q_a; end
      S3_WRITE_A:    begin addr_a = 10'd0; data_a = temp_a; we_a = 1'b1; end
      S4_VERIFY_A:   display_value = q_a;

      // Port B sequence
      S5_READ_B:     addr_b = 10'h200;
      S7_WRITE_B:    begin addr_b = 10'h200; data_b = temp_b; we_b = 1'b1; end
      S8_VERIFY_B:   begin display_value = q_b; done = 1'b1; end
    endcase
  end

endmodule
