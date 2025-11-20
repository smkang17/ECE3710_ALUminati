// PS2.v
// Top-level module: PS/2 keyboard input → key pulses, LEDs, HEX display, and game controller

module PS2 (
    input  wire        CLOCK_50,
    input  wire        KEY0,        // Board push button KEY[0], active-low
    input  wire        PS2_CLK,
    input  wire        PS2_DAT,

    output wire [9:0]  LEDR,
    output wire [6:0]  HEX0,
    output wire [6:0]  HEX1
    //output wire [6:0]  HEX2,
    //output wire [6:0]  HEX3
);

    // Reset signal
    wire rst = ~KEY0;

    // PS2 scan-code receiver
    wire [7:0] scan_code;
    wire       scan_ready;

    ps2_keyboard u_ps2 (
        .clk        (CLOCK_50),
        .rst        (rst),
        .ps2_clk    (PS2_CLK),
        .ps2_data   (PS2_DAT),
        .data_out   (scan_code),
        .data_ready (scan_ready)
    );

    // Register to store the most recent scan code for HEX display
    reg [7:0] last_code;
    always @(posedge CLOCK_50 or posedge rst) begin
        if (rst)
            last_code <= 8'h00;
        else if (scan_ready)
            last_code <= scan_code;
    end


    // Scan-code for W/A/S/D/Space/R press pulses
    wire w_press, a_press, s_press, d_press;
    wire space_press, r_press;

    key_decoder u_dec (
        .clk         (CLOCK_50),
        .rst         (rst),
        .data_in     (scan_code),
        .data_ready  (scan_ready),
        .w_press     (w_press),
        .a_press     (a_press),
        .s_press     (s_press),
        .d_press     (d_press),
        .space_press (space_press),
        .r_press     (r_press)
    );

    // Game controller for RUN/STOP & direction (W/A/S/D for now)

    wire [2:0] dir;               // Not used for outputs here, but available for game logic
    wire       game_run;          // 1 = running, 0 = stopped
    wire       game_reset_pulse;  // One-clock reset pulse for internal game logic
    wire       game_over;

    // game_over has no death logic yet
    assign game_over = 1'b0;

    game_controller u_game_ctrl (
        .clk              (CLOCK_50),
        .rst              (rst),
        .w_press          (w_press),
        .a_press          (a_press),
        .s_press          (s_press),
        .d_press          (d_press),
        .space_press      (space_press),
        .r_press          (r_press),
        .game_over        (game_over),
        .dir              (dir),
        .game_run         (game_run),
        .game_reset_pulse (game_reset_pulse)
    );

    // LEDs, last pressed key (one-hot) + game state
    // key_leds encoding: {R, SPACE, D, S, A, W}
    reg [5:0] key_leds;

    always @(posedge CLOCK_50 or posedge rst) begin
        if (rst) begin
            key_leds <= 6'b000000;
        end else begin
            // Priority: whichever key was pressed most recently
            if (w_press)          key_leds <= 6'b000001; // W
            else if (a_press)     key_leds <= 6'b000010; // A
            else if (s_press)     key_leds <= 6'b000100; // S
            else if (d_press)     key_leds <= 6'b001000; // D
            else if (space_press) key_leds <= 6'b010000; // Space
            else if (r_press)     key_leds <= 6'b100000; // R
            // If no key is pressed, keep previous value
        end
    end

    // Map key indications to LEDs
    assign LEDR[0] = key_leds[0]; // W
    assign LEDR[1] = key_leds[1]; // A
    assign LEDR[2] = key_leds[2]; // S
    assign LEDR[3] = key_leds[3]; // D
    assign LEDR[4] = key_leds[4]; // Space
    assign LEDR[5] = key_leds[5]; // R

    // Game state indication:
    // LEDR[6] = 1 when game is running
    // LEDR[7] = 1 when game is stopped
    assign LEDR[6] = game_run;       // RUN indicator
    assign LEDR[7] = ~game_run;      // STOP indicator

    // Unused upper bits (can be reused later)
    assign LEDR[9:8] = 2'b00;

    //7-seg HEX decoder
    function [6:0] hex7seg_ah;
        input [3:0] n;
        begin
            case (n)
                4'h0: hex7seg_ah = 7'b0111111; 4'h1: hex7seg_ah = 7'b0000110;
                4'h2: hex7seg_ah = 7'b1011011; 4'h3: hex7seg_ah = 7'b1001111;
                4'h4: hex7seg_ah = 7'b1100110; 4'h5: hex7seg_ah = 7'b1101101;
                4'h6: hex7seg_ah = 7'b1111101; 4'h7: hex7seg_ah = 7'b0000111;
                4'h8: hex7seg_ah = 7'b1111111; 4'h9: hex7seg_ah = 7'b1100111;
                4'hA: hex7seg_ah = 7'b1110111; 4'hB: hex7seg_ah = 7'b1111100;
                4'hC: hex7seg_ah = 7'b0111001; 4'hD: hex7seg_ah = 7'b1011110;
                4'hE: hex7seg_ah = 7'b1111001; 4'hF: hex7seg_ah = 7'b1110001;
                default: hex7seg_ah = 7'b0000000;
            endcase
        end
    endfunction

    // Show last_code on HEX1/HEX0 as a 2-digit hex value
    wire [15:0] display_value;
    assign display_value[7:0]  = last_code;
    assign display_value[15:8] = 8'h00;    // HEX2, HEX3 would be 0 if used

    //assign HEX3 = ~hex7seg_ah(display_value[15:12]); // 0
    //assign HEX2 = ~hex7seg_ah(display_value[11:8]);  // 0
    assign HEX1 = ~hex7seg_ah(display_value[7:4]);   // High nibble
    assign HEX0 = ~hex7seg_ah(display_value[3:0]);   // Low nibble

endmodule
