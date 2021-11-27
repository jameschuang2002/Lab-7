// To ensure Quartus uses the embedded MLAB memory blocks inside the Cyclone
// V on your DE1-SoC we follow the coding style from in Altera's Quartus II
// Handbook (QII5V1 2015.05.04) in Chapter 12, “Recommended HDL Coding Style”
//
// 1. "Example 12-11: Verilog Single Clock Simple Dual-Port Synchronous RAM 
//     with Old Data Read-During-Write Behavior" 
// 2. "Example 12-29: Verilog HDL RAM Initialized with the readmemb Command"

module RAM(clk,read_address,write_address,write,din,dout);
    parameter data_width = 32; 
    parameter addr_width = 4;
    parameter filename = "data.txt";

    input clk;
    input [addr_width-1:0] read_address, write_address;
    input write;
    input [data_width-1:0] din;
    output [data_width-1:0] dout;
    reg [data_width-1:0] dout;

    reg [data_width-1:0] mem [2**addr_width-1:0];

    initial $readmemb(filename, mem);

    always @ (posedge clk) begin
    if (write)
        mem[write_address] <= din;
    dout <= mem[read_address]; // dout doesn't get din in this clock cycle 
                                // (this is due to Verilog non-blocking assignment "<=")
    end 
endmodule


module lab7_top(KEY,SW,LEDR,HEX0,HEX1,HEX2,HEX3,HEX4,HEX5);
    input [3:0] KEY;
    input [9:0] SW;
    output [9:0] LEDR;
    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
    wire[7:0] read_address, write_address;
    wire[8:0] mem_addr;
    wire[15:0] din, dout, read_data, out;
    wire write, enable;
    assign write = 1'b0;
    wire Z, N, V;
    wire[2:0] mem_cmd;
    cpu CPU (
                .clk(~KEY[0]),
                .reset(~KEY[1]),
                .in(read_data),
                .out(out),
                .N(N),
                .Z(Z),
                .V(V),
                .mem_cmd(mem_cmd),
                .mem_addr(mem_addr)
            );
    
    assign read_address = mem_addr[7:0];
    assign write_address = mem_addr[7:0];

    assign enable = mem_cmd[1] & ~mem_addr[8];

    RAM #(16, 8, "data.txt") MEM(   
                                    .clk(~KEY[0]), 
                                    .read_address(read_address), 
                                    .write_address(write_address), 
                                    .write(write), 
                                    .din(din), 
                                    .dout(dout)
                                );

    assign read_data = enable ? dout : {16{1'bz}};

endmodule