module servant_timer
  #(parameter WIDTH = 16,
	 parameter RESET_STRATEGY = "",
	 parameter DIVIDER = 0)
  (input logic 	     i_clk,
	input logic 	     i_rst,
	output logic 	     o_irq,
	input logic [31:0] i_wb_dat,
	input logic 	     i_wb_we,
	input logic 	     i_wb_cyc,
	output logic [31:0] o_wb_rdt);

	localparam HIGH = WIDTH-1-DIVIDER;

	logic [WIDTH-1:0]   mtime;
	logic [HIGH:0]      mtimecmp;
	logic [HIGH:0]     mtimeslice;

	assign mtimeslice = mtime[WIDTH-1:DIVIDER];

	always @(mtimeslice) begin
		o_wb_rdt = 32'd0;
		o_wb_rdt[HIGH:0] = mtimeslice;
	end

	always @(posedge i_clk) begin
		if (RESET_STRATEGY != "NONE")
			if (i_rst) begin
				mtime <= 0;
				mtimecmp <= 0;
			end
		if (i_wb_cyc & i_wb_we) begin
			mtimecmp <= i_wb_dat[HIGH:0];
			mtime <= 0;
		end
		else begin
			mtime <= mtime + 'd1;
		end
		o_irq <= (mtimeslice >= mtimecmp);
	end
endmodule
