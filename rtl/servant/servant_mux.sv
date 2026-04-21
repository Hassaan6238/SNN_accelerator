/*
 mem = 00
 gamux = 01
 timer = 10
 testcon = 11
 */
module servant_mux
  (
   input logic 	      i_clk,
   input logic 	      i_rst,
   input logic [31:0]  i_wb_cpu_adr,
   input logic [31:0]  i_wb_cpu_dat,
   input logic [3:0]   i_wb_cpu_sel,
   input logic 	      i_wb_cpu_we,
   input logic 	      i_wb_cpu_cyc,
   output logic [31:0] o_wb_cpu_rdt,
   output logic 	      o_wb_cpu_ack,

   output logic [31:0] o_wb_mem_adr,
   output logic [31:0] o_wb_mem_dat,
   output logic [3:0]  o_wb_mem_sel,
   output logic 	      o_wb_mem_we,
   output logic 	      o_wb_mem_cyc,
   input logic [31:0]  i_wb_mem_rdt,

   output logic [31:0] o_wb_gpio_adr,
   output logic [31:0]    o_wb_gpio_dat,
   output logic 	      o_wb_gpio_we,
   output logic 	      o_wb_gpio_cyc,
   input logic 	[31:0]      i_wb_gpio_rdt,

   output logic [31:0] o_wb_timer_adr,
   output logic [31:0] o_wb_timer_dat,
   output logic 	      o_wb_timer_we,
   output logic 	      o_wb_timer_cyc,
   input logic [31:0]  i_wb_timer_rdt,
   
   output logic [31:0] o_wb_acc_adr,
   output logic [31:0] o_wb_acc_dat,
   output logic 	      o_wb_acc_we,
   output logic 	      o_wb_acc_cyc,
   input logic [31:0]  i_wb_acc_rdt,
   input logic 		  i_wb_acc_ack
   );

   parameter sim = 0;
   logic [1:0] 	  s;

   assign s = i_wb_cpu_adr[31:30];

   assign o_wb_cpu_rdt = (s == 2'b11) ? i_wb_gpio_rdt :
						 (s == 2'b10) ? i_wb_timer_rdt :
						 (s == 2'b01) ? i_wb_acc_rdt : 
						 i_wb_mem_rdt;

   always @(posedge i_clk) begin
      o_wb_cpu_ack <= 1'b0;
      if (i_wb_cpu_cyc & !o_wb_cpu_ack & (s != 2'b01))
	      o_wb_cpu_ack <= 1'b1;
	  if (i_wb_cpu_cyc & !o_wb_cpu_ack & (s == 2'b01))	// bram read requires 1 extra clock-cycle
		  o_wb_cpu_ack <= i_wb_acc_ack;
      if (i_rst)
	      o_wb_cpu_ack <= 1'b0;
   end

   assign o_wb_mem_adr = i_wb_cpu_adr;
   assign o_wb_mem_dat = i_wb_cpu_dat;
   assign o_wb_mem_sel = i_wb_cpu_sel;
   assign o_wb_mem_we  = i_wb_cpu_we;
   assign o_wb_mem_cyc = i_wb_cpu_cyc & (s == 2'b00);

   assign o_wb_acc_adr = i_wb_cpu_adr;
   assign o_wb_acc_dat = i_wb_cpu_dat;
   assign o_wb_acc_we  = i_wb_cpu_we;
   assign o_wb_acc_cyc = i_wb_cpu_cyc & (s == 2'b01);

   assign o_wb_timer_adr = i_wb_cpu_adr;
   assign o_wb_timer_dat = i_wb_cpu_dat;
   assign o_wb_timer_we  = i_wb_cpu_we;
   assign o_wb_timer_cyc = i_wb_cpu_cyc & (s == 2'b10);

   assign o_wb_gpio_adr = i_wb_cpu_adr;
   assign o_wb_gpio_dat = i_wb_cpu_dat;
   assign o_wb_gpio_we  = i_wb_cpu_we;
   assign o_wb_gpio_cyc = i_wb_cpu_cyc & (s == 2'b11);

   generate
      if (sim) begin
         logic sig_en, halt_en;
	 assign sig_en = (i_wb_cpu_adr[31:28] == 4'h8) & i_wb_cpu_cyc & o_wb_cpu_ack;
	 assign halt_en = (i_wb_cpu_adr[31:28] == 4'h9) & i_wb_cpu_cyc & o_wb_cpu_ack;

	 logic [1023:0] signature_file;
	 integer      f = 0;

	 initial
       /* verilator lint_off WIDTH */
	   if ($value$plusargs("signature=%s", signature_file)) begin
	      $display("Writing signature to %0s", signature_file);
	      f = $fopen(signature_file, "w");
	   end
       /* verilator lint_on WIDTH */

	 always @(posedge i_clk)
	    if (sig_en & (f != 0))
	      $fwrite(f, "%c", i_wb_cpu_dat[7:0]);
	    else if(halt_en) begin
	       $display("Test complete");
	       $finish;
	    end
      end
   endgenerate
endmodule
