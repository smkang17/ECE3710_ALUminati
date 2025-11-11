module pc (
    input  wire        clk,
    input  wire        rst,
    input  wire        PCe,
	 input  wire [15:0]  PC_in,
    output reg [15:0]  PC_value
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            PC_value <= 16'h0000;
        else if (PCe)
				PC_value <= PC_in;
    end
endmodule
