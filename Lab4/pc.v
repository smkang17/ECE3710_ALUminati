module pc (
    input  wire        clk,
    input  wire        rst,
    input  wire        PCe,
    output reg [15:0]  pc_value
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            pc_value <= 16'h0000;
        else if (PCe)
            pc_value <= pc_value + 16'h0001;
    end
endmodule
