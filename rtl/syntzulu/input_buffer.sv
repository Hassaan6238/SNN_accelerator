module input_buffer
#(

    parameter CHANNELS = 128,
    parameter DW = 15
)
(
    input logic clk, rst,
    input logic en,
    input logic signed [15:0] data_in,
    
    output logic valid,
    output logic signed [DW-1:0] data_out,
	
	input logic external_access_en,
	input logic [clogb2(CHANNELS-1)-1:0] external_addr,
	output logic signed [15:0] external_data_out,
	input logic external_access_wren,
	input logic signed [15:0] external_data_in
    );

	localparam SIMD = (DW==8)?1:0;
	localparam CHANNELS_INT = SIMD?CHANNELS/2:CHANNELS;

	logic [clogb2(CHANNELS_INT-1)-1:0] pointer;
	logic read_flag;
	
	logic slow_stream_out;
	logic [15:0] data_in_mux;
	logic wr_en;
	logic [15:0] mem_out;
	logic [clogb2(CHANNELS_INT-1)-1:0] adr;

	initial slow_stream_out = (SIMD == 0) ? 1 : 0;
	generate
    if (SIMD) begin
        always @(posedge clk) begin
            if (rst)
                slow_stream_out <= 0;
            else if (read_flag)
                slow_stream_out <= ~slow_stream_out;
        end
    end else begin
        always @(*) begin
            slow_stream_out = 1; // Combinational assignment
        end
    end
	endgenerate

	assign data_in_mux = external_access_wren ? external_data_in : data_in;
	
	assign wr_en = en | external_access_wren;
	

	BRAM_singlePort_readFirst #(
	.RAM_WIDTH(16),
	.RAM_DEPTH(CHANNELS_INT),
	.RAM_PERFORMANCE("LOW_LATENCY"),
	.INIT_FILE("")
	) 
	buffer (
		.addra(adr),
		.addrb(adr),
		.dina(data_in_mux),
		.clk(clk),
		.wea(wr_en),
		.ena(wr_en),
		.enb(1'b1),
		.rst(rst),
		.regceb(1'b1),
		.doutb(mem_out)
	);

	assign adr = external_access_en | external_access_wren ? external_addr : pointer;

	always @(posedge clk)
		if(rst)
			pointer <= 0;
		else if(wr_en)
				if(pointer < CHANNELS_INT)
					pointer <= pointer + 1'b1;
				else
					pointer <= 0;
			 else if(read_flag && slow_stream_out)// if !wr_en
					if(pointer < CHANNELS_INT)
						pointer <= pointer + 1'b1;
					else
						pointer <= 0;
	
	always @(posedge clk)
		if(rst)
			read_flag <= 1'b0;
		else if(wr_en && pointer == CHANNELS_INT-1)
				read_flag <= 1'b1;
				else if(read_flag && slow_stream_out && pointer == CHANNELS_INT-1)
						read_flag <= 1'b0;
					
	always @(posedge clk)
		if(rst) 
			valid <= 0;
		else
			valid <= read_flag;

	generate
		if(SIMD)
			assign data_out = slow_stream_out?mem_out[15:8]:mem_out[7:0];
		else
			assign data_out = mem_out;
	endgenerate

	assign external_data_out = mem_out;
	
	//  The following function calculates the address width based on specified RAM depth
	function integer clogb2;
	  input integer depth;
		for (clogb2=0; depth>0; clogb2=clogb2+1)
		  depth = depth >> 1;
	endfunction   
    
endmodule 
