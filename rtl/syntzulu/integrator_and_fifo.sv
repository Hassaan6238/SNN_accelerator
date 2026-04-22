module integrator_and_fifo #(parameter DEPTH = 256, parameter WIDTH = 25)
    (
    input logic clk, rst, en, detection,
    input logic [13:0] decay,
    input logic [WIDTH-1:0] stimolo,
    input logic [WIDTH-1:0] threshold,
    
    output logic valid,
    output logic spike,
    output logic [WIDTH-1:0] output_new
	`ifdef CONFIGURABILITY
		,input logic clear_counter
	`endif
    );
    
    logic [WIDTH-1:0] stimolo_d;
    logic en_d;
    logic [WIDTH-1:0] output_old;
    
    // FIFO
    bram_fifo #( .DATA_WIDTH(WIDTH), .DEPTH(DEPTH) ) fifo_i (.clk(clk),.rst(rst),.DI(output_new),.rden(en),.wren(valid),.DO(output_old) `ifdef CONFIGURABILITY , .clear_counter(clear_counter) `endif); 
    // wait fifo output
    always @(posedge clk)
        if (rst) begin
            en_d <= 0;
            stimolo_d <= 0;
         end
        else begin 
            en_d <= en;
            if(en)
                stimolo_d <= stimolo;
        end
    // INTEGRATOR
    integrator #(.WIDTH(WIDTH)) integrator_i (clk, rst, en_d, detection,output_old,decay,stimolo_d,threshold,valid,spike,output_new);
    

    endmodule
