module VGA_Bitgen (
	input wire clock, bright, slowPulse
	input wire [9:0] hCount, vCount, xLocation, yLocation,
	input wire [7:0] pixelData,
	
	output wire [7:0] rgb
	
	// clock, slowPulse, x and y locations are not needed
);

	// We can do three different techniques
	// Bitmapped graphics -- not worth it, takes too much memory
	// Character/glyph graphics
	// Direct graphics
	
	// Colors we can get using 3-bits
	// black, blue, green, cyan, red, magenta, yellow, white

endmodule