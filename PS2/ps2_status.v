module ps2_status (
    input  wire       clk,
    input  wire       rst,

    input  wire [7:0] scan_code,   // data_out  
    input  wire       scan_ready,  // data_ready (1-clock pulse)

    // key_status bits:
    // [0] = W
    // [1] = A
    // [2] = S
    // [3] = D
    // [4] = Space
    // [5] = R
    output reg  [5:0] key_status
);

    // PS2 scan codes
    localparam [7:0] SC_F0    = 8'hF0;
    localparam [7:0] SC_W     = 8'h1D;
    localparam [7:0] SC_A     = 8'h1C;
    localparam [7:0] SC_S     = 8'h1B;
    localparam [7:0] SC_D     = 8'h23;
    localparam [7:0] SC_R     = 8'h2D;
    localparam [7:0] SC_SPACE = 8'h29;

    // When 0xF0 is received, the next scan code is a BREAK (key release)
    reg break_pending;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            key_status    <= 6'b000000;
            break_pending <= 1'b0;
        end 
        else if (scan_ready) begin
            // Detect BREAK prefix
            if (scan_code == SC_F0) begin
                // Next scan code will indicate key release
                break_pending <= 1'b1;
            end 
            else begin
                // MAKE:  break_pending == 0 → key pressed  → bit = 1
                // BREAK: break_pending == 1 → key released → bit = 0
                case (scan_code)
                    SC_W: begin
                        // W key
                        key_status[0] <= (break_pending ? 1'b0 : 1'b1);
                    end

                    SC_A: begin
                        // A key
                        key_status[1] <= (break_pending ? 1'b0 : 1'b1);
                    end

                    SC_S: begin
                        // S key
                        key_status[2] <= (break_pending ? 1'b0 : 1'b1);
                    end

                    SC_D: begin
                        // D key
                        key_status[3] <= (break_pending ? 1'b0 : 1'b1);
                    end

                    SC_SPACE: begin
                        // Space bar
                        key_status[4] <= (break_pending ? 1'b0 : 1'b1);
                    end

                    SC_R: begin
                        // R key
                        key_status[5] <= (break_pending ? 1'b0 : 1'b1);
                    end

                    default: begin
                        // Ignore other keys
                    end
                endcase

                // After handling this scan code, clear break_pending
                break_pending <= 1'b0;
            end
        end
    end

endmodule