module serv_ctrl
  #(parameter RESET_STRATEGY = "MINI",
    parameter RESET_PC = 32'd0,
    parameter WITH_CSR = 1)
  (
   input logic 	     clk,
   input logic 	     i_rst,
   //State
   input logic 	     i_pc_en,
   input logic 	     i_cnt12to31,
   input logic 	     i_cnt0,
   input logic        i_cnt1,
   input logic 	     i_cnt2,
   //Control
   input logic 	     i_jump,
   input logic 	     i_jal_or_jalr,
   input logic 	     i_utype,
   input logic 	     i_pc_rel,
   input logic 	     i_trap,
   input logic        i_iscomp,
   //Data
   input logic 	     i_imm,
   input logic 	     i_buf,
   input logic 	     i_csr_pc,
   output logic 	     o_rd,
   output logic 	     o_bad_pc,
   //External
   output logic [31:0] o_ibus_adr);

   logic       pc_plus_4;
   logic       pc_plus_4_cy;
   logic 	      pc_plus_4_cy_r;
   logic       pc_plus_offset;
   logic       pc_plus_offset_cy;
   logic 	      pc_plus_offset_cy_r;
   logic       pc_plus_offset_aligned;
   logic       plus_4;
   logic pc;
   logic new_pc;
   logic offset_a;
   logic offset_b;

    
    
    /*  If i_iscomp=1: increment pc by 2 else increment pc by 4  */
    
   assign       pc = o_ibus_adr[0];
   assign plus_4        = i_iscomp ? i_cnt1 : i_cnt2;

   assign o_bad_pc = pc_plus_offset_aligned;

   assign {pc_plus_4_cy,pc_plus_4} = pc+plus_4+pc_plus_4_cy_r;

   generate
      if (|WITH_CSR)
	assign new_pc = i_trap ? (i_csr_pc & !i_cnt0) : i_jump ? pc_plus_offset_aligned : pc_plus_4;
      else
	assign new_pc = i_jump ? pc_plus_offset_aligned : pc_plus_4;
   endgenerate
   assign o_rd  = (i_utype & pc_plus_offset_aligned) | (pc_plus_4 & i_jal_or_jalr);

   assign offset_a = i_pc_rel & pc;
   assign offset_b = i_utype ? (i_imm & i_cnt12to31): i_buf;
   assign {pc_plus_offset_cy,pc_plus_offset} = offset_a+offset_b+pc_plus_offset_cy_r;

   assign pc_plus_offset_aligned = pc_plus_offset & !i_cnt0;

   initial if (RESET_STRATEGY == "NONE") o_ibus_adr = RESET_PC;

   always @(posedge clk) begin
      pc_plus_4_cy_r <= i_pc_en & pc_plus_4_cy;
      pc_plus_offset_cy_r <= i_pc_en & pc_plus_offset_cy;

      if (RESET_STRATEGY == "NONE") begin
	 if (i_pc_en)
	   o_ibus_adr <= {new_pc, o_ibus_adr[31:1]};
      end else begin
	 if (i_pc_en | i_rst)
	   o_ibus_adr <= i_rst ? RESET_PC : {new_pc, o_ibus_adr[31:1]};
      end
   end
endmodule
