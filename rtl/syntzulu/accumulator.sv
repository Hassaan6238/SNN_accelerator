// This code implements a parameterizable subtractor followed by multiplier which will be packed into DSP Block
(* use_dsp = "yes" *)
module accumulator
#(
parameter SIZEIN = 16  // Size of inputs
)
(
input logic clk, // Clock
input logic ce1,ce2,ce3,  // Clock enable
input logic rst, // Reset
input logic clear_and_go, clear, // to reset the accumulator
input logic signed [SIZEIN-1:0] a,  // 1st Input to pre-subtractor
input logic signed [SIZEIN-1:0] b,  // 2nd input to pre-subtractor
//input logic signed [SIZEIN-1:0] c,  // multiplier input
output logic signed [2*SIZEIN-1:0] presubmult_out
);
    


// Declare registers for intermediate values
logic signed [SIZEIN-1:0] a_reg, b_reg; 
//logic signed [SIZEIN-1:0]c_reg;
logic signed [SIZEIN-1:0]   add_reg;
//logic signed [2*SIZEIN:0] m_reg;
logic signed [2*SIZEIN:0] p_reg;

always @(posedge clk)
 if (rst | clear)
  begin
    a_reg   <= 0;
    b_reg   <= 0;
    //c_reg   <= 0;
	add_reg <= 0;
    //m_reg   <= 0;
    p_reg   <= 0;
  end
 else begin
    if (ce1)
      begin
        a_reg   <= a;
        b_reg   <= b;
        //c_reg   <= c;
      end
    if (ce2)
        add_reg <= a_reg + b_reg;
    //m_reg   <= add_reg * c_reg;
    //p_reg   <= p_reg + m_reg;
    if (ce3)
        if(clear_and_go)
            p_reg <= add_reg;
        else    
            p_reg   <= p_reg + add_reg;
  end

assign presubmult_out = p_reg;    
    

endmodule
