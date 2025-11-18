module VGA_Controller (
	input wire clock, 				// 100 MHz clock
	input wire clear,
	
	output reg hSync, 
	output reg vSync, 
	output reg bright,
	
	output reg [9:0] hCount, 
	output reg [9:0] vCount
);
	// This module controls the counters
	
	/*
		Horizontal timing:
			0 -> 639: 		visible pixels
			640 -> 655: 	front porch
			656 -> 751: 	sync pulse (hSync low)
			752 -> 799: 	back porch
			
		Vertical timing:
			0 -> 479:		visible lines
			480 -> 489:		front porch
			490 -> 491:		sync pulse (vSync low)
			492 -> 524:		back porch
	*/
	

	// 25 MHz Enable Pulse for counter
	reg [1:0] divider = 0;
	wire enable = (divider == 0);
	
	always @(posedge clock) begin
		if (clear)
			divider <= 0;
		else 
			divider <= divider + 1;
	end
	
	
	// VGA timing parameters 
	// Horizontal
	localparam H_VISIBLE = 640;
	localparam H_FRONT 	= 16;
	localparam H_SYNC		= 96;
	localparam H_BACK 	= 48;
	localparam H_TOTAL 	= H_VISIBLE + H_FRONT + H_SYNC + H_BACK;	// 800
	
	// Vertical
	localparam V_VISIBLE	= 480;
	localparam V_FRONT	= 10;
	localparam V_SYNC 	= 2;
	localparam V_BACK		= 33;
	localparam V_TOTAL	= V_VISIBLE + V_FRONT + V_SYNC + V_BACK;	// 525


	// Counter (increments only on 25 MHz enable)
	// hCounter increments from 0 -> 800 then resets
	// vCounter increments from 0 -> 525 ONLY when hCounter completes a full cycle
	reg [9:0] hCounter = 0;
	reg [9:0] vCounter = 0;
	
	always @(posedge clock) begin
		if (clear) begin
			hCounter <= 0;
			vCounter <= 0;
		end
		else if (enable) begin
			if (hCounter == H_TOTAL - 1) begin
				hCounter <= 0;
				if (vCounter == V_TOTAL -1)
					vCounter <= 0;
				else
					vCounter <= vCounter + 1;
			end
			else 
				hCounter <= hCounter + 1;
	end


	// Sync pulses (active low)
	always @(posedge clock) begin
		// hSync low during sync interval
		hSync <= ~(hCounter >= (H_VISIBLE + H_FRONT) &&
						hCounter < (H_VISIBLE + H_FRONT + H_SYNC));
		
		// vSync low during sync interval
		vSync <= ~(vCounter >= (V_VISIBLE + V_FRONT) &&
						vCounter < (V_VISIBLE + V_FRONT + V_SYNC));
	end
	
	
	// Visible region and pixel coordinates
	always @(posedge clock) begin
		// bright = ONLY when in visible region
		bright <= (hCounter < H_VISIBLE) && (vCounter < V_VISIBLE);
		
		// pixel coordinates
			hCount <= hCounter;
			vCount <= vCounter;
	end
		
endmodule
