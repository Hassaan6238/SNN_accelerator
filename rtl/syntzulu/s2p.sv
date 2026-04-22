module s2p #(parameter P = 2)(
    input logic clk, rst, en, spike_s,
    output logic [P-1:0] spike_p,
    output logic valid, 
    output logic active_group 
    );
    
    logic end_cnt;
    logic [clogb2(P-1)-1:0] cnt;
    
    // clear logic
    always @(posedge clk)
        if (rst)
            valid <= 0;
        else 
            valid <= end_cnt;
     
    always @(posedge clk)
        if (rst)
            cnt <= 0;
        else if(en)
            cnt <= cnt + 1'b1;
            
     assign end_cnt = (cnt == P-1) & en;
    
    
    // Serial 2 Parallel
	integer i;
    always @(posedge clk)
        if (rst)
            spike_p <= 0;
        else if(en) begin
            spike_p[0] <= spike_s;
            for(i=1;i<P;i=i+1)
				spike_p[i] <= spike_p[i-1];
            end
                else if(valid)
                    spike_p <= 0;
    
    // check if is present at least an input equal to 1
    always @(posedge clk)
        if (rst)
            active_group <= 0;
        else if(en) 
            active_group <= (active_group && ~valid) | spike_s;
             else if(valid)
                    active_group <= 0;
    

//  The following function calculates the address width based on specified RAM depth
function integer clogb2;
  input integer depth;
    for (clogb2=0; depth>0; clogb2=clogb2+1)
      depth = depth >> 1;

endfunction      
     
endmodule
