module cpu(clk, reset, in, out, N, V, Z, mem_cmd, mem_addr);
    input clk, reset;
    input[15:0] in;
    output[15:0] out;
    output N, V, Z;
    output[2:0] mem_cmd;
    output[8:0] mem_addr;
    wire[15:0] inst_reg, sximm5, sximm8, C;
    wire[2:0] readnum, writenum, opcode, nsel;
    wire[1:0] ALUop, op, shift, sh;
    wire asel, bsel, loada, loadb, loadc, write, loads, reset_pc, load_pc, addr_sel, load_ir, load_addr;
    wire[8:0] PC, next_pc, data_address_reg;
    wire[3:0] vsel;
    wire[15:0] mdata = in;
    /* instruction register */
    regload #(16) LOAD(clk, load_ir, in, inst_reg);

    /* instruction decoder */
    instruct_decoder INST(inst_reg, nsel, opcode, op, readnum, writenum, shift, sximm8, sximm5);
    
    /* FSM Controller */
    FSMCtrl CTRL(   
                    /* input */
                    .clk(clk), 
                    .reset(reset), 
                    .opcode(opcode), 
                    .op(op), 
                    .shift(shift),

                    /* instruction decoder */
                    .nsel(nsel), 

                    /* datapath */
                    .vsel(vsel), 
                    .asel(asel), 
                    .bsel(bsel), 
                    .loada(loada), 
                    .loadb(loadb), 
                    .loadc(loadc), 
                    .write(write), 
                    .loads(loads), 
                    .ALUop(ALUop),

                    /* memory */ 
                    .reset_pc(reset_pc), 
                    .load_pc(load_pc), 
                    .addr_sel(addr_sel), 
                    .mem_cmd(mem_cmd), 
                    .load_ir(load_ir),
                    .load_addr(load_addr),
                    .sh(sh)
                );
    /* PC multiplexer, add 1 if not reset, if reset back to 0 */
    assign next_pc = reset_pc ? {9{1'b0}} : PC + 9'd1;

    /* load for updating pc */
    regload #(9) PRCT(clk, load_pc, next_pc, PC);

    /* memory address multiplexer: either PC or the value for ldr and str */
    assign mem_addr = addr_sel ? PC : data_address_reg;

    /* datapath */
    datapath DP(
                    .mdata(mdata),
                    .sximm8(sximm8), 
                    .sximm5(sximm5), 
                    .datapath_out(out), 
                    .vsel(vsel), 
                    .asel(asel), 
                    .bsel(bsel), 
                    .clk(clk), 
                    .writenum(writenum), 
                    .write(write), 
                    .readnum(readnum), 
                    .loada(loada), 
                    .loadb(loadb), 
                    .shift(sh), 
                    .ALUop(ALUop), 
                    .Z_out(Z), 
                    .loadc(loadc), 
                    .loads(loads), 
                    .N_out(N), 
                    .V_out(V)
                );
    /* regload instantiation for address of data for ldr, str */
    regload #(9) DATADDR(clk, load_addr, out[8:0], data_address_reg);
endmodule

