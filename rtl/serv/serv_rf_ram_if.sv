module serv_rf_ram_if
  #(//Data width. Adjust to preferred width of SRAM data interface
    parameter width=8,

    //Select reset strategy.
    // "MINI" for resetting minimally required FFs
    // "NONE" for relying on FFs having a defined value on startup
    parameter reset_strategy="MINI",

    //Number of CSR registers. These are allocated after the normal
    // GPR registers in the RAM.
    parameter csr_regs=4,

    //Internal parameters calculated from above values. Do not change
    parameter raw=$clog2(32+csr_regs), //Register address width
    parameter l2w=$clog2(width), //log2 of width
    parameter aw=5+raw-l2w) //Address width
  (
   //SERV side
   input logic		   i_clk,
   input logic		   i_rst,
   input logic		   i_wreq,
   input logic		   i_rreq,
   output logic		   o_ready,
   input logic [raw-1:0]	   i_wreg0,
   input logic [raw-1:0]	   i_wreg1,
   input logic		   i_wen0,
   input logic		   i_wen1,
   input logic		   i_wdata0,
   input logic		   i_wdata1,
   input logic [raw-1:0]	   i_rreg0,
   input logic [raw-1:0]	   i_rreg1,
   output logic		   o_rdata0,
   output logic		   o_rdata1,
   //RAM side
   output logic [aw-1:0]	   o_waddr,
   output logic [width-1:0] o_wdata,
   output logic		   o_wen,
   output logic [aw-1:0]	   o_raddr,
   output logic		   o_ren,
   input logic [width-1:0]  i_rdata);
   
   logic 				   rgnt;
   logic [4:0] 	  rcnt;
   
   logic 		  rtrig1;
   /*
   ********** Write side ***********
   */
   
   logic [4:0] 	     wcnt;
   
   logic [width-1:0]   wdata0_r;
   logic [width-0:0]   wdata1_r;
   
   logic 		     wen0_r;
   logic 		     wen1_r;
   logic 	     wtrig0;
   logic 	     wtrig1;
   logic [raw-1:0] wreg;
   logic 	 rtrig0;
   logic [raw-1:0] rreg;
   logic [width-1:0]  rdata0;
   logic [width-2:0]  rdata1;
   logic 		    rgate;
   logic 	      rreq_r;
   
   assign o_ready = rgnt | i_wreq;
   assign wtrig0 = rtrig1;
   
   generate if (width == 2) begin
      assign wtrig1 =  wcnt[0];
   end else begin
    logic wtrig0_r;
    always @(posedge i_clk) wtrig0_r <= wtrig0;
    assign wtrig1 = wtrig0_r;
  end
   endgenerate

   assign 	     o_wdata = wtrig1 ? wdata1_r[width-1:0] : wdata0_r;
   assign        wreg  = wtrig1 ? i_wreg1 : i_wreg0;
   
   generate if (width == 32)
     assign o_waddr = wreg;
   else
     assign o_waddr = {wreg, wcnt[4:l2w]};
   endgenerate

   assign o_wen = (wtrig0 & wen0_r) | (wtrig1 & wen1_r);

   assign wcnt = rcnt-4;

   always @(posedge i_clk) begin
      if (wcnt[0]) begin
	    wen0_r    <= i_wen0;
	    wen1_r    <= i_wen1;
      end

      wdata0_r  <= {i_wdata0,wdata0_r[width-1:1]};
      wdata1_r  <= {i_wdata1,wdata1_r[width-0:1]};

   end

   /*
    ********** Read side ***********
    */



   assign rreg = rtrig0 ? i_rreg1 : i_rreg0;
   generate if (width == 32)
     assign o_raddr = rreg;
   else
     assign o_raddr = {rreg, rcnt[4:l2w]};
   endgenerate


   assign o_rdata0 = rdata0[0];
   assign o_rdata1 = rtrig1 ? i_rdata[0] : rdata1[0];

   assign rtrig0 = (rcnt[l2w-1:0] == 1);

   generate if (width == 2)
     assign o_ren = rgate;
   else
     assign o_ren = rgate & (rcnt[l2w-1:1] == 0);
   endgenerate


   generate if (width>2)
     always @(posedge i_clk) begin
	rdata1 <= {1'b0,rdata1[width-2:1]}; //Optimize?
	if (rtrig1)
	  rdata1[width-2:0] <= i_rdata[width-1:1];
     end
   else
     always @(posedge i_clk) if (rtrig1) rdata1 <= i_rdata[1];
   endgenerate

   always @(posedge i_clk) begin
      if (&rcnt | i_rreq)
	rgate <= i_rreq;

      rtrig1 <= rtrig0;
      rcnt <= rcnt+5'd1;
      if (i_rreq | i_wreq)
	 rcnt <= {3'd0,i_wreq,1'b0};

      rreq_r <= i_rreq;
      rgnt <= rreq_r;

      rdata0 <= {1'b0,rdata0[width-1:1]};
      if (rtrig0)
	rdata0 <= i_rdata;

      if (i_rst) begin
	 if (reset_strategy != "NONE") begin
	    rgate <= 1'b0;
	    rgnt <= 1'b0;
	    rreq_r <= 1'b0;
	    rcnt <= 5'd0;
	 end
      end
   end


endmodule
