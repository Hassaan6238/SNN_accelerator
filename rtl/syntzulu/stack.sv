module stack
#(
parameter DATA_WIDTH = 4,
parameter DEPTH = 24
)
(
input logic clk, rst,
input logic [DATA_WIDTH-1:0] din,
input logic wr_en, clear,
input logic stream_out,

output logic [DATA_WIDTH-1:0] dout,
output logic done,
output logic [clogb2(DEPTH-1)-1:0] active_entries,
output logic empty 
);

// shift register    
logic [DATA_WIDTH-1:0] shift [DEPTH-1:0];
logic [clogb2(DEPTH-1):0] entries_cnt;    
logic [clogb2(DEPTH-1)-1:0] stream_cnt;    

integer i;
always@(posedge clk)
    if (rst)
       for(i=0;i<DEPTH;i=i+1)
            shift[i] <= 0;
    else    
        if(wr_en) begin
            shift[0] <= din;
            for(i=1;i<DEPTH;i=i+1)
                shift[i] <= shift[i-1];
        end
            
// entries counter
always @(posedge clk)
    if(rst)
       entries_cnt <= 0;
    else
        if(wr_en)
            entries_cnt <= entries_cnt + 1'b1;     
        else if (clear)
            entries_cnt <= 0;

// stream counter
always @(posedge clk)
    if(rst)
       stream_cnt <= 0;
    else
        if(stream_out && (entries_cnt != 0) )
            stream_cnt <= entries_cnt - 1'b1;
        else if (stream_cnt != 0) 
            stream_cnt <= stream_cnt - 1'b1;

// output assignment 
assign dout = shift[stream_cnt];

always @(posedge clk)
    if (rst) 
        done = 0;
    else if (stream_cnt == 1 || ( stream_out && ( (entries_cnt == 1) || (entries_cnt == 0) ) ) )
            done <= 1;
         else
            done <= 0;

assign active_entries = entries_cnt == 0 ? 0 : entries_cnt - 1'b1;            
 
assign empty = entries_cnt == 0;
           
//  The following function calculates the address width based on specified RAM depth
function integer clogb2;
  input integer depth;
    for (clogb2=0; depth>0; clogb2=clogb2+1)
      depth = depth >> 1;
endfunction 
   
endmodule
