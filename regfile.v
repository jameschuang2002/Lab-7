/* decoder module */
module decoder(a, b);
    parameter n = 2; // input bits
    parameter m = 4; // output bits
    input[n-1:0] a; // input value
    output[m-1:0] b; // output value

    /* shift 1 to the left by a digits with all other bits automatically filled with 0 */
    assign b = 1 << a; 
endmodule

/* register with load module */
module regload(clk, load, in, out);
    parameter n = 1; // specify the input and output bits 
    input[n-1:0] in; // input value
    input load, clk; // load checks whether to pass the value
    output reg [n-1:0] out; // output register for the output value

    /* designed based on state machine, update hold_data to in when load is true */
    wire[15:0] hold_data = load ? in : out;

    /* set the output to the updated data when clk is on  */
    always @(posedge clk) begin
        out = hold_data;
    end
endmodule

/* register file with 8 registers each 16 bits */
module regfile(data_in, writenum, write, readnum, clk, data_out);

    /* variable declaration */
    input[15:0] data_in; // input data
    input[2:0] writenum, readnum; // write_num select the register to save the value, read_num select the register to read from using the multiple0er
    input write, clk; // write decides whether to load the value
    output reg[15:0] data_out; // output data
    wire[7:0] load, sel_write, sel_read; // sel_write select which register to write to (output of InputDec), sel_read select which register to read from (output of SelDec)
    wire[15:0] R0, R1, R2, R3, R4, R5, R6, R7; // Defining the registers and output register

    decoder #(3, 8) WriteDec(writenum, sel_write); // decoding from binary to one-hot for register number to write to

    assign load[7:0] = {8{write}} & sel_write; // copy write for 8 times put each into bit-wise and to determine load for each register 

    /* load data to each register when clk and its respective load are both 1 */
    regload #(16) RL0(clk, load[0], data_in, R0); 
    regload #(16) RL1(clk, load[1], data_in, R1);
    regload #(16) RL2(clk, load[2], data_in, R2);
    regload #(16) RL3(clk, load[3], data_in, R3);
    regload #(16) RL4(clk, load[4], data_in, R4);
    regload #(16) RL5(clk, load[5], data_in, R5);
    regload #(16) RL6(clk, load[6], data_in, R6);
    regload #(16) RL7(clk, load[7], data_in, R7);

    decoder #(3, 8) ReadDec(readnum, sel_read); // decoding from binary to one-hot for register number to read from 

    /* the multiplexer to determine which register to read from  */
    always @(*) begin
        case(sel_read)
            {1'b1, {7{1'b0}}}: data_out = R7;
            {2'b01,{6{1'b0}}}: data_out = R6;
            {3'b001,{5{1'b0}}}: data_out = R5;
            {4'b0001,{4{1'b0}}}: data_out = R4;
            {{4{1'b0}}, 1'b1, {3{1'b0}}}: data_out = R3;
            {{5{1'b0}}, 3'b100}: data_out = R2;
            {{6{1'b0}}, 2'b10}: data_out = R1;
            {{7{1'b0}}, 1'b1}: data_out = R0;
            default: data_out = {8{1'bx}}; 
        endcase
    end
endmodule