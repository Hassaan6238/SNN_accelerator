module serv_decode
  #(parameter [0:0] PRE_REGISTER = 1,
    parameter [0:0] MDU = 0)
  (
   input logic        clk,
   //Input
   input logic [31:2] i_wb_rdt,
   input logic        i_wb_en,
   //To state
   output logic       o_sh_right,
   output logic       o_bne_or_bge,
   output logic       o_cond_branch,
   output logic       o_e_op,
   output logic       o_ebreak,
   output logic       o_branch_op,
   output logic       o_shift_op,
   output logic       o_slt_or_branch,
   output logic       o_rd_op,
   output logic       o_two_stage_op,
   output logic       o_dbus_en,
   //MDU
   output logic       o_mdu_op,
   //Extension
   output logic [2:0] o_ext_funct3,
   //To bufreg
   output logic       o_bufreg_rs1_en,
   output logic       o_bufreg_imm_en,
   output logic       o_bufreg_clr_lsb,
   output logic       o_bufreg_sh_signed,
   //To ctrl
   output logic       o_ctrl_jal_or_jalr,
   output logic       o_ctrl_utype,
   output logic       o_ctrl_pc_rel,
   output logic       o_ctrl_mret,
   //To alu
   output logic       o_alu_sub,
   output logic [1:0] o_alu_bool_op,
   output logic       o_alu_cmp_eq,
   output logic       o_alu_cmp_sig,
   output logic [2:0] o_alu_rd_sel,
   //To mem IF
   output logic       o_mem_signed,
   output logic       o_mem_word,
   output logic       o_mem_half,
   output logic       o_mem_cmd,
   //To CSR
   output logic       o_csr_en,
   output logic [1:0] o_csr_addr,
   output logic       o_csr_mstatus_en,
   output logic       o_csr_mie_en,
   output logic       o_csr_mcause_en,
   output logic [1:0] o_csr_source,
   output logic       o_csr_d_sel,
   output logic       o_csr_imm_en,
   output logic       o_mtval_pc,
   //To top
   output logic [3:0] o_immdec_ctrl,
   output logic [3:0] o_immdec_en,
   output logic       o_op_b_source,
   //To RF IF
   output logic       o_rd_mem_en,
   output logic       o_rd_csr_en,
   output logic       o_rd_alu_en);

   logic [4:0] opcode;
   logic [2:0] funct3;
   logic        op20;
   logic        op21;
   logic        op22;
   logic        op26;

   logic       imm25;
   logic       imm30;
   logic co_mdu_op;
   logic co_two_stage_op;
   logic co_shift_op;
   logic co_slt_or_branch;
   logic co_branch_op;
   logic co_dbus_en;
   logic co_mtval_pc;
   logic co_mem_word;
   logic co_rd_alu_en;
   logic co_rd_mem_en;
   logic [2:0] co_ext_funct3;
   logic co_bufreg_rs1_en;
   logic co_bufreg_imm_en;
   logic co_bufreg_clr_lsb;
   logic co_cond_branch;
   logic co_ctrl_utype;
   logic co_ctrl_jal_or_jalr;
   logic co_ctrl_pc_rel;
   logic co_rd_op;
   logic co_sh_right;
   logic co_bne_or_bge;
   logic csr_op;
   logic co_ebreak;
   logic co_ctrl_mret;
   logic co_e_op;
   logic co_bufreg_sh_signed;
   logic co_alu_sub;
   logic csr_valid;
   logic co_rd_csr_en;
   logic co_csr_en;
   logic co_csr_mstatus_en;
   logic co_csr_mie_en;
   logic co_csr_mcause_en;
   logic [1:0] co_csr_source;
   logic co_csr_d_sel;
   logic co_csr_imm_en;
   logic [1:0] co_csr_addr;
   logic co_alu_cmp_eq;
   logic co_alu_cmp_sig;
   logic co_mem_cmd;
   logic co_mem_signed;
   logic co_mem_half;
   logic [1:0] co_alu_bool_op;
   logic [3:0] co_immdec_ctrl;
   logic [3:0] co_immdec_en;
   logic [2:0] co_alu_rd_sel;
   logic co_op_b_source;
   logic co_immdec_ctrl;
   logic  co_immdec_en;
   logic co_alu_rd_sel;
   
   assign co_mdu_op     = MDU & (opcode == 5'b01100) & imm25;

   assign co_two_stage_op =
	~opcode[2] | (funct3[0] & ~funct3[1] & ~opcode[0] & ~opcode[4]) |
	(funct3[1] & ~funct3[2] & ~opcode[0] & ~opcode[4]) | co_mdu_op;
   assign co_shift_op = (opcode[2] & ~funct3[1]) & !co_mdu_op;
   assign co_slt_or_branch = (opcode[4] | (funct3[1] & opcode[2]) | (imm30 & opcode[2] & opcode[3] & ~funct3[2])) & !co_mdu_op;
   assign co_branch_op = opcode[4];
   assign co_dbus_en    = ~opcode[2] & ~opcode[4];
   assign co_mtval_pc   = opcode[4];   
   assign co_mem_word   = funct3[1];
   assign co_rd_alu_en  = !opcode[0] & opcode[2] & !opcode[4] & !co_mdu_op;
   assign co_rd_mem_en  = (!opcode[2] & !opcode[0]) | co_mdu_op;
   assign co_ext_funct3 = funct3;

   //jal,branch =     imm
   //jalr       = rs1+imm
   //mem        = rs1+imm
   //shift      = rs1
   assign co_bufreg_rs1_en = !opcode[4] | (!opcode[1] & opcode[0]);
   assign co_bufreg_imm_en = !opcode[2];

   //Clear LSB of immediate for BRANCH and JAL ops
   //True for BRANCH and JAL
   //False for JALR/LOAD/STORE/OP/OPIMM?
   assign co_bufreg_clr_lsb = opcode[4] & ((opcode[1:0] == 2'b00) | (opcode[1:0] == 2'b11));

   //Conditional branch
   //True for BRANCH
   //False for JAL/JALR
   assign co_cond_branch = !opcode[0];

   assign co_ctrl_utype       = !opcode[4] & opcode[2] & opcode[0];
   assign co_ctrl_jal_or_jalr = opcode[4] & opcode[0];

   //PC-relative operations
   //True for jal, b* auipc, ebreak
   //False for jalr, lui
   assign co_ctrl_pc_rel = (opcode[2:0] == 3'b000)  |
                          (opcode[1:0] == 2'b11)  |
                          (opcode[4] & opcode[2]) & op20|
                          (opcode[4:3] == 2'b00);
   //Write to RD
   //True for OP-IMM, AUIPC, OP, LUI, SYSTEM, JALR, JAL, LOAD
   //False for STORE, BRANCH, MISC-MEM
   assign co_rd_op = (opcode[2] |
                     (!opcode[2] & opcode[4] & opcode[0]) |
                     (!opcode[2] & !opcode[3] & !opcode[0]));

   //
   //funct3
   //

   assign co_sh_right   = funct3[2];
   assign co_bne_or_bge = funct3[0];

   //Matches system ops except eceall/ebreak/mret
   assign csr_op = opcode[4] & opcode[2] & (|funct3);


   //op20
   assign co_ebreak = op20;


   //opcode & funct3 & op21

   assign co_ctrl_mret = opcode[4] & opcode[2] & op21 & !(|funct3);
   //Matches system opcodes except CSR accesses (funct3 == 0)
   //and mret (!op21)
   assign co_e_op = opcode[4] & opcode[2] & !op21 & !(|funct3);

   //opcode & funct3 & imm30

   assign co_bufreg_sh_signed = imm30;

   /*
    True for sub, b*, slt*
    False for add*
    op    opcode f3  i30
    b*    11000  xxx x   t
    addi  00100  000 x   f
    slt*  0x100  01x x   t
    add   01100  000 0   f
    sub   01100  000 1   t
    */
    assign co_alu_sub = funct3[1] | funct3[0] | (opcode[3] & imm30) | opcode[4];

   /*
    Bits 26, 22, 21 and 20 are enough to uniquely identify the eight supported CSR regs
    mtvec, mscratch, mepc and mtval are stored externally (normally in the RF) and are
    treated differently from mstatus, mie and mcause which are stored in serv_csr.

    The former get a 2-bit address as seen below while the latter get a
    one-hot enable signal each.

    Hex|2 222|Reg     |csr
    adr|6 210|name    |addr
    ---|-----|--------|----
    300|0_000|mstatus | xx
    304|0_100|mie     | xx
    305|0_101|mtvec   | 01
    340|1_000|mscratch| 00
    341|1_001|mepc    | 10
    342|1_010|mcause  | xx
    343|1_011|mtval   | 11

    */

   //true  for mtvec,mscratch,mepc and mtval
   //false for mstatus, mie, mcause

   assign csr_valid = op20 | (op26 & !op21);

   assign co_rd_csr_en = csr_op;

   assign co_csr_en         = csr_op & csr_valid;
   assign co_csr_mstatus_en = csr_op & !op26 & !op22;
   assign co_csr_mie_en     = csr_op & !op26 &  op22 & !op20;
   assign co_csr_mcause_en  = csr_op         &  op21 & !op20;


   assign co_csr_source = funct3[1:0];
   assign co_csr_d_sel = funct3[2];
   assign co_csr_imm_en = opcode[4] & opcode[2] & funct3[2];
   assign  co_csr_addr = {op26 & op20, !op26 | op21};

   assign co_alu_cmp_eq = funct3[2:1] == 2'b00;

   assign co_alu_cmp_sig = ~((funct3[0] & funct3[1]) | (funct3[1] & funct3[2]));

   assign co_mem_cmd  = opcode[3];
   assign co_mem_signed = ~funct3[2];
   assign co_mem_half   = funct3[0];

   assign  co_alu_bool_op = funct3[1:0];

   //True for S (STORE) or B (BRANCH) type instructions
   //False for J type instructions
   assign co_immdec_ctrl[0] = opcode[3:0] == 4'b1000;
   //True for OP-IMM, LOAD, STORE, JALR  (I S)
   //False for LUI, AUIPC, JAL           (U J)
   assign co_immdec_ctrl[1] = (opcode[1:0] == 2'b00) | (opcode[2:1] == 2'b00);
   assign co_immdec_ctrl[2] = opcode[4] & !opcode[0];
   assign co_immdec_ctrl[3] = opcode[4];

   assign co_immdec_en[3] = opcode[4] | opcode[3] | opcode[2] | !opcode[0];                 //B I J S U
   assign co_immdec_en[2] = (opcode[4] & opcode[2]) | !opcode[3] | opcode[0];               //  I J   U
   assign co_immdec_en[1] = (opcode[2:1] == 2'b01) | (opcode[2] & opcode[0]) | co_csr_imm_en;//    J   U
   assign co_immdec_en[0] = ~co_rd_op;                                                       //B     S

   assign co_alu_rd_sel[0] = (funct3 == 3'b000); // Add/sub
   assign co_alu_rd_sel[1] = (funct3[2:1] == 2'b01); //SLT*
   assign co_alu_rd_sel[2] = funct3[2]; //Bool

   //0 (OP_B_SOURCE_IMM) when OPIMM
   //1 (OP_B_SOURCE_RS2) when BRANCH or OP
   assign co_op_b_source = opcode[3];

   generate
      if (PRE_REGISTER) begin

         always @(posedge clk) begin
            if (i_wb_en) begin
               funct3 <= i_wb_rdt[14:12];
               imm30  <= i_wb_rdt[30];
               imm25  <= i_wb_rdt[25];
               opcode <= i_wb_rdt[6:2];
               op20   <= i_wb_rdt[20];
               op21   <= i_wb_rdt[21];
               op22   <= i_wb_rdt[22];
               op26   <= i_wb_rdt[26];
            end
         end

         always @(*) begin
            o_sh_right         = co_sh_right;
            o_bne_or_bge       = co_bne_or_bge;
            o_cond_branch      = co_cond_branch;
            o_dbus_en          = co_dbus_en;
            o_mtval_pc         = co_mtval_pc;
	    o_two_stage_op     = co_two_stage_op;
            o_e_op             = co_e_op;
            o_ebreak           = co_ebreak;
            o_branch_op        = co_branch_op;
            o_shift_op         = co_shift_op;
            o_slt_or_branch    = co_slt_or_branch;
            o_rd_op            = co_rd_op;
            o_mdu_op           = co_mdu_op;
            o_ext_funct3       = co_ext_funct3;
            o_bufreg_rs1_en    = co_bufreg_rs1_en;
            o_bufreg_imm_en    = co_bufreg_imm_en;
            o_bufreg_clr_lsb   = co_bufreg_clr_lsb;
            o_bufreg_sh_signed = co_bufreg_sh_signed;
            o_ctrl_jal_or_jalr = co_ctrl_jal_or_jalr;
            o_ctrl_utype       = co_ctrl_utype;
            o_ctrl_pc_rel      = co_ctrl_pc_rel;
            o_ctrl_mret        = co_ctrl_mret;
            o_alu_sub          = co_alu_sub;
            o_alu_bool_op      = co_alu_bool_op;
            o_alu_cmp_eq       = co_alu_cmp_eq;
            o_alu_cmp_sig      = co_alu_cmp_sig;
            o_alu_rd_sel       = co_alu_rd_sel;
            o_mem_signed       = co_mem_signed;
            o_mem_word         = co_mem_word;
            o_mem_half         = co_mem_half;
            o_mem_cmd          = co_mem_cmd;
            o_csr_en           = co_csr_en;
            o_csr_addr         = co_csr_addr;
            o_csr_mstatus_en   = co_csr_mstatus_en;
            o_csr_mie_en       = co_csr_mie_en;
            o_csr_mcause_en    = co_csr_mcause_en;
            o_csr_source       = co_csr_source;
            o_csr_d_sel        = co_csr_d_sel;
            o_csr_imm_en       = co_csr_imm_en;
            o_immdec_ctrl      = co_immdec_ctrl;
            o_immdec_en        = co_immdec_en;
            o_op_b_source      = co_op_b_source;
            o_rd_csr_en        = co_rd_csr_en;
            o_rd_alu_en        = co_rd_alu_en;
            o_rd_mem_en        = co_rd_mem_en;
         end

      end else begin

         always @(*) begin
            funct3  = i_wb_rdt[14:12];
            imm30   = i_wb_rdt[30];
            imm25   = i_wb_rdt[25];
            opcode  = i_wb_rdt[6:2];
            op20    = i_wb_rdt[20];
            op21    = i_wb_rdt[21];
            op22    = i_wb_rdt[22];
            op26    = i_wb_rdt[26];
         end

         always @(posedge clk) begin
            if (i_wb_en) begin
               o_sh_right         <= co_sh_right;
               o_bne_or_bge       <= co_bne_or_bge;
               o_cond_branch      <= co_cond_branch;
               o_e_op             <= co_e_op;
               o_ebreak           <= co_ebreak;
               o_two_stage_op     <= co_two_stage_op;
               o_dbus_en          <= co_dbus_en;
               o_mtval_pc         <= co_mtval_pc;
               o_branch_op        <= co_branch_op;
               o_shift_op         <= co_shift_op;
               o_slt_or_branch    <= co_slt_or_branch;
               o_rd_op            <= co_rd_op;
               o_mdu_op           <= co_mdu_op;
               o_ext_funct3       <= co_ext_funct3;
               o_bufreg_rs1_en    <= co_bufreg_rs1_en;
               o_bufreg_imm_en    <= co_bufreg_imm_en;
               o_bufreg_clr_lsb   <= co_bufreg_clr_lsb;
               o_bufreg_sh_signed <= co_bufreg_sh_signed;
               o_ctrl_jal_or_jalr <= co_ctrl_jal_or_jalr;
               o_ctrl_utype       <= co_ctrl_utype;
               o_ctrl_pc_rel      <= co_ctrl_pc_rel;
               o_ctrl_mret        <= co_ctrl_mret;
               o_alu_sub          <= co_alu_sub;
               o_alu_bool_op      <= co_alu_bool_op;
               o_alu_cmp_eq       <= co_alu_cmp_eq;
               o_alu_cmp_sig      <= co_alu_cmp_sig;
               o_alu_rd_sel       <= co_alu_rd_sel;
               o_mem_signed       <= co_mem_signed;
               o_mem_word         <= co_mem_word;
               o_mem_half         <= co_mem_half;
               o_mem_cmd          <= co_mem_cmd;
               o_csr_en           <= co_csr_en;
               o_csr_addr         <= co_csr_addr;
               o_csr_mstatus_en   <= co_csr_mstatus_en;
               o_csr_mie_en       <= co_csr_mie_en;
               o_csr_mcause_en    <= co_csr_mcause_en;
               o_csr_source       <= co_csr_source;
               o_csr_d_sel        <= co_csr_d_sel;
               o_csr_imm_en       <= co_csr_imm_en;
               o_immdec_ctrl      <= co_immdec_ctrl;
               o_immdec_en        <= co_immdec_en;
               o_op_b_source      <= co_op_b_source;
               o_rd_csr_en        <= co_rd_csr_en;
               o_rd_alu_en        <= co_rd_alu_en;
               o_rd_mem_en        <= co_rd_mem_en;
            end
         end

      end
   endgenerate

endmodule
