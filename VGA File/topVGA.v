module topVGA(
    input  wire clk,
    input  wire reset,
    output wire [3:0] r,
    output wire [3:0] g,
    output wire [3:0] b,
    output wire vga_hs,
    output wire vga_vs,
    output wire vga_blank,
    output wire vga_sync,
    output wire vga_clk
);

    // -----------------------------
    // 25 MHz pixel clock (toggle)
    // -----------------------------
    reg clk_25 = 0;
    always @(posedge clk) clk_25 <= ~clk_25;

    // -----------------------------
    // VGA controller
    // -----------------------------
    wire bright;
    wire [9:0] hCount, vCount;

    VGA_Controller VC (
        .clock(clk_25),
        .clear(reset),
        .sync(vga_sync),
        .clk(vga_clk),
        .blank(vga_blank),
        .hSync(vga_hs),
        .vSync(vga_vs),
        .bright(bright),
        .hCount(hCount),
        .vCount(vCount)
    );
// ======================
// BRAM
// ======================
wire [15:0] bram_q;
reg  [15:0] bram_d = 0;   // unused for now
wire [9:0]  bram_addr;

Bram #(.DATA_WIDTH(16), .ADDR_WIDTH(10)) BRAM (
    .data_a(bram_d),
    .addr_a(bram_addr),
    .we_a(1'b0),
    .clk(clk_25),
    .q_a(bram_q),

    .data_b(16'b0),
    .addr_b(10'b0),
    .we_b(1'b0),
    .q_b()
);


// ======================
// Sprite Renderer
// ======================
SpriteRenderer renderer (
    .clk(clk_25),
	 .rst(reset),
    .hCount(hCount),
    .vCount(vCount),
    .bright(bright),
    .bram_addr(bram_addr),
    .bram_data(bram_q),
    .r(r),
    .g(g),
    .b(b)
);

endmodule
