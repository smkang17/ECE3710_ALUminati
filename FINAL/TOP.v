module CPU (
    input  wire CLOCK_50,   
    input  wire RESET_N,    

    // PS/2 
    input  wire PS2_CLK,
    input  wire PS2_DAT,

    // VGA
    output wire [3:0] r,
    output wire [3:0] g,
    output wire [3:0] b,
    output wire       vga_hs,
    output wire       vga_vs,
    output wire       vga_blank,
    output wire       vga_sync,
    output wire       vga_clk
);

    wire reset = ~RESET_N;

    // =====================================
    // CPU 
    // =====================================
    CPU_Control u_cpu_ctrl (
        .clk (CLOCK_50),
        .rst (reset)
    );

    // =====================================
    // VGA + PS2 
    // =====================================
    topVGA u_top_vga (
        .clk      (CLOCK_50),
        .reset    (!reset),

        .PS2_CLK  (PS2_CLK),
        .PS2_DAT  (PS2_DAT),

        .r        (r),
        .g        (g),
        .b        (b),
        .vga_hs   (vga_hs),
        .vga_vs   (vga_vs),
        .vga_blank(vga_blank),
        .vga_sync (vga_sync),
        .vga_clk  (vga_clk)
    );

endmodule
