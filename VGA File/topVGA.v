module topVGA(
	input clock,
	input clear,
	
	output hSync,
	output vSync,
	output [3:0] red,
	output [3:0] green,
	output [3:0] blue
);

	wire [9:0] hCount, vCount;
	wire bright;
	
	VGA_Controller vc(
		.clock(clock),
		.clear(clear),
		.hSync(hSync),
		.vSync(vSync),
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
