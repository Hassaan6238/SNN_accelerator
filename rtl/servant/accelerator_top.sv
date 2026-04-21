module accelerator_top #(
    parameter WEIGHT_DEPTH_12 = 8192,
    parameter WEIGHT_DEPTH_34 = 8192,
    parameter CHANNELS = 128,
	parameter MAX_NEURONS = 128,
	parameter MAX_SYNAPSES = 128,
    parameter pClockFrequency = 16_000_000,
	parameter DOUBLE_CLOCK = 0,
	parameter UART_QUEUE = 8
)
(
    // cpu
    input  logic         wb_clk,
    input  logic         spi_clk,
    input  logic         wb_rst,
    input  logic [31:0]  i_cpu_adr,
    input  logic [31:0]  i_cpu_dat,
    input  logic         i_cpu_we,
    input  logic         i_cpu_cyc,
    output logic [31:0]  o_cpu_rdt,
	output  logic 		o_cpu_ack,

    // flash
    output logic         o_flash_sck,
    output logic         o_flash_mosi,
    output logic         o_flash_ss,
    input  logic         i_flash_miso,
    
    // snn
    input logic          i_snn_valid,
    output logic         output_buffer_ren,
	output logic [7:0] output_buffer_addr,
	input logic [31:0] output_buffer_out,
    output logic [31:0]  o_snn_adr_w1,
	output logic [31:0]  o_snn_adr_w2,
	output logic [31:0]  o_snn_adr_w3,
	output logic [31:0]  o_snn_adr_w4,
	output logic [ 4:0]  o_snn_we,
    output logic [15:0]  o_snn_dat,
	output logic [clogb2(MAX_SYNAPSES-1)-1:0] snn_input_channels, 
	output logic [clogb2(MAX_NEURONS-1)-1:0] neuron_1, neuron_2, neuron_3, neuron_4, 
	output logic [2:0] layers,

    // uart
    output logic         o_txd,

	//spike mem 1 & 2
	input logic [7:0] i_spike_mem_dat,
	output logic [7:0] o_spike_mem_adr,
	output logic [1:0] o_spike_mem_rd_en,
	output logic [1:0] o_spike_mem_wr_en,
	output logic [3:0] o_spike_mem_dat,

	// sample mem
	input logic [15:0] i_sample_mem_dat,	
	output logic [7:0] o_sample_mem_adr,
	output logic       o_sample_mem_rd_en, 
	output logic        o_sample_mem_wr_en,
	output logic [15:0] o_sample_mem_dat,

	output logic o_encoding_bypass,

	// gate clocks
	output logic gate_spi, gate_snn, gate_enc, gate_serv, 
	input logic timer_irq, 
	output logic gate_general
    );
    
    logic [23:0] spi_if_adr;
    logic [31:0] spi_if_size;
    logic [ 7:0] spi_if_dat;
    logic        ctrl_if_start;
    logic        ctrl_if_clr;
    logic        ctrl_if_load1;
    logic        ctrl_if_load2;
    logic        ctrl_if_set0;
    logic        ctrl_if_snn_we;
    logic        ctrl_spi_valid;
    logic        ctrl_spi_end;
    logic        ctrl_spi_enable;
    logic        ctrl_spi_read_ack;
    logic        uart_if_ready;
    logic [ 7:0] uart_if_data;
    logic        uart_if_send;
	logic        uart_wren;
	logic 		o_uart_hp;
    
