/* Arbitrates between dbus and ibus accesses.
 * Relies on the fact that not both masters are active at the same time
 */
module servant_arbiter
  (
   input logic [31:0]  i_wb_cpu_dbus_adr,
   input logic [31:0]  i_wb_cpu_dbus_dat,
   input logic [3:0]   i_wb_cpu_dbus_sel,
   input logic 	      i_wb_cpu_dbus_we,
   input logic 	      i_wb_cpu_dbus_cyc,
   output logic [31:0] o_wb_cpu_dbus_rdt,
   output logic 	      o_wb_cpu_dbus_ack,

   input logic [31:0]  i_wb_cpu_ibus_adr,
   input logic 	      i_wb_cpu_ibus_cyc,
   output logic [31:0] o_wb_cpu_ibus_rdt,
   output logic 	      o_wb_cpu_ibus_ack,

   output logic [31:0] o_wb_cpu_adr,
   output logic [31:0] o_wb_cpu_dat,
   output logic [3:0]  o_wb_cpu_sel,
   output logic 	      o_wb_cpu_we,
   output logic 	      o_wb_cpu_cyc,
   input logic [31:0]  i_wb_cpu_rdt,
   input logic 	      i_wb_cpu_ack);

   assign o_wb_cpu_dbus_rdt = i_wb_cpu_rdt;
   assign o_wb_cpu_dbus_ack = i_wb_cpu_ack & !i_wb_cpu_ibus_cyc;

   assign o_wb_cpu_ibus_rdt = i_wb_cpu_rdt;
   assign o_wb_cpu_ibus_ack = i_wb_cpu_ack & i_wb_cpu_ibus_cyc;

   assign o_wb_cpu_adr = i_wb_cpu_ibus_cyc ? i_wb_cpu_ibus_adr : i_wb_cpu_dbus_adr;
   assign o_wb_cpu_dat = i_wb_cpu_dbus_dat;
   assign o_wb_cpu_sel = i_wb_cpu_dbus_sel;
   assign o_wb_cpu_we  = i_wb_cpu_dbus_we & !i_wb_cpu_ibus_cyc;
   assign o_wb_cpu_cyc = i_wb_cpu_ibus_cyc | i_wb_cpu_dbus_cyc;

endmodule
