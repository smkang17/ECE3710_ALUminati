`timescale 1ns/1ps

// ======================================================================
// Testbench: tb_cpu_ps2_bram
// - Instantiates the top-level CPU
// - Forces PS2 scan_code / scan_ready inside uPS2
// - Checks that:
//     1) PS2 key_status_out matches CPU_Control key_status
//     2) BRAM Port-A read (mem_dout) at STATUS_ADDR matches key_status
// ======================================================================
module tb_ps2_status;

    // ------------------------------------------------------------------
    // DUT top-level I/O
    // ------------------------------------------------------------------
    reg  CLOCK_50;
    reg  KEY0;
    reg  PS2_CLK;
    reg  PS2_DAT;

    wire VGA_SYNC;
    wire VGA_CLK;
    wire VGA_BLANK;
    wire VGA_HS;
    wire VGA_VS;
    wire [3:0] VGA_R;
    wire [3:0] VGA_G;
    wire [3:0] VGA_B;

    // ------------------------------------------------------------------
    // Instantiate DUT
    //  - Assumes your top-level is named "CPU"
    //  - Assumes it contains instances:
    //      PS2        uPS2
    //      CPU_Control uCPU
    // ------------------------------------------------------------------
    CPU dut (
        .CLOCK_50 (CLOCK_50),
        .KEY0     (KEY0),
        .PS2_CLK  (PS2_CLK),
        .PS2_DAT  (PS2_DAT),
        .VGA_SYNC (VGA_SYNC),
        .VGA_CLK  (VGA_CLK),
        .VGA_BLANK(VGA_BLANK),
        .VGA_HS   (VGA_HS),
        .VGA_VS   (VGA_VS),
        .VGA_R    (VGA_R),
        .VGA_G    (VGA_G),
        .VGA_B    (VGA_B)
    );

    // ------------------------------------------------------------------
    // Local copy of STATUS_ADDR
    //  - Must match the localparam in CPU_Control
    // ------------------------------------------------------------------
    localparam [15:0] STATUS_ADDR = 16'h03F0;

    // ------------------------------------------------------------------
    // Shortcuts to internal signals (for display/debug)
    // ------------------------------------------------------------------
    // PS2.v output (from ps2_status)
    wire [5:0] ps2_status;
    assign ps2_status = dut.uPS2.key_status_out;

    // CPU_Control input port
    wire [5:0] cpu_status;
    assign cpu_status = dut.uCPU.key_status;

    // BRAM Port-A read data as seen by CPU_Control
    wire [15:0] mem_dout;
    assign mem_dout = dut.uCPU.mem_dout;

    // ------------------------------------------------------------------
    // Clock generation: 50 MHz (20 ns period)
    // ------------------------------------------------------------------
    initial begin
        CLOCK_50 = 1'b0;
        forever #10 CLOCK_50 = ~CLOCK_50;
    end

    // ------------------------------------------------------------------
    // Reset and default values
    // ------------------------------------------------------------------
    initial begin
        KEY0    = 1'b0;  // active-low reset asserted
        PS2_CLK = 1'b0;
        PS2_DAT = 1'b0;

        // Hold reset for a few cycles
        repeat (5) @(posedge CLOCK_50);
        KEY0 = 1'b1;     // release reset

        // Wait a bit after reset
        repeat (5) @(posedge CLOCK_50);

        // Run the test sequence
        test_sequence();

        // Finish simulation
        #200;
        $display("=== End of tb_cpu_ps2_bram ===");
        $finish;
    end

    // ------------------------------------------------------------------
    // Task: send one PS/2 scan code into uPS2
    //  - Uses hierarchical force on scan_code / scan_ready regs
    // ------------------------------------------------------------------
    task send_code(input [7:0] code);
    begin
        // Drive internal regs of PS2.v
        force dut.uPS2.scan_code  = code;
        force dut.uPS2.scan_ready = 1'b1;

        @(posedge CLOCK_50);

        force dut.uPS2.scan_ready = 1'b0;
        @(posedge CLOCK_50);

        // Release the forces so internal logic can take over again
        release dut.uPS2.scan_code;
        release dut.uPS2.scan_ready;
    end
    endtask

    // ------------------------------------------------------------------
    // Task: sample status from PS2, CPU, and BRAM at STATUS_ADDR
    //  - Forces mem_addr to STATUS_ADDR and disables mem_WE for one cycle
    //    so mem_dout reflects the status register contents
    // ------------------------------------------------------------------
    task show_status(input [127:0] label);
    begin
        // Override CPU_Control's memory address and write enable
        force dut.uCPU.mem_addr = STATUS_ADDR;
        force dut.uCPU.mem_WE   = 1'b0;

        @(posedge CLOCK_50);

        $display("%s time=%0t  PS2=%06b  CPU=%06b  MEM=%06b",
                 label, $time, ps2_status, cpu_status, mem_dout[5:0]);

        // Release overrides
        release dut.uCPU.mem_addr;
        release dut.uCPU.mem_WE;
    end
    endtask

    // ------------------------------------------------------------------
    // Main test sequence
    //  - Assumes scan codes:
    //      W     = 0x1D
    //      A     = 0x1C
    //      S     = 0x1B
    //      D     = 0x23
    //      Space = 0x29
    //      R     = 0x2D
    //      Break prefix = 0xF0
    // ------------------------------------------------------------------
    task test_sequence;
    begin
        // 1) Press W (make)
        $display("=== Press W (make: 0x1D) ===");
        send_code(8'h1D);
        show_status("After W make     ");

        // 2) Release W (break: F0, 1D)
        $display("=== Release W (break: F0, 1D) ===");
        send_code(8'hF0);
        send_code(8'h1D);
        show_status("After W break    ");

        // 3) Press Space (0x29)
        $display("=== Press Space (make: 0x29) ===");
        send_code(8'h29);
        show_status("After Space make ");

        // 4) Release Space (break: F0, 29)
        $display("=== Release Space (break: F0, 29) ===");
        send_code(8'hF0);
        send_code(8'h29);
        show_status("After Space break");

        // 5) Press W + D together
        $display("=== Press W + D (make: 1D, 23) ===");
        send_code(8'h1D);   // W
        send_code(8'h23);   // D
        show_status("After W + D make ");
    end
    endtask

endmodule
