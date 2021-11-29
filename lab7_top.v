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
    wire write, enable, load;
    wire Z, N, V;
    wire[2:0] mem_cmd;

    /* instantiation of the CPU module for this computer */
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
    
    /* assign read and write address to mem_addr */
    assign read_address = mem_addr[7:0];
    assign write_address = mem_addr[7:0];

    /* let memory input = out of datapath for address computation */
    assign din = out;

    /* the memcmd is represented in one hot: 001 NONE, 010 READ, 100 WRITE */

    /* check if command is read and the last bit on mem_addr */
    assign enable = mem_cmd[1] & ~mem_addr[8];

    /* check if command is write and the last bit on mem_addr */
    assign write = ~mem_addr[8] & mem_cmd[2];

    /* RAM module instantiation */
    RAM #(16, 8, "data.txt") MEM(   
                                    .clk(~KEY[0]), 
                                    .read_address(read_address), 
                                    .write_address(write_address), 
                                    .write(write), 
                                    .din(din), 
                                    .dout(dout)
                                );


    /* we check if command is read and the address according to stage 3, if not, we go through the tri-state driver described in stage 1 */
    assign read_data = (mem_addr == 9'h140 & mem_cmd == 3'b010) ? {8'd0, SW[7:0]} : enable ? dout : {16{1'bz}};

    /* LED specifications */
    assign load = mem_addr == 9'h100 & mem_cmd == 3'b100; // condition for led to shine
    vDFFE #(8) LED(~KEY[0], load, out[7:0], LEDR[7:0]);
    assign LEDR[9:8] = 2'b00; // set the top two leds to 0
    assign HEX5[0] = ~Z;
    assign HEX5[6] = ~N;
    assign HEX5[3] = ~V;

    // fill in sseg to display 4-bits in hexidecimal 0,1,2...9,A,B,C,D,E,F
    sseg H0(out[3:0],   HEX0);
    sseg H1(out[7:4],   HEX1);
    sseg H2(out[11:8],  HEX2);
    sseg H3(out[15:12], HEX3);
    assign HEX4 = {7{1'b1}};
    assign {HEX5[2:1],HEX5[5:4]} = 4'b1111; // disabled
endmodule

// The sseg module below can be used to display the value of datpath_out on
// the hex LEDS the input is a 4-bit value representing numbers between 0 and
// 15 the output is a 7-bit value that will print a hexadecimal digit.  You
// may want to look at the code in Figure 7.20 and 7.21 in Dally but note this
// code will not work with the DE1-SoC because the order of segments used in
// the book is not the same as on the DE1-SoC (see comments below).

module sseg(in,segs);
  input [3:0] in;
  output reg[6:0] segs;

  // NOTE: The code for sseg below is not complete: You can use your code from
  // Lab4 to fill this in or code from someone else's Lab4.  
  //
  // IMPORTANT:  If you *do* use someone else's Lab4 code for the seven
  // segment display you *need* to state the following three things in
  // a file README.txt that you submit with handin along with this code: 
  //
  //   1.  First and last name of student providing code
  //   2.  Student number of student providing code
  //   3.  Date and time that student provided you their code
  //
  // You must also (obviously!) have the other student's permission to use
  // their code.
  //
  // To do otherwise is considered plagiarism.
  //
  // One bit per segment. On the DE1-SoC a HEX segment is illuminated when
  // the input bit is 0. Bits 6543210 correspond to:
  //
  //    0000
  //   5    1
  //   5    1
  //    6666
  //   4    2
  //   4    2
  //    3333
  //
  // Decimal value | Hexadecimal symbol to render on (one) HEX display
  //             0 | 0
  //             1 | 1
  //             2 | 2
  //             3 | 3
  //             4 | 4
  //             5 | 5
  //             6 | 6
  //             7 | 7
  //             8 | 8
  //             9 | 9
  //            10 | A
  //            11 | b
  //            12 | C
  //            13 | d
  //            14 | E
  //            15 | F

  always @(*) begin
    case (in)
      4'b0000: segs = {1'b1, {6{1'b0}}};
      4'b0001: segs = 7'b1111001;
      4'b0010: segs = 7'b0100100;
      4'b0011: segs = 7'b0110000;
      4'b0100: segs = 7'b0011001;
      4'b0101: segs = 7'b0010010;
      4'b0110: segs = 7'b0000011;
      4'b0111: segs = 7'b1111000;
      4'b1000: segs = {7{1'b0}};
      4'b1001: segs = 7'b0011000;
      4'b1010: segs = 7'b0001000;
      4'b1011: segs = 7'b0000011;
      4'b1100: segs = 7'b1000110;
      4'b1101: segs = 7'b0100001;
      4'b1110: segs = 7'b0000110;
      4'b1111: segs = 7'b0001110;
      default: segs = {7{1'b1}};
    endcase
  end

endmodule