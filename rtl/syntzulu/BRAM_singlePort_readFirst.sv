
module BRAM_singlePort_readFirst #(
  parameter RAM_WIDTH = 4,                  // Specify RAM data width
  parameter RAM_DEPTH = 64,                  // Specify RAM depth (number of entries)
  parameter RAM_PERFORMANCE = "HIGH_PERFORMANCE", // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
  parameter INIT_FILE = ""                       // Specify name/location of RAM initialization file if using one (leave blank if not)
)
(
  input logic [clogb2(RAM_DEPTH-1)-1:0] addra,  // Port A address bus, width determined from RAM_DEPTH
  input logic [clogb2(RAM_DEPTH-1)-1:0] addrb,  // Port B address bus, width determined from RAM_DEPTH
  input logic [RAM_WIDTH-1:0] dina,           // Port A RAM input data
  input logic clk,                           // Clock
  input logic wea,                            // Port A write enable
  input logic ena,                            // Port A RAM Enable, for additional power savings, disable port when not in use
  input logic enb,                            // Port B RAM Enable, for additional power savings, disable port when not in use
  input logic rst,                           // Port A and B output reset (does not affect memory contents)
  input logic regceb,                         // Port B output register enable
  
  output logic [RAM_WIDTH-1:0] doutb                   // Port B RAM output data
    );

  logic [RAM_WIDTH-1:0] ram [RAM_DEPTH-1:0];
  logic [RAM_WIDTH-1:0] ram_data_b = {RAM_WIDTH{1'b0}};

  generate
	  genvar idx;
	  for(idx = 0; idx < 16; idx = idx+1) begin
		 logic [RAM_WIDTH-1:0] tmp;
		assign tmp = ram[idx];
	  end
  endgenerate

  // The following code either initializes the memory values to a specified file or to all zeros to match hardware
  generate
    if (INIT_FILE != "") begin: use_init_file
      initial
        $readmemh(INIT_FILE, ram, 0, RAM_DEPTH-1);
    end else begin: init_bram_to_zero
      integer ram_index;
      initial
        for (ram_index = 0; ram_index < RAM_DEPTH; ram_index = ram_index + 1)
          ram[ram_index] = {RAM_WIDTH{1'b0}};
    end
  endgenerate

  always @(posedge clk)
    if (ena) begin
      if (wea)
        ram[addra] <= dina;
    end

  always @(posedge clk)
    if (enb) begin
      ram_data_b <= ram[addrb];
    end

  //  The following code generates HIGH_PERFORMANCE (use output register) or LOW_LATENCY (no output register)
  generate
    if (RAM_PERFORMANCE == "LOW_LATENCY") begin: no_output_register

      // The following is a 1 clock cycle read latency at the cost of a longer clock-to-out timing
       assign doutb = ram_data_b;

    end else begin: output_register

      // The following is a 2 clock cycle read latency with improve clock-to-out timing

      logic [RAM_WIDTH-1:0] doutb_reg = {RAM_WIDTH{1'b0}};

      always @(posedge clk)
        if (rst)
          doutb_reg <= {RAM_WIDTH{1'b0}};
        else if (regceb)
          doutb_reg <= ram_data_b;

      assign doutb = doutb_reg;

    end
  endgenerate

  //  The following function calculates the address width based on specified RAM depth
  function integer clogb2;
    input integer depth;
      for (clogb2=0; depth>0; clogb2=clogb2+1)
        depth = depth >> 1;
  endfunction
							
endmodule
