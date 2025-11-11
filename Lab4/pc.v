module pc (
    input  wire        clk,
    input  wire        rst,
    input  wire        PCe,
	 
	 input  wire		  PCsrc,			// 00: PC+1, 01: PC+disp, 10: Rtarget
	 input  wire		  branch_disp,
	 input  wire 		  Rtarget,
	 
    output reg [15:0]  pc_value
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            pc_value <= 16'h0000;
        else if (PCe) begin
				case(PCsrc)
					2'b00: pc_value <= pc_value + 16'h0001;
					2'b01: pc_value <= pc_value + branch_disp;
					2'b10: pc_value <= Rtarget;
					default: pc_value <= pc_value + 16'h0001;
				endcase
		  end
    end
endmodule
