// Plain Verilog test for the preserved array_max_min interface.
// iverilog -g2005 -s tb_array_max_min -o minmax_sim rtl/array_max_min.v tb/tb_array_max_min.v
// vvp minmax_sim
`timescale 1ns/1ps
module minmax_verilog_check #(parameter W=8,N=8)(output reg finished);
    reg clk,rst,start;reg [N*W-1:0] data_in;
    wire [W-1:0] maximum,minimum;wire busy,done;
    integer trial,k,value,expected_max,expected_min,cycles,seed;
    array_max_min #(.N(N),.WIDTH(W)) dut(
        .clk(clk),.rst(rst),.start(start),.data_in(data_in),
        .max_val(maximum),.min_val(minimum),.busy(busy),.done(done)
    );
    always #5 clk=~clk;
    task tick;begin @(posedge clk);#1;@(negedge clk);end endtask
    initial begin
        clk=0;rst=1;start=0;data_in=0;finished=0;seed=134+W+N;
        tick();rst=0;
        for(trial=0;trial<100;trial=trial+1)begin
            expected_max=0;expected_min=(1<<W)-1;
            for(k=0;k<N;k=k+1)begin
                data_in[k*W+:W]=$random(seed);
                value=data_in[k*W+:W];
                if(value>expected_max)expected_max=value;
                if(value<expected_min)expected_min=value;
            end
            start=1;tick();start=0;cycles=0;
            // Legacy module scans data_in directly: keep it stable until done.
            while(!done)begin tick();cycles=cycles+1;
                if(cycles>N+10)begin $display("FAIL max/min timeout");$finish;end
            end
            if(maximum!==expected_max || minimum!==expected_min)begin
                $display("FAIL max/min W=%0d N=%0d trial=%0d",W,N,trial);$finish;
            end
            tick();tick();
        end
        $display("PASS max/min W=%0d N=%0d cases=100",W,N);finished=1;
    end
endmodule
module tb_array_max_min;
    wire a,b;
    minmax_verilog_check #(1,1) small_case(a);
    minmax_verilog_check #(8,8) array_case(b);
    initial begin wait(a&&b);$display("PASS tb_array_max_min (pure Verilog-2005)");$finish;end
    initial begin #1000000;$display("FAIL timeout");$finish;end
endmodule
