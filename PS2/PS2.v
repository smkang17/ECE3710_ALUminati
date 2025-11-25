//PS/2 keyboard input to key pulses, LEDs, HEX display, and game controller

module PS2 (
    input  wire        CLOCK_50,
    input  wire        KEY0,        // Board push button KEY[0], active-low
    input  wire        PS2_CLK,
    input  wire        PS2_DAT,

    output wire [9:0]  LEDR,
    output wire [6:0]  HEX0,
    output wire [6:0]  HEX1
);

    // Reset signal
    wire rst = ~KEY0;


    // PS/2 scan-code receiver
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

    // Store last scan code for HEX display
    reg [7:0] last_code;
    always @(posedge CLOCK_50 or posedge rst) begin
        if (rst)
            last_code <= 8'h00;
        else if (scan_ready)
            last_code <= scan_code;
    end


    // Press pulses, original decoder, still used by game_controller
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

    // Game controller 
    wire [2:0] dir;
    wire       game_run;
    wire       game_reset_pulse;
    wire       game_over = 1'b0;

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


    // Key status register (HOLD state) ps2_status
    wire [5:0] key_status;

    ps2_status u_ps2_status (
        .clk        (CLOCK_50),
        .rst        (rst),
        .scan_code  (scan_code),
        .scan_ready (scan_ready),
        .key_status (key_status)
    );

    // LEDs show key_status directly
    // key_status[0] = W
    // key_status[1] = A
    // key_status[2] = S
    // key_status[3] = D
    // key_status[4] = Space
    // key_status[5] = R

    assign LEDR[0] = key_status[0]; // W
    assign LEDR[1] = key_status[1]; // A
    assign LEDR[2] = key_status[2]; // S
    assign LEDR[3] = key_status[3]; // D
    assign LEDR[4] = key_status[4]; // Space
    assign LEDR[5] = key_status[5]; // R

    // Game state LEDs
    assign LEDR[6] = game_run;
    assign LEDR[7] = ~game_run;

    assign LEDR[9:8] = 2'b00;

    // 7-seg HEX decoder
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

    // HEX output (unchanged)
    wire [15:0] display_value;
    assign display_value[7:0]  = last_code;
    assign display_value[15:8] = 8'h00;

    assign HEX1 = ~hex7seg_ah(display_value[7:4]);
    assign HEX0 = ~hex7seg_ah(display_value[3:0]);

endmodule
