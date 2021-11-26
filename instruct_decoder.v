module instruct_decoder(in, nsel, opcode, op, readnum, writenum, shift, sximm8, sximm5);

    /* variable declaration */
    input[15:0] in;
    input[2:0] nsel; // input from FSM for select in mux 
    output reg[2:0] readnum, writenum;
    output[1:0] shift, op;
    output[2:0] opcode;
    output[15:0] sximm5, sximm8; // immediate input from #
    wire[2:0] Rn, Rd, Rm; // Rd: destination, Rn: number without shift, Rm: number with shifting

    /* assign each value to its decoding rules, which values to use will be determined by the FSM */
    assign opcode = in[15:13];  
    assign op = in[12:11];
    assign Rn = in[10:8];
    assign Rd = in[7:5];
    assign shift = in[4:3];
    assign Rm = in[2:0];
    assign sximm5 = {{11{in[4]}}, in[4:0]};
    assign sximm8 = {{8{in[7]}}, in[7:0]};

    /* multiplexer with nsel from FSM to determine which R to read from */
    always @(*) begin
        case(nsel)
            3'b001: {writenum, readnum} = {2{Rn}};
            3'b010: {writenum, readnum} = {2{Rd}};
            3'b100: {writenum, readnum} = {2{Rm}};
            default: {writenum, readnum} = {6{1'bx}};
        endcase
    end
endmodule