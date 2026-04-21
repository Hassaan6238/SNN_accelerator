
module serv_immdec
  #(parameter SHARED_RFADDR_IMM_REGS = 1)
  (
   input logic 	     i_clk,
   //State
   input logic 	     i_cnt_en,
   input logic 	     i_cnt_done,
   //Control
   input logic [3:0]  i_immdec_en,
   input logic 	     i_csr_imm_en,
   input logic [3:0]  i_ctrl,
   output logic [4:0] o_rd_addr,
   output logic [4:0] o_rs1_addr,
   output logic [4:0] o_rs2_addr,
   //Data
   output logic 	     o_csr_imm,
   output logic 	     o_imm,
   //External
   input logic 	     i_wb_en,
   input logic [31:7] i_wb_rdt);

   logic 		     imm31;

   logic [8:0]  imm19_12_20;
   logic 	      imm7;
   logic [5:0]  imm30_25;
   logic [4:0]  imm24_20;
   logic [4:0]  imm11_7;
   logic [4:0]  rd_addr;
   logic [4:0]  rs1_addr;
   logic [4:0]  rs2_addr;
   logic signbit;

   assign o_csr_imm = imm19_12_20[4];

   assign signbit = imm31 & !i_csr_imm_en;

   generate
      if (SHARED_RFADDR_IMM_REGS) begin
	 assign o_rs1_addr = imm19_12_20[8:4];
	 assign o_rs2_addr = imm24_20;
	 assign o_rd_addr  = imm11_7;

	 always @(posedge i_clk) begin
	    if (i_wb_en) begin
	       /* CSR immediates are always zero-extended, hence clear the signbit */
	       imm31     <= i_wb_rdt[31];
	    end
	    if (i_wb_en | (i_cnt_en & i_immdec_en[1]))
	      imm19_12_20 <= i_wb_en ? {i_wb_rdt[19:12],i_wb_rdt[20]} : {i_ctrl[3] ? signbit : imm24_20[0], imm19_12_20[8:1]};
	    if (i_wb_en | (i_cnt_en))
	      imm7        <= i_wb_en ? i_wb_rdt[7]                    : signbit;

	    if (i_wb_en | (i_cnt_en & i_immdec_en[3]))
	      imm30_25    <= i_wb_en ? i_wb_rdt[30:25] : {i_ctrl[2] ? imm7 : i_ctrl[1] ? signbit : imm19_12_20[0], imm30_25[5:1]};

	    if (i_wb_en | (i_cnt_en & i_immdec_en[2]))
	      imm24_20    <= i_wb_en ? i_wb_rdt[24:20] : {imm30_25[0], imm24_20[4:1]};

	    if (i_wb_en | (i_cnt_en & i_immdec_en[0]))
	      imm11_7     <= i_wb_en ? i_wb_rdt[11:7] : {imm30_25[0], imm11_7[4:1]};
	 end
      end else begin

	 assign o_rd_addr  = rd_addr;
	 assign o_rs1_addr = rs1_addr;
	 assign o_rs2_addr = rs2_addr;
	 always @(posedge i_clk) begin
	    if (i_wb_en) begin
	       /* CSR immediates are always zero-extended, hence clear the signbit */
	       imm31       <= i_wb_rdt[31];
	       imm19_12_20 <= {i_wb_rdt[19:12],i_wb_rdt[20]};
	       imm7        <= i_wb_rdt[7];
	       imm30_25    <= i_wb_rdt[30:25];
	       imm24_20    <= i_wb_rdt[24:20];
	       imm11_7     <= i_wb_rdt[11:7];

               rd_addr  <= i_wb_rdt[11:7];
               rs1_addr <= i_wb_rdt[19:15];
               rs2_addr <= i_wb_rdt[24:20];
	    end
	    if (i_cnt_en) begin
	       imm19_12_20 <= {i_ctrl[3] ? signbit : imm24_20[0], imm19_12_20[8:1]};
	       imm7        <= signbit;
	       imm30_25    <= {i_ctrl[2] ? imm7 : i_ctrl[1] ? signbit : imm19_12_20[0], imm30_25[5:1]};
	       imm24_20    <= {imm30_25[0], imm24_20[4:1]};
	       imm11_7     <= {imm30_25[0], imm11_7[4:1]};
	    end
	 end
      end
   endgenerate

	 assign o_imm = i_cnt_done ? signbit : i_ctrl[0] ? imm11_7[0] : imm24_20[0];
	 
endmodule
