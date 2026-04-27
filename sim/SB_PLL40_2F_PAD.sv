module SB_PLL40_2F_PAD (
	input logic PACKAGEPIN,
	output logic PLLOUTCOREA = 1,
	output logic PLLOUTGLOBALA,
	output logic PLLOUTCOREB = 1,
	output logic PLLOUTGLOBALB,
	input logic EXTFEEDBACK,
	input logic [7:0] DYNAMICDELAY,
	output logic LOCK,
	input logic BYPASS,
	input logic RESETB,
	input logic LATCHINPUTVALUE,
	output logic SDO,
	input logic SDI,
	input logic SCLK
);
	parameter FEEDBACK_PATH = "SIMPLE";
	parameter DELAY_ADJUSTMENT_MODE_FEEDBACK = "FIXED";
	parameter DELAY_ADJUSTMENT_MODE_RELATIVE = "FIXED";
	parameter SHIFTREG_DIV_MODE = 2'b00;
	parameter FDA_FEEDBACK = 4'b0000;
	parameter FDA_RELATIVE = 4'b0000;
	parameter PLLOUT_SELECT_PORTA = "GENCLK";
	parameter PLLOUT_SELECT_PORTB = "GENCLK";
	parameter DIVR = 4'b0000;
	parameter DIVF = 7'b0000000;
	parameter DIVQ = 3'b000;
	parameter FILTER_RANGE = 3'b000;
	parameter ENABLE_ICEGATE_PORTA = 1'b0;
	parameter ENABLE_ICEGATE_PORTB = 1'b0;
	parameter TEST_MODE = 1'b0;
	parameter EXTERNAL_DIVIDE_FACTOR = 1;

	assign LOCK = 1'b1;
	always #15500 PLLOUTCOREA <= !PLLOUTCOREA;
	always #31000 PLLOUTCOREB <= !PLLOUTCOREB;
	
endmodule