//////// UART ///////	
	
	logic uart_tx_go, uart_tx_go_hp;
	logic [7:0] uart_byte, uart_byte_hp;
	logic [clogb2(UART_QUEUE-1)-1:0] sel;
	logic hp_tx_start;
    
    accelerator_if #(
        .WEIGHT_DEPTH_12(WEIGHT_DEPTH_12),
        .WEIGHT_DEPTH_34(WEIGHT_DEPTH_34),
        .CHANNELS       (CHANNELS),
		.MAX_NEURONS	(MAX_NEURONS),
		.MAX_SYNAPSES   (MAX_SYNAPSES)
    )
    aif(
        .i_wb_clk       (wb_clk),
        .i_wb_rst       (wb_rst),

        .i_wb_adr       (i_cpu_adr),
        .i_wb_dat       (i_cpu_dat),
        .i_wb_we        (i_cpu_we),
        .i_wb_cyc       (i_cpu_cyc),
        .o_wb_rdt       (o_cpu_rdt),
		.o_wb_ack		(o_cpu_ack),
        
        .i_snn_valid    (i_snn_valid),
		.output_buffer_ren(output_buffer_ren),
		.output_buffer_addr(output_buffer_addr),
		.output_buffer_out(output_buffer_out), 
        .o_snn_adr_w1   (o_snn_adr_w1),
        .o_snn_adr_w2   (o_snn_adr_w2),
        .o_snn_adr_w3   (o_snn_adr_w3),
        .o_snn_adr_w4   (o_snn_adr_w4),
        .o_snn_we       (o_snn_we),        
        .o_snn_dat      (o_snn_dat),
		.snn_input_channels(snn_input_channels), 
		.neuron_1(neuron_1), .neuron_2(neuron_2), .neuron_3(neuron_3), .neuron_4(neuron_4), 
		.layers(layers),
        
        .i_spi_dat      (spi_if_dat),
        .o_spi_adr      (spi_if_adr),
        .o_spi_siz      (spi_if_size),
        
        .i_ctrl_clr     (ctrl_if_clr),
        .i_ctrl_load1   (ctrl_if_load1),
        .i_ctrl_load2   (ctrl_if_load2),
        .i_ctrl_set0    (ctrl_if_set0),
        .i_ctrl_snn_we  (ctrl_if_snn_we),
        .o_ctrl_start   (ctrl_if_start),

        .i_uart_ready   (uart_if_ready),
        .o_uart_data    (uart_if_data),
        .o_uart_send    (uart_if_send),
		.o_uart_wren    (uart_wren),
		.o_uart_hp		(o_uart_hp),
		
		//spike mem 1 & 2
		.i_spike_mem_dat(i_spike_mem_dat),
		.o_spike_mem_adr(o_spike_mem_adr),
		.o_spike_mem_rd_en(o_spike_mem_rd_en),
		.o_spike_mem_wr_en(o_spike_mem_wr_en),
		.o_spike_mem_dat(o_spike_mem_dat),
		// sample mem
		.i_sample_mem_dat(i_sample_mem_dat),	
		.o_sample_mem_adr(o_sample_mem_adr),
		.o_sample_mem_rd_en(o_sample_mem_rd_en),
		.o_sample_mem_wr_en(o_sample_mem_wr_en),
		.o_sample_mem_dat(o_sample_mem_dat),
		
		.o_encoding_bypass(o_encoding_bypass),

		.gate_spi(gate_spi), .gate_snn(gate_snn), .gate_enc(gate_enc), .gate_serv(gate_serv), 
		.timer_irq(timer_irq), .gate_general(gate_general)
    );
    
    spi_acc_control #(.DOUBLE_CLOCK(DOUBLE_CLOCK)) sac(
        .wb_clk(spi_clk),
        .wb_rst(wb_rst),
        .i_if_start     (ctrl_if_start),
        .o_if_clr       (ctrl_if_clr),
        .o_if_load1     (ctrl_if_load1),
        .o_if_load2     (ctrl_if_load2),
        .o_if_set0      (ctrl_if_set0),
        .i_spi_valid    (ctrl_spi_valid),
        .i_spi_end      (ctrl_spi_end),
        .o_spi_en       (ctrl_spi_enable),
        .o_spi_read_ack (ctrl_spi_read_ack),
        .o_if_snn_we    (ctrl_if_snn_we)
    );

    spi_master spi(
        .clk                (spi_clk),
        .reset              (wb_rst),
        .SPI_SCK            (o_flash_sck),
        .SPI_SS             (o_flash_ss),
        .SPI_MOSI           (o_flash_mosi),
        .SPI_MISO           (i_flash_miso),
        .en                 (ctrl_spi_enable),
        .addr               (spi_if_adr),
        .valid              (ctrl_spi_valid),
        .end_transaction    (ctrl_spi_end),
        .rd_ack             (ctrl_spi_read_ack),
        .rd_data            (spi_if_dat),
        .words_to_read      (spi_if_size),
        .read_req           (1'b1),
        .wr_data            (8'b0)
    );



	assign hp_tx_start = uart_wren & o_uart_hp;

	fsm_uart_tx #( .N(UART_QUEUE)) 
	fsm_uart_tx_i
		(
		.clk(wb_clk),
		.rst(wb_rst),
		.i_start(hp_tx_start),
		.i_continue(uart_if_ready),
		.o_sel(sel),
		.o_valid(uart_tx_go_hp)
		);

	assign uart_byte_hp =  (sel == 0)? output_buffer_out[7:0] : 
                           (sel == 1)? output_buffer_out[15:8]:
                           (sel == 2)? output_buffer_out[23:16] : 
                        	     	   output_buffer_out[31:24];
		
	assign uart_byte = o_uart_hp ? uart_byte_hp : uart_if_data;
	assign uart_tx_go = o_uart_hp ? uart_tx_go_hp : uart_wren;

	SerialTransmitter #(.pClockFrequency(pClockFrequency), .pBaudRate(4000000))
	uart_transmitter(
		.iClock (wb_clk),
		.iData  (uart_byte),
		.iSend  (uart_tx_go),
		.oReady (uart_if_ready),
		.oTxd   (o_txd)); 


	//  The following function calculates the address width based on specified RAM depth
	function integer clogb2;
	  input integer depth;
		for (clogb2=0; depth>0; clogb2=clogb2+1)
		  depth = depth >> 1;
	endfunction 
    
endmodule

