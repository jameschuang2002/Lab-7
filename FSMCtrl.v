module vDFF(clk,D,Q);
  parameter n=1;
  input clk;
  input [n-1:0] D;
  output [n-1:0] Q;
  reg [n-1:0] Q;
  always @(posedge clk)
    Q <= D;
endmodule

module FSMCtrl (s, clk, reset, opcode, op, w, nsel, vsel, asel, bsel, loada, loadb, loadc, write, loads, ALUop);
    input s, reset, clk;
    input[2:0] opcode;
    input[1:0] op;
    output reg w, asel, bsel, loada, loadb, loadc, write, loads;
    output reg[2:0] nsel;
    output reg[3:0] vsel;
    output reg[1:0] ALUop;

    /* state declaration */
    `define WAIT 4'b0000
    `define DEC  4'b0001
    `define GETA 4'b0011
    `define GETB 4'b0100
    `define ADD  4'b0101
    `define CMP  4'b0110
    `define AND  4'b0111
    `define MVN  4'b1000
    `define WRITE 4'b1001
    `define MGETB 4'b1010
    `define MGETA 4'b1011
    `define MWRITE 4'b1100
    `define MSHOW 4'b1101

    wire[3:0] next_state_reset, current_state;
    reg[3:0] next_state;

    /* check for reset signal */
    assign next_state_reset = reset ? `WAIT : next_state;

    /* state transition at the rising edge of the clk */
    vDFF #(4) U0(clk, next_state_reset, current_state);

