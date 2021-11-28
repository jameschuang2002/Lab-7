module lab7_top_tb ();

    reg[3:0] KEY;
    reg[9:0] SW;
    wire[9:0] LEDR;
    wire[6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
    reg err = 1'b0;

    lab7_top DUT(KEY,SW,LEDR,HEX0,HEX1,HEX2,HEX3,HEX4,HEX5);

    task test;
        input [15:0] out;
        begin
            if(lab7_top_tb.DUT.CPU.out !== out) begin
                err = 1'b1;
                $display("Incorrect Output. Expected: %b, Actual: %b", out, DUT.CPU.out);
            end
        end
    endtask

    initial forever begin
        KEY[0] = 1; #5;
        KEY[0] = 0; #5;
    end

    initial begin
        KEY[1] = 0; #10;
        KEY[1] = 1; #700;
        test(16'd5);

        $display("R0: %b", lab7_top_tb.DUT.CPU.DP.REGFILE.R0);
        $display("R1: %b", lab7_top_tb.DUT.CPU.DP.REGFILE.R1);
        $display("R2: %b", lab7_top_tb.DUT.CPU.DP.REGFILE.R2);
        $display("R3: %b", lab7_top_tb.DUT.CPU.DP.REGFILE.R3);
        $display("R4: %b", lab7_top_tb.DUT.CPU.DP.REGFILE.R4);
        $display("R5: %b", lab7_top_tb.DUT.CPU.DP.REGFILE.R5);
        $display("R6: %b", lab7_top_tb.DUT.CPU.DP.REGFILE.R6);
        $display("R7: %b", lab7_top_tb.DUT.CPU.DP.REGFILE.R7);
        $display("mdata: %b", lab7_top_tb.DUT.CPU.DP.mdata);
        $display("Instruction: %b", lab7_top_tb.DUT.CPU.inst_reg);
        $display("Address : %b", lab7_top_tb.DUT.CPU.data_address_reg);
        if(err == 1'b0) begin 
            $display("Passed");
        end
        $stop;
    end
endmodule