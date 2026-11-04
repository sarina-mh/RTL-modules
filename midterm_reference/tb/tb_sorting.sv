`timescale 1ns/1ps
module sorting_check #(parameter W=8,N=8,SIGNED=0)(output bit finished=0);
    localparam ALGORITHMS=20;
    logic clk=0;always #5 clk=~clk;
    logic rst_n=0,start=0;logic [N*W-1:0] data=0;
    wire [N*W-1:0] sorted[ALGORITHMS];wire [ALGORITHMS-1:0] busy,done;
    selection_sort #(W,N,SIGNED) s0(clk,rst_n,start,data,sorted[0],busy[0],done[0]);
    bubble_sort #(W,N,SIGNED) s1(clk,rst_n,start,data,sorted[1],busy[1],done[1]);
    insertion_sort #(W,N,SIGNED) s2(clk,rst_n,start,data,sorted[2],busy[2],done[2]);
    quick_sort #(W,N,SIGNED) s3(clk,rst_n,start,data,sorted[3],busy[3],done[3]);
    merge_sort #(W,N,SIGNED) s4(clk,rst_n,start,data,sorted[4],busy[4],done[4]);
    heap_sort #(W,N,SIGNED) s5(clk,rst_n,start,data,sorted[5],busy[5],done[5]);
    shell_sort #(W,N,SIGNED) s6(clk,rst_n,start,data,sorted[6],busy[6],done[6]);
    gnome_sort #(W,N,SIGNED) s7(clk,rst_n,start,data,sorted[7],busy[7],done[7]);
    cocktail_sort #(W,N,SIGNED) s8(clk,rst_n,start,data,sorted[8],busy[8],done[8]);
    comb_sort #(W,N,SIGNED) s9(clk,rst_n,start,data,sorted[9],busy[9],done[9]);
    odd_even_sort #(W,N,SIGNED) s10(clk,rst_n,start,data,sorted[10],busy[10],done[10]);
    radix_sort #(W,N,SIGNED) s11(clk,rst_n,start,data,sorted[11],busy[11],done[11]);
    counting_sort #(W,N,SIGNED) s12(clk,rst_n,start,data,sorted[12],busy[12],done[12]);
    bucket_sort #(W,N,SIGNED) s13(clk,rst_n,start,data,sorted[13],busy[13],done[13]);
    generate if((N&(N-1))==0)begin
        bitonic_sort #(W,N,SIGNED) s14(clk,rst_n,start,data,sorted[14],busy[14],done[14]);
    end else begin
        // Bitonic's documented power-of-two restriction is intentional.
        assign sorted[14]=sorted[0];assign busy[14]=busy[0];assign done[14]=done[0];
    end endgenerate
    // The sixteenth standard method is rank (enumeration) sort.
    rank_sort #(W,N,SIGNED) s15(clk,rst_n,start,data,sorted[15],busy[15],done[15]);
    intro_sort #(W,N,SIGNED) s16(clk,rst_n,start,data,sorted[16],busy[16],done[16]);
    tim_sort #(W,N,SIGNED) s17(clk,rst_n,start,data,sorted[17],busy[17],done[17]);
    // Extra parameter configurations explicitly cover heap fallback and RUN=1.
    intro_sort #(W,N,SIGNED,0) s18(clk,rst_n,start,data,sorted[18],busy[18],done[18]);
    tim_sort #(W,N,SIGNED,1) s19(clk,rst_n,start,data,sorted[19],busy[19],done[19]);
    int original[N],golden[N],t,i,j,rank_value,k,cycles;bit [ALGORITHMS-1:0] seen;
    task tick;@(posedge clk);#1;@(negedge clk);endtask
    initial begin
        tick();rst_n=1;start=1;tick();start=0;rst_n=0;tick();
        if(busy||done)$fatal(1,"sorting reset");rst_n=1;
        for(t=0;t<100;t++)begin
            for(i=0;i<N;i++)begin
                case(t%10)
                    0:data[i*W+:W]=0;
                    1:data[i*W+:W]=i;
                    2:data[i*W+:W]=N-i;
                    3:data[i*W+:W]={W{1'b1}};
                    4:data[i*W+:W]=(i%2)?(1<<(W-1)):((1<<(W-1))-1);
                    default:data[i*W+:W]=$urandom;
                endcase
                original[i]=int'(data[i*W+:W]);
                if(SIGNED&&data[i*W+W-1])original[i]-=(1<<W);
            end
            for(i=0;i<N;i++)begin
                rank_value=0;
                for(j=0;j<N;j++)if($signed(original[j])<$signed(original[i]) || (original[j]==original[i]&&j<i))rank_value++;
                golden[rank_value]=original[i];
            end
            start=1;tick();start=0;data=~data;seen=0;cycles=0;
            while(!(&seen))begin
                for(k=0;k<ALGORITHMS;k++)if(done[k])begin
                    if(busy[k]||seen[k])$fatal(1,"sorting handshake algorithm=%0d",k);
                    for(i=0;i<N;i++)if(sorted[k][i*W+:W]!==(golden[i]&((1<<W)-1)))
                        $fatal(1,"sort algorithm=%0d W=%0d N=%0d signed=%0d case=%0d index=%0d got=%h expected=%h",k,W,N,SIGNED,t,i,sorted[k][i*W+:W],golden[i]);
                    seen[k]=1;
                end
                tick();cycles++;
                if(cycles>20*N*N+4*(1<<W)+100)$fatal(1,"sorting timeout seen=%h",seen);
            end
            tick();if(done)$fatal(1,"sorting done pulse");
        end
        $display("PASS sorting W=%0d N=%0d signed=%0d arrays=100 methods=18 extra_configs=2",W,N,SIGNED);finished=1;
    end
endmodule
module tb_sorting;
    wire a,b,c,d,e;
    sorting_check #(1,1,0) c0(a);sorting_check #(4,5,0) c1(b);
    sorting_check #(4,4,1) c2(c);sorting_check #(8,8,1) c3(d);sorting_check #(8,8,0) c4(e);
    initial begin wait(a&&b&&c&&d&&e);$display("PASS tb_sorting");$finish;end
    initial begin #10000000;$fatal(1,"timeout");end
endmodule
