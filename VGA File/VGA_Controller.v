module VGA_Controller (
	input wire clock,
	input wire clear,
	
	output sync,
	output clk,
	output blank,
	output reg hSync, 
	output reg vSync, 
	output reg bright,
	
	output reg [9:0] hCount, 
	output reg [9:0] vCount
);
	
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
		if (!clear) begin
			hCounter <= 0;
			vCounter <= 0;
		end
		else begin
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
	
	assign sync = 1'b_0;
	assign clk = clock;
	assign blank = hSync & vSync;
	
endmodule
