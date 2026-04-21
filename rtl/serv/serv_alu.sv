module serv_alu
  (
   input logic 	    clk,
   //State
   input logic 	    i_en,
   input logic 	    i_cnt0,
   output logic 	    o_cmp,
   //Control
   input logic 	    i_sub,
   input logic [1:0] i_bool_op,
   input logic 	    i_cmp_eq,
   input logic 	    i_cmp_sig,
   input logic [2:0] i_rd_sel,
   //Data
   input logic 	    i_rs1,
   input logic 	    i_op_b,
   input logic 	    i_buf,
   output logic 	    o_rd);

   logic        result_add;

   logic 	       cmp_r;

   logic        add_cy;
   logic 	       add_cy_r;
   logic rs1_sx;
   logic op_b_sx;
   logic result_lt;
   logic result_eq;
   logic result_bool;

   //Sign-extended operands
   assign rs1_sx  = i_rs1 & i_cmp_sig;
   assign op_b_sx = i_op_b  & i_cmp_sig;

   assign  add_b = i_op_b^i_sub;

   assign {add_cy,result_add}   = i_rs1+add_b+add_cy_r;

   assign result_lt = rs1_sx + ~op_b_sx + add_cy;

   assign result_eq = !result_add & (cmp_r | i_cnt0);

   assign o_cmp = i_cmp_eq ? result_eq : result_lt;

   /*
    The result_bool expression implements the following operations between
    i_rs1 and i_op_b depending on the value of i_bool_op

    00 xor
    01 0
    10 or
    11 and

    i_bool_op will be 01 during shift operations, so by outputting zero under
    this condition we can safely or result_bool with i_buf
    */
   assign result_bool = ((i_rs1 ^ i_op_b) & ~ i_bool_op[0]) | (i_bool_op[1] & i_op_b & i_rs1);

   assign o_rd = i_buf |
                 (i_rd_sel[0] & result_add) |
                 (i_rd_sel[1] & cmp_r & i_cnt0) |
                 (i_rd_sel[2] & result_bool);

   always @(posedge clk) begin
      add_cy_r <= i_en ? add_cy : i_sub;

      if (i_en)
	cmp_r <= o_cmp;
   end

endmodule
