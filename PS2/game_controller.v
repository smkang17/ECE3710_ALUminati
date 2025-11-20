// game_controller.v
// Game state controller (start/stop/reset) + direction FSM based on keyboard input
module game_controller (
    input  wire clk,
    input  wire rst,            // Global board reset (active-high)

    // 1-clock pulses from key_decoder
    input  wire w_press,
    input  wire a_press,
    input  wire s_press,
    input  wire d_press,
    input  wire space_press,
    input  wire r_press,

    // Signal from game core: asserted when the player dies
    input  wire game_over,

    // Outputs: current direction + game state
    output reg  [2:0] dir,              // 0: none, 1: up, 2: down, 3: left, 4: right
    output reg        game_run,         // 1 = game running, 0 = stopped/paused
    output reg        game_reset_pulse  // 1-clock pulse for internal initialization
);

    // Direction codes
    localparam [2:0] DIR_NONE  = 3'd0;
    localparam [2:0] DIR_UP    = 3'd1;
    localparam [2:0] DIR_DOWN  = 3'd2;
    localparam [2:0] DIR_LEFT  = 3'd3;
    localparam [2:0] DIR_RIGHT = 3'd4;

    // State definitions
    localparam [1:0] ST_STOPPED = 2'd0;
    localparam [1:0] ST_RUNNING = 2'd1;

    reg [1:0] state;

    // State transitions, game_run, and reset pulse logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state            <= ST_STOPPED;
            game_run         <= 1'b0;
            game_reset_pulse <= 1'b1;   // Send reset once at power-up
        end else begin
            // Default: reset pulse is off unless triggered
            game_reset_pulse <= 1'b0;

            case (state)
                ST_STOPPED: begin
                    game_run <= 1'b0;

                    // In STOP state: pressing R triggers a reset pulse (game stays stopped)
                    if (r_press) begin
                        game_reset_pulse <= 1'b1;
                    end

                    // In STOP state: pressing Space starts the game
                    if (space_press) begin
                        state    <= ST_RUNNING;
                        game_run <= 1'b1;
                    end
                end

                ST_RUNNING: begin
                    game_run <= 1'b1;

                    // While running, Space pauses → transition to STOP
                    if (space_press) begin
                        state    <= ST_STOPPED;
                        game_run <= 1'b0;
                    end
                    // If game_over becomes 1 → game stops
                    else if (game_over) begin
                        state    <= ST_STOPPED;
                        game_run <= 1'b0;
                        // No auto-reset here; only pressing R should trigger reset pulse
                    end
                end

                default: begin
                    state    <= ST_STOPPED;
                    game_run <= 1'b0;
                end
            endcase
        end
    end

    // Direction register
    // - DIR resets to NONE on power-up or game_reset_pulse
    // - Direction updates only while RUNNING
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dir <= DIR_NONE;
        end else begin
            if (game_reset_pulse) begin
                dir <= DIR_NONE;
            end else if (game_run) begin
                if (w_press)      dir <= DIR_UP;
                else if (s_press) dir <= DIR_DOWN;
                else if (a_press) dir <= DIR_LEFT;
                else if (d_press) dir <= DIR_RIGHT;
            end
            // If STOPPED, keep the same direction (change if desired)
        end
    end

endmodule
