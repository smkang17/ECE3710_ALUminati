///fib_fsm  (rd_idx removed; destination is always ra_idx)
module FSM (
    input  wire       clk, rst,
    output reg  [3:0] ra_idx, rb_idx,        // rd_idx removed
    output reg        wEnable,
    output reg  [7:0] alu_op,
    output reg        selB_imm,
    output reg [15:0] immB
);

    localparam
      S_INIT0_R = 6'd0,  S_INIT0_W = 6'd1,
      S_INIT1_R = 6'd2,  S_INIT1_W = 6'd3,
      S_K2_R    = 6'd4,  S_K2_W    = 6'd5,
      S_K3_R    = 6'd6,  S_K3_W    = 6'd7,
      S_K4_R    = 6'd8,  S_K4_W    = 6'd9,
      S_K5_R    = 6'd10, S_K5_W    = 6'd11,
      S_K6_R    = 6'd12, S_K6_W    = 6'd13,
      S_K7_R    = 6'd14, S_K7_W    = 6'd15,
      S_K8_R    = 6'd16, S_K8_W    = 6'd17,
      S_K9_R    = 6'd18, S_K9_W    = 6'd19,
      S_K10_R   = 6'd20, S_K10_W   = 6'd21,
      S_K11_R   = 6'd22, S_K11_W   = 6'd23,
      S_K12_R   = 6'd24, S_K12_W   = 6'd25,
      S_K13_R   = 6'd26, S_K13_W   = 6'd27,
      S_K14_R   = 6'd28, S_K14_W   = 6'd29,
      S_K15_R   = 6'd30, S_K15_W   = 6'd31,
      S_DONE    = 6'd63;

    reg [5:0] y;  // state

    always @(posedge clk) begin
        if (rst) y <= S_INIT0_R;
        else case (y)
            S_INIT0_R: y <= S_INIT0_W;
            S_INIT0_W: y <= S_INIT1_R;
            S_INIT1_R: y <= S_INIT1_W;
            S_INIT1_W: y <= S_K2_R;

            S_K2_R:  y <= S_K2_W;   S_K2_W:  y <= S_K3_R;
            S_K3_R:  y <= S_K3_W;   S_K3_W:  y <= S_K4_R;
            S_K4_R:  y <= S_K4_W;   S_K4_W:  y <= S_K5_R;
            S_K5_R:  y <= S_K5_W;   S_K5_W:  y <= S_K6_R;
            S_K6_R:  y <= S_K6_W;   S_K6_W:  y <= S_K7_R;
            S_K7_R:  y <= S_K7_W;   S_K7_W:  y <= S_K8_R;
            S_K8_R:  y <= S_K8_W;   S_K8_W:  y <= S_K9_R;
            S_K9_R:  y <= S_K9_W;   S_K9_W:  y <= S_K10_R;
            S_K10_R: y <= S_K10_W;  S_K10_W: y <= S_K11_R;
            S_K11_R: y <= S_K11_W;  S_K11_W: y <= S_K12_R;
            S_K12_R: y <= S_K12_W;  S_K12_W: y <= S_K13_R;
            S_K13_R: y <= S_K13_W;  S_K13_W: y <= S_K14_R;
            S_K14_R: y <= S_K14_W;  S_K14_W: y <= S_K15_R;
            S_K15_R: y <= S_K15_W;  S_K15_W: y <= S_DONE;

            default:  y <= S_DONE;
        endcase
    end

    //(Moore)
    always @(y) begin
        // Defaults
        ra_idx   = 4'd0;
        rb_idx   = 4'd0;
        wEnable  = 1'b0;
        alu_op   = 8'b00000101;     
        selB_imm = 1'b0;
        immB     = 16'h0000;

        case (y)
            // R0 <- 0  (dest == ra_idx)
            S_INIT0_R: begin
                ra_idx   = 4'd0;      // A reads R0 (currently 0 after reset)
                selB_imm = 1'b1;      // use immediate on B
                immB     = 16'h0000;  // +0
                // wEnable=0 (READ phase)
            end
            S_INIT0_W: begin
                ra_idx   = 4'd0;      // WRITE goes to R0 (dest==ra_idx)
                selB_imm = 1'b1;
                immB     = 16'h0000;
                wEnable  = 1'b1;      // WRITE phase
            end

            // R1 <- 1
            S_INIT1_R: begin
                ra_idx   = 4'd1;      // A reads R1 (0 after reset)
                selB_imm = 1'b1;
                immB     = 16'h0001;  // +1
            end
            S_INIT1_W: begin
                ra_idx   = 4'd1;      // WRITE goes to R1
                selB_imm = 1'b1;
                immB     = 16'h0001;
                wEnable  = 1'b1;
            end

            // From here on:
            // READ state: set ra_idx/rb_idx to source registers
            // WRITE state: set ra_idx to the (former) destination register
            // (Because RegALU writes to ra_idx when wEnable=1)

            // R2 <- R0 + R1
            S_K2_R:  begin ra_idx=4'd0; rb_idx=4'd1; selB_imm=1'b0; end
            S_K2_W:  begin ra_idx=4'd2;              selB_imm=1'b0; wEnable=1'b1; end

            // R3 <- R1 + R2
            S_K3_R:  begin ra_idx=4'd1; rb_idx=4'd2; selB_imm=1'b0; end
            S_K3_W:  begin ra_idx=4'd3;              selB_imm=1'b0; wEnable=1'b1; end

            S_K4_R:  begin ra_idx=4'd2; rb_idx=4'd3; selB_imm=1'b0; end
            S_K4_W:  begin ra_idx=4'd4;              selB_imm=1'b0; wEnable=1'b1; end

            S_K5_R:  begin ra_idx=4'd3; rb_idx=4'd4; selB_imm=1'b0; end
            S_K5_W:  begin ra_idx=4'd5;              selB_imm=1'b0; wEnable=1'b1; end

            S_K6_R:  begin ra_idx=4'd4; rb_idx=4'd5; selB_imm=1'b0; end
            S_K6_W:  begin ra_idx=4'd6;              selB_imm=1'b0; wEnable=1'b1; end

            S_K7_R:  begin ra_idx=4'd5; rb_idx=4'd6; selB_imm=1'b0; end
            S_K7_W:  begin ra_idx=4'd7;              selB_imm=1'b0; wEnable=1'b1; end

            S_K8_R:  begin ra_idx=4'd6; rb_idx=4'd7; selB_imm=1'b0; end
            S_K8_W:  begin ra_idx=4'd8;              selB_imm=1'b0; wEnable=1'b1; end

            S_K9_R:  begin ra_idx=4'd7; rb_idx=4'd8; selB_imm=1'b0; end
            S_K9_W:  begin ra_idx=4'd9;              selB_imm=1'b0; wEnable=1'b1; end

            S_K10_R: begin ra_idx=4'd8; rb_idx=4'd9;  selB_imm=1'b0; end
            S_K10_W: begin ra_idx=4'd10;             selB_imm=1'b0; wEnable=1'b1; end

            S_K11_R: begin ra_idx=4'd9;  rb_idx=4'd10; selB_imm=1'b0; end
            S_K11_W: begin ra_idx=4'd11;              selB_imm=1'b0; wEnable=1'b1; end

            S_K12_R: begin ra_idx=4'd10; rb_idx=4'd11; selB_imm=1'b0; end
            S_K12_W: begin ra_idx=4'd12;              selB_imm=1'b0; wEnable=1'b1; end

            S_K13_R: begin ra_idx=4'd11; rb_idx=4'd12; selB_imm=1'b0; end
            S_K13_W: begin ra_idx=4'd13;              selB_imm=1'b0; wEnable=1'b1; end

            S_K14_R: begin ra_idx=4'd12; rb_idx=4'd13; selB_imm=1'b0; end
            S_K14_W: begin ra_idx=4'd14;              selB_imm=1'b0; wEnable=1'b1; end

            S_K15_R: begin ra_idx=4'd13; rb_idx=4'd14; selB_imm=1'b0; end
            S_K15_W: begin ra_idx=4'd15;              selB_imm=1'b0; wEnable=1'b1; end

            default:  begin end
        endcase
    end
endmodule


module Fib_FSM (
    input  wire       clk,
    input  wire       rst,
    output wire [15:0] alu_out,
    output wire [4:0]  flags
);
    // Control wires from FSM
    wire [3:0] ra_idx;
    wire [3:0] rb_idx;
    wire       wEnable;
    wire [7:0] alu_op;
    wire       selB_imm;
    wire [15:0] immB;

    // FSM (drives the control of RegALU)
    FSM u_fsm (
        .clk     (clk),
        .rst     (rst),
        .ra_idx  (ra_idx),
        .rb_idx  (rb_idx),
        .wEnable (wEnable),
        .alu_op  (alu_op),
        .selB_imm(selB_imm),
        .immB    (immB)
    );

    // RegALU (contains RegBank + ALU)
    RegALU uRegALU (
        .clk      (clk),
        .reset    (rst),
        .wEnable  (wEnable),
        .ra_idx   (ra_idx),
        .rb_idx   (rb_idx),
        .opcode   (alu_op),   // FSM's ALU opcode
        .immB     (immB),
        .selB_imm (selB_imm),
        .alu_out  (alu_out),
        .flags    (flags)
    );
endmodule

