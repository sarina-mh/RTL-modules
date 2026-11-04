`timescale 1ns/1ps
module sort_check #(parameter W=8,N=8,SIGNED=0)(output bit finished=0);
    logic clk=0;always #5 clk=~clk;
    logic rst_n=0,start=0;logic [N*W-1:0] data;
    wire [N*W-1:0] s,b,i;wire bs,bb,bi,ds,db,di;
    wire [W+$clog2(N)-1:0] sum;wire sum_busy,sum_done;
    wire [W-1:0] minimum,maximum;wire [(N>1?$clog2(N):1)-1:0] argmax;
    selection_sort #(W,N,SIGNED) s0(clk,rst_n,start,data,s,bs,ds);
    bubble_sort #(W,N,SIGNED) b0(clk,rst_n,start,data,b,bb,db);
    insertion_sort #(W,N,SIGNED) i0(clk,rst_n,start,data,i,bi,di);
    array_sum #(W,N) su(clk,rst_n,start,data,sum,sum_busy,sum_done);
    array_extrema #(W,N,SIGNED) ex(data,minimum,maximum,argmax);
    int golden[N],original[N],t,k,m,rank_index,cycles,expected_sum,minval,maxval,maxidx;
    bit seen_s,seen_b,seen_i,seen_sum;
    task tick; @(posedge clk);#1;@(negedge clk);endtask
    initial begin
        data=0;tick();rst_n=1;
        // Abort an active transaction, then verify complete restart.
        start=1;tick();start=0;rst_n=0;tick();
        if(bs||bb||bi||ds||db||di||sum_busy||sum_done) $fatal(1,"sort reset");
        rst_n=1;
        for(t=0;t<200;t++) begin
            expected_sum=0;
            for(k=0;k<N;k++) begin
                case(t%10)
                    0:data[k*W+:W]=0;
                    1:data[k*W+:W]=k;
                    2:data[k*W+:W]=N-k;
                    3:data[k*W+:W]={W{1'b1}};
                    default:data[k*W+:W]=$urandom;
                endcase
                expected_sum+=int'(data[k*W+:W]);
                original[k]=int'(data[k*W+:W]);
                if(SIGNED && data[k*W+W-1]) original[k]-=(1<<W);
                golden[k]=original[k];
            end
            minval=original[0];maxval=original[0];maxidx=0;
            for(k=1;k<N;k++)begin
                if(original[k]<minval)minval=original[k];
                if(original[k]>maxval)begin maxval=original[k];maxidx=k;end
            end
            // Independent rank oracle; ties are ordered by original index.
            for(k=0;k<N;k++) begin
                rank_index=0;
                for(m=0;m<N;m++)
                    if($signed(original[m])<$signed(original[k]) ||
                       (original[m]==original[k] && m<k)) rank_index++;
                golden[rank_index]=original[k];
            end
            #1;
            if(minimum!==(minval&((1<<W)-1)) || maximum!==(maxval&((1<<W)-1)) || argmax!==maxidx) $fatal(1,"extrema");
            start=1;tick();start=0;
            // Input changes after acceptance must not affect the transaction.
            data=~data;
            seen_s=0;seen_b=0;seen_i=0;seen_sum=0;cycles=0;
            while(!(seen_s&&seen_b&&seen_i&&seen_sum)) begin
                if(ds)begin
                    for(k=0;k<N;k++) if(s[k*W+:W]!==(golden[k]&((1<<W)-1))) $fatal(1,"selection N=%0d t=%0d k=%0d",N,t,k);
                    if(bs)$fatal(1,"selection busy on done");seen_s=1;
                end
                if(db)begin
                    for(k=0;k<N;k++) if(b[k*W+:W]!==(golden[k]&((1<<W)-1))) begin $display("original=%p golden=%p",original,golden);$fatal(1,"bubble N=%0d t=%0d k=%0d got=%h expected=%h packed=%h",N,t,k,b[k*W+:W],golden[k],b);end
                    seen_b=1;
                end
                if(di)begin
                    for(k=0;k<N;k++) if(i[k*W+:W]!==(golden[k]&((1<<W)-1))) $fatal(1,"insertion");
                    seen_i=1;
                end
                if(sum_done)begin if(sum!==expected_sum)$fatal(1,"array sum");seen_sum=1;end
                tick();cycles++;
                if(cycles>4*N*N+20)$fatal(1,"algorithm timeout");
            end
            tick();if(ds||db||di||sum_done)$fatal(1,"done not pulse");
        end
        $display("PASS sorts/extrema/array_sum W=%0d N=%0d signed=%0d cases=200",W,N,SIGNED);finished=1;
    end
endmodule

module tb_algorithms;
    wire f1,f2,f3;
    sort_check #(8,8,0) s1(f1);sort_check #(1,1,0) s2(f2);sort_check #(13,5,1) s3(f3);
    logic clk=0;always #5 clk=~clk;
    logic rst_n=0,start=0;logic [7:0] a,b;
    wire [15:0] product;wire [7:0] g,q,r;wire bg,bm,bd,dg,dm,dd,dz;
    gcd #(8) ug(clk,rst_n,start,a,b,g,bg,dg);
    shift_add_multiplier #(8) um(clk,rst_n,start,a,b,product,bm,dm);
    iterative_divider #(8) ud(clk,rst_n,start,a,b,q,r,bd,dd,dz);
    int t,aa,bb,ref_g,x,y,remnant,cycles;bit sg,sm,sd;
    task tick;@(posedge clk);#1;@(negedge clk);endtask
    initial begin
        a=0;b=0;tick();rst_n=1;
        for(t=0;t<4096;t++) begin
            a=$urandom;b=$urandom;
            if(t<256)begin a=t;b=0;end
            if(t>=256&&t<512)begin a=t-256;b=1;end
            aa=a;bb=b;x=aa;y=bb;
            while(y!=0)begin remnant=x%y;x=y;y=remnant;end ref_g=x;
            start=1;tick();start=0;a=~a;b=~b;
            sg=0;sm=0;sd=0;cycles=0;
            while(!(sg&&sm&&sd))begin
                if(dg)begin if(g!==ref_g)$fatal(1,"gcd");sg=1;end
                if(dm)begin if(product!==aa*bb)$fatal(1,"multiply");sm=1;end
                if(dd)begin
                    if(q!==((bb==0)?255:aa/bb)||r!==((bb==0)?aa:aa%bb)||dz!==(bb==0))$fatal(1,"iterative divide");sd=1;
                end
                tick();cycles++;if(cycles>300)$fatal(1,"arithmetic timeout");
            end
        end
        wait(f1&&f2&&f3);$display("PASS tb_algorithms: 4096 GCD/multiply/divide transactions");$finish;
    end
    initial begin #20000000;$fatal(1,"timeout");end
endmodule
