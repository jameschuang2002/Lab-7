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
        SW[7:0] = 8'd4;
        KEY[1] = 1; #700;
        test(16'd8);
        if(lab7_top_tb.DUT.CPU.DP.REGFILE.R3[7:0] !== LEDR[7:0]) begin
            err = 1'b1;
            $display("Incorrect LED. Expected: %b, Actual: %b", lab7_top_tb.DUT.CPU.DP.REGFILE.R3[7:0], LEDR[7:0]);
        end
        if(err == 1'b0) begin 
            $display("Passed");
        end
        $stop;
    end
endmodule