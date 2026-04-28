module vlog_tb_utils;
   parameter MAX_STRING_LEN = 128;
   localparam CHAR_WIDTH = 8;

   //Force simulation stop after timeout cycles
   logic [63:0] timeout;
   logic [MAX_STRING_LEN*CHAR_WIDTH-1:0] testcase;
   logic [63:0] heartbeat;
   
   initial
     if($value$plusargs("timeout=%d", timeout)) begin
	#timeout $display("Timeout: Forcing end of simulation");
	$finish;
     end

   //FIXME: Add more options for VCD logging

   initial begin
      if($test$plusargs("vcd")) begin
	 if($value$plusargs("testcase=%s", testcase))
	   $dumpfile({testcase,".vcd"});
	 else
	   $dumpfile("testlog.vcd");
	 $dumpvars;
      end
   end

   //Heartbeat timer for simulations
   initial begin
      if($value$plusargs("heartbeat=%d", heartbeat))
	forever #heartbeat $display("Heartbeat : Time=%0t", $time);
   end

endmodule // vlog_tb_utils
