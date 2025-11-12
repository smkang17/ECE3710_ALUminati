module RegBank(
    input         clk,
    input         reset,
    input  [15:0] wData,         
    input  [15:0] regEnable,     
    input  [3:0]  ra_idx,        
    input  [3:0]  rb_idx,        
    output reg [15:0] busA,
    output reg [15:0] busB_reg
);
    wire [15:0] reg_data [0:15];

    genvar i;
    generate
        for (i=0; i<16; i=i+1) begin : GEN_REG
            Register u_reg (
                .D_in    (wData),
                .wEnable (regEnable[i]),
                .reset   (reset),
                .clk     (clk),
                .r       (reg_data[i])
            );
        end
    endgenerate

    always @(ra_idx, rb_idx, reset) begin
        if (reset) begin
            busA     = 16'h0000;
            busB_reg = 16'h0000;
        end else begin
            case (ra_idx)
                4'd0:  busA = reg_data[0];
                4'd1:  busA = reg_data[1];
                4'd2:  busA = reg_data[2];
                4'd3:  busA = reg_data[3];
                4'd4:  busA = reg_data[4];
                4'd5:  busA = reg_data[5];
                4'd6:  busA = reg_data[6];
                4'd7:  busA = reg_data[7];
                4'd8:  busA = reg_data[8];
                4'd9:  busA = reg_data[9];
                4'd10: busA = reg_data[10];
                4'd11: busA = reg_data[11];
                4'd12: busA = reg_data[12];
                4'd13: busA = reg_data[13];
                4'd14: busA = reg_data[14];
                4'd15: busA = reg_data[15];
                default: busA = 16'h0000;
            endcase

            case (rb_idx)
                4'd0:  busB_reg = reg_data[0];
                4'd1:  busB_reg = reg_data[1];
                4'd2:  busB_reg = reg_data[2];
                4'd3:  busB_reg = reg_data[3];
                4'd4:  busB_reg = reg_data[4];
                4'd5:  busB_reg = reg_data[5];
                4'd6:  busB_reg = reg_data[6];
                4'd7:  busB_reg = reg_data[7];
                4'd8:  busB_reg = reg_data[8];
                4'd9:  busB_reg = reg_data[9];
                4'd10: busB_reg = reg_data[10];
                4'd11: busB_reg = reg_data[11];
                4'd12: busB_reg = reg_data[12];
                4'd13: busB_reg = reg_data[13];
                4'd14: busB_reg = reg_data[14];
                4'd15: busB_reg = reg_data[15];
                default: busB_reg = 16'h0000;
            endcase
        end
    end
endmodule
