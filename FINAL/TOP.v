module TOP (
    input  wire CLOCK_50,
    input  wire KEY0,      // active-low reset

    // PS/2 pins
    input  wire PS2_CLK,
    input  wire PS2_DAT,

    // VGA output
    output wire        VGA_SYNC,
    output wire        VGA_CLK,
    output wire        VGA_BLANK,
    output wire        VGA_HS,
    output wire        VGA_VS,
    output wire [3:0]  VGA_R,
    output wire [3:0]  VGA_G,
    output wire [3:0]  VGA_B
);

    wire rst = ~KEY0;

    // Keyboard status bus from PS2
    wire [5:0] ps2_key_status;

    // -----------------------------------------------------------
    // CPU core
    // -----------------------------------------------------------
    CPU_Control uCPU (
        .clk        (CLOCK_50),
        .rst        (rst),
        .key_status (ps2_key_status)
        //
    );

    // -----------------------------------------------------------
    // PS/2 keyboard module
    // -----------------------------------------------------------
    PS2 uPS2 (
        .CLOCK_50       (CLOCK_50),
        .KEY0           (KEY0),
        .PS2_CLK        (PS2_CLK),
        .PS2_DAT        (PS2_DAT),
        .key_status_out (ps2_key_status)
    );

    // -----------------------------------------------------------
    // VGA controller 
    // -----------------------------------------------------------
    topVGA uVGA (
        .CLOCK_50 (CLOCK_50),
        .clear    (rst),

        .sync     (VGA_SYNC),
        .clk      (VGA_CLK),
        .blank    (VGA_BLANK),
        .hSync    (VGA_HS),
        .vSync    (VGA_VS),

        .red      (VGA_R),
        .green    (VGA_G),
        .blue     (VGA_B)
    );

endmodule


