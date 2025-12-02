module PS2 (
    input  wire CLOCK_50,
    input  wire KEY0,        // active-low reset

    // Physical PS/2 pins (currently unused in this stub)
    input  wire PS2_CLK,
    input  wire PS2_DAT,

    // Export key status (W A S D Space R)
    output wire [5:0] key_status_out
);

    // Active-high reset
    wire rst = ~KEY0;

    // -----------------------------------------------------------------
    // STUB: scan_code / scan_ready
    // -----------------------------------------------------------------
    reg [7:0] scan_code;
    reg       scan_ready;

    always @(posedge CLOCK_50 or posedge rst) begin
        if (rst) begin
            scan_code  <= 8'h00;
            scan_ready <= 1'b0;
        end else begin
            scan_ready <= 1'b0;   // default: no PS/2 event
        end
    end


    // -----------------------------------------------------------------
    // Held-state key status bits (W A S D Space R)
    // -----------------------------------------------------------------
    wire [5:0] key_status;

    ps2_status u_status (
        .clk        (CLOCK_50),
        .rst        (rst),
        .scan_code  (scan_code),
        .scan_ready (scan_ready),
        .key_status (key_status)
    );

    // Output to CPU
    assign key_status_out = key_status;

endmodule

