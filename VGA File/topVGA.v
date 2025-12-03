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

    reg clk_25 = 0;
    always @(posedge clk) clk_25 <= ~clk_25;

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
	 
	 wire [9:0] addr_b;
	 wire [15:0] q_b;
	
	Bram bram (
		 .clk(clk_25),
		 .addr_b(addr_b),
		 .q_b(q_b),
		 .we_b(1'b0),
	);

	vgaFSM fsm (
		 .clk(clk_25),
		 .reset(reset),
		 .bright(bright),
		 .hCount(hCount),
		 .vCount(vCount),
	
		 .q_b(q_b),            // from BRAM port B
		 .addr_b(addr_b),      // to BRAM port B
	
		 .r(r),
		 .g(g),
		 .b(b)
	);



endmodule
