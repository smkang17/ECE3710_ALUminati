module TOP (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    output wire [6:0]  HEX0,
    output wire [6:0]  HEX1,
    output wire [6:0]  HEX2,
    output wire [6:0]  HEX3
);

  wire [15:0] display_value;
  wire done, error;

  // BRAM-FSM wires
  wire [9:0]  addr_a, addr_b;
  wire [15:0] data_a, data_b, q_a, q_b;
  wire we_a, we_b;
  
  // Reset button polarity
  localparam RST_ACTIVE_LOW = 1;
  wire rst_int = (RST_ACTIVE_LOW) ? ~rst : rst;
  
    // === clock divider ===
    reg [25:0] slow_count;
    always @(posedge clk or posedge rst_int) begin
        if (rst_int)
            slow_count <= 26'd0;
        else
            slow_count <= slow_count + 1;
    end
    wire slow_clk = slow_count[25];
	 
  // === Instantiate BRAM ===
  Bram bram_inst (
    .data_a(data_a), .data_b(data_b),
    .addr_a(addr_a), .addr_b(addr_b),
    .we_a(we_a), .we_b(we_b),
    .clk(slow_clk),
    .q_a(q_a), .q_b(q_b)
  );

  // === Instantiate FSM ===
  FSM fsm_inst (
    .clk(slow_clk), .rst(rst_int), .start(start),
    .addr_a(addr_a), .data_a(data_a), .we_a(we_a), .q_a(q_a),
    .addr_b(addr_b), .data_b(data_b), .we_b(we_b), .q_b(q_b),
    .display_value(display_value),
    .done(done),
    .error(error)
  );

  // === HEX display function ===
  function [6:0] hex7seg_ah;
    input [3:0] n;
    begin
      case (n)
        4'h0: hex7seg_ah = 7'b0111111; 4'h1: hex7seg_ah = 7'b0000110;
        4'h2: hex7seg_ah = 7'b1011011; 4'h3: hex7seg_ah = 7'b1001111;
        4'h4: hex7seg_ah = 7'b1100110; 4'h5: hex7seg_ah = 7'b1101101;
        4'h6: hex7seg_ah = 7'b1111101; 4'h7: hex7seg_ah = 7'b0000111;
        4'h8: hex7seg_ah = 7'b1111111; 4'h9: hex7seg_ah = 7'b1100111;
        4'hA: hex7seg_ah = 7'b1110111; 4'hB: hex7seg_ah = 7'b1111100;
        4'hC: hex7seg_ah = 7'b0111001; 4'hD: hex7seg_ah = 7'b1011110;
        4'hE: hex7seg_ah = 7'b1111001; 4'hF: hex7seg_ah = 7'b1110001;
        default: hex7seg_ah = 7'b0000000;
      endcase
    end
  endfunction

  // Split 16-bit value across 4 displays
  assign HEX3 = ~hex7seg_ah(display_value[15:12]);
  assign HEX2 = ~hex7seg_ah(display_value[11:8]);
  assign HEX1 = ~hex7seg_ah(display_value[7:4]);
  assign HEX0 = ~hex7seg_ah(display_value[3:0]);

endmodule