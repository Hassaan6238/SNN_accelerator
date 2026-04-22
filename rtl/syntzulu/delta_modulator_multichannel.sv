module delta_modulator_multichannel #(
	parameter CHANNELS = 16,    
	parameter WIDTH = 16
    )
(
  input logic clk,           // Clock input
  input logic rst,           // Reset input
  input logic en,
  input logic signed [WIDTH-1:0] samples, // Analog input samples (8-bit resolution)
  output logic pos_spike, neg_spike,     // Delta modulation output
  output logic valid
);


  logic signed [WIDTH-1:0] data_in_pipe;
	logic signed [WIDTH-1:0] delta;   
  
  logic [clogb2(CHANNELS-1)-1:0] channel_cnt, r_channel_cnt, rr_channel_cnt;
  logic signed [WIDTH-1:0] data_old; // old sample
  logic signed [WIDTH-1:0] prev_sample;    // next value to store
  logic signed [WIDTH-1:0] samples_d;
  logic en_d, en_dd;

  always @(posedge clk)
        if (rst) begin
            channel_cnt <= 0;
            r_channel_cnt <= 0;
			rr_channel_cnt <= 0;
          end
        else begin
            if(en)
                channel_cnt <= channel_cnt + 1'b1;  
            r_channel_cnt <= channel_cnt;
			rr_channel_cnt <= r_channel_cnt;
          end
    

    BRAM_singlePort_readFirst
    #(
      .RAM_WIDTH(WIDTH),        
      .RAM_DEPTH(CHANNELS),             
      .RAM_PERFORMANCE("LOW_LATENCY"), 
	  .INIT_FILE("")      
	)
    sample_mem
     (
      .addra(rr_channel_cnt), 
      .addrb(channel_cnt), 
      .dina(prev_sample),
      .clk(clk),
      .wea(en_dd), 
      .ena(en_dd),                   
      .enb(en),      
      .rst(rst),                    
      .regceb(1'b1),
      
      .doutb(data_old)
    );   

    BRAM_singlePort_readFirst
    #(
      .RAM_WIDTH(WIDTH),        
      .RAM_DEPTH(CHANNELS),             
      .RAM_PERFORMANCE("LOW_LATENCY"), 
	  .INIT_FILE({"sim/mem/",`PATH,"/delta.txt"})      
	)
    delta_mem
     (
      .addra(), 
      .addrb(channel_cnt), 
      .dina(),
      .clk(clk),
      .wea(1'b0), 
      .ena(1'b0),                   
      .enb(en),      
      .rst(rst),                    
      .regceb(1'b1),
      
      .doutb(delta)
    ); 

  always @(posedge clk) samples_d <= samples;


  always @(posedge clk ) begin
    if (rst) begin
      prev_sample <= 0;
      {pos_spike, neg_spike} <= 0;
    end else 
	begin
      if (samples_d < (data_old - delta))
		begin
			{pos_spike, neg_spike} <= 2'b01;
            prev_sample <= data_old-delta;
		end
      else if (samples_d > (data_old + delta))
			begin
				{pos_spike, neg_spike} <= 2'b10;
				prev_sample <= data_old+delta;
			end
		  else
			begin
				{pos_spike, neg_spike} <= 2'b00;
				prev_sample <= data_old;
			end
    end
  end
  
  always @(posedge clk)
		begin
			en_d  <= en;
			en_dd <= en_d;
        	valid <= en_d;
		end

////////////////////////////
//  _               ____  //
// | | ___   __ _  |___ \ //
// | |/ _ \ / _` |   __)  //
// | | (_) | (_| |  / __/ //
// |_|\___/ \__, | |_____ //
//          |___/         //
////////////////////////////
   
//  The following function calculates the address width based on specified RAM depth
function integer clogb2;
  input integer depth;
    for (clogb2=0; depth>0; clogb2=clogb2+1)
      depth = depth >> 1;
endfunction 
  
endmodule
