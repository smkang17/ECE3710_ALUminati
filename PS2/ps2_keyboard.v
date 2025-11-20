// PS/2 keyboard receiver: Reads an 11-bit frame and outputs 8-bit data + a 1-cycle ready pulse.
module ps2_keyboard (
    input  wire clk,        // System clock (e.g., 50 MHz)
    input  wire rst,        // Asynchronous reset, active-high

    input  wire ps2_clk,    // PS/2 clock pin
    input  wire ps2_data,   // PS/2 data pin

    output reg  [7:0] data_out,   // Received 1-byte scan code
    output reg        data_ready  // 1-clock pulse when new data is available
);

    // Synchronize PS2 clock + detect falling edge

    reg [2:0] ps2c_sync;
    always @(posedge clk or posedge rst) begin
        if (rst)
            ps2c_sync <= 3'b111;
        else
            ps2c_sync <= {ps2c_sync[1:0], ps2_clk};
    end

    wire ps2c_fall = (ps2c_sync[2:1] == 2'b10);  // Detect 1 -> 0 transition

    // Registers for receiving the 11-bit PS/2 frame

    reg [3:0] bit_cnt;      // bit index: 0..10
    reg       start_bit;
    reg [7:0] data_bits;
    reg       parity_bit;
    reg       stop_bit;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            bit_cnt    <= 4'd0;
            start_bit  <= 1'b1;
            data_bits  <= 8'h00;
            parity_bit <= 1'b0;
            stop_bit   <= 1'b1;
            data_out   <= 8'h00;
            data_ready <= 1'b0;
        end 
        else begin
            data_ready <= 1'b0;  // Default: ready pulse lasts only 1 cycle

            if (ps2c_fall) begin
                case (bit_cnt)
                    4'd0: begin
                        // Start bit
                        start_bit <= ps2_data;
                    end

                    4'd1: data_bits[0] <= ps2_data; // LSB first
                    4'd2: data_bits[1] <= ps2_data;
                    4'd3: data_bits[2] <= ps2_data;
                    4'd4: data_bits[3] <= ps2_data;
                    4'd5: data_bits[4] <= ps2_data;
                    4'd6: data_bits[5] <= ps2_data;
                    4'd7: data_bits[6] <= ps2_data;
                    4'd8: data_bits[7] <= ps2_data; // MSB

                    4'd9: begin
                        // Parity bit (stored but not checked here)
                        parity_bit <= ps2_data;
                    end

                    4'd10: begin
                        // Stop bit
                        stop_bit <= ps2_data;

                        // Valid frame: start=0 and stop=1
                        if (start_bit == 1'b0 && ps2_data == 1'b1) begin
                            data_out   <= data_bits;
                            data_ready <= 1'b1;
                        end
                    end
                endcase

                // Increment/reset bit counter
                if (bit_cnt == 4'd10)
                    bit_cnt <= 4'd0;
                else
                    bit_cnt <= bit_cnt + 4'd1;
            end
        end
    end

endmodule
