`timescale 1ns / 1ps
module processor_top_tb();
integer i = 0;
reg clk = 0,sys_rst = 0;
reg [15:0]din = 0;
wire [15:0]dout;
processor_top dut(clk,sys_rst,din,dout);
always #5 clk = ~clk;
initial begin
#10; din = 16'b0000000000010000;
#50; din = 16'd5;
end
initial begin
sys_rst = 1'b1;
repeat (5)@(posedge clk);
sys_rst = 1'b0;
#2000; $stop;
end
endmodule
