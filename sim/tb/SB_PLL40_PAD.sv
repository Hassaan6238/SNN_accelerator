module SB_PLL40_PAD (
	input logic PACKAGEPIN,
	output logic PLLOUTCORE,
	output logic PLLOUTGLOBAL,
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
	parameter SHIFTREG_DIV_MODE = 1'b0;
	parameter FDA_FEEDBACK = 4'b0000;
	parameter FDA_RELATIVE = 4'b0000;
	parameter PLLOUT_SELECT = "GENCLK";
	parameter DIVR = 4'b0000;
	parameter DIVF = 7'b0000000;
	parameter DIVQ = 3'b000;
	parameter FILTER_RANGE = 3'b000;
	parameter ENABLE_ICEGATE = 1'b0;
	parameter TEST_MODE = 1'b0;
	parameter EXTERNAL_DIVIDE_FACTOR = 1;


	assign LOCK = 1'b1;
	assign PLLOUTCORE = PACKAGEPIN;

endmodule
