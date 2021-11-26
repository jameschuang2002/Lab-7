/* the Arithmetic Logic Unit performs 4 operations : A+B, A-B, A&B, ~B */
module ALU(Ain, Bin, ALUop, out, Z, N, V);
    input[15:0] Ain, Bin;
    input[1:0] ALUop;
    output reg[15:0] out;
    output reg Z, N, V;

    /* performs the operation for each ALUop input according to specs */
    always @(*) begin
        case(ALUop)
            2'b00: out = Ain + Bin;
            2'b01: out = Ain - Bin;
            2'b10: out = Ain & Bin;
            2'b11: out = ~Bin;
            default: out = {16{1'bx}};
        endcase
    end

    /* determine Z: If out = 0, Z = 1. Else Z = 0; */
    always @(*) begin
        case(out)
            {16{1'b0}}: Z = 1'b1;
            default: Z = 1'b0;
        endcase
    end

    /* determine V: If the result is within 2's complement of 15 bits, V = 0, else V = 1*/
    always @(*) begin
        case({Ain[15], Bin[15]})
            2'b10: V = out[15] ? 1'b0 : 1'b1; /* neg - pos, answer should be neg, so if pos then overflow */
            2'b01: V = out[15] ? 1'b1 : 1'b0; /* pos - neg, answer should be pos, so if neg then overflow */
            default: V = 1'b0; /* other situation are just within range */
        endcase
    end

    /* determine N: If overflow then it will not be negative. Then check the MSB of output */
    always @(*) begin
        case(V)
            1'b1: N = 1'b0;
            1'b0: N = out[15];
            default: N = 1'bx;
        endcase
    end
endmodule
