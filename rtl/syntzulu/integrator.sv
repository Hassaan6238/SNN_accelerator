module integrator #(parameter WIDTH = 25)
    (
    input logic clk, rst, en, detection,
    input logic [WIDTH-1:0] output_old,
    input logic [13:0] decay,
    input logic [WIDTH-1:0] stimolo,
    input logic [WIDTH-1:0] threshold,
    
    output logic valid,
    output logic spike,
    output logic [WIDTH-1:0] output_new
    );

localparam P_SIZE = WIDTH+13;
    
logic signed [WIDTH-1:0] r_output_old;  
logic signed [13:0] r_decay; 
logic signed [P_SIZE-1:0] p;
logic signed [WIDTH-1:0] p_shift;
logic signed [WIDTH-1:0] r_stimolo[2:0];
logic signed [WIDTH-1:0] r_threshold [3:0];
(* use_dsp = "yes" *)
logic signed [WIDTH-1:0] comparator_in;
logic [3:0] en_shift;
logic [P_SIZE-1:0] supporto_1, supporto_2;


integer i;
always @(posedge clk)
    if(rst) begin
        en_shift <= 0;
        r_output_old <= 0;
        r_decay <= 0;
        p <= 0;
        p_shift <= 0;
        comparator_in <= 0;
         for(i=0;i<4;i=i+1)
            r_threshold[i] <= 0;
        
        for(i=0;i<3;i=i+1)
            r_stimolo[i] <= 0;
    end
    else begin
        en_shift[0] <= en;
        r_output_old <= output_old;
        r_decay <= decay;
        r_stimolo[0] <= stimolo;
        r_threshold[0] <= threshold;
        
        en_shift[1] <= en_shift[0];
        p <= r_output_old*r_decay;
        r_stimolo[1] <= r_stimolo[0];
        r_threshold[1] <= r_threshold[0];
        
        en_shift[2] <= en_shift[1];
        if(p[P_SIZE-1]) begin
            supporto_1 = ~p+1'b1;            
            supporto_2 = supporto_1[P_SIZE-1:12];
            p_shift <= ~supporto_2+1'b1;
        end
        else
            p_shift <= p[P_SIZE-1:12];
        
        r_stimolo[2] <= r_stimolo[1];
        r_threshold[2] <= r_threshold[1];
        
        en_shift[3] <= en_shift[2];
        comparator_in <= p_shift + r_stimolo[2];
        r_threshold[3] <= r_threshold[2];
    end

assign spike = (comparator_in >= r_threshold[3]) & detection? 1'b1 : 1'b0; 
assign output_new = spike? 0 : comparator_in;     
assign valid = en_shift[3];
    
endmodule
