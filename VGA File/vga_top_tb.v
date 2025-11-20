`timescale 1ns/1ps

module vga_top_tb;

    // Testbench signals
    reg clock;
    reg clear;
    wire hSync, vSync;
    wire [3:0] red, green, blue;

    // Instantiate DUT
    topVGA dut(
        .clock(clock),
        .clear(clear),
        .hSync(hSync),
        .vSync(vSync),
        .red(red),
        .green(green),
        .blue(blue)
    );

    // Clock generation: 100 MHz
    initial clock = 0;
    always #5 clock = ~clock;

    // Reset
    initial begin
        clear = 1;
        #20;
        clear = 0;
    end

    // Error counter for the current frame
    integer frame_errors = 0;
    integer total_frames = 0;
    integer total_errors = 0;

    // Full-frame pixel validation, only when bright is active
    always @(posedge clock) begin
        if (!clear && dut.vc.bright) begin
            // Player rectangle
            if ((dut.vc.hCount >= 200 && dut.vc.hCount < 200+40) &&
                (dut.vc.vCount >= 200 && dut.vc.vCount < 200+40)) begin
                if (!(red == 0 && green == 15 && blue == 0)) begin
                    frame_errors = frame_errors + 1;
                end
            end
            // Obstacle rectangle
            else if ((dut.vc.hCount >= 400 && dut.vc.hCount < 400+20) &&
                     (dut.vc.vCount >= 100 && dut.vc.vCount < 100+80)) begin
                if (!(red == 15 && green == 0 && blue == 0)) begin
                    frame_errors = frame_errors + 1;
                end
            end
            // Background
            else begin
                if (!(red == 0 && green == 0 && blue == 15)) begin
                    frame_errors = frame_errors + 1;
                end
            end
        end
    end

    // Detect end of frame (vSync pulse)
    reg vSync_last = 0;
    always @(posedge clock) begin
        if (!vSync_last && dut.vSync) begin
            // vSync rising edge: new frame starting
            total_frames = total_frames + 1;
            total_errors = total_errors + frame_errors;
            if (frame_errors == 0) begin
                $display("Frame %0d: PASS", total_frames);
            end else begin
                $display("Frame %0d: FAIL with %0d pixel errors", total_frames, frame_errors);
            end
            frame_errors = 0;
        end
        vSync_last <= dut.vSync;
    end

    // Run simulation for a few frames
    initial begin
        #5000000; // adjust depending on frame count / resolution
        $display("Simulation finished after %0d frames with %0d total errors.", 
                 total_frames, total_errors);
        $stop;
    end

endmodule
