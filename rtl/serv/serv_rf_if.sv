module serv_rf_if
  #(parameter WITH_CSR = 1)
  (//RF Interface
   input logic 		      i_cnt_en,
   output logic [4+WITH_CSR:0] o_wreg0,
   output logic [4+WITH_CSR:0] o_wreg1,
   output logic 		      o_wen0,
   output logic 		      o_wen1,
   output logic 		      o_wdata0,
   output logic 		      o_wdata1,
   output logic [4+WITH_CSR:0] o_rreg0,
   output logic [4+WITH_CSR:0] o_rreg1,
   input logic 		      i_rdata0,
   input logic 		      i_rdata1,

   //Trap interface
   input logic 		      i_trap,
   input logic 		      i_mret,
   input logic 		      i_mepc,
   input logic 		      i_mtval_pc,
   input logic 		      i_bufreg_q,
   input logic 		      i_bad_pc,
   output logic 		      o_csr_pc,
   //CSR interface
   input logic 		      i_csr_en,
   input logic [1:0] 	      i_csr_addr,
   input logic 		      i_csr,
   output logic 		      o_csr,
   //RD write port
   input logic 		      i_rd_wen,
   input logic [4:0] 	      i_rd_waddr,
   input logic 		      i_ctrl_rd,
   input logic 		      i_alu_rd,
   input logic 		      i_rd_alu_en,
   input logic 		      i_csr_rd,
   input logic 		      i_rd_csr_en,
   input logic 		      i_mem_rd,
   input logic 		      i_rd_mem_en,

   //RS1 read port
   input logic [4:0] 	      i_rs1_raddr,
   output logic 		      o_rs1,
   //RS2 read port
   input logic [4:0] 	      i_rs2_raddr,
   output logic 		      o_rs2);

   logic rd_wen;

   /*
    ********** Write side ***********
    */

   assign 	     rd_wen = i_rd_wen & (|i_rd_waddr);

   generate
   if (|WITH_CSR) begin

   logic rd;
   logic mtval;
   logic sel_rs2;
   logic rd;

   assign 	     rd = (i_ctrl_rd ) |
			  (i_alu_rd & i_rd_alu_en) |
			  (i_csr_rd & i_rd_csr_en) |
			  (i_mem_rd & i_rd_mem_en);

   assign 	     mtval = i_mtval_pc ? i_bad_pc : i_bufreg_q;

   assign 	     o_wdata0 = i_trap ? mtval  : rd;
   assign	     o_wdata1 = i_trap ? i_mepc : i_csr;

   /* Port 0 handles writes to mtval during traps and rd otherwise
    * Port 1 handles writes to mepc during traps and csr accesses otherwise
    *
    * GPR registers are mapped to address 0-31 (bits 0xxxxx).
    * Following that are four CSR registers
    * mscratch 100000
    * mtvec    100001
    * mepc     100010
    * mtval    100011
    */

   assign o_wreg0 = i_trap ? {6'b100011} : {1'b0,i_rd_waddr};
   assign o_wreg1 = i_trap ? {6'b100010} : {4'b1000,i_csr_addr};

   assign       o_wen0 = i_cnt_en & (i_trap | rd_wen);
   assign       o_wen1 = i_cnt_en & (i_trap | i_csr_en);

   /*
    ********** Read side ***********
    */

   //0 : RS1
   //1 : RS2 / CSR

   assign o_rreg0 = {1'b0, i_rs1_raddr};

   /*
    The address of the second read port (o_rreg1) can get assigned from four
    different sources

    Normal operations : i_rs2_raddr
    CSR access        : i_csr_addr
    trap              : MTVEC
    mret              : MEPC

    Address 0-31 in the RF are assigned to the GPRs. After that follows the four
    CSRs on addresses 32-35

    32 MSCRATCH
    33 MTVEC
    34 MEPC
    35 MTVAL

    The expression below is an optimized version of this logic
    */
   assign sel_rs2 = !(i_trap | i_mret | i_csr_en);
   assign o_rreg1 = {~sel_rs2,
		     i_rs2_raddr[4:2] & {3{sel_rs2}},
		     {1'b0,i_trap} | {i_mret,1'b0} | ({2{i_csr_en}} & i_csr_addr) | ({2{sel_rs2}} & i_rs2_raddr[1:0])};

   assign o_rs1 = i_rdata0;
   assign o_rs2 = i_rdata1;
   assign o_csr = i_rdata1 & i_csr_en;
   assign o_csr_pc = i_rdata1;

   end else begin
      assign rd = (i_ctrl_rd ) |
			  (i_alu_rd & i_rd_alu_en) |
			  (i_mem_rd & i_rd_mem_en);

      assign 	     o_wdata0 = rd;
      assign	     o_wdata1 = 1'b0;

      assign o_wreg0 = i_rd_waddr;
      assign o_wreg1 = 5'd0;

      assign       o_wen0 = i_cnt_en & rd_wen;
      assign       o_wen1 = 1'b0;

   /*
    ********** Read side ***********
    */

      assign o_rreg0 = i_rs1_raddr;
      assign o_rreg1 = i_rs2_raddr;

      assign o_rs1 = i_rdata0;
      assign o_rs2 = i_rdata1;
      assign o_csr = 1'b0;
      assign o_csr_pc = 1'b0;
   end // else: !if(WITH_CSR)
   endgenerate
endmodule
