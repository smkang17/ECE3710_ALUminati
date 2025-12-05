//=========================================================
// vgaFSM
//=========================================================
module vgaFSM (
    input wire clk,
    input wire reset,          // active-low reset (!reset = reset)

    input wire bright,
    input wire [9:0] hCount,
    input wire [9:0] vCount,
    
    input wire [5:0] key_status,

    input  wire [15:0] q_b,
    output reg  [9:0]  addr_b,

    output reg [3:0] r,
    output reg [3:0] g,
    output reg [3:0] b
);

    localparam PLAYER_W = 32;
    localparam PLAYER_H = 32;
    localparam OBS_W    = 16;
    localparam OBS_H    = 16;
    localparam MAX_OBS  = 15;

    localparam [9:0] SPRITE_BASE = 10'd0;

    // ----------------------------------------------------
    // Color palette
    // ----------------------------------------------------
    reg [11:0] palette [0:15];
    initial begin
        palette[0]  = 12'h000;
        palette[1]  = 12'h000;
        palette[2]  = 12'hFFF;
        palette[3]  = 12'hCA3;
        palette[4]  = 12'hB90;
        palette[5]  = 12'hCB0;
        palette[6]  = 12'hBC3;
        palette[7]  = 12'hBCC;
        palette[8]  = 12'hEFF;
        palette[9]  = 12'h798;
        palette[10] = 12'h454;
        palette[11] = 12'h000;
        palette[12] = 12'h000;
        palette[13] = 12'h000;
        palette[14] = 12'h000;
        palette[15] = 12'h000;
    end

    // ----------------------------------------------------
    // Player sprite (32x32)
    // ----------------------------------------------------
    (* ramstyle = "M10K" *) reg [127:0] playerGlyph [0:PLAYER_H-1];
    initial begin
        playerGlyph[0]  = 128'h000000000000000FF000000000000000;
        playerGlyph[1]  = 128'h000000000000000FF000000000000000;
        playerGlyph[2]  = 128'h00000000000000F33F00000000000000;
        playerGlyph[3]  = 128'h00000000000000F33F00000000000000;
        playerGlyph[4]  = 128'h0000000000000F4444F0000000000000;
        playerGlyph[5]  = 128'h0000000000000F3333F0000000000000;
        playerGlyph[6]  = 128'h000000000000F333333F000000000000;
        playerGlyph[7]  = 128'h000000000000F433334F000000000000;
        playerGlyph[8]  = 128'h00000000000F34444443F00000000000;
        playerGlyph[9]  = 128'h00000000000F33333333F00000000000;
        playerGlyph[10] = 128'h0000000000F3333333333F0000000000;
        playerGlyph[11] = 128'h0000000000F4433333344F0000000000;
        playerGlyph[12] = 128'h000000000F334444444433F000000000;
        playerGlyph[13] = 128'h000000000F333333333333F000000000;
        playerGlyph[14] = 128'h00000000F433333FF333333F00000000;
        playerGlyph[15] = 128'h00000000F44333F22F33344F00000000;
        playerGlyph[16] = 128'h0000000F33444F2222F44433F0000000;
        playerGlyph[17] = 128'h0000000F33333F2222F33333F0000000;
        playerGlyph[18] = 128'h000000F333333F2222F333333F000000;
        playerGlyph[19] = 128'h000000F443333F2FF2F333344F000000;
        playerGlyph[20] = 128'h00000F3344333F2FF2F3334433F00000;
        playerGlyph[21] = 128'h00000F3334444F2FF2F4444333F00000;
        playerGlyph[22] = 128'h0000F33333333F2FF2F33333333F0000;
        playerGlyph[23] = 128'h0000F44333333F2222F33333344F0000;
        playerGlyph[24] = 128'h000F3344433333F22F3333344433F000;
        playerGlyph[25] = 128'h000F33334444444FF44444443333F000;
        playerGlyph[26] = 128'h00F33333333333333333333333333F00;
        playerGlyph[27] = 128'h00F44333333333333333333333344F00;
        playerGlyph[28] = 128'h0F3344443333333333333333444433F0;
        playerGlyph[29] = 128'h0F3333444444444444444444433333F0;
        playerGlyph[30] = 128'hF333333333333333333333333333333F;
        playerGlyph[31] = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    end

    // ----------------------------------------------------
    // Obstacle sprite (16x16)
    // ----------------------------------------------------
    (* ramstyle = "M10K" *) reg [127:0] obsGlyph [0:15];
    initial begin
         obsGlyph[0]  = 128'h00000000000000000000000000000000;
         obsGlyph[1]  = 128'h00000000000000000000000000000000;
         obsGlyph[2]  = 128'h00000000000000000000008887000000;
         obsGlyph[3]  = 128'h00000000000000000000088887700000;
         obsGlyph[4]  = 128'h00000000000000000000888887770000;
         obsGlyph[5]  = 128'h00000000000000000007888887777000;
         obsGlyph[6]  = 128'h00000000000000000007788877777000;
         obsGlyph[7]  = 128'h00000000000000000000777777770000;
         obsGlyph[8]  = 128'h00000000000000000999077777709990;
         obsGlyph[9]  = 128'h00000000000000000999500000059990;
         obsGlyph[10] = 128'h00000000000000000A995599995599A0;
         obsGlyph[11] = 128'h00000000000000000A999929929999A0;
         obsGlyph[12] = 128'h00000000000000000AAA99999999AAA0;
         obsGlyph[13] = 128'h000000000000000000AAAAAAAAAAAA00;
         obsGlyph[14] = 128'h00000000000000000000AAAAAAAA0000;
         obsGlyph[15] = 128'h00000000000000000000000000000000;
    end

    // ----------------------------------------------------
    // Title text (top of screen)
    // ----------------------------------------------------
    localparam TITLE_LEN = 15;
    localparam TITLE_X   = 252;
		
    reg [3:0] title_text [0:TITLE_LEN-1];
    initial begin
         title_text[0]  = 0;
         title_text[1]  = 1;
         title_text[2]  = 2;
         title_text[3]  = 3;
         title_text[4]  = 4;
         title_text[5]  = 5;
         title_text[6]  = 0;
         title_text[7]  = 6;
         title_text[8]  = 4;
         title_text[9]  = 4'd15;
         title_text[10] = 7;
         title_text[11] = 8;
         title_text[12] = 7;
         title_text[13] = 9;
         title_text[14] = 10;
    end
		
    wire [127:0] font_row;
    reg  [3:0]   font_sel;
    reg  [3:0]   font_row_index;
    wire [31:0]  font_row32;
    assign font_row32 = font_row[31:0];
		
    FontROM font_rom (
         .char_sel (font_sel),
         .row      (font_row_index),
         .glyph_row(font_row)
    );

    // ----------------------------------------------------
    // Sprite data from BRAM
    // ----------------------------------------------------
    reg [15:0] sprite_count;

    reg [9:0] player_x;
    reg [9:0] player_y;

    reg [9:0] obs_x  [0:MAX_OBS-1];
    reg [9:0] obs_y  [0:MAX_OBS-1];

    // New: per-obstacle direction for diagonal movement
    // obs_dir_x: 0 = left,  1 = right
    // obs_dir_y: 0 = up,    1 = down
    reg        obs_dir_x[0:MAX_OBS-1];
    reg        obs_dir_y[0:MAX_OBS-1];

    // ----------------------------------------------------
    // Game state
    // ----------------------------------------------------
    localparam [1:0] STATE_RUNNING   = 2'd0;
    localparam [1:0] STATE_PAUSED    = 2'd1;
    localparam [1:0] STATE_GAME_OVER = 2'd2;

    reg [1:0] game_state;
    reg       space_old;

    reg [15:0] frame_cnt;
    reg [3:0]  speed_level;
    reg [3:0]  active_obs;

    // Key mapping
    wire key_w     = key_status[0];
    wire key_a     = key_status[1];
    wire key_s     = key_status[2];
    wire key_d     = key_status[3];
    wire key_space = key_status[4];
    wire key_r     = key_status[5];

    // ----------------------------------------------------
    // BRAM load FSM (read sprite positions from BRAM port B)
    // ----------------------------------------------------
    localparam L_IDLE   = 3'd0;
    localparam L_COUNT  = 3'd1;
    localparam L_X      = 3'd2;
    localparam L_Y      = 3'd3;
    localparam L_DONE   = 3'd4;

    reg [2:0] load_state;
    reg [4:0] load_index;
    reg [9:0] temp_x;

    integer i, k, j, t;
    integer sx_p, sy_p, sx_o, sy_o;
    integer cx, px;
    integer bit_offset;
    integer step;
	 
    wire loaded = (load_state == L_DONE);

    // ----------------------------------------------------
    // Game update and BRAM loading
    // ----------------------------------------------------
    always @(posedge clk) begin
        if (!reset) begin
            load_state   <= L_IDLE;
            addr_b       <= SPRITE_BASE;
            load_index   <= 5'd0;
            sprite_count <= 16'd0;

            player_x <= 10'd0;
            player_y <= 10'd0;
            for (i = 0; i < MAX_OBS; i = i + 1) begin
                obs_x[i]     <= 10'd0;
                obs_y[i]     <= 10'd0;
                obs_dir_x[i] <= 1'b0;   // start moving left
                obs_dir_y[i] <= 1'b0;   // start moving up
            end

            game_state  <= STATE_RUNNING;
            space_old   <= 1'b0;
            frame_cnt   <= 16'd0;
            speed_level <= 4'd0;
            active_obs  <= 4'd2;  
        end else begin
            case (load_state)
                // -----------------------------------------
                // Read from BRAM at startup
                // -----------------------------------------
                L_IDLE: begin
                    addr_b     <= SPRITE_BASE;
                    load_index <= 5'd0;
                    load_state <= L_COUNT;
                end

                L_COUNT: begin
                    sprite_count <= q_b;
                    addr_b       <= SPRITE_BASE + 10'd1;
                    load_state   <= L_X;
                end

                L_X: begin
                    temp_x     <= q_b[9:0];
                    addr_b     <= addr_b + 10'd1;
                    load_state <= L_Y;
                end

                L_Y: begin
                    if (load_index == 5'd0) begin
                        player_x <= temp_x;
                        player_y <= q_b[9:0];
                    end else begin
                        if (load_index - 5'd1 < MAX_OBS) begin
                            obs_x[load_index - 5'd1] <= temp_x;
                            obs_y[load_index - 5'd1] <= q_b[9:0];
                        end
                    end

                    load_index <= load_index + 5'd1;

                    if (load_index + 5'd1 < sprite_count[4:0]) begin
                        addr_b     <= SPRITE_BASE + 10'd1 + (load_index + 5'd1)*10'd2;
                        load_state <= L_X;
                    end else begin
                        load_state <= L_DONE;
                    end
                end

                // -----------------------------------------
                // Game loop (after sprite positions loaded)
                // -----------------------------------------
                L_DONE: begin
                    // Update only once per frame (top-left pixel)
                    if (hCount == 0 && vCount == 0) begin
                        // R to reset game state and reload
                        if (key_r) begin
                            game_state  <= STATE_RUNNING;
                            space_old   <= 1'b0;
                            load_state  <= L_IDLE;
                            addr_b      <= SPRITE_BASE;
                            frame_cnt   <= 16'd0;
                            speed_level <= 4'd0;
                            active_obs  <= 4'd2;   
                        end else begin
                            // Space to pause / resume (edge-detected)
                            if (key_space && !space_old && game_state != STATE_GAME_OVER) begin
                                if (game_state == STATE_RUNNING)
                                    game_state <= STATE_PAUSED;
                                else if (game_state == STATE_PAUSED)
                                    game_state <= STATE_RUNNING;
                            end
                            space_old <= key_space;

                            if (game_state == STATE_RUNNING) begin
                                // Global frame counter and speed / number of active obstacles
                                frame_cnt <= frame_cnt + 16'd1;
                                if (frame_cnt == 16'd200) begin
                                    frame_cnt <= 16'd0;
                                    if (speed_level < 4'd5)
                                        speed_level <= speed_level + 4'd1;

                                    if (sprite_count > 16'd1 &&
                                        active_obs < 4'd15 &&
                                        active_obs < (sprite_count[3:0] - 4'd1))
                                        active_obs <= active_obs + 4'd1;
                                end

                                // -----------------------------
                                // Player movement (WASD)
                                // -----------------------------
                                if (key_w) begin
                                    if (player_y > 1)
                                        player_y <= player_y - 10'd2;
                                    else
                                        player_y <= 10'd0;
                                end

                                if (key_s) begin
                                    if (player_y + 10'd2 < (480 - PLAYER_H))
                                        player_y <= player_y + 10'd2;
                                    else
                                        player_y <= (480 - PLAYER_H);
                                end

                                if (key_a) begin
                                    if (player_x > 1)
                                        player_x <= player_x - 10'd2;
                                    else
                                        player_x <= 10'd0;
                                end

                                if (key_d) begin
                                    if (player_x + 10'd2 < (640 - PLAYER_W))
                                        player_x <= player_x + 10'd2;
                                    else
                                        player_x <= (640 - PLAYER_W);
                                end

                                // -----------------------------
                                // Obstacle movement (diagonal)
                                // -----------------------------
                                step = 1 + speed_level;

                                for (k = 0; k < MAX_OBS; k = k + 1) begin
                                    if (k < active_obs && k < (sprite_count - 1)) begin
                                        // Horizontal movement (X)
                                        if (obs_dir_x[k] == 1'b0) begin
                                            // moving left
                                            if (obs_x[k] > step)
                                                obs_x[k] <= obs_x[k] - step;
                                            else begin
                                                obs_x[k]     <= 0;
                                                obs_dir_x[k] <= 1'b1; // bounce → move right
                                            end
                                        end else begin
                                            // moving right
                                            if (obs_x[k] + OBS_W + step <= 640)
                                                obs_x[k] <= obs_x[k] + step;
                                            else begin
                                                obs_x[k]     <= 640 - OBS_W;
                                                obs_dir_x[k] <= 1'b0; // bounce → move left
                                            end
                                        end

                                        // Vertical movement (Y)
                                        if (obs_dir_y[k] == 1'b0) begin
                                            // moving up
                                            if (obs_y[k] > step)
                                                obs_y[k] <= obs_y[k] - step;
                                            else begin
                                                obs_y[k]     <= 0;
                                                obs_dir_y[k] <= 1'b1; // bounce → move down
                                            end
                                        end else begin
                                            // moving down
                                            if (obs_y[k] + OBS_H + step <= 480)
                                                obs_y[k] <= obs_y[k] + step;
                                            else begin
                                                obs_y[k]     <= 480 - OBS_H;
                                                obs_dir_y[k] <= 1'b0; // bounce → move up
                                            end
                                        end

                                        // Collision check
                                        if (game_state == STATE_RUNNING) begin
                                            if ( (player_x <  obs_x[k] + OBS_W) &&
                                                 (player_x + PLAYER_W > obs_x[k]) &&
                                                 (player_y <  obs_y[k] + OBS_H) &&
                                                 (player_y + PLAYER_H > obs_y[k]) ) begin
                                                game_state <= STATE_GAME_OVER;
                                            end
                                        end
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

    // ----------------------------------------------------
    // Sprite selection and pixel lookup
    // ----------------------------------------------------
    reg [3:0] sprite_index;
    reg [3:0] pix;

    always @(*) begin
        sprite_index   = 4'd0;   
        font_row_index = 4'b0;
        font_sel       = 4'd0;
        pix            = 4'd0;

        if (bright && loaded) begin
            // Player
            if (hCount >= player_x && hCount < player_x + PLAYER_W &&
                vCount >= player_y && vCount < player_y + PLAYER_H) begin

                sx_p = hCount - player_x;
                sy_p = vCount - player_y;

                pix = playerGlyph[sy_p][ ((PLAYER_W-1 - sx_p)*4) +: 4 ];
                if (pix != 4'd0)
                    sprite_index = pix;
            end

            // Obstacles
            for (j = 0; j < MAX_OBS; j = j + 1) begin
                if (j < active_obs && j < (sprite_count - 1)) begin
                    if (sprite_index == 4'd0) begin
                        if (hCount >= obs_x[j] && hCount < obs_x[j] + OBS_W &&
                            vCount >= obs_y[j] && vCount < obs_y[j] + OBS_H) begin

                            sx_o = hCount - obs_x[j];
                            sy_o = vCount - obs_y[j];

                            pix = obsGlyph[sy_o][ ((OBS_W-1 - sx_o)*4) +: 4 ];
                            if (pix != 4'd0)
                                sprite_index = pix;
                        end
                    end
                end
            end

            // Title text on top
            if (sprite_index == 4'd0 && vCount >= 4 && vCount < 12) begin
                font_row_index = vCount - 4;

                for (t = 0; t < TITLE_LEN; t = t + 1) begin
                    cx = TITLE_X + (t * 9);

                    if (hCount >= cx && hCount < cx + 8) begin
                        px = hCount - cx;

                        font_sel = title_text[t];
                        if (font_sel != 4'd15) begin
                            case (px)
                                0: pix = font_row32[3:0];
                                1: pix = font_row32[7:4];
                                2: pix = font_row32[11:8];
                                3: pix = font_row32[15:12];
                                4: pix = font_row32[19:16];
                                5: pix = font_row32[23:20];
                                6: pix = font_row32[27:24];
                                7: pix = font_row32[31:28];
                                default: pix = 4'd0;
                            endcase

                            if (pix != 4'd0 && sprite_index == 4'd0)
                                sprite_index = pix; 
                        end
                    end
                end
            end
        end
    end

    // ----------------------------------------------------
    // Final RGB output
    // ----------------------------------------------------
    always @(posedge clk) begin
        if (!reset) begin
            {r,g,b} <= 12'h000;
        end else if (!bright || !loaded || sprite_index == 4'd0) begin
            {r,g,b} <= 12'h000;
        end else begin
            {r,g,b} <= palette[sprite_index];
        end
    end

endmodule
