module serv_bufreg #(
      parameter [0:0] MDU = 0
)(
   input logic 	      i_clk,
   //State
   input logic 	      i_cnt0,
   input logic 	      i_cnt1,
   input logic 	      i_en,
   input logic 	      i_init,
   input logic           i_mdu_op,
   output logic [1:0]    o_lsb,
   //Control
   input logic 	      i_rs1_en,
   input logic 	      i_imm_en,
   input logic 	      i_clr_lsb,
   input logic 	      i_sh_signed, 
   //Data
   input logic 	      i_rs1,
   input logic 	      i_imm,
   output logic 	      o_q,
   //External
   output logic [31:0] o_dbus_adr,
   //Extension
   output logic [31:0] o_ext_rs1);

   logic 	      c, q;
   logic 		      c_r;
   logic [31:2] 	      data;
   logic [1:0]            lsb;
   logic clr_lsb;

   assign clr_lsb = i_cnt0 & i_clr_lsb;

   assign {c,q} = {1'b0,(i_rs1 & i_rs1_en)} + {1'b0,(i_imm & i_imm_en & !clr_lsb)} + c_r;

   always @(posedge i_clk) begin
      //Make sure carry is cleared before loading new data
      c_r <= c & i_en;

      if (i_en)
	data <= {i_init ? q : (data[31] & i_sh_signed), data[31:3]};

      if (i_init ? (i_cnt0 | i_cnt1) : i_en)
	lsb <= {i_init ? q : data[2],lsb[1]};
   end

   assign o_q = lsb[0] & i_en;
   assign o_dbus_adr = {data, 2'b00};
   assign o_ext_rs1  = {o_dbus_adr[31:2],lsb};
   assign o_lsb = (MDU & i_mdu_op) ? 2'b00 : lsb;

endmodule
