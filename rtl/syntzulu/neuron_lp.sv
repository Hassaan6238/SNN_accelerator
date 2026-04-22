module neuron_lp#(parameter DEPTH = 256, parameter WIDTH = 25, parameter WEIGHT = 8, parameter LAYERS = 4)
    (
    input logic clk, rst, en,
    input logic [13:0] current_decay_1, voltage_decay_1,
    input logic [WIDTH-1:0] threshold_1,
    input logic [13:0] current_decay_2, voltage_decay_2,
    input logic [WIDTH-1:0] threshold_2,
	input logic [13:0] current_decay_3, voltage_decay_3,
    input logic [WIDTH-1:0] threshold_3,
    input logic [13:0] current_decay_4, voltage_decay_4,
    input logic [WIDTH-1:0] threshold_4,
    input logic [2*(WEIGHT+1)-1:0] synaptic_current,
    input logic [clogb2(LAYERS-1)-1:0] layer_id,
    
    output logic valid,
    output logic [1:0] spike_p,
    output logic active_group,
    output logic voltage_ready,
    output logic [WIDTH-1:0] voltage
    );

localparam CURRENT_WIDTH = 2*(WEIGHT+1);

logic [13:0] current_decay, voltage_decay;
logic [WIDTH-1:0] threshold;
logic [WIDTH-1:0] current;
logic [WIDTH-1:0] synaptic_current_ext;
logic spike_s;

assign current_decay = layer_id == 0 ? current_decay_1: 
					   layer_id == 1 ? current_decay_2:
					   layer_id == 2 ? current_decay_3: 
					   				   current_decay_4;

assign voltage_decay = layer_id == 0 ? voltage_decay_1: 
					   layer_id == 1 ? voltage_decay_2:
					   layer_id == 2 ? voltage_decay_3: 
					   				   voltage_decay_4;

assign threshold     = layer_id == 0 ? threshold_1: 
					   layer_id == 1 ? threshold_2:
					   layer_id == 2 ? threshold_3: 
					   			       threshold_4;

`ifdef CONFIGURABILITY
	logic [clogb2(LAYERS-1)-1:0] layer_id_d;
	always @(posedge clk)
			layer_id_d <= layer_id;

	logic clear_counter;
	assign clear_counter = layer_id_d > layer_id;
`endif

//assign synaptic_current_ext = {{(WIDTH-CURRENT_WIDTH-7){synaptic_current[CURRENT_WIDTH-1]}},synaptic_current,{(7){1'b0}}};
    
//integrator_and_fifo #(.DEPTH(DEPTH), .WIDTH(WIDTH)) Current_i (clk, rst, en, 1'b0, current_decay,synaptic_current_ext,threshold,current_ready,current_spike, current);   
//integrator_and_fifo #(.DEPTH(DEPTH), .WIDTH(WIDTH)) Voltage_i (clk, rst, current_ready, 1'b1, voltage_decay,current,threshold,voltage_ready,spike_s,voltage);   
integrator_and_fifo #(.DEPTH(DEPTH), .WIDTH(WIDTH)) Voltage_i (clk, rst, en, 1'b1, voltage_decay,synaptic_current,threshold,voltage_ready,spike_s,voltage `ifdef CONFIGURABILITY , clear_counter `endif);   
s2p #(2) s2p_i (clk, rst, voltage_ready, spike_s, spike_p, valid, active_group);    
   
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
