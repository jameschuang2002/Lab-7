module cpu(clk, reset, s, load, in, out, N, V, Z, w);
    input clk, reset, s, load;
    input[15:0] in;
    output[15:0] out;
    output N, V, Z, w;
    wire[15:0] inst_reg, sximm5, sximm8, mdata, C;
    wire[2:0] readnum, writenum, opcode, nsel, mem_cmd;
    wire[1:0] ALUop, op, shift;
    wire asel, bsel, loada, loadb, loadc, write, loads, reset_pc, load_pc, addr_sel, load_ir;
    wire[7:0] PC;
    wire[3:0] vsel;

    /* instruction register */
    regload #(16) LOAD(clk, load, in, inst_reg);

    /* instruction decoder */
    instruct_decoder INST(inst_reg, nsel, opcode, op, readnum, writenum, shift, sximm8, sximm5);
    
    /* FSM Controller */
    FSMCtrl CTRL(s, clk, reset, opcode, op, w, nsel, vsel, asel, bsel, loada, loadb, loadc, write, loads, ALUop, reset_pc, load_pc, addr_sel, mem_cmd, load_ir);

    //TODO: Check Figure 4 CPU Changes 
    /* datapath */
    datapath DP(sximm8, sximm5, out, vsel, asel, bsel, clk, writenum, write, readnum, loada, loadb, shift, ALUop, Z, loadc, loads, N, V);
endmodule

