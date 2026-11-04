`timescale 1ns/1ps
module exam_arrays #(parameter W=8,N=5,SIGNED=0)(output bit finished=0);
    localparam I=(N>1?$clog2(N):1),AW=W+$clog2(N),DW=2*W+$clog2(N),MASK=(1<<W)-1;
    localparam R=2,K=3,C=2,MW=2*W+$clog2(K);
    logic clk=0;always #5 clk=~clk;
    logic rst_n=0,start=0;logic [N*W-1:0] a=0,b=0,sorted=0;logic [W-1:0] target=0,x=0;
    logic [R*K*W-1:0] ma=0;logic [K*C*W-1:0] mb=0;
    wire lf,bf;wire [I-1:0] li,bi;wire [7:0] busy,done;
    wire [N*W-1:0] reversed;wire [N*AW-1:0] prefixes;wire [DW-1:0] dot;
    wire [R*C*MW-1:0] matrix;wire [W-1:0] polynomial;wire [(2*N-1)*DW-1:0] conv;
    linear_search #(W,N) lin(clk,rst_n,start,a,target,lf,li,busy[0],done[0]);
    binary_search #(W,N,SIGNED) bin(clk,rst_n,start,sorted,target,bf,bi,busy[1],done[1]);
    array_reverse #(W,N) rev(clk,rst_n,start,a,reversed,busy[2],done[2]);
    prefix_sum #(W,N) pre(clk,rst_n,start,a,prefixes,busy[3],done[3]);
    dot_product #(W,N,SIGNED) dp(clk,rst_n,start,a,b,dot,busy[4],done[4]);
    matrix_multiply #(W,R,K,C,SIGNED) mm(clk,rst_n,start,ma,mb,matrix,busy[5],done[5]);
    polynomial_horner #(W,N) ph(clk,rst_n,start,x,a,polynomial,busy[6],done[6]);
    convolution #(W,N,N,SIGNED) co(clk,rst_n,start,a,b,conv,busy[7],done[7]);
    int av[N],bv[N],order[N],mv_a[R*K],mv_b[K*C],expected_prefix[N],expected_matrix[R*C],expected_conv[2*N-1];
    int t,i,j,k,r,c,rank_value,expected_l,expected_b,expected_dot,expected_poly,total,cycles;
    bit [7:0] seen;
    function integer signed_value;input [W-1:0] v;
        begin signed_value=int'(v);if(SIGNED&&v[W-1])signed_value=signed_value-(1<<W);end
    endfunction
    task tick;@(posedge clk);#1;@(negedge clk);endtask
    initial begin
        tick();rst_n=1;
        for(t=0;t<160;t++)begin
            expected_dot=0;total=0;
            for(i=0;i<N;i++)begin
                a[i*W+:W]=$urandom;b[i*W+:W]=$urandom;
                if(t%8==0)begin a[i*W+:W]=3;b[i*W+:W]=0;end
                av[i]=signed_value(a[i*W+:W]);bv[i]=signed_value(b[i*W+:W]);
                expected_dot+=av[i]*bv[i];total+=int'(a[i*W+:W]);expected_prefix[i]=total;
            end
            for(i=0;i<N;i++)begin
                rank_value=0;
                for(j=0;j<N;j++)if($signed(av[j])<$signed(av[i])||(av[j]==av[i]&&j<i))rank_value++;
                order[rank_value]=av[i];
            end
            for(i=0;i<N;i++)sorted[i*W+:W]=order[i]&MASK;
            target=(t%2)?a[(t%N)*W+:W]:$urandom;x=$urandom;expected_l=-1;expected_b=-1;
            for(i=N-1;i>=0;i--)begin
                if((av[i]&MASK)==target)expected_l=i;
                if((order[i]&MASK)==target)expected_b=i;
            end
            // Direct powers form an oracle independent of Horner's recurrence.
            expected_poly=0;total=1;
            for(i=0;i<N;i++)begin expected_poly=(expected_poly+(av[i]&MASK)*total)&MASK;total=(total*int'(x))&MASK;end
            for(i=0;i<R*K;i++)begin ma[i*W+:W]=$urandom;mv_a[i]=signed_value(ma[i*W+:W]);end
            for(i=0;i<K*C;i++)begin mb[i*W+:W]=$urandom;mv_b[i]=signed_value(mb[i*W+:W]);end
            for(r=0;r<R;r++)for(c=0;c<C;c++)begin
                total=0;for(k=0;k<K;k++)total+=mv_a[r*K+k]*mv_b[k*C+c];expected_matrix[r*C+c]=total;
            end
            for(i=0;i<2*N-1;i++)begin
                total=0;for(j=0;j<N;j++)if(i>=j&&i-j<N)total+=av[j]*bv[i-j];expected_conv[i]=total;
            end
            start=1;tick();start=0;a=0;b=0;ma=0;mb=0;sorted=0;target=0;x=0;seen=0;cycles=0;
            while(!(&seen))begin
                for(k=0;k<8;k++)if(done[k])begin if(busy[k]||seen[k])$fatal(1,"exam handshake");seen[k]=1;end
                if(done[0]&&(lf!==(expected_l>=0)||li!==((expected_l>=0)?expected_l:0)))$fatal(1,"linear search");
                if(done[1]&&(bf!==(expected_b>=0)||bi!==((expected_b>=0)?expected_b:0)))$fatal(1,"binary search W=%0d N=%0d",W,N);
                if(done[2])for(i=0;i<N;i++)if(reversed[i*W+:W]!==(av[N-1-i]&MASK))$fatal(1,"reverse");
                if(done[3])for(i=0;i<N;i++)if(prefixes[i*AW+:AW]!==expected_prefix[i])$fatal(1,"prefix sum");
                if(done[4]&&dot!==(expected_dot&((1<<DW)-1)))$fatal(1,"dot product");
                if(done[5])for(i=0;i<R*C;i++)if(matrix[i*MW+:MW]!==(expected_matrix[i]&((1<<MW)-1)))$fatal(1,"matrix");
                if(done[6]&&polynomial!==expected_poly)$fatal(1,"polynomial");
                if(done[7])for(i=0;i<2*N-1;i++)if(conv[i*DW+:DW]!==(expected_conv[i]&((1<<DW)-1)))$fatal(1,"convolution W=%0d N=%0d signed=%0d case=%0d index=%0d got=%h expected=%h",W,N,SIGNED,t,i,conv[i*DW+:DW],expected_conv[i]);
                tick();if(cycles++>4*N*N+100)$fatal(1,"exam arrays timeout");
            end
        end
        start=1;tick();start=0;rst_n=0;tick();if(busy||done)$fatal(1,"exam arrays reset");
        $display("PASS exam arrays W=%0d N=%0d signed=%0d cases=160 modules=8",W,N,SIGNED);finished=1;
    end
endmodule

module tb_exam_algorithms;
    wire a,b,c;exam_arrays #(1,1,0) ar0(a);exam_arrays #(8,5,1) ar1(b);exam_arrays #(8,8,0) ar2(c);
    logic clk=0;always #5 clk=~clk;
    logic rst_n=0,start=0;logic [15:0] x=0,base=0;logic [7:0] exponent=0,n=0;
    wire [15:0] power,fact,fib,root;wire [3:0] busy,done;wire fact_overflow,fib_overflow;
    integer_power #(16,8) po(clk,rst_n,start,base,exponent,power,busy[0],done[0]);
    factorial #(16,8) fa(clk,rst_n,start,n,fact,busy[1],done[1],fact_overflow);
    fibonacci #(16,8) fi(clk,rst_n,start,n,fib,busy[2],done[2],fib_overflow);
    integer_sqrt #(16) sq(clk,rst_n,start,x,root,busy[3],done[3]);
    logic [63:0] values[10];int fd,scan,t,i,cycles;bit [3:0] seen;
    task tick;@(posedge clk);#1;@(negedge clk);endtask
    initial begin
        fd=$fopen("build/vectors/exam_scalar.txt","r");if(!fd)$fatal(1,"missing scalar vectors");
        tick();rst_n=1;
        for(t=0;t<1200;t++)begin
            for(i=0;i<10;i++)begin scan=$fscanf(fd,"%h",values[i]);if(scan!=1)$fatal(1,"bad scalar vectors");end
            x=values[0];base=values[1];exponent=values[2];n=values[3];
            start=1;tick();start=0;x=0;base=0;exponent=0;n=0;seen=0;cycles=0;
            while(!(&seen))begin
                for(i=0;i<4;i++)if(done[i])begin if(busy[i]||seen[i])$fatal(1,"scalar handshake");seen[i]=1;end
                if(done[0]&&power!==values[8])$fatal(1,"integer power");
                if(done[1]&&(fact!==values[4]||fact_overflow!==values[5][0]))$fatal(1,"factorial case=%0d",t);
                if(done[2]&&(fib!==values[6]||fib_overflow!==values[7][0]))$fatal(1,"fibonacci case=%0d",t);
                if(done[3]&&root!==values[9])$fatal(1,"integer sqrt");
                tick();if(cycles++>300)$fatal(1,"scalar timeout");
            end
        end
        $fclose(fd);wait(a&&b&&c);$display("PASS tb_exam_algorithms scalar_cases=1200 modules=4");$finish;
    end
    initial begin #20000000;$fatal(1,"timeout");end
endmodule
