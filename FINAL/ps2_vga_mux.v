module ps2_vga_mux (
	input mux_sel,
	input [9:0] vga_addr,
	output reg [9:0] addr,
	output reg We
);
	
	
	localparam [9:0] ps2_addr = 10'h3FF;

	// We mux
	always @(mux_sel) begin
		case (mux_sel)
			1'b0:    We = 0;
			1'b1:    We = 1;
			default: We = 0;
		endcase
	end
	
	
	//addr mux
	always @(mux_sel or vga_addr or ps2_addr) begin
		case (mux_sel)
			1'b0:    addr = vga_addr;
			1'b1:    addr = ps2_addr;
			default: addr = vga_addr;
		endcase
	end
endmodule