module topVGA(
	input wire CLOCK_50,
	input wire clear,
	
	output wire sync,
	output wire clk,
	output wire blank,
	output wire hSync,
	output wire vSync,
	
	output wire [3:0] red,
	output wire [3:0] green,
	output wire [3:0] blue
);	
	
	wire [9:0] hCount, vCount;
	wire bright;
	
	 // -----------------------------
    // Generate ~25 MHz clock from 50 MHz
    // -----------------------------
    reg clk_25 = 0;
    always @(posedge CLOCK_50) clk_25 <= ~clk_25;
	
	VGA_Controller vc(
		.clock(clk_25),
		.clear(clear),
		.hSync(hSync),
		.vSync(vSync),
		.sync(sync),
		.clk(clk),
		.blank(blank),
		.hCount(hCount),
		.vCount(vCount),
		.bright(bright)
	);
	
	// Hard-coded positions for now:
	wire [9:0] player_x = 200;
	wire [9:0] player_y = 200;
	
	wire [9:0] obs_x = 400;
	wire [9:0] obs_y = 100;
	
	VGA_Bitgen bitgen(
		.bright(bright),
		.hCount(hCount),
		.vCount(vCount),
		
		.player_x(player_x),
		.player_y(player_y),
		
		.obs_x(obs_x),
		.obs_y(obs_y),
		
		.red(red),
		.green(green),
		.blue(blue)
	);

endmodule
