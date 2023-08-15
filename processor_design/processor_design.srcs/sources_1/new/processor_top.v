`timescale 1ns / 1ps
`define oper_type   IR[31:27]   // operation type
`define rdst        IR[26:22]   // destination register in gpr
`define rsrc1       IR[21:17]   // 1st source register in gpr
`define imm_mode    IR[16]      // mode selection "1" for immediate operation and "0" for normal operation
`define rsrc2       IR[15:11]   //2nd source register in gpr
`define isrc        IR[15:0]    //for immediate operation
//arithmetic operation
`define movsgpr 5'b00000    // move data from sgpr(accumulator) to gpr
`define mov     5'b00001    // mov data from one register to another register
`define add     5'b00010    // add two data stored in two registers or with a data by immediate operation
`define sub     5'b00011    // subtract two data stored in two registers or from a register data to a data by immediate operation
`define mul     5'b00100    // multiplication operation
///logical operation (bit-wise)
`define ror     5'b00101   // bitwise OR
`define rand    5'b00110   //bitwise AND
`define rxor    5'b00111   //bitwise XOR
`define rxnor   5'b01000   //bitwise XNOR
`define rnand   5'b01001   //bitwise NAND
`define rnor    5'b01010   //bitwise NOR
`define rnot    5'b01011   //bitwise NOT
//load and store instructions
`define storereg    5'b01101    //store content of register into Data memory
`define storedin    5'b01110    // store content of din into data Memory
`define sendout     5'b01111    // send data from data memory to dout bus
`define sendreg     5'b10001    // send data from data memory to register
//jump and branch instructions
`define jump         5'b10010   //jump to specified location
`define jcarry       5'b10011   // jump when carry = 1 satisfied
`define jnocarry     5'b10100   // jump when carry = 0 satisfied
`define jsign        5'b10101   // jump when sign bit is 1 satisfied
`define jnosign      5'b10110   // jump when sign bit is 0 satisfied
`define jzero        5'b10111   // jump when zero is set
`define jnozero      5'b11000   // jump when zero is reset
`define joverflow    5'b11001   // jump when overflow is set
`define jnooverflow  5'b11010   //jump when overflow is reset
// halt instruction
`define halt 5'b11011   // to stop or pause the operation
///////////////////////////////////////////////
module processor_top(input clk, sys_rst,
                    input [15:0]din,
                    output reg [15:0]dout);
reg [31:0]IR;               // instruction register
reg [15:0]SGPR;             // accumulator
reg [15:0]GPR[0:31];        // general purpose register
reg [31:0]mul_res;          //temporary multiplier register
reg[31:0]inst_mem[15:0];    //program memory
reg [15:0]data_mem[15:0];   //data memory
reg sign=0,zero=0,carry=0,overflow=0;   //flags
reg [16:0]temp_sum;     // temporary sum register for flag determination
reg jmp_flag = 0;
reg stop = 0;
reg [2:0] count = 0;    //delay counter
integer  pc = 0;    //program counter
//arithmetic,logical,load,store,jump an branch declaration block
task decode_inst();      
begin
jmp_flag = 1'b0;
stop = 1'b0;
case(`oper_type)
`movsgpr: begin
GPR[`rdst] = SGPR;
end
`mov: begin
if(`imm_mode)
GPR[`rdst] = `isrc;
else
GPR[`rdst] = GPR[`rsrc1];
end
`add: begin
if(`imm_mode)
GPR[`rdst] = GPR[`rsrc1] + `isrc;
else
GPR[`rdst] = GPR[`rsrc1] + GPR[`rsrc2];
end
`sub: begin
if(`imm_mode)
GPR[`rdst] = GPR[`rsrc1] - `isrc;
else
GPR[`rdst] = GPR[`rsrc1] - GPR[`rsrc2];
end
`mul: begin
if(`imm_mode)
mul_res = GPR[`rsrc1]*`isrc;
else
mul_res = GPR[`rsrc1]*GPR[`rsrc2];
SGPR = mul_res[31:16];
GPR[`rdst] = mul_res[15:0];
end
`ror: begin
if(`imm_mode)
GPR[`rdst] = GPR[`rsrc1]|`isrc;
else
GPR[`rdst] = GPR[`rsrc1]|GPR[`rsrc2];
end
`rand: begin
if(`imm_mode)
GPR[`rdst] = GPR[`rsrc1]&`isrc;
else
GPR[`rdst] = GPR[`rsrc1]&GPR[`rsrc2];
end
`rxor: begin
if(`imm_mode)
GPR[`rdst] = GPR[`rsrc1]^`isrc;
else
GPR[`rdst] = GPR[`rsrc1]^GPR[`rsrc2];
end
`rxnor: begin
if(`imm_mode)
GPR[`rdst] = GPR[`rsrc1]~^`isrc;
else
GPR[`rdst] = GPR[`rsrc1]~^GPR[`rsrc2];
end
`rnand: begin
if(`imm_mode)
GPR[`rdst] = ~(GPR[`rsrc1]&`isrc);
else
GPR[`rdst] = ~(GPR[`rsrc1]&GPR[`rsrc2]);
end
`rnor: begin
if(`imm_mode)
GPR[`rdst] = ~(GPR[`rsrc1]|`isrc);
else
GPR[`rdst] = ~(GPR[`rsrc1]|GPR[`rsrc2]);
end
`rnot: begin
if(`imm_mode)
GPR[`rdst] = ~(`isrc);
else
GPR[`rdst] = ~(GPR[`rsrc1]);
end
`storedin: begin
data_mem[`isrc] = din;
end
`storereg: begin
data_mem[`isrc] = GPR[`rsrc1];
end
`sendout: begin
dout = data_mem[`isrc];
end
`sendreg: begin
GPR[`rdst] = data_mem[`isrc];
end
`jump: begin
jmp_flag = 1'b1;
end
`jcarry: begin
if(carry == 1'b1)
jmp_flag = 1'b1;
else
jmp_flag = 1'b0;
end
`jsign: begin
if(sign ==1'b1)
jmp_flag =1'b1;
else
jmp_flag = 1'b0;
end
`jzero: begin
if(zero == 1'b1)
jmp_flag =1'b1;
else
jmp_flag = 1'b0;
end
`joverflow: begin
if(overflow == 1'b1)
jmp_flag =1'b1;
else
jmp_flag = 1'b0;
end
`jnocarry: begin
if(carry ==1'b0)
jmp_flag =1'b1;
else
jmp_flag = 1'b0;
end
`jnosign: begin
if(sign ==1'b0)
jmp_flag =1'b1;
else
jmp_flag = 1'b0;
end
`jnozero: begin
if(zero == 1'b0)
jmp_flag =1'b1;
else
jmp_flag = 1'b0;
end
`jnooverflow: begin
if(overflow ==1'b0)
jmp_flag =1'b1;
else
jmp_flag = 1'b0;
end
`halt: begin
stop = 1'b1;
end
endcase
end
endtask
///////////flag declaration block//////
task decode_condflag();      
begin
if(`oper_type ==`mul)       //sign_bit
sign = SGPR[15];
else
sign = GPR[`rdst][15];
if(`oper_type == `add)      //carry_bit
begin
if(`imm_mode)
begin
temp_sum = GPR[`rsrc1]+`isrc;
carry = temp_sum[16];
end
else
begin
temp_sum = GPR[`rsrc1]+GPR[`rsrc2];
carry = temp_sum[16];
end
end
else
begin
carry = 1'b0;
end
if(`oper_type == `mul)      //zero_bit
zero = ~((|SGPR)|(|GPR[`rdst]));
else
zero = ~(|GPR[`rdst]);
if(`oper_type ==`add)       //overflow
begin
if(`imm_mode)
overflow = ((~GPR[`rsrc1][15] & ~IR[15] & GPR[`rdst][15])|(GPR[`rsrc1][15] & IR[15] & ~GPR[`rdst]));
else
overflow = ((~GPR[`rsrc1][15] & ~GPR[`rsrc2][15] & GPR[`rdst][15])|(GPR[`rsrc1][15] & GPR[`rsrc2][15] & ~GPR[`rdst][15]));
end
else if(`oper_type == `sub)
begin
if(`imm_mode)
overflow = ((~GPR[`rsrc1][15] & IR[15] & GPR[`rdst][15])|(GPR[`rsrc1][15] & ~IR[15] & ~GPR[`rdst][15]));
else
overflow = ((~GPR[`rsrc1][15] & GPR[`rsrc2][15] & GPR[`rdst][15])|(GPR[`rsrc1][15] & ~GPR[`rsrc2][15] & ~GPR[`rdst][15]));
end
else
begin
overflow = 1'b0;
end
end
endtask
//reading program
initial begin
$readmemb("division.mem",inst_mem);
end
//fsm
parameter idle = 0,fetch_inst = 1, dec_exec_inst = 2, next_inst = 3,sense_halt = 4, delay_next_inst = 5;
reg[2:0] state = idle, next_state = idle;
always@(posedge clk)
begin
if(sys_rst ==1'b1)
state<=idle;
else state <= next_state;
end
always@(*)
begin
case(state)
idle: begin
IR=32'h0;
pc = 0;
next_state = fetch_inst;
end
fetch_inst: begin
IR = inst_mem[pc];
next_state = dec_exec_inst;
end
dec_exec_inst: begin
decode_inst();
decode_condflag();
next_state = delay_next_inst;
end
delay_next_inst: begin
if(count<4)
next_state = delay_next_inst;
else
next_state = next_inst;
end
next_inst: begin
next_state = sense_halt;
if(jmp_flag == 1'b1)
pc = `isrc;
else
pc = pc +1;
end
sense_halt: begin
if(stop == 1'b0)
next_state = fetch_inst;
else if(sys_rst)
next_state = idle;
else
next_state = sense_halt;
end
default: next_state = idle;
endcase
end
always@(posedge clk)
begin
case(state)
idle: begin
count<=0;
end
fetch_inst: begin
count<=0;
end
dec_exec_inst: begin
count<=0;
end
delay_next_inst: begin
count <= count +1;
end
next_inst: begin
count<=0;
end
sense_halt: begin
count<=0;
end
default: count <=0;
endcase
end
endmodule



