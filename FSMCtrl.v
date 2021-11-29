module vDFF(clk,D,Q);
  parameter n=1;
  input clk;
  input [n-1:0] D;
  output [n-1:0] Q;
  reg [n-1:0] Q;
  always @(posedge clk)
    Q <= D;
endmodule

module FSMCtrl (clk, shift, reset, opcode, op, nsel, vsel, asel, bsel, loada, loadb, loadc, write, loads, ALUop, reset_pc, load_pc, addr_sel, mem_cmd, load_ir, load_addr, sh);
    input reset, clk;
    input[2:0] opcode;
    input[1:0] op, shift;
    output reg asel, bsel, loada, loadb, loadc, write, loads, reset_pc, load_pc, addr_sel, load_ir, load_addr;
    output reg[2:0] nsel, mem_cmd;
    output reg[3:0] vsel;
    output reg[1:0] ALUop, sh;

    /* state declaration */
    `define RST 5'b00000 // reset 
    `define IF1 5'b00001 // fetch instruction
    `define DEC  5'b00010 // decode 
    `define GETA 5'b00011 // get first value for alu 
    `define GETB 5'b00100 // get second value for alu
    `define ADD  5'b00101 // a+b
    `define CMP  5'b00110 // a-b with relevant signals 
    `define AND  5'b00111 // a & b
    `define MVN  5'b01000 // ~b
    `define WRITE 5'b01001 // write to register 

    /* move instruction separated because some control signals are different */
    `define MGETB 5'b01010 // get b for move instruction 
    `define MGETA 5'b01011 // get a for move instruction 
    `define MWRITE 5'b01100 // write for move instruction 
    `define MSHOW 5'b01101 // show result for op 00
    `define IF2 5'b01110 // load fetched instruction 
    `define UPDATEPC 5'b01111 // update PC
    `define HALT 5'b10000 // infinite loop 
    /* memory states are combined for geta, getb, add, and put: shift operation are set to 0 for data safety */
    `define MEMADD 5'b10001 
    `define LDRWRITE 5'b10010 // write the value into the register 
    `define STRSHOW 5'b10011 // show what is loaded to memory
    `define MEMGETA 5'b10100
    `define MEMGETB 5'b10101
    `define PUTADDR 5'b10110 // put the address in the address register 
    `define LDRGET 5'b10111 // get the value to be loaded 
    `define STRGET 5'b11000
    `define STRWRITE 5'b11001

    wire[4:0] next_state_reset, current_state;
    reg[4:0] next_state;

    /* check for reset signal */
    assign next_state_reset = reset ? `RST : next_state;

    /* state transition at the rising edge of the clk */
    vDFF #(5) U0(clk, next_state_reset, current_state);

/* this always block keep tracks of state transitions */
    always @(*) begin
        case(current_state)
        /* initializing: we keep key loads and write closed to ensure no data are input */
            `RST: next_state = `IF1;
            `IF1: next_state = `IF2;
            `IF2: next_state = `UPDATEPC;
            `UPDATEPC: next_state = `DEC;
            `DEC:   case(opcode)
                        3'b110: next_state = `MGETA;
                        3'b101: next_state = `GETA;
                        3'b111: next_state = `HALT;
                        3'b011, 3'b100: next_state = `MEMGETA;
                        default: next_state = 5'bxxxxx;
                    endcase
        /* getting stage: only data related to get will be operated, loadc and loads will remain closed */
            `GETA:  next_state = `GETB;
            `GETB:  case(op)
                        2'b00: next_state = `ADD;
                        2'b01: next_state = `CMP;
                        2'b10: next_state = `AND;
                        2'b11: next_state = `MVN;
                        default: next_state = 5'bxxxxx;
                    endcase
            /* MGETA is useless so same as initialize stage */
            `MGETA: next_state = op[1]? `MSHOW: `MGETB;
            `MGETB: next_state = `MSHOW;
        /* Compute and Display Stage: The results are computed and displayed */
            `MSHOW: next_state = `MWRITE;
            `ADD: next_state = `WRITE;
            `MVN: next_state = `WRITE;
            `AND: next_state = `WRITE;
            `CMP: next_state = `IF1;
        /* Writing Stage: The results are written into the register */
            `WRITE: next_state = `IF1;
            `MWRITE: next_state = `IF1;

        /* HALT command */
            `HALT: next_state = `HALT;

        /* Memory related states */
            `MEMGETA: next_state = `MEMGETB; 
            `MEMGETB: next_state = `MEMADD; 
            `MEMADD: next_state = `PUTADDR; 
            `PUTADDR: next_state = opcode[2] ? `STRGET : `LDRGET; 
            `STRGET: next_state = `STRSHOW; 
            `LDRGET: next_state = `LDRWRITE; 
            `STRSHOW: next_state = `STRWRITE; 
            `LDRWRITE: next_state = `IF1;
            `STRWRITE: next_state = `IF1;

            default: next_state = 5'bxxxxx;
        endcase
    end

    /* at the positive edge of the clock, next_state_reset was for the next state, this approach avoids inferred latches */
    always @(posedge clk) begin
        case(next_state_reset)
        /* initialization */
            `RST: begin
                        loada = 1'b0;
                        loadb = 1'b0;
                        loadc = 1'b0;
                        loads = 1'b0;
                        write = 1'b0;
                        reset_pc = 1'b1;
                        load_pc = 1'b1;
                        addr_sel = 1'b1;
                        mem_cmd = 3'b001;
                        load_ir = 1'b0;
                        load_addr = 1'b0;
                        /* unrelated signals, declared to prevent latches */
                        asel = 1'b0; 
                        bsel = 1'b0;
                        vsel = 4'b0001;
                        nsel = 3'b001;
                        ALUop = 2'b00;
                    end
            `IF1:   begin
                        loada = 1'b0;
                        loadb = 1'b0;
                        loadc = 1'b0;
                        loads = 1'b0;
                        write = 1'b0;
                        reset_pc = 1'b0;
                        load_pc = 1'b0;
                        addr_sel = 1'b1;
                        mem_cmd = 3'b010;
                        load_ir = 1'b0;
                        load_addr = 1'b0;
                        sh = shift;
                        /* unrelated signals, declared to prevent latches */
                        asel = 1'b0; 
                        bsel = 1'b0;
                        vsel = 4'b0001;
                        nsel = 3'b001;
                        ALUop = 2'b00;
                    end
            `IF2: begin
                        loada = 1'b0;
                        loadb = 1'b0;
                        loadc = 1'b0;
                        loads = 1'b0;
                        write = 1'b0;
                        reset_pc = 1'b0;
                        load_pc = 1'b0;
                        addr_sel = 1'b1;
                        mem_cmd = 3'b010;
                        load_ir = 1'b1;
                        load_addr = 1'b0;
                        sh = shift;
                        /* unrelated signals, declared to prevent latches */
                        asel = 1'b0; 
                        bsel = 1'b0;
                        vsel = 4'b0001;
                        nsel = 3'b001;
                        ALUop = 2'b00;
                    end
            `UPDATEPC:  begin
                            loada = 1'b0;
                            loadb = 1'b0;
                            loadc = 1'b0;
                            loads = 1'b0;
                            write = 1'b0;
                            reset_pc = 1'b0;
                            load_pc = 1'b1;
                            addr_sel = 1'b1;
                            mem_cmd = 3'b001;
                            load_ir = 1'b0;
                            load_addr = 1'b0;
                            sh = shift;
                            /* unrelated signals, declared to prevent latches */
                            asel = 1'b0; 
                            bsel = 1'b0;
                            vsel = 4'b0001;
                            nsel = 3'b001;
                            ALUop = 2'b00;
                        end
            `DEC:   begin
                        loada = 1'b0;
                        loadb = 1'b0;
                        loadc = 1'b0;
                        loads = 1'b0;
                        write = 1'b0;
                        reset_pc = 1'b0;
                        load_pc = 1'b0;
                        addr_sel = 1'b1;
                        mem_cmd = 3'b001;
                        load_ir = 1'b0;
                        load_addr = 1'b0;
                        sh = shift;
                        asel = 1'b0; 
                        bsel = 1'b0;
                        vsel = 4'b0001;
                        nsel = 3'b001;
                        ALUop = 2'b00;
                    end
        /* loading data */
            `GETA:  begin
                /* load data to a if operation is ALU */
                        loada = 1'b1; 
                        loadb = 1'b0;
                        loadc = 1'b0;
                        loads = 1'b0;
                        write = 1'b0;
                        nsel = 3'b001;
                        reset_pc = 1'b0;
                        load_pc = 1'b0;
                        addr_sel = 1'b1;
                        mem_cmd = 3'b001;
                        load_ir = 1'b0;
                        load_addr = 1'b0;
                        sh = shift;
                        /* unrelated signals */
                        asel = 1'b0;
                        bsel = 1'b0;
                        vsel = 4'b0001;
                    end
            `GETB:  begin
                        loada = 1'b0;
                        loadb = 1'b1;
                        loadc = 1'b0;
                        loads = 1'b0;
                        write = 1'b0;
                        nsel = 3'b100;
                        reset_pc = 1'b0;
                        load_pc = 1'b0;
                        addr_sel = 1'b1;
                        mem_cmd = 3'b001;
                        load_ir = 1'b0;
                        load_addr = 1'b0;
                        sh = shift;
                        /* unrelated signals */
                        asel = 1'b0;
                        bsel = 1'b0;
                        vsel = 4'b0001;
                    end
            `MGETA: begin
                        loada = 1'b0;
                        loadb = 1'b0;
                        loadc = 1'b0;
                        loads = 1'b0;
                        write = 1'b0;
                        reset_pc = 1'b0;
                        load_pc = 1'b0;
                        addr_sel = 1'b1;
                        mem_cmd = 3'b001;
                        load_ir = 1'b0;
                        load_addr = 1'b0;
                        sh = shift;
                        /* unrelated signals */
                        asel = 1'b0;
                        bsel = 1'b0;
                        nsel = 3'b001;
                        vsel = 4'b0001;
                    end
            `MGETB: begin
                        loada = 1'b0; 
                        loadb = 1'b1;
                        loadc = 1'b0; 
                        loads = 1'b0;
                        write = 1'b0;
                        nsel = 3'b100;
                        reset_pc = 1'b0;
                        load_pc = 1'b0;
                        addr_sel = 1'b1;
                        mem_cmd = 3'b001;
                        load_ir = 1'b0;
                        load_addr = 1'b0;
                        sh = shift;
                        /* unrelated signals */
                        asel = 1'b0;
                        bsel = 1'b0;
                        vsel = 4'b0001;
                    end
        /* compute and display */
            `MSHOW: begin
                        loada = 1'b0; 
                        loadb = 1'b0;
                        loadc = 1'b1; 
                        loads = 1'b0;
                        write = 1'b0;
                        asel = 1'b1;
                        bsel = 1'b0;
                        ALUop = 2'b00;
                        reset_pc = 1'b0;
                        load_pc = 1'b0;
                        addr_sel = 1'b1;
                        mem_cmd = 3'b001;
                        load_ir = 1'b0;
                        load_addr = 1'b0;
                        sh = shift;
                        /* unrelated signals */
                        vsel = 4'b0001;
                        nsel = 3'b001;
                    end
            `ADD:   begin
                        loada = 1'b0;
                        loadb = 1'b0;
                        loadc = 1'b1;
                        loads = 1'b0;
                        write = 1'b0;
                        asel = 1'b0;
                        bsel = 1'b0;
                        ALUop = 2'b00;
                        reset_pc = 1'b0;
                        load_pc = 1'b0;
                        addr_sel = 1'b1;
                        mem_cmd = 3'b001;
                        load_ir = 1'b0;
                        load_addr = 1'b0;
                        sh = shift;
                        /* unrelated signals */
                        vsel = 4'b0001;
                        nsel = 3'b001;
                    end
            `MVN:   begin
                        loada = 1'b0;
                        loadb = 1'b0;
                        loadc = 1'b1;
                        loads = 1'b0;
                        write = 1'b0;
                        asel = 1'b0;
                        bsel = 1'b0;
                        ALUop = 2'b11;
                        reset_pc = 1'b0;
                        load_pc = 1'b0;
                        addr_sel = 1'b1;
                        mem_cmd = 3'b001;
                        load_ir = 1'b0;
                        load_addr = 1'b0;
                        sh = shift;
                        /* unrelated signals */
                        vsel = 4'b0001;
                        nsel = 3'b001;
                    end
            `AND: begin
                        loada = 1'b0;
                        loadb = 1'b0;
                        loadc = 1'b1;
                        loads = 1'b0;
                        write = 1'b0;
                        asel = 1'b0;
                        bsel = 1'b0;
                        ALUop = 2'b10;
                        reset_pc = 1'b0;
                        load_pc = 1'b0;
                        addr_sel = 1'b1;
                        mem_cmd = 3'b001;
                        load_ir = 1'b0;
                        load_addr = 1'b0;
                        sh = shift;
                        /* unrelated signals */
                        vsel = 4'b0001;
                        nsel = 3'b001;
                    end
            `CMP: begin
                        loada = 1'b0;
                        loadb = 1'b0;
                        loadc = 1'b1;
                        loads = 1'b1;
                        write = 1'b0;
                        asel = 1'b0;
                        bsel = 1'b0;
                        ALUop = 2'b01;
                        reset_pc = 1'b0;
                        load_pc = 1'b0;
                        addr_sel = 1'b1;
                        mem_cmd = 3'b001;
                        load_ir = 1'b0;
                        load_addr = 1'b0;
                        sh = shift;
                        /* unrelated signals */
                        vsel = 4'b0001;
                        nsel = 3'b001;
                    end
        /* writing */
            `WRITE: begin 
                        loada = 1'b0;
                        loadb = 1'b0;
                        loadc = 1'b0;
                        loads = 1'b0;
                        write = 1'b1;
                        nsel = 3'b010;
                        vsel = 4'b0001;
                        reset_pc = 1'b0;
                        load_pc = 1'b0;
                        addr_sel = 1'b1;
                        mem_cmd = 3'b001;
                        load_ir = 1'b0;
                        load_addr = 1'b0;
                        sh = shift;
                        /* unrelated signals */
                        asel = 1'b0;
                        bsel = 1'b0;
                        ALUop = 2'b00;
                    end
            `MWRITE: begin
                        loada = 1'b0;
                        loadb = 1'b0;
                        loadc = 1'b0;
                        loads = 1'b0;
                        write = 1'b1;
                        reset_pc = 1'b0;
                        load_pc = 1'b0;
                        addr_sel = 1'b1;
                        mem_cmd = 3'b001;
                        load_ir = 1'b0;
                        load_addr = 1'b0;
                        vsel = op[1] ? 4'b0100 : 4'b0001; // select output if it's reg, input if it's imm
                        nsel = op[1] ? 3'b001 : 3'b010; // Rn if imm, Rd if some reg
                        sh = shift;
                        /* unrelated signals */
                        asel = 1'b0;
                        bsel = 1'b0;
                        ALUop = 2'b00;
                    end
            `HALT:  begin
                        loada = 1'b0;
                        loadb = 1'b0;
                        loadc = 1'b0;
                        loads = 1'b0;
                        write = 1'b0;
                        reset_pc = 1'b0;
                        load_pc = 1'b0;
                        addr_sel = 1'b1;
                        mem_cmd = 3'b001;
                        load_ir = 1'b0;
                        load_addr = 1'b0;
                        sh = shift;
                        /* unrelated signals, declared to prevent latches */
                        asel = 1'b0; 
                        bsel = 1'b0;
                        vsel = 4'b0001;
                        nsel = 3'b001;
                        ALUop = 2'b00;
                    end
            `MEMGETA:   begin
                            loada = 1'b1;
                            loadb = 1'b0;
                            loadc = 1'b0;
                            loads = 1'b0;
                            write = 1'b0;
                            reset_pc = 1'b0;
                            load_pc = 1'b0;
                            addr_sel = 1'b1;
                            mem_cmd = 3'b001;
                            load_ir = 1'b0;
                            load_addr = 1'b0;
                            sh = 2'b00;
                            /* unrelated signals */
                            asel = 1'b0;
                            bsel = 1'b0;
                            nsel = 3'b001;
                            vsel = 4'b0001;
                        end
            `MEMGETB:   begin
                            loada = 1'b0;
                            loadb = 1'b0;
                            loadc = 1'b0;
                            loads = 1'b0;
                            write = 1'b0;
                            reset_pc = 1'b0;
                            load_pc = 1'b0;
                            addr_sel = 1'b0;
                            mem_cmd = 3'b001;
                            load_ir = 1'b0;
                            load_addr = 1'b0;
                            sh = 2'b00;
                            /* unrelated signals */
                            asel = 1'b0;
                            bsel = 1'b0;
                            nsel = 3'b001;
                            vsel = 4'b0001;
                        end
            `MEMADD:    begin 
                            loada = 1'b0;
                            loadb = 1'b0;
                            loadc = 1'b1;
                            loads = 1'b0;
                            write = 1'b0;
                            asel = 1'b0;
                            bsel = 1'b1;
                            ALUop = 2'b00;
                            reset_pc = 1'b0;
                            load_pc = 1'b0;
                            addr_sel = 1'b0;
                            mem_cmd = 3'b001;
                            load_ir = 1'b0;
                            load_addr = 1'b0;
                            sh = 2'b00;
                            /* unrelated signals */
                            vsel = 4'b0001;
                            nsel = 3'b001;
                        end
            `PUTADDR:   begin
                            loada = 1'b0;
                            loadb = 1'b0;
                            loadc = 1'b0;
                            loads = 1'b0;
                            write = 1'b0;
                            asel = 1'b0;
                            bsel = 1'b0;
                            ALUop = 2'b00;
                            reset_pc = 1'b0;
                            load_pc = 1'b0;
                            addr_sel = 1'b0;
                            mem_cmd = 3'b001;
                            load_ir = 1'b0;
                            load_addr = 1'b1;
                            sh = 2'b00;
                            /* unrelated signals */
                            vsel = 4'b0001;
                            nsel = 3'b001;
                        end
            `LDRGET:  begin
                            loada = 1'b0;
                            loadb = 1'b0;
                            loadc = 1'b0;
                            loads = 1'b0;
                            write = 1'b0;
                            asel = 1'b0;
                            bsel = 1'b0;
                            ALUop = 2'b00;
                            reset_pc = 1'b0;
                            load_pc = 1'b0;
                            addr_sel = 1'b0;
                            mem_cmd = 3'b010;
                            load_ir = 1'b0;
                            load_addr = 1'b1;
                            sh = 2'b00;
                            /* unrelated signals */
                            vsel = 4'b0001;
                            nsel = 3'b001;
                        end
            `STRGET:    begin
                            loada = 1'b0;
                            loadb = 1'b1;
                            loadc = 1'b0;
                            loads = 1'b0;
                            write = 1'b0;
                            asel = 1'b0;
                            bsel = 1'b0;
                            ALUop = 2'b00;
                            reset_pc = 1'b0;
                            load_pc = 1'b0;
                            addr_sel = 1'b0;
                            mem_cmd = 3'b100;
                            load_ir = 1'b0;
                            load_addr = 1'b1;
                            sh = 2'b00;
                            /* unrelated signals */
                            vsel = 4'b0001;
                            nsel = 3'b010;
                        end
            `LDRWRITE:  begin
                            loada = 1'b0;
                            loadb = 1'b0;
                            loadc = 1'b0;
                            loads = 1'b0;
                            write = 1'b1;
                            asel = 1'b0;
                            bsel = 1'b0;
                            ALUop = 2'b00;
                            reset_pc = 1'b0;
                            load_pc = 1'b0;
                            addr_sel = 1'b0;
                            mem_cmd = 3'b010;
                            load_ir = 1'b0;
                            load_addr = 1'b0;
                            sh = 2'b00;
                            vsel = 4'b1000;
                            nsel = 3'b010;
                        end
            `STRSHOW:   begin
                            loada = 1'b0;
                            loadb = 1'b0;
                            loadc = 1'b1;
                            loads = 1'b0;
                            write = 1'b0;
                            asel = 1'b1;
                            bsel = 1'b0;
                            ALUop = 2'b00;
                            reset_pc = 1'b0;
                            load_pc = 1'b0;
                            addr_sel = 1'b0;
                            mem_cmd = 3'b100;
                            load_ir = 1'b0;
                            load_addr = 1'b0;
                            sh = 2'b00;
                            /* unrelated signals */
                            vsel = 4'b0001;
                            nsel = 3'b001;
                        end
            `STRWRITE:   begin
                            loada = 1'b0;
                            loadb = 1'b0;
                            loadc = 1'b0;
                            loads = 1'b0;
                            write = 1'b0;
                            asel = 1'b0;
                            bsel = 1'b0;
                            ALUop = 2'b00;
                            reset_pc = 1'b0;
                            load_pc = 1'b0;
                            addr_sel = 1'b0;
                            mem_cmd = 3'b100;
                            load_ir = 1'b0;
                            load_addr = 1'b0;
                            sh = 2'b00;
                            /* unrelated signals */
                            vsel = 4'b0001;
                            nsel = 3'b001;
                        end
        endcase
    end
endmodule
