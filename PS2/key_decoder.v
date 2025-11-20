// key_decoder.v
// Convert 1-byte PS/2 scan code → WASD / Space / R key press pulse
module key_decoder (
    input  wire clk,
    input  wire rst,

    input  wire [7:0] data_in,     // data_out from ps2_keyboard
    input  wire       data_ready,  // data_ready from ps2_keyboard (1-clock pulse)

    output reg        w_press,
    output reg        a_press,
    output reg        s_press,
    output reg        d_press,
    output reg        space_press,
    output reg        r_press
);

    // Scan code constants (Set 2 — modify if needed)
    localparam [7:0] SC_F0    = 8'hF0;
    localparam [7:0] SC_W     = 8'h1D;
    localparam [7:0] SC_A     = 8'h1C;
    localparam [7:0] SC_S     = 8'h1B;
    localparam [7:0] SC_D     = 8'h23;
    localparam [7:0] SC_R     = 8'h2D;
    localparam [7:0] SC_SPACE = 8'h29;

    reg break_pending;  // Indicates that the previous byte was F0 (break prefix)

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            break_pending <= 1'b0;
            w_press       <= 1'b0;
            a_press       <= 1'b0;
            s_press       <= 1'b0;
            d_press       <= 1'b0;
            space_press   <= 1'b0;
            r_press       <= 1'b0;
        end else begin
            // Default: all pulses inactive
            w_press     <= 1'b0;
            a_press     <= 1'b0;
            s_press     <= 1'b0;
            d_press     <= 1'b0;
            space_press <= 1'b0;
            r_press     <= 1'b0;

            if (data_ready) begin
                if (!break_pending) begin
                    // No break code pending
                    if (data_in == SC_F0) begin
                        // Next byte will be break code
                        break_pending <= 1'b1;
                    end else begin
                        // Process make codes (key press)
                        case (data_in)
                            SC_W:     w_press     <= 1'b1;
                            SC_A:     a_press     <= 1'b1;
                            SC_S:     s_press     <= 1'b1;
                            SC_D:     d_press     <= 1'b1;
                            SC_SPACE: space_press <= 1'b1;
                            SC_R:     r_press     <= 1'b1;
                            default:  ; // Ignore other keys
                        endcase
                    end
                end else begin
                    // Previous byte was F0 → this is a break code
                    // We don't use key-release, so just clear flag
                    break_pending <= 1'b0;
                end
            end
        end
    end

endmodule
