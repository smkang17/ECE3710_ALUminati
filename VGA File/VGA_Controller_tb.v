`timescale 1ns / 1ps

module VGA_Controller_tb;

    reg clock;
    reg clear;
    wire hSync;
    wire vSync;
    wire bright;
    wire [9:0] hCount;
    wire [9:0] vCount;

    integer error_count = 0;

    // Instantiate the VGA controller
    VGA_Controller uut (
        .clock(clock),
        .clear(clear),
        .hSync(hSync),
        .vSync(vSync),
        .bright(bright),
        .hCount(hCount),
        .vCount(vCount)
    );

    // Clock generation: 100 MHz
    initial clock = 0;
    always #5 clock = ~clock;  // 10 ns period (100 MHz)

    // Clear pulse
    initial begin
        clear = 1;
        #20;
        clear = 0;
    end

    // VGA timing parameters
    localparam H_VISIBLE = 640;
    localparam H_FRONT   = 16;
    localparam H_SYNC    = 96;
    localparam H_BACK    = 48;
    localparam H_TOTAL   = H_VISIBLE + H_FRONT + H_SYNC + H_BACK;

    localparam V_VISIBLE = 480;
    localparam V_FRONT   = 10;
    localparam V_SYNC    = 2;
    localparam V_BACK    = 33;
    localparam V_TOTAL   = V_VISIBLE + V_FRONT + V_SYNC + V_BACK;

    // Error checking
    always @(posedge clock) begin
        if (!clear) begin
            // Brightness check
            if (bright && (hCount >= H_VISIBLE || vCount >= V_VISIBLE)) begin
                error_count = error_count + 1;
            end

            // Horizontal sync
            if ((hCount >= H_VISIBLE + H_FRONT && hCount < H_VISIBLE + H_FRONT + H_SYNC && hSync !== 0) ||
                (hCount < H_VISIBLE + H_FRONT || hCount >= H_VISIBLE + H_FRONT + H_SYNC) && hSync !== 1) begin
                error_count = error_count + 1;
            end

            // Vertical sync
            if ((vCount >= V_VISIBLE + V_FRONT && vCount < V_VISIBLE + V_FRONT + V_SYNC && vSync !== 0) ||
                (vCount < V_VISIBLE + V_FRONT || vCount >= V_VISIBLE + V_FRONT + V_SYNC) && vSync !== 1) begin
                error_count = error_count + 1;
            end
        end
    end

    // Simulation stop & summary
    initial begin
        #100000; // run simulation for 100 us (adjust if needed)
        if (error_count == 0) begin
            $display("SIMULATION PASSED: No errors detected!");
        end else begin
            $display("SIMULATION FAILED: %0d errors detected.", error_count);
        end
        $stop;
    end

endmodule
