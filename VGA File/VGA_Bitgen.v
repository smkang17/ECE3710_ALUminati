module VGA_Bitgen (
	input bright,
	input [9:0] hCount,
	input [9:0] vCount,
	
	input [9:0] player_x,
	input [9:0] player_y,
	
	input [9:0] obs_x,
	input [9:0] obs_y,
	
	output [3:0] red,
	output [3:0] green,
	output [3:0] blue
);

	// Player size (width x height)
	localparam PLAYER_W = 40;
	localparam PLAYER_H = 40;
	
	// Obstacle size (width x height)
	localparam OBS_W = 20;
	localparam OBS_H = 80;
	
	// Check if inside player
	wire player_on = (hCount >= player_x) && (hCount < player_x + PLAYER_W) &&
						  (vCount >= player_y) && (vCount < player_y + PLAYER_H);
						  
	// Check if inside obstacle
	wire obs_on = (hCount >= obs_x) && (hCount < obs_x + OBS_W) &&
					  (vCount >= obs_y) && (vCount < obs_y + OBS_H);
					  
	// Output colors
	assign {red, green, blue} =
		!bright		? 12'h000 :		// outside visible area
		player_on	? 12'h0F0 :		// green player
		obs_on		? 12'hF00 :		// red obstacle
						  12'h00F;		// blue background

endmodule
