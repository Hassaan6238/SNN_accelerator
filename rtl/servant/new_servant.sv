module servant(
    input  logic         wb_clk,
	input  logic         timer_clk,
    input  logic         wb_rst,
    output logic [3:0]   led,
	input  logic [2:0]   buttons,
 	output logic 	    timer_irq,	

    output logic [31:0]  o_wb_acc_adr,
    output logic [31:0]  o_wb_acc_dat,
    output logic         o_wb_acc_we,
    output logic         o_wb_acc_cyc,
    input  logic [31:0]  i_wb_acc_rdt,
	input logic          i_wb_acc_ack
);

    parameter memfile = "zephyr_hello.hex";
    parameter memsize = 8192;
    parameter reset_strategy = "MINI";
    parameter sim = 0;
    parameter with_csr = 1;
    parameter [0:0] compress = 0;
    parameter [0:0] align = compress;

    logic [31:0] wb_ibus_adr;
    logic 	    wb_ibus_cyc;
    logic [31:0] wb_ibus_rdt;
    logic 	    wb_ibus_ack;

    logic [31:0] wb_dbus_adr;
    logic [31:0] wb_dbus_dat;
    logic [3:0] 	wb_dbus_sel;
    logic 	    wb_dbus_we;
    logic 	    wb_dbus_cyc;
    logic [31:0] wb_dbus_rdt;
    logic 	    wb_dbus_ack;

    logic [31:0] wb_dmem_adr;
    logic [31:0] wb_dmem_dat;
    logic [ 3:0] wb_dmem_sel;
    logic 	    wb_dmem_we;
    logic 	    wb_dmem_cyc;
    logic [31:0] wb_dmem_rdt;
    logic 	    wb_dmem_ack;

    logic [31:0]	wb_mem_adr;
    logic [31:0] wb_mem_dat;
    logic [ 3:0] wb_mem_sel;
    logic 	    wb_mem_we;
    logic 	    wb_mem_cyc;
    logic [31:0] wb_mem_rdt;
    logic 	    wb_mem_ack;

    logic [31:0] wb_gamux_adr;
    logic [31:0]	wb_gamux_dat;
    logic        wb_gamux_we;
    logic 	    wb_gamux_cyc;
    logic [31:0]	wb_gamux_rdt;

	logic [31:0] wb_gpio_adr;
    logic [31:0] wb_gpio_dat;
    logic        wb_gpio_we;
    logic 	    wb_gpio_cyc;
    logic [31:0] wb_gpio_rdt;

    logic [31:0] wb_timer_adr;
    logic [31:0] wb_timer_dat;
    logic 	    wb_timer_we;
    logic 	    wb_timer_cyc;
    logic [31:0] wb_timer_rdt;

    logic [31:0] mdu_rs1;
    logic [31:0] mdu_rs2;
    logic [ 2:0] mdu_op;
    logic        mdu_valid;
    logic [31:0] mdu_rd;
    logic        mdu_ready;

    servant_arbiter arbiter(
        .i_wb_cpu_dbus_adr (wb_dmem_adr),
        .i_wb_cpu_dbus_dat (wb_dmem_dat),
        .i_wb_cpu_dbus_sel (wb_dmem_sel),
        .i_wb_cpu_dbus_we  (wb_dmem_we ),
        .i_wb_cpu_dbus_cyc (wb_dmem_cyc),
        .o_wb_cpu_dbus_rdt (wb_dmem_rdt),
        .o_wb_cpu_dbus_ack (wb_dmem_ack),

        .i_wb_cpu_ibus_adr (wb_ibus_adr),
        .i_wb_cpu_ibus_cyc (wb_ibus_cyc),
        .o_wb_cpu_ibus_rdt (wb_ibus_rdt),
        .o_wb_cpu_ibus_ack (wb_ibus_ack),

        .o_wb_cpu_adr (wb_mem_adr),
        .o_wb_cpu_dat (wb_mem_dat),
        .o_wb_cpu_sel (wb_mem_sel),
        .o_wb_cpu_we  (wb_mem_we ),
        .o_wb_cpu_cyc (wb_mem_cyc),
        .i_wb_cpu_rdt (wb_mem_rdt),
        .i_wb_cpu_ack (wb_mem_ack)
        );

   servant_mux #(sim) servant_mux
     (
      .i_clk (wb_clk),
      .i_rst (wb_rst & (reset_strategy != "NONE")),
      .i_wb_cpu_adr (wb_dbus_adr),
      .i_wb_cpu_dat (wb_dbus_dat),
      .i_wb_cpu_sel (wb_dbus_sel),
      .i_wb_cpu_we  (wb_dbus_we),
      .i_wb_cpu_cyc (wb_dbus_cyc),
      .o_wb_cpu_rdt (wb_dbus_rdt),
      .o_wb_cpu_ack (wb_dbus_ack),

      .o_wb_mem_adr (wb_dmem_adr),
      .o_wb_mem_dat (wb_dmem_dat),
      .o_wb_mem_sel (wb_dmem_sel),
      .o_wb_mem_we  (wb_dmem_we),
      .o_wb_mem_cyc (wb_dmem_cyc),
      .i_wb_mem_rdt (wb_dmem_rdt),

      .o_wb_gpio_adr (wb_gpio_adr),
      .o_wb_gpio_dat (wb_gpio_dat),
      .o_wb_gpio_we (wb_gpio_we),
      .o_wb_gpio_cyc (wb_gpio_cyc),
      .i_wb_gpio_rdt (wb_gpio_rdt), 

      .o_wb_acc_adr (o_wb_acc_adr),
      .o_wb_acc_dat (o_wb_acc_dat),
      .o_wb_acc_we (o_wb_acc_we),
      .o_wb_acc_cyc (o_wb_acc_cyc),
      .i_wb_acc_rdt (i_wb_acc_rdt),
	  .i_wb_acc_ack (i_wb_acc_ack),

      .o_wb_timer_adr (wb_timer_adr),
      .o_wb_timer_dat (wb_timer_dat),
      .o_wb_timer_we  (wb_timer_we),
      .o_wb_timer_cyc (wb_timer_cyc),
      .i_wb_timer_rdt (wb_timer_rdt));

   servant_ram
     #(.memfile (memfile),
       .depth (memsize),
       .RESET_STRATEGY (reset_strategy))
   ram
     (// Wishbone interface
      .i_wb_clk (wb_clk),
      .i_wb_rst (wb_rst),
      .i_wb_adr (wb_mem_adr[$clog2(memsize)-1:2]),
      .i_wb_cyc (wb_mem_cyc),
      .i_wb_we  (wb_mem_we) ,
      .i_wb_sel (wb_mem_sel),
      .i_wb_dat (wb_mem_dat),
      .o_wb_rdt (wb_mem_rdt),
      .o_wb_ack (wb_mem_ack));

	//`ifdef IEEG
		 servant_timer
		   #(.RESET_STRATEGY (reset_strategy),
			 .WIDTH (32))
		 timer
		   (.i_clk    (wb_clk), // always on clk
			.i_rst    (wb_rst),
			.o_irq    (),
			.i_wb_cyc (wb_timer_cyc),
			.i_wb_we  (wb_timer_we) ,
			.i_wb_dat (wb_timer_dat),
			.o_wb_rdt ());
	
	// EMG		
		 servant_slow_timer
		   #(.RESET_STRATEGY (reset_strategy),
			 .WIDTH (32))
		 timer_slow
		   (.i_clk    (wb_clk), // serv stops gating stops with the interrupt
			.slow_clk (timer_clk),
			.i_rst    (wb_rst),
			.o_irq    (timer_irq),
			.i_wb_cyc (wb_timer_cyc),
			.i_wb_we  (wb_timer_we) ,
			.i_wb_dat (wb_timer_dat),
			.o_wb_rdt (wb_timer_rdt));
	
   servant_gpio gpio
     (.i_wb_clk (wb_clk),
      .i_wb_adr (wb_gpio_adr),            
      .i_wb_dat (wb_gpio_dat),
      .i_wb_we  (wb_gpio_we),
      .i_wb_cyc (wb_gpio_cyc),
      .o_wb_rdt (wb_gpio_rdt),
      .led   (led),
	  .buttons(buttons)); 

   serv_rf_top
     #(.RESET_PC (32'h0000_0000),
       .RESET_STRATEGY (reset_strategy),
  `ifdef MDU
       .MDU(1),
  `endif 
       .WITH_CSR (with_csr),
       .COMPRESSED(compress),
       .ALIGN(align))
   cpu
     (
      .clk      (wb_clk),
      .i_rst    (wb_rst),
      .i_timer_irq  (timer_irq),
`ifdef RISCV_FORMAL
      .rvfi_valid     (),
      .rvfi_order     (),
      .rvfi_insn      (),
      .rvfi_trap      (),
      .rvfi_halt      (),
      .rvfi_intr      (),
      .rvfi_mode      (),
      .rvfi_ixl       (),
      .rvfi_rs1_addr  (),
      .rvfi_rs2_addr  (),
      .rvfi_rs1_rdata (),
      .rvfi_rs2_rdata (),
      .rvfi_rd_addr   (),
      .rvfi_rd_wdata  (),
      .rvfi_pc_rdata  (),
      .rvfi_pc_wdata  (),
      .rvfi_mem_addr  (),
      .rvfi_mem_rmask (),
      .rvfi_mem_wmask (),
      .rvfi_mem_rdata (),
      .rvfi_mem_wdata (),
`endif

      .o_ibus_adr   (wb_ibus_adr),
      .o_ibus_cyc   (wb_ibus_cyc),
      .i_ibus_rdt   (wb_ibus_rdt),
      .i_ibus_ack   (wb_ibus_ack),

      .o_dbus_adr   (wb_dbus_adr),
      .o_dbus_dat   (wb_dbus_dat),
      .o_dbus_sel   (wb_dbus_sel),
      .o_dbus_we    (wb_dbus_we),
      .o_dbus_cyc   (wb_dbus_cyc),
      .i_dbus_rdt   (wb_dbus_rdt),
      .i_dbus_ack   (wb_dbus_ack),
      
      //Extension
      .o_ext_rs1    (mdu_rs1),
      .o_ext_rs2    (mdu_rs2),
      .o_ext_funct3 (mdu_op),
      .i_ext_rd     (mdu_rd),
      .i_ext_ready  (mdu_ready),
      //MDU
      .o_mdu_valid  (mdu_valid));

`ifdef MDU
    mdu_top mdu_serv
    (
     .i_clk(wb_clk),
     .i_rst(wb_rst),
     .i_mdu_rs1(mdu_rs1),
     .i_mdu_rs2(mdu_rs2),
     .i_mdu_op(mdu_op),
     .i_mdu_valid(mdu_valid),
     .o_mdu_ready(mdu_ready),
     .o_mdu_rd(mdu_rd));
`else
    assign mdu_ready = 1'b0;
    assign mdu_rd = 32'b0;
`endif

endmodule
