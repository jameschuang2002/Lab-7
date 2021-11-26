module datapath(sximm8, sximm5, datapath_out, vsel, asel, bsel, clk, writenum, write, readnum, loada, loadb, shift, ALUop, Z_out, loadc, loads, N_out, V_out);

    input[15:0] sximm8, sximm5;
    input asel, bsel, clk, write, loada, loadb, loadc, loads;
    input[3:0] vsel;
    input[2:0] writenum, readnum;
    input[1:0] shift, ALUop;
    output Z_out, N_out, V_out;
    output[15:0] datapath_out;
    reg[15:0] datapath_in;
    
    wire[15:0] C, reg_data_out, loada_out, loadb_out, Ain, Bin, shift_out, alu_out, mdata;
    wire[7:0] PC;
    wire _Z, _N, _V;

    assign mdata = {16{1'b0}};
    assign PC = {8{1'b0}};

    /* modified input mux */
    always @(*) begin
        case(vsel)
            4'b0001: datapath_in = C;
            4'b0010: datapath_in = {{8{1'b0}}, PC};
            4'b0100: datapath_in = sximm8;
            4'b1000: datapath_in = mdata;
            default: datapath_in = {16{1'bx}};
        endcase 
    end

    /* instantiate the register file and determine which register to read and write to and from. */
    regfile REGFILE(datapath_in, writenum, write, readnum, clk, reg_data_out);

    /* load register to part A */
    regload #(16) LA(clk, loada, reg_data_out, loada_out);

    /* load register to part B */
    regload #(16) LB(clk, loadb, reg_data_out, loadb_out);

    /* the shifter in part B to perform shifting operations */
    shifter SHF(loadb_out, shift, shift_out);

    /* multiplexer between 0 or the output of loada. asel = 0, Ain = 0*/
    assign Ain = asel ? {16{1'b0}} : loada_out;
    
    /* multiplexer between the last 4 digit of input or the output of the shifter */
    assign Bin = bsel ? sximm5 : shift_out;

    /* the Arithmetic Logic Unit that performs decided operations according to ALUop on Ain and Bin */
    ALU AL(Ain, Bin, ALUop, alu_out, _Z, _N, _V);

    /* output load for the datapath_out */
    regload #(16) LC(clk, loadc, alu_out, C);

    /* output load for the status (Z), returns 1 if datapath_out is 0 */
    regload #(1) STATUSZ(clk, loads, _Z, Z_out);
    regload #(1) STATUSV(clk, loads, _V, V_out);
    regload #(1) STATUSN(clk, loads, _N, N_out);

    assign datapath_out = C; // C is a temperorary storage wire for output 
endmodule