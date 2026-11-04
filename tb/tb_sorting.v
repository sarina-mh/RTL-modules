// Pure Verilog-2005 self-checking testbench (no SystemVerilog, no Python).
// Example with Icarus:
//   iverilog -g2005 -s tb_sorting -o sorting_sim rtl/*.v tb/tb_sorting.v
//   vvp sorting_sim
// Each sorting file includes its controller, datapath and public top.
`timescale 1ns/1ps

module sorting_verilog_check #(parameter W=8,N=8,SIGNED=0)(output reg finished);
    reg clk,rst_n,start;
    reg [N*W-1:0] data_in;
    wire [N*W-1:0] sorted[0:17];
    wire [17:0] busy,done;
    reg [17:0] seen;
    integer original[0:N-1],expected[0:N-1];
    integer trial,i,j,m,rank_value,cycles,seed;
    localparam MASK=(1<<W)-1;

    selection_sort #(W,N,SIGNED) u0(clk,rst_n,start,data_in,sorted[0],busy[0],done[0]);
    bubble_sort #(W,N,SIGNED) u1(clk,rst_n,start,data_in,sorted[1],busy[1],done[1]);
    insertion_sort #(W,N,SIGNED) u2(clk,rst_n,start,data_in,sorted[2],busy[2],done[2]);
    quick_sort #(W,N,SIGNED) u3(clk,rst_n,start,data_in,sorted[3],busy[3],done[3]);
    merge_sort #(W,N,SIGNED) u4(clk,rst_n,start,data_in,sorted[4],busy[4],done[4]);
    heap_sort #(W,N,SIGNED) u5(clk,rst_n,start,data_in,sorted[5],busy[5],done[5]);
    shell_sort #(W,N,SIGNED) u6(clk,rst_n,start,data_in,sorted[6],busy[6],done[6]);
    gnome_sort #(W,N,SIGNED) u7(clk,rst_n,start,data_in,sorted[7],busy[7],done[7]);
    cocktail_sort #(W,N,SIGNED) u8(clk,rst_n,start,data_in,sorted[8],busy[8],done[8]);
    comb_sort #(W,N,SIGNED) u9(clk,rst_n,start,data_in,sorted[9],busy[9],done[9]);
    odd_even_sort #(W,N,SIGNED) u10(clk,rst_n,start,data_in,sorted[10],busy[10],done[10]);
    radix_sort #(W,N,SIGNED) u11(clk,rst_n,start,data_in,sorted[11],busy[11],done[11]);
    counting_sort #(W,N,SIGNED) u12(clk,rst_n,start,data_in,sorted[12],busy[12],done[12]);
    bucket_sort #(W,N,SIGNED) u13(clk,rst_n,start,data_in,sorted[13],busy[13],done[13]);
    bitonic_sort #(W,N,SIGNED) u14(clk,rst_n,start,data_in,sorted[14],busy[14],done[14]);
    rank_sort #(W,N,SIGNED) u15(clk,rst_n,start,data_in,sorted[15],busy[15],done[15]);
    intro_sort #(W,N,SIGNED) u16(clk,rst_n,start,data_in,sorted[16],busy[16],done[16]);
    tim_sort #(W,N,SIGNED) u17(clk,rst_n,start,data_in,sorted[17],busy[17],done[17]);

    always #5 clk=~clk;
    task tick;
        begin @(posedge clk);#1;@(negedge clk);end
    endtask
    initial begin
        clk=0;rst_n=0;start=0;data_in=0;finished=0;seed=451+W+N+SIGNED;
        tick();rst_n=1;
        for(trial=0;trial<80;trial=trial+1)begin
            for(i=0;i<N;i=i+1)begin
                case(trial%8)
                    0:data_in[i*W+:W]=0;
                    1:data_in[i*W+:W]=i;
                    2:data_in[i*W+:W]=N-i;
                    3:data_in[i*W+:W]={W{1'b1}};
                    default:data_in[i*W+:W]=$random(seed);
                endcase
                original[i]=data_in[i*W+:W];
                if(SIGNED && data_in[i*W+W-1])original[i]=original[i]-(1<<W);
            end
            // Independent rank oracle; earlier equal elements break ties.
            for(i=0;i<N;i=i+1)begin
                rank_value=0;
                for(j=0;j<N;j=j+1)
                    if(original[j]<original[i] || (original[j]==original[i] && j<i))rank_value=rank_value+1;
                expected[rank_value]=original[i];
            end
            start=1;tick();start=0;data_in=~data_in;seen=0;cycles=0;
            while(seen!={18{1'b1}})begin
                for(m=0;m<18;m=m+1)if(done[m])begin
                    if(busy[m] || seen[m])begin
                        $display("FAIL handshake method=%0d",m);$finish;
                    end
                    for(i=0;i<N;i=i+1)if(sorted[m][i*W+:W] !== (expected[i]&MASK))begin
                        $display("FAIL method=%0d W=%0d N=%0d signed=%0d trial=%0d index=%0d",m,W,N,SIGNED,trial,i);$finish;
                    end
                    seen[m]=1;
                end
                tick();cycles=cycles+1;
                if(cycles>20*N*N+4*(1<<W)+100)begin $display("FAIL timeout");$finish;end
            end
            tick();if(done!=0)begin $display("FAIL done pulse");$finish;end
        end
        $display("PASS Verilog sorting W=%0d N=%0d signed=%0d methods=18 arrays=80",W,N,SIGNED);
        finished=1;
    end
endmodule

module tb_sorting;
    wire a,b,c;
    sorting_verilog_check #(1,1,0) small_case(a);
    sorting_verilog_check #(8,8,0) unsigned_case(b);
    sorting_verilog_check #(8,8,1) signed_case(c);
    initial begin wait(a&&b&&c);$display("PASS tb_sorting (pure Verilog-2005)");$finish;end
    initial begin #10000000;$display("FAIL global timeout");$finish;end
endmodule
