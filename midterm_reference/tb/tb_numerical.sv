`timescale 1ns/1ps
module taylor_check #(parameter W=32,Q=20)(output bit finished=0);
    logic clk=0;always #5 clk=~clk;
    logic rst_n=0,start=0;logic signed [W-1:0] xe=0,xt=0,xw=0;
    wire signed [W-1:0] ye,ys,yc,yw;wire [3:0] busy,done,range_error,overflow;
    exp_taylor #(W,Q) exp0(clk,rst_n,start,xe,ye,busy[0],done[0],range_error[0],overflow[0]);
    sin_taylor #(W,Q) sin0(clk,rst_n,start,xt,ys,busy[1],done[1],range_error[1],overflow[1]);
    cos_taylor #(W,Q) cos0(clk,rst_n,start,xt,yc,busy[2],done[2],range_error[2],overflow[2]);
    exponential_fixed #(W,Q) exp1(clk,rst_n,start,xw,yw,busy[3],done[3],range_error[3],overflow[3]);
    logic signed [W-1:0] re,rs,rc,rw,vxe,vxt,vxw;logic [W-1:0] ov;
    int fd,scan,count=0,cycles,err,max_error=0;bit [3:0] seen;
    string filename;
    task tick;@(posedge clk);#1;@(negedge clk);endtask
    task verify;input integer got,expected;
        begin err=got-expected;if(err<0)err=-err;if(err>max_error)max_error=err;
            if(err>64)$fatal(1,"Taylor W=%0d Q=%0d case=%0d got=%0d expected=%0d error=%0d",W,Q,count,got,expected,err);
        end
    endtask
    initial begin
        filename=$sformatf("build/vectors/taylor_%0d_%0d.txt",W,Q);fd=$fopen(filename,"r");if(!fd)$fatal(1,"missing numeric file");
        tick();rst_n=1;
        while(!$feof(fd))begin
            scan=$fscanf(fd,"%h %h %h %h %h %h %h %h\n",vxe,vxt,vxw,re,rs,rc,rw,ov);
            if(scan!=8)$fatal(1,"bad numeric vector");
            xe=vxe;xt=vxt;xw=vxw;start=1;tick();start=0;xe=0;xt=0;xw=0;seen=0;cycles=0;
            while(!(&seen))begin
                if(done[0])begin verify($signed(ye),$signed(re));seen[0]=1;end
                if(done[1])begin verify($signed(ys),$signed(rs));seen[1]=1;end
                if(done[2])begin verify($signed(yc),$signed(rc));seen[2]=1;end
                if(done[3])begin verify($signed(yw),$signed(rw));seen[3]=1;if(overflow[3]!==ov[0])$fatal(1,"exp overflow");end
                if(range_error)$fatal(1,"unexpected numeric domain");
                if(overflow[2:0])$fatal(1,"Taylor unexpected overflow");
                tick();if(cycles++>60)$fatal(1,"Taylor timeout");
            end
            count++;
        end
        $fclose(fd);
        // Deliberately violate each documented input domain.
        xe=2<<Q;xt=4<<Q;xw=5<<Q;start=1;tick();start=0;
        if(range_error!==4'b1111)$fatal(1,"domain flags");
        rst_n=0;tick();if(busy||done)$fatal(1,"numeric reset");
        $display("PASS Taylor/exp W=%0d Q=%0d cases=%0d max_error_LSB=%0d tolerance=64",W,Q,count,max_error);finished=1;
    end
endmodule

module fourier_check #(parameter N=8,Q=20,INVERSE=0,W=32)(output bit finished=0);
    logic clk=0;always #5 clk=~clk;
    logic rst_n=0,start=0;logic [N*W-1:0] re=0,im=0;
    wire [N*W-1:0] dr,di,fr,fi;wire bd,dd,od,bf,df,of;
    dft_fixed #(W,Q,N,INVERSE) dft(clk,rst_n,start,re,im,dr,di,bd,dd,od);
    fft_radix2 #(W,Q,N,INVERSE) fft(clk,rst_n,start,re,im,fr,fi,bf,df,of);
    logic signed [W-1:0] v,golden_r[N],golden_i[N];
    int fd,scan,t,k,cycles,error_value,max_error=0;bit seen_d,seen_f;string filename;
    task tick;@(posedge clk);#1;@(negedge clk);endtask
    task verify;input [N*W-1:0] r,i;
        integer p,got,expected;
        begin
            for(p=0;p<N;p++)begin
                got=$signed(r[p*W+:W]);expected=$signed(golden_r[p]);error_value=got-expected;
                if(error_value<0)error_value=-error_value;if(error_value>max_error)max_error=error_value;
                if(error_value>4*N+8)$fatal(1,"Fourier real N=%0d inverse=%0d case=%0d bin=%0d got=%0d expected=%0d",N,INVERSE,t,p,got,expected);
                got=$signed(i[p*W+:W]);expected=$signed(golden_i[p]);error_value=got-expected;
                if(error_value<0)error_value=-error_value;if(error_value>max_error)max_error=error_value;
                if(error_value>4*N+8)$fatal(1,"Fourier imag N=%0d inverse=%0d bin=%0d got=%0d expected=%0d",N,INVERSE,p,got,expected);
            end
        end
    endtask
    initial begin
        filename=$sformatf("build/vectors/fourier_%0d_%0d_%0d.txt",N,Q,INVERSE);fd=$fopen(filename,"r");if(!fd)$fatal(1,"missing Fourier vectors");
        tick();rst_n=1;
        for(t=0;t<24;t++)begin
            for(k=0;k<N;k++)begin scan=$fscanf(fd,"%h",v);if(scan!=1)$fatal(1,"bad Fourier vector");re[k*W+:W]=v;end
            for(k=0;k<N;k++)begin scan=$fscanf(fd,"%h",v);if(scan!=1)$fatal(1,"bad Fourier vector");im[k*W+:W]=v;end
            for(k=0;k<N;k++)begin scan=$fscanf(fd,"%h",golden_r[k]);if(scan!=1)$fatal(1,"bad Fourier expected");end
            for(k=0;k<N;k++)begin scan=$fscanf(fd,"%h",golden_i[k]);if(scan!=1)$fatal(1,"bad Fourier expected");end
            start=1;tick();start=0;re=0;im=0;seen_d=0;seen_f=0;cycles=0;
            while(!(seen_d&&seen_f))begin
                if(dd)begin verify(dr,di);seen_d=1;if(od)$fatal(1,"DFT overflow");end
                if(df)begin verify(fr,fi);seen_f=1;if(of)$fatal(1,"FFT overflow");end
                tick();if(cycles++>N*N+100)$fatal(1,"Fourier timeout");
            end
        end
        $fclose(fd);
        // Large DC input deliberately overflows unnormalized transforms.
        if(N>1 && !INVERSE)begin
            for(k=0;k<N;k++)begin re[k*W+:W]=32'h7fffffff;im[k*W+:W]=0;end
            start=1;tick();start=0;seen_d=0;seen_f=0;cycles=0;
            while(!(seen_d&&seen_f))begin
                if(dd)begin if(!od || dr[0+:W]!==32'h7fffffff)$fatal(1,"DFT saturation");seen_d=1;end
                if(df)begin if(!of || fr[0+:W]!==32'h7fffffff)$fatal(1,"FFT saturation");seen_f=1;end
                tick();if(cycles++>N*N+100)$fatal(1,"overflow timeout");
            end
        end
        start=1;tick();start=0;rst_n=0;tick();if(bd||bf||dd||df)$fatal(1,"Fourier reset");
        $display("PASS DFT/FFT N=%0d Q=%0d inverse=%0d cases=24 max_error_LSB=%0d tolerance=%0d",N,Q,INVERSE,max_error,4*N+8);finished=1;
    end
endmodule

module series_check #(parameter H=3,Q=20,W=32)(output bit finished=0);
    logic clk=0;always #5 clk=~clk;
    logic rst_n=0,start=0;logic [5:0] phase=0;
    logic [(H+1)*W-1:0] cs=0,ss=0;
    wire signed [W-1:0] result;wire busy,done,overflow;
    fourier_series #(W,Q,H) dut(clk,rst_n,start,phase,cs,ss,result,busy,done,overflow);
    logic signed [31:0] v,expected;int fd,scan,t,k,cycles,err,max_error=0;string filename;
    task tick;@(posedge clk);#1;@(negedge clk);endtask
    initial begin
        filename=$sformatf("build/vectors/series_%0d_%0d.txt",H,Q);fd=$fopen(filename,"r");if(!fd)$fatal(1,"missing series file");
        tick();rst_n=1;
        for(t=0;t<64;t++)begin
            scan=$fscanf(fd,"%h",v);if(scan!=1)$fatal(1,"bad series");phase=v;
            for(k=0;k<=H;k++)begin scan=$fscanf(fd,"%h",v);if(scan!=1)$fatal(1,"bad series");cs[k*W+:W]=v;end
            for(k=0;k<=H;k++)begin scan=$fscanf(fd,"%h",v);if(scan!=1)$fatal(1,"bad series");ss[k*W+:W]=v;end
            scan=$fscanf(fd,"%h",expected);if(scan!=1)$fatal(1,"bad series expected");
            start=1;tick();start=0;cs=0;ss=0;phase=0;cycles=0;
            while(!done)begin tick();if(cycles++>H+10)$fatal(1,"series timeout");end
            err=$signed(result)-$signed(expected);if(err<0)err=-err;if(err>max_error)max_error=err;
            if(err>4*H+4||overflow)$fatal(1,"Fourier series H=%0d phase=%0d got=%0d expected=%0d error=%0d",H,t,result,expected,err);
            tick();
        end
        $fclose(fd);$display("PASS Fourier series H=%0d Q=%0d phases=64 max_error_LSB=%0d",H,Q,max_error);finished=1;
    end
endmodule

module tb_numerical;
    wire a,b,c,d,e,f,g,h,i,j;
    taylor_check #(16,12) t0(a);taylor_check #(32,20) t1(b);
    fourier_check #(1,12,0) f0(c);fourier_check #(4,12,1) f1(d);
    fourier_check #(8,20,0) f2(e);fourier_check #(16,12,0) f3(f);fourier_check #(64,20,0) f4(g);
    series_check #(0,12) fs0(h);series_check #(3,20) fs1(i);series_check #(8,12) fs2(j);
    initial begin wait(a&&b&&c&&d&&e&&f&&g&&h&&i&&j);$display("PASS tb_numerical");$finish;end
    initial begin #20000000;$fatal(1,"timeout");end
endmodule
