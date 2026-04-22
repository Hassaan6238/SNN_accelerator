module fifo
#(
parameter DATA_WIDTH = 25, DEPTH = 256
)
(
input logic clk, rst,
input logic [DATA_WIDTH-1:0] DI,
input logic rden, wren,
output logic [DATA_WIDTH-1:0] DO
    );

logic [DATA_WIDTH-1:0] fifo [DEPTH-1:0];
logic [clogb2(DEPTH-1)-1:0] rd_pointer;
logic [clogb2(DEPTH-1)-1:0] wr_pointer;

integer i;
always @(posedge clk)
    if(rst) 
        for(i=0;i<DEPTH;i=i+1)
            fifo[i] = 0;
    else  
        if(wren) begin
            fifo[wr_pointer] <= DI;
           end

always @(posedge clk)
    if(rst) 
		rd_pointer <= 0;
	else if(rden)
			if(rd_pointer<DEPTH-1)		
				rd_pointer <= rd_pointer + 1'b1;
			else
				rd_pointer <= 0;

always @(posedge clk)
    if(rst) 
		wr_pointer <= 0;
	else if(wren)
			if(wr_pointer<DEPTH-1)
				wr_pointer <= wr_pointer + 1'b1;
			else
				wr_pointer <= 0;

assign DO = fifo[rd_pointer];

	//  The following function calculates the address width based on specified RAM depth
	function integer clogb2;
	  input integer depth;
		for (clogb2=0; depth>0; clogb2=clogb2+1)
		  depth = depth >> 1;
	endfunction 

endmodule
