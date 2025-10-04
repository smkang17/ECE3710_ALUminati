
module FSM_ALU_All (
    input  wire       clk, rst,
    output reg  [3:0] ra_idx, rb_idx,
    output reg        wEnable,
    output reg  [7:0] alu_op,
    output reg        selB_imm,
    output reg [15:0] immB
);

    // Concrete opcode representatives for the 'xxxx' and 'x' patterns
    localparam ADD     = 8'b00000101;
    localparam ADDI    = 8'b01010000; // 0101xxxx -> pick 01010000
    localparam ADDU    = 8'b00000110;
    localparam ADDUI   = 8'b01100000; // 0110xxxx -> pick 01100000
    localparam ADDC    = 8'b00000111;
    localparam ADDCU   = 8'b00001000;
    localparam ADDCUI  = 8'b11010000; // 1101xxxx -> pick 11010000
    localparam ADDCI   = 8'b01110000; // 0111xxxx -> pick 01110000
    localparam SUB     = 8'b00001001;
    localparam SUBI    = 8'b10010000; // 1001xxxx -> pick 10010000
    localparam CMP     = 8'b00001011;
    localparam CMPI    = 8'b10110000; // 1011xxxx
    localparam CMPU    = 8'b00001111;
    localparam CMPUI   = 8'b11100000; // 1110xxxx
    localparam AND_    = 8'b00000001;
    localparam OR_     = 8'b00000010;
    localparam XOR_    = 8'b00000011;
    localparam NOT_    = 8'b00000100;
    localparam LSH     = 8'b10000100;
    localparam LSHI    = 8'b10000000; // 1000000x -> pick 10000000
    localparam RSH     = 8'b10001100;
    localparam RSHI    = 8'b10001000; // 1000100x -> pick 10001000
    localparam ALSH    = 8'b10000010;
    localparam ARSH    = 8'b10000011;
    localparam NOP     = 8'b00000000;

    // States: init a few registers, then one READ/WRITE pair per opcode
    localparam
      S_INIT0_R = 8'd0,  S_INIT0_W = 8'd1,   // R0 <- 5
      S_INIT1_R = 8'd2,  S_INIT1_W = 8'd3,   // R1 <- 7
      S_INIT2_R = 8'd4,  S_INIT2_W = 8'd5,   // R2 <- 0xFFFF
      S_INIT3_R = 8'd6,  S_INIT3_W = 8'd7,   // R3 <- 1
      S_INIT4_R = 8'd8,  S_INIT4_W = 8'd9,   // R4 <- 0x00F0
      S_INIT5_R = 8'd10, S_INIT5_W = 8'd11,  // R5 <- 0x0F0F

      S_ADD_R   = 8'd12, S_ADD_W   = 8'd13,
      S_ADDI_R  = 8'd14, S_ADDI_W  = 8'd15,
      S_ADDU_R  = 8'd16, S_ADDU_W  = 8'd17,
      S_ADDUI_R = 8'd18, S_ADDUI_W = 8'd19,
      S_ADDC_R  = 8'd20, S_ADDC_W  = 8'd21,
      S_ADDCU_R = 8'd22, S_ADDCU_W = 8'd23,
      S_ADDCUI_R= 8'd24, S_ADDCUI_W= 8'd25,
      S_ADDCI_R = 8'd26, S_ADDCI_W = 8'd27,
      S_SUB_R   = 8'd28, S_SUB_W   = 8'd29,
      S_SUBI_R  = 8'd30, S_SUBI_W  = 8'd31,
      S_CMP_R   = 8'd32, S_CMP_W   = 8'd33,
      S_CMPI_R  = 8'd34, S_CMPI_W  = 8'd35,
      S_CMPU_R  = 8'd36, S_CMPU_W  = 8'd37,
      S_CMPUI_R = 8'd38, S_CMPUI_W = 8'd39,
      S_AND_R   = 8'd40, S_AND_W   = 8'd41,
      S_OR_R    = 8'd42, S_OR_W    = 8'd43,
      S_XOR_R   = 8'd44, S_XOR_W   = 8'd45,
      S_NOT_R   = 8'd46, S_NOT_W   = 8'd47,
      S_LSH_R   = 8'd48, S_LSH_W   = 8'd49,
      S_LSHI_R  = 8'd50, S_LSHI_W  = 8'd51,
      S_RSH_R   = 8'd52, S_RSH_W   = 8'd53,
      S_RSHI_R  = 8'd54, S_RSHI_W  = 8'd55,
      S_ALSH_R  = 8'd56, S_ALSH_W  = 8'd57,
      S_ARSH_R  = 8'd58, S_ARSH_W  = 8'd59,
      S_NOP_R   = 8'd60, S_NOP_W   = 8'd61,
      S_DONE    = 8'd255;

    reg [7:0] y;
    always @(posedge clk) begin
      if (rst) y <= S_INIT0_R;
      else case (y)
        S_INIT0_R: y <= S_INIT0_W;  S_INIT0_W: y <= S_INIT1_R;
        S_INIT1_R: y <= S_INIT1_W;  S_INIT1_W: y <= S_INIT2_R;
        S_INIT2_R: y <= S_INIT2_W;  S_INIT2_W: y <= S_INIT3_R;
        S_INIT3_R: y <= S_INIT3_W;  S_INIT3_W: y <= S_INIT4_R;
        S_INIT4_R: y <= S_INIT4_W;  S_INIT4_W: y <= S_INIT5_R;
        S_INIT5_R: y <= S_INIT5_W;  S_INIT5_W: y <= S_ADD_R;

        S_ADD_R:   y <= S_ADD_W;    S_ADD_W:    y <= S_ADDI_R;
        S_ADDI_R:  y <= S_ADDI_W;   S_ADDI_W:   y <= S_ADDU_R;
        S_ADDU_R:  y <= S_ADDU_W;   S_ADDU_W:   y <= S_ADDUI_R;
        S_ADDUI_R: y <= S_ADDUI_W;  S_ADDUI_W:  y <= S_ADDC_R;
        S_ADDC_R:  y <= S_ADDC_W;   S_ADDC_W:   y <= S_ADDCU_R;
        S_ADDCU_R: y <= S_ADDCU_W;  S_ADDCU_W:  y <= S_ADDCUI_R;
        S_ADDCUI_R:y <= S_ADDCUI_W; S_ADDCUI_W: y <= S_ADDCI_R;
        S_ADDCI_R: y <= S_ADDCI_W;  S_ADDCI_W:  y <= S_SUB_R;
        S_SUB_R:   y <= S_SUB_W;    S_SUB_W:    y <= S_SUBI_R;
        S_SUBI_R:  y <= S_SUBI_W;   S_SUBI_W:   y <= S_CMP_R;
        S_CMP_R:   y <= S_CMP_W;    S_CMP_W:    y <= S_CMPI_R;
        S_CMPI_R:  y <= S_CMPI_W;   S_CMPI_W:   y <= S_CMPU_R;
        S_CMPU_R:  y <= S_CMPU_W;   S_CMPU_W:   y <= S_CMPUI_R;
        S_CMPUI_R: y <= S_CMPUI_W;  S_CMPUI_W:  y <= S_AND_R;
        S_AND_R:   y <= S_AND_W;    S_AND_W:    y <= S_OR_R;
        S_OR_R:    y <= S_OR_W;     S_OR_W:     y <= S_XOR_R;
        S_XOR_R:   y <= S_XOR_W;    S_XOR_W:    y <= S_NOT_R;
        S_NOT_R:   y <= S_NOT_W;    S_NOT_W:    y <= S_LSH_R;
        S_LSH_R:   y <= S_LSH_W;    S_LSH_W:    y <= S_LSHI_R;
        S_LSHI_R:  y <= S_LSHI_W;   S_LSHI_W:   y <= S_RSH_R;
        S_RSH_R:   y <= S_RSH_W;    S_RSH_W:    y <= S_RSHI_R;
        S_RSHI_R:  y <= S_RSHI_W;   S_RSHI_W:   y <= S_ALSH_R;
        S_ALSH_R:  y <= S_ALSH_W;   S_ALSH_W:   y <= S_ARSH_R;
        S_ARSH_R:  y <= S_ARSH_W;   S_ARSH_W:   y <= S_NOP_R;
        S_NOP_R:   y <= S_NOP_W;    S_NOP_W:    y <= S_DONE;

        default: y <= S_DONE;
      endcase
    end

    // Result destination mapping R8..R31 in order of ops above
    function [3:0] dst_reg;
      input [7:0] st;
      begin
        case (st)
          S_ADD_W:     dst_reg = 4'd8;
          S_ADDI_W:    dst_reg = 4'd9;
          S_ADDU_W:    dst_reg = 4'd10;
          S_ADDUI_W:   dst_reg = 4'd11;
          S_ADDC_W:    dst_reg = 4'd12;
          S_ADDCU_W:   dst_reg = 4'd13;
          S_ADDCUI_W:  dst_reg = 4'd14;
          S_ADDCI_W:   dst_reg = 4'd15;
          S_SUB_W:     dst_reg = 4'd0;  // wraps (adjust as needed)
          S_SUBI_W:    dst_reg = 4'd1;
          S_CMP_W:     dst_reg = 4'd2;
          S_CMPI_W:    dst_reg = 4'd3;
          S_CMPU_W:    dst_reg = 4'd4;
          S_CMPUI_W:   dst_reg = 4'd5;
          S_AND_W:     dst_reg = 4'd6;
          S_OR_W:      dst_reg = 4'd7;
          S_XOR_W:     dst_reg = 4'd8;
          S_NOT_W:     dst_reg = 4'd9;
          S_LSH_W:     dst_reg = 4'd10;
          S_LSHI_W:    dst_reg = 4'd11;
          S_RSH_W:     dst_reg = 4'd12;
          S_RSHI_W:    dst_reg = 4'd13;
          S_ALSH_W:    dst_reg = 4'd14;
          S_ARSH_W:    dst_reg = 4'd15;
          S_NOP_W:     dst_reg = 4'd0;
          default:     dst_reg = 4'd0;
        endcase
      end
    endfunction

    // Moore output logic
    always @(*) begin
      // defaults
      ra_idx   = 4'd0;
      rb_idx   = 4'd0;
      wEnable  = 1'b0;
      alu_op   = ADD;
      selB_imm = 1'b0;
      immB     = 16'h0000;

      case (y)
        // init: load constants
        S_INIT0_R: begin ra_idx=4'd0; selB_imm=1'b1; immB=16'd5;  alu_op=ADD; end
        S_INIT0_W: begin ra_idx=4'd0; selB_imm=1'b1; immB=16'd5;  alu_op=ADD; wEnable=1'b1; end

        S_INIT1_R: begin ra_idx=4'd1; selB_imm=1'b1; immB=16'd7;  alu_op=ADD; end
        S_INIT1_W: begin ra_idx=4'd1; selB_imm=1'b1; immB=16'd7;  alu_op=ADD; wEnable=1'b1; end

        S_INIT2_R: begin ra_idx=4'd2; selB_imm=1'b1; immB=16'hFFFF; alu_op=ADD; end
        S_INIT2_W: begin ra_idx=4'd2; selB_imm=1'b1; immB=16'hFFFF; alu_op=ADD; wEnable=1'b1; end

        S_INIT3_R: begin ra_idx=4'd3; selB_imm=1'b1; immB=16'h0001; alu_op=ADD; end
        S_INIT3_W: begin ra_idx=4'd3; selB_imm=1'b1; immB=16'h0001; alu_op=ADD; wEnable=1'b1; end

        S_INIT4_R: begin ra_idx=4'd4; selB_imm=1'b1; immB=16'h00F0; alu_op=ADD; end
        S_INIT4_W: begin ra_idx=4'd4; selB_imm=1'b1; immB=16'h00F0; alu_op=ADD; wEnable=1'b1; end

        S_INIT5_R: begin ra_idx=4'd5; selB_imm=1'b1; immB=16'h0F0F; alu_op=ADD; end
        S_INIT5_W: begin ra_idx=4'd5; selB_imm=1'b1; immB=16'h0F0F; alu_op=ADD; wEnable=1'b1; end

        // sweep (A from R0 unless noted; B from R1 or imm)
        S_ADD_R:    begin ra_idx=4'd0; rb_idx=4'd1;            alu_op=ADD;    selB_imm=1'b0; end
        S_ADD_W:    begin ra_idx=dst_reg(S_ADD_W);             alu_op=ADD;    wEnable=1'b1;  end

        S_ADDI_R:   begin ra_idx=4'd0;                         alu_op=ADDI;   selB_imm=1'b1; immB=16'd3; end
        S_ADDI_W:   begin ra_idx=dst_reg(S_ADDI_W);            alu_op=ADDI;   wEnable=1'b1; end

        S_ADDU_R:   begin ra_idx=4'd0; rb_idx=4'd1;            alu_op=ADDU;   selB_imm=1'b0; end
        S_ADDU_W:   begin ra_idx=dst_reg(S_ADDU_W);            alu_op=ADDU;   wEnable=1'b1; end

        S_ADDUI_R:  begin ra_idx=4'd0;                         alu_op=ADDUI;  selB_imm=1'b1; immB=16'd9; end
        S_ADDUI_W:  begin ra_idx=dst_reg(S_ADDUI_W);           alu_op=ADDUI;  wEnable=1'b1; end

        S_ADDC_R:   begin ra_idx=4'd2; rb_idx=4'd3;            alu_op=ADDC;   selB_imm=1'b0; end
        S_ADDC_W:   begin ra_idx=dst_reg(S_ADDC_W);            alu_op=ADDC;   wEnable=1'b1; end

        S_ADDCU_R:  begin ra_idx=4'd2; rb_idx=4'd3;            alu_op=ADDCU;  selB_imm=1'b0; end
        S_ADDCU_W:  begin ra_idx=dst_reg(S_ADDCU_W);           alu_op=ADDCU;  wEnable=1'b1; end

        S_ADDCUI_R: begin ra_idx=4'd2;                         alu_op=ADDCUI; selB_imm=1'b1; immB=16'd1; end
        S_ADDCUI_W: begin ra_idx=dst_reg(S_ADDCUI_W);          alu_op=ADDCUI; wEnable=1'b1; end

        S_ADDCI_R:  begin ra_idx=4'd2;                         alu_op=ADDCI;  selB_imm=1'b1; immB=16'd0; end
        S_ADDCI_W:  begin ra_idx=dst_reg(S_ADDCI_W);           alu_op=ADDCI;  wEnable=1'b1; end

        S_SUB_R:    begin ra_idx=4'd1; rb_idx=4'd0;            alu_op=SUB;    selB_imm=1'b0; end
        S_SUB_W:    begin ra_idx=dst_reg(S_SUB_W);             alu_op=SUB;    wEnable=1'b1; end

        S_SUBI_R:   begin ra_idx=4'd1;                         alu_op=SUBI;   selB_imm=1'b1; immB=16'd2; end
        S_SUBI_W:   begin ra_idx=dst_reg(S_SUBI_W);            alu_op=SUBI;   wEnable=1'b1; end

        S_CMP_R:    begin ra_idx=4'd0; rb_idx=4'd1;            alu_op=CMP;    selB_imm=1'b0; end
        S_CMP_W:    begin ra_idx=dst_reg(S_CMP_W);             alu_op=CMP;    wEnable=1'b1; end

        S_CMPI_R:   begin ra_idx=4'd0;                         alu_op=CMPI;   selB_imm=1'b1; immB=16'd5; end
        S_CMPI_W:   begin ra_idx=dst_reg(S_CMPI_W);            alu_op=CMPI;   wEnable=1'b1; end

        S_CMPU_R:   begin ra_idx=4'd0; rb_idx=4'd1;            alu_op=CMPU;   selB_imm=1'b0; end
        S_CMPU_W:   begin ra_idx=dst_reg(S_CMPU_W);            alu_op=CMPU;   wEnable=1'b1; end

        S_CMPUI_R:  begin ra_idx=4'd0;                         alu_op=CMPUI;  selB_imm=1'b1; immB=16'd6; end
        S_CMPUI_W:  begin ra_idx=dst_reg(S_CMPUI_W);           alu_op=CMPUI;  wEnable=1'b1; end

        S_AND_R:    begin ra_idx=4'd4; rb_idx=4'd5;            alu_op=AND_;   selB_imm=1'b0; end
        S_AND_W:    begin ra_idx=dst_reg(S_AND_W);             alu_op=AND_;   wEnable=1'b1; end

        S_OR_R:     begin ra_idx=4'd4; rb_idx=4'd5;            alu_op=OR_;    selB_imm=1'b0; end
        S_OR_W:     begin ra_idx=dst_reg(S_OR_W);              alu_op=OR_;    wEnable=1'b1; end

        S_XOR_R:    begin ra_idx=4'd4; rb_idx=4'd5;            alu_op=XOR_;   selB_imm=1'b0; end
        S_XOR_W:    begin ra_idx=dst_reg(S_XOR_W);             alu_op=XOR_;   wEnable=1'b1; end

        S_NOT_R:    begin ra_idx=4'd4;                         alu_op=NOT_;   selB_imm=1'b0; end
        S_NOT_W:    begin ra_idx=dst_reg(S_NOT_W);             alu_op=NOT_;   wEnable=1'b1; end

        S_LSH_R:    begin ra_idx=4'd0; rb_idx=4'd3;            alu_op=LSH;    selB_imm=1'b0; end
        S_LSH_W:    begin ra_idx=dst_reg(S_LSH_W);             alu_op=LSH;    wEnable=1'b1; end

        S_LSHI_R:   begin ra_idx=4'd0;                         alu_op=LSHI;   selB_imm=1'b1; immB=16'd4; end
        S_LSHI_W:   begin ra_idx=dst_reg(S_LSHI_W);            alu_op=LSHI;   wEnable=1'b1; end

        S_RSH_R:    begin ra_idx=4'd0; rb_idx=4'd3;            alu_op=RSH;    selB_imm=1'b0; end
        S_RSH_W:    begin ra_idx=dst_reg(S_RSH_W);             alu_op=RSH;    wEnable=1'b1; end

        S_RSHI_R:   begin ra_idx=4'd0;                         alu_op=RSHI;   selB_imm=1'b1; immB=16'd3; end
        S_RSHI_W:   begin ra_idx=dst_reg(S_RSHI_W);            alu_op=RSHI;   wEnable=1'b1; end

        S_ALSH_R:   begin ra_idx=4'd0; rb_idx=4'd3;            alu_op=ALSH;   selB_imm=1'b0; end
        S_ALSH_W:   begin ra_idx=dst_reg(S_ALSH_W);            alu_op=ALSH;   wEnable=1'b1; end

        S_ARSH_R:   begin ra_idx=4'd0; rb_idx=4'd3;            alu_op=ARSH;   selB_imm=1'b0; end
        S_ARSH_W:   begin ra_idx=dst_reg(S_ARSH_W);            alu_op=ARSH;   wEnable=1'b1; end

        S_NOP_R:    begin ra_idx=4'd0;                         alu_op=NOP;    selB_imm=1'b0; end
        S_NOP_W:    begin ra_idx=dst_reg(S_NOP_W);             alu_op=NOP;    wEnable=1'b1; end

        default: begin end
      endcase
    end

endmodule


// Wrapper identical shape to your Fib_FSM (drop-in replacement in a testbench)
module ALL_FSM (
    input  wire        clk,
    input  wire        rst,
    output wire [15:0] alu_out,
    output wire [4:0]  flags
);
  wire [3:0] ra_idx, rb_idx;
  wire       wEnable;
  wire [7:0] alu_op;
  wire       selB_imm;
  wire [15:0] immB;

  FSM_ALU_All u_fsm (
    .clk     (clk),
    .rst     (rst),
    .ra_idx  (ra_idx),
    .rb_idx  (rb_idx),
    .wEnable (wEnable),
    .alu_op  (alu_op),
    .selB_imm(selB_imm),
    .immB    (immB)
  );

  RegALU uRegALU (
    .clk      (clk),
    .reset    (rst),
    .wEnable  (wEnable),
    .ra_idx   (ra_idx),
    .rb_idx   (rb_idx),
    .opcode   (alu_op),
    .immB     (immB),
    .selB_imm (selB_imm),
    .alu_out  (alu_out),
    .flags    (flags)
  );
endmodule
