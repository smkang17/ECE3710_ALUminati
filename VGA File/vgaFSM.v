module vgaFSM (
    input wire clk,
    input wire reset,

    input wire bright,
    input wire [9:0] hCount,
    input wire [9:0] vCount,
	 
	 input wire [5:0] key_status,
    input wire [15:0] q_b,
    output reg [9:0] addr_b,

    output reg [3:0] r,
    output reg [3:0] g,
    output reg [3:0] b
);
	
	 // SpriteROMs
    localparam PLAYER_W = 32;
    localparam PLAYER_H = 32;
    localparam OBS_W    = 16;
    localparam OBS_H    = 16;
    localparam MAX_OBS  = 15; // We can increase num of obstacles later if needed

    reg [PLAYER_W-1:0] playerGlyph [0:PLAYER_H-1];
    initial begin
        playerGlyph[0]  = 32'b11111111111111111111111111111111;
        playerGlyph[1]  = 32'b11111111111111111111111111111111;
        playerGlyph[2]  = 32'b11111111111111111111111111111111;
        playerGlyph[3]  = 32'b11100000000000000000000000000111;
        playerGlyph[4]  = 32'b11100000000000000000000000000111;
        playerGlyph[5]  = 32'b11100000000000000000000000000111;
        playerGlyph[6]  = 32'b11100000000000000000000000000111;
        playerGlyph[7]  = 32'b11100000000000000000000000000111;
        playerGlyph[8]  = 32'b11100000000000000000000000000111;
        playerGlyph[9]  = 32'b11100000000000000000000000000111;
        playerGlyph[10] = 32'b11100001111000000000011110000111;
        playerGlyph[11] = 32'b11100001111000000000011110000111;
        playerGlyph[12] = 32'b11100001111000000000011110000111;
        playerGlyph[13] = 32'b11100001111000000000011110000111;
        playerGlyph[14] = 32'b11100000000000000000000000000111;
        playerGlyph[15] = 32'b11100000000000000000000000000111;
        playerGlyph[16] = 32'b11100000000000000000000000000111;
        playerGlyph[17] = 32'b11100000000000000000000000000111;
        playerGlyph[18] = 32'b11100000000000000000000000000111;
        playerGlyph[19] = 32'b11100000000000000000000000000111;
        playerGlyph[20] = 32'b11100000000111111111100000000111;
        playerGlyph[21] = 32'b11100000000111111111100000000111;
        playerGlyph[22] = 32'b11100000000000000000000000000111;
        playerGlyph[23] = 32'b11100000000000000000000000000111;
        playerGlyph[24] = 32'b11100000000000000000000000000111;
        playerGlyph[25] = 32'b11100000000000000000000000000111;
        playerGlyph[26] = 32'b11100000000000000000000000000111;
        playerGlyph[27] = 32'b11100000000000000000000000000111;
        playerGlyph[28] = 32'b11100000000000000000000000000111;
        playerGlyph[29] = 32'b11111111111111111111111111111111;
        playerGlyph[30] = 32'b11111111111111111111111111111111;
        playerGlyph[31] = 32'b11111111111111111111111111111111;
    end

    reg [OBS_W-1:0] obsGlyph [0:OBS_H-1];
    initial begin
        obsGlyph[0]  = 16'b0000001111000000;
        obsGlyph[1]  = 16'b0000111111110000;
        obsGlyph[2]  = 16'b0001110000111000;
        obsGlyph[3]  = 16'b0011000000001100;
        obsGlyph[4]  = 16'b0110000000000110;
        obsGlyph[5]  = 16'b1100000000000011;
        obsGlyph[6]  = 16'b1100000000000011;
        obsGlyph[7]  = 16'b1100000000000011;
        obsGlyph[8]  = 16'b1100000000000011;
        obsGlyph[9]  = 16'b1100000000000011;
        obsGlyph[10] = 16'b0110000000000110;
        obsGlyph[11] = 16'b0011000000001100;
        obsGlyph[12] = 16'b0001110000111000;
        obsGlyph[13] = 16'b0000111111110000;
        obsGlyph[14] = 16'b0000001111000000;
        obsGlyph[15] = 16'b0000000000000000;
    end

	 
	 // Sprite position registers
    reg [15:0] sprite_count; // addr 0

    reg [9:0] player_x;		  // addr 1
    reg [9:0] player_y;		  // addr 2

    reg [9:0] obs_x [0:MAX_OBS-1];
    reg [9:0] obs_y [0:MAX_OBS-1];
	 reg obs_dir [0:MAX_OBS-1]; // Moving logic for obstacles, 0 = left/up, 1 = right/down

	 
	 // Load positions from Bram (LOAD FSM)
    localparam L_IDLE   = 3'd0;
    localparam L_COUNT  = 3'd1;
    localparam L_X      = 3'd2;
    localparam L_Y      = 3'd3;
    localparam L_DONE   = 3'd4;

    reg [2:0] load_state;
    reg [4:0] load_index;   // which sprite we are on (0 = player)
    reg [9:0] temp_x;       // holds x while we read y

    integer i, k;

    wire loaded = (load_state == L_DONE);

    always @(posedge clk) begin
        if (!reset) begin
            load_state   <= L_IDLE;
            addr_b       <= 10'd0;
            load_index   <= 5'd0;
            sprite_count <= 16'd0;

            player_x <= 10'd0;
            player_y <= 10'd0;
            for (i = 0; i < MAX_OBS; i = i + 1) begin
                obs_x[i] <= 10'd0;
                obs_y[i] <= 10'd0;
					 obs_dir[i] <= 1'b0;
            end
        end else begin
            case (load_state)
                // set addr_b = 0, wait one cycle for q_b
                L_IDLE: begin
                    addr_b     <= 10'd0;
                    load_index <= 5'd0;
                    load_state <= L_COUNT;
                end

                // Read sprite_count from q_b
                L_COUNT: begin
                    sprite_count <= q_b;      // total sprite
                    addr_b       <= 10'd1;    // next: X for sprite 0 (player)
                    load_state   <= L_X;
                end

                // Read X for current sprite (addr_b already set previous cycle)
                L_X: begin
                    temp_x <= q_b[9:0];       // latch X
                    addr_b <= addr_b + 10'd1; // move to Y address
                    load_state <= L_Y;
                end

                // Read Y and store X/Y into the right registers
                L_Y: begin
                    if (load_index == 5'd0) begin
                        // sprite 0 = player
                        player_x <= temp_x;
                        player_y <= q_b[9:0];
                    end else if (load_index - 1 < MAX_OBS) begin
                        // sprites 1..15 = obstacles
                        obs_x[load_index - 1] <= temp_x;
                        obs_y[load_index - 1] <= q_b[9:0];
                    end

                    load_index <= load_index + 5'd1;

                    // More sprites to load? (and cap at our MAX)
                    if ( (load_index + 5'd1) < sprite_count &&
                         (load_index + 5'd1) < (MAX_OBS + 1) ) begin
                        addr_b     <= addr_b + 10'd1; // next X
                        load_state <= L_X;
                    end else begin
                        load_state <= L_DONE;
                    end
                end

                // Stay here forever; positions now come only from registers
						L_DONE: begin
							 // Once loading is done, we apply movement logic
							 if (hCount == 0 && vCount == 0) begin
								  // Player movement
								  // W = up
								  if (key_status[0] && player_y > 0)
										player_y <= player_y - 2;
						
								  // S = down
								  if (key_status[2] && player_y < (480 - PLAYER_H))
										player_y <= player_y + 2;
						
								  // A = left
								  if (key_status[1] && player_x > 0)
										player_x <= player_x - 2;
						
								  // D = right
								  if (key_status[3] && player_x < (640 - PLAYER_W))
										player_x <= player_x + 2;
						
								  // Obstacle movement
								  // even index -> horizontal
								  // odd index  -> vertical
									for (k = 0; k < MAX_OBS; k = k + 1) begin
										 // Horizontal movers: k even
										 if (k[0] == 1'b0) begin
											  if (obs_dir[k] == 1'b0) begin
													// moving left
													if (obs_x[k] > 0)
														 obs_x[k] <= obs_x[k] - 1;
													else begin
														 obs_x[k]   <= 0;        // stay at left edge
														 obs_dir[k] <= 1'b1;     // now move right
													end
											  end else begin
													// moving right
													if (obs_x[k] < (640 - OBS_W))
														 obs_x[k] <= obs_x[k] + 1;
													else begin
														 obs_x[k]   <= 640 - OBS_W; // stay at right edge
														 obs_dir[k] <= 1'b0;        // now move left
													end
											  end
										 end
										 // Vertical movers: k odd
										 else begin
											  if (obs_dir[k] == 1'b0) begin
													// moving up
													if (obs_y[k] > 0)
														 obs_y[k] <= obs_y[k] - 1;
													else begin
														 obs_y[k]   <= 0;        // stay at top
														 obs_dir[k] <= 1'b1;     // now move down
													end
											  end else begin
													// moving down
													if (obs_y[k] < (480 - OBS_H))
														 obs_y[k] <= obs_y[k] + 1;
													else begin
														 obs_y[k]   <= 480 - OBS_H; // stay at bottom
														 obs_dir[k] <= 1'b0;        // now move up
													end
											  end
										 end
									end
							 end
						end
					default: load_state <= L_IDLE;
            endcase
        end
    end


	 // Draw (per-pixel, using registers)
    reg player_pixel;
    reg obs_pixel;

    integer j;

    always @(*) begin
        player_pixel = 1'b0;
        obs_pixel    = 1'b0;

        if (bright && loaded) begin
            // Player
            if (hCount >= player_x && hCount < player_x + PLAYER_W &&
                vCount >= player_y && vCount < player_y + PLAYER_H) begin

                player_pixel =
                    playerGlyph[vCount - player_y]
                               [PLAYER_W-1 - (hCount - player_x)];
            end

            // Obstacles
            for (j = 0; j < MAX_OBS; j = j + 1) begin
                if (hCount >= obs_x[j] && hCount < obs_x[j] + OBS_W &&
                    vCount >= obs_y[j] && vCount < obs_y[j] + OBS_H) begin

                    if (obsGlyph[vCount - obs_y[j]]
                               [OBS_W-1 - (hCount - obs_x[j])])
                        obs_pixel = 1'b1;
                end
            end
        end
    end

    // Final RGB output
    always @(posedge clk) begin
        if (!reset) begin
            {r,g,b} <= 12'h000;
        end else if (!bright || !loaded) begin
            // Before loaded is true, or outside visible: black
            {r,g,b} <= 12'h000;
        end else if (player_pixel) begin
            // Player: white
            {r,g,b} <= 12'hFFF;
        end else if (obs_pixel) begin
            // Obstacles: red (you can change)
            {r,g,b} <= {4'hF, 4'h0, 4'h0};
        end else begin
            // Background: black
            {r,g,b} <= 12'h000;
        end
    end

endmodule
