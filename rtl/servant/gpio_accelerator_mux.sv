// 011 gpio
// 010 accelerator

module gpio_accelerator_mux
  (input logic         i_wb_clk,
   input logic  [31:0] i_wb_adr,
   input logic  [31:0] i_wb_dat,
   input logic         i_wb_we,
   input logic         i_wb_cyc,
   output logic [31:0] o_wb_rdt,
   
   //output logic [31:0] o_wb_gpio_adr,
   output logic        o_wb_gpio_dat,
   output logic 	      o_wb_gpio_we,
   output logic 	      o_wb_gpio_cyc,
   input logic         i_wb_gpio_rdt,
   
   output logic [31:0] o_wb_acc_adr,
   output logic [31:0] o_wb_acc_dat,
   output logic 	      o_wb_acc_we,
   output logic 	      o_wb_acc_cyc,
   input logic  [31:0] i_wb_acc_rdt);

   logic s;

   assign s = i_wb_adr[29];

   assign o_wb_rdt = s ? {31'b0, i_wb_gpio_rdt} : i_wb_acc_rdt;

   //assign o_wb_gpio_adr = i_wb_adr;
   assign o_wb_gpio_dat = i_wb_dat[0];
   assign o_wb_gpio_we  = i_wb_we;

   assign o_wb_acc_adr = i_wb_adr;
   assign o_wb_acc_dat = i_wb_dat;
   assign o_wb_acc_we  = i_wb_we;

   assign o_wb_gpio_cyc = i_wb_cyc & s;
   assign o_wb_acc_cyc  = i_wb_cyc & ~s;

endmodule