/* this always block keep tracks of state transitions */
    always @(*) begin
        case(current_state)
        /* initializing: we keep key loads and write closed to ensure no data are input */
            `WAIT: next_state = s ? `DEC : `WAIT;
            `DEC:   case(opcode)
                        3'b110: next_state = `MGETA;
                        3'b101: next_state = `GETA;
                        default: next_state = 4'bxxxx;
                    endcase
        /* getting stage: only data related to get will be operated, loadc and loads will remain closed */
            `GETA:  next_state = `GETB;
            `GETB:  case(op)
                        2'b00: next_state = `ADD;
                        2'b01: next_state = `CMP;
                        2'b10: next_state = `AND;
                        2'b11: next_state = `MVN;
                        default: next_state = 4'bxxxx;
                    endcase
            /* MGETA is useless so same as initialize stage */
            `MGETA: next_state = op[1]? `MSHOW: `MGETB;
            `MGETB: next_state = `MSHOW;
        /* Compute and Display Stage: The results are computed and displayed */
            `MSHOW: next_state = `MWRITE;
            `ADD: next_state = `WRITE;
            `MVN: next_state = `WRITE;
            `AND: next_state = `WRITE;
            `CMP: next_state = `WAIT;
        /* Writing Stage: The results are written into the register */
            `WRITE: next_state = `WAIT;
            `MWRITE: next_state = `WAIT;
            default: next_state = 4'bxxxx;
        endcase
    end

    /* at the positive edge of the clock, next_state_reset was for the next state, this approach avoids inferred latches */
    always @(posedge clk) begin
        case(next_state_reset)
        /* initialization */
            `WAIT: begin
                        w = 1'b1;
                        loada = 1'b0;
                        loadb = 1'b0;
                        loadc = 1'b0;
                        loads = 1'b0;
                        write = 1'b0;
                        /* unrelated signals, declared to prevent latches */
                        asel = 1'b0; 
                        bsel = 1'b0;
                        vsel = 4'b0001;
                        nsel = 3'b001;
                        ALUop = 2'b00;
                    end
            `DEC:   begin
                        w = 1'b0;
                        loada = 1'b0;
                        loadb = 1'b0;
                        loadc = 1'b0;
                        loads = 1'b0;
                        write = 1'b0;
                        asel = 1'b0; 
                        bsel = 1'b0;
                        vsel = 4'b0001;
                        nsel = 3'b001;
                        ALUop = 2'b00;
                    end
        /* loading data */
            `GETA:  begin
                /* load data to a if operation is ALU */
                        w = 1'b0;
                        loada = 1'b1; 
                        loadb = 1'b0;
                        loadc = 1'b0;
                        loads = 1'b0;
                        write = 1'b0;
                        nsel = 3'b001;
                        /* unrelated signals */
                        asel = 1'b0;
                        bsel = 1'b0;
                        vsel = 4'b0001;
                    end
            `GETB:  begin
                        w = 1'b0;
                        loada = 1'b0;
                        loadb = 1'b1;
                        loadc = 1'b0;
                        loads = 1'b0;
                        write = 1'b0;
                        nsel = 3'b100;
                        /* unrelated signals */
                        asel = 1'b0;
                        bsel = 1'b0;
                        vsel = 4'b0001;
                    end
            `MGETA: begin
                        w = 1'b0;
                        loada = 1'b0;
                        loadb = 1'b0;
                        loadc = 1'b0;
                        loads = 1'b0;
                        write = 1'b0;
                        /* unrelated signals */
                        asel = 1'b0;
                        bsel = 1'b0;
                        nsel = 3'b001;
                        vsel = 4'b0001;
                    end
            `MGETB: begin
                        w = 1'b0;
                        loada = 1'b0; 
                        loadb = 1'b1;
                        loadc = 1'b0; 
                        loads = 1'b0;
                        write = 1'b0;
                        nsel = 3'b100;
                        /* unrelated signals */
                        asel = 1'b0;
                        bsel = 1'b0;
                        vsel = 4'b0001;
                    end
        /* compute and display */
            `MSHOW: begin
                        w = 1'b0;
                        loada = 1'b0; 
                        loadb = 1'b0;
                        loadc = 1'b1; 
                        loads = 1'b0;
                        write = 1'b0;
                        asel = 1'b1;
                        bsel = 1'b0;
                        ALUop = 2'b00;
                        /* unrelated signals */
                        vsel = 4'b0001;
                        nsel = 3'b001;
                    end
            `ADD:   begin
                        w = 1'b0;
                        loada = 1'b0;
                        loadb = 1'b0;
                        loadc = 1'b1;
                        loads = 1'b0;
                        write = 1'b0;
                        asel = 1'b0;
                        bsel = 1'b0;
                        ALUop = 2'b00;
                        /* unrelated signals */
                        vsel = 4'b0001;
                        nsel = 3'b001;
                    end
            `MVN:   begin
                        w = 1'b0;
                        loada = 1'b0;
                        loadb = 1'b0;
                        loadc = 1'b1;
                        loads = 1'b0;
                        write = 1'b0;
                        asel = 1'b0;
                        bsel = 1'b0;
                        ALUop = 2'b11;
                        /* unrelated signals */
                        vsel = 4'b0001;
                        nsel = 3'b001;
                    end
            `AND: begin
                        w = 1'b0;
                        loada = 1'b0;
                        loadb = 1'b0;
                        loadc = 1'b1;
                        loads = 1'b0;
                        write = 1'b0;
                        asel = 1'b0;
                        bsel = 1'b0;
                        ALUop = 2'b10;
                        /* unrelated signals */
                        vsel = 4'b0001;
                        nsel = 3'b001;
                    end
            `CMP: begin
                        w = 1'b0;
                        loada = 1'b0;
                        loadb = 1'b0;
                        loadc = 1'b1;
                        loads = 1'b1;
                        write = 1'b0;
                        asel = 1'b0;
                        bsel = 1'b0;
                        ALUop = 2'b01;
                        /* unrelated signals */
                        vsel = 4'b0001;
                        nsel = 3'b001;
                    end
        /* writing */
            `WRITE: begin 
                        w = 1'b0;
                        loada = 1'b0;
                        loadb = 1'b0;
                        loadc = 1'b0;
                        loads = 1'b0;
                        write = 1'b1;
                        nsel = 3'b010;
                        vsel = 4'b0001;
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
                        vsel = op[1] ? 4'b0100 : 4'b0001; // select output if it's reg, input if it's imm
                        nsel = op[1] ? 3'b001 : 3'b010; // Rn if imm, Rd if some reg
                        /* unrelated signals */
                        asel = 1'b0;
                        bsel = 1'b0;
                        ALUop = 2'b00;
                    end
        endcase
    end
endmodule
