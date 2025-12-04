//=========================================================
// topVGA
// - Top-level module for VGA + PS2 + CPU + BRAM
//=========================================================
module topVGA(
    input wire clk,          // 50 MHz board clock
    input wire reset,        // Active-high reset

    input wire PS2_CLK,
    input wire PS2_DAT,

    output wire [3:0] r,
    output wire [3:0] g,
    output wire [3:0] b,
    output wire vga_hs,
    output wire vga_vs,
    output wire vga_blank,
    output wire vga_sync,
    output wire vga_clk
);

    //=====================================================
    // 25 MHz pixel clock (divide by 2 from 50 MHz)
    //=====================================================
    reg clk_25 = 0;
    always @(posedge clk) clk_25 <= ~clk_25;

    //=====================================================
    // VGA timing generator
    //=====================================================
    wire bright;
    wire [9:0] hCount, vCount;

    VGA_Controller VC (
        .clock (clk_25),
        .clear (reset),      // active-high reset
        .sync  (vga_sync),
        .clk   (vga_clk),
        .blank (vga_blank),
        .hSync (vga_hs),
        .vSync (vga_vs),
        .bright(bright),
        .hCount(hCount),
        .vCount(vCount)
    );

    //=====================================================
    // Memory interface wires (BRAM port A)
    //=====================================================
    wire [15:0] mem_addr;   // CPU -> BRAM A address
    wire [15:0] mem_din;    // CPU -> BRAM A write data
    wire [15:0] mem_dout;   // CPU <- BRAM read data
    wire        mem_WE;     // CPU -> BRAM A write enable

    wire [15:0] bram_q_a;   // Raw BRAM A output
    wire [15:0] bram_q_b;   // Raw BRAM B output

    wire [9:0]  addr_b;     // VGA -> BRAM B address
    wire [15:0] q_b;        // BRAM B -> VGA data

    //=====================================================
    // PS2 keyboard interface
    //=====================================================
    wire [7:0] scan_code;
    wire       scan_ready;

    ps2_keyboard keyboard_hw (
        .clk      (clk),
        .rst      (!reset),      // depends on your PS2 module (active-low here)
        .ps2_clk  (PS2_CLK),
        .ps2_data (PS2_DAT),
        .data_out (scan_code),
        .data_ready(scan_ready)
    );

    wire [5:0] key_status;
    ps2_status ps2stat (
        .clk       (clk),
        .rst       (!reset),     // same polarity as keyboard_hw
        .scan_code (scan_code),
        .scan_ready(scan_ready),
        .key_status(key_status)
    );

    //=====================================================
    // PS2 status word (goes DIRECTLY to CPU as ps2_data)
    //=====================================================
    wire [15:0] ps2_word = {10'b0, key_status};

    //=====================================================
    // Dual-port BRAM
    //  - Port A: CPU (clk_25)
    //  - Port B: VGA (clk_25, read-only)
//=====================================================
    Bram uBram (
        .clk   (clk_25),

        // Port A (CPU)
        .data_a(mem_din),
        .data_b(16'h0000),       // Unused for CPU, used on port B
        .addr_a(mem_addr[9:0]),
        .addr_b(addr_b),
        .we_a  (mem_WE),
        .we_b  (1'b0),           // VGA side is read-only
        .q_a   (bram_q_a),
        .q_b   (q_b)
    );

    // mem_dout is now ONLY BRAM data (no PS2 mux here)
    assign mem_dout = bram_q_a;

    //=====================================================
    // CPU core and control (runs at clk_25)
//  - Uses mem_addr/mem_din/mem_dout/mem_WE
//  - Also receives ps2_word as ps2_data, which becomes R15
//=====================================================
    CPU_Control cpu (
        .clk      (clk_25),
        .rst      (reset),
        .ps2_data (ps2_word),   // ★ NEW: PS2 goes directly into CPU
        .mem_addr (mem_addr),
        .mem_din  (mem_din),
        .mem_dout (mem_dout),
        .mem_WE   (mem_WE)
    );

    //=====================================================
    // VGA sprite renderer (reads BRAM via port B)
    //=====================================================
    vgaFSM fsm (
        .clk    (clk_25),
        .reset    (reset),
        .bright (bright),
        .hCount (hCount),
        .vCount (vCount),

        .q_b    (q_b),
        .addr_b (addr_b),

		  .key_status(key_status),
		  
        .r      (r),
        .g      (g),
        .b      (b)
    );

endmodule
