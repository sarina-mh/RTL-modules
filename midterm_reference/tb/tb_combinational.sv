`timescale 1ns/1ps
module comb_check #(parameter W=8,N=5)(output bit done=0);
    localparam S=(N>1?$clog2(N):1), SH=(W>1?$clog2(W+1):1), C=$clog2(W+1);
    logic [W-1:0] a,b,y,ar,dq,dr,shifted,mux_y,demux_d=0,m2;
    logic cin,sub,carry,overflow,cout,lt,eq,gt,slt,seq,sgt,z,neg,ac,av;
    logic right,arithmetic,rotate,odd,dbz;
    logic [SH-1:0] amount;
    logic [2:0] op;
    logic [C-1:0] pc,lz;
    logic [N*W-1:0] lanes,demux_y;
    logic [S-1:0] sel;
    adder #(W) u0(a,b,cin,y,cout);
    add_sub #(W) u1(a,b,sub,ar,carry,overflow);
    comparator #(W,0) u2(a,b,lt,eq,gt);
    comparator #(W,1) u3(a,b,slt,seq,sgt);
    divider #(W) u4(a,b,dq,dr,dbz);
    barrel_shifter #(W) u5(a,amount,right,arithmetic,rotate,shifted);
    parity #(W) u6(a,odd);
    popcount #(W) u7(a,pc);
    leading_zero_count #(W) u8(a,lz);
    alu #(W) u9(a,b,op,demux_d,z,neg,ac,av);
    mux #(W,N) u10(lanes,sel,mux_y);
    demux #(W,N) u11(a,sel,demux_y);
    mux2 #(W) u12(a,b,cin,m2);
    integer t,k,n,expected_pc,expected_lz,signed_a,signed_b,full,expected,mask;
    logic [W-1:0] shift_ref;
    initial begin
        mask=(1<<W)-1;
        for(t=0;t<(W<=4?(1<<(2*W)):24000);t++) begin
            if(W<=4) begin a=t&mask;b=(t>>W)&mask;end
            else begin a=$urandom;b=$urandom;end
            // Directed zero/divisor boundaries are mixed with random operands.
            if(t%97==0) b=0;
            cin=t%2;sub=(t/2)%2;op=t%8;
            amount=t%(1<<SH);right=t%2;arithmetic=(t/2)%2;rotate=(t/4)%2;
            sel=t%(1<<S);
            for(k=0;k<N;k++) lanes[k*W+:W]=(t+k)&mask;
            #1;
            full=int'(a)+int'(b)+int'(cin);
            if({cout,y}!==full) $fatal(1,"adder W=%0d",W);
            full=sub ? int'(a)-int'(b) : int'(a)+int'(b);
            if(ar!==(full&mask)) $fatal(1,"addsub");
            if(carry!==(sub?(a>=b):(full>mask))) $fatal(1,"carry");
            signed_a=a[W-1]?int'(a)-(1<<W):int'(a);
            signed_b=b[W-1]?int'(b)-(1<<W):int'(b);
            full=sub?signed_a-signed_b:signed_a+signed_b;
            if(overflow!==((full<-(1<<(W-1)))||(full>((1<<(W-1))-1)))) $fatal(1,"overflow");
            if({lt,eq,gt}!=={(a<b),(a==b),(a>b)}) $fatal(1,"unsigned compare");
            if({slt,seq,sgt}!=={(signed_a<signed_b),(signed_a==signed_b),(signed_a>signed_b)}) $fatal(1,"signed compare");
            if(b!=0) begin if(dq!==(int'(a)/int'(b)) || dr!==(int'(a)%int'(b))) $fatal(1,"divide");end
            else if(dq!==mask || dr!==a) $fatal(1,"divide zero");
            if(dbz!==(b==0)) $fatal(1,"divide flag");
            expected_pc=0;expected_lz=W;
            for(k=0;k<W;k++) if(a[k]) begin expected_pc++;expected_lz=W-1-k;end
            if(pc!==expected_pc || lz!==expected_lz || odd!==(expected_pc%2!=0)) $fatal(1,"bit functions");
            // Independent shift oracle follows individual source bits.
            shift_ref=0;n=rotate?int'(amount)%W:int'(amount);
            for(k=0;k<W;k++) begin
                if(rotate) shift_ref[k]=a[right?((k+n)%W):((k-n+W)%W)];
                else if(right) shift_ref[k]=(k+n<W)?a[k+n]:(arithmetic?a[W-1]:1'b0);
                else shift_ref[k]=(k>=n)?a[k-n]:1'b0;
            end
            if(shifted!==shift_ref) $fatal(1,"shift W=%0d",W);
            expected=0;
            case(op)
                0:expected=(a+b)&mask;1:expected=(a-b)&mask;
                2:expected=a&b;3:expected=a|b;4:expected=a^b;
                5:expected=(int'(b)>=W)?0:((int'(a)<<b)&mask);
                6:expected=(signed_a>>>b)&mask;7:expected=(signed_a<signed_b);
            endcase
            if(demux_d!==expected || z!==(expected==0) || neg!==demux_d[W-1]) $fatal(1,"ALU");
            if(op==0 || op==1) begin
                full=(op==0)?signed_a+signed_b:signed_a-signed_b;
                if(av!==((full<-(1<<(W-1)))||(full>((1<<(W-1))-1)))) $fatal(1,"ALU overflow");
                if(ac!==((op==0)?(int'(a)+int'(b)>mask):(a>=b))) $fatal(1,"ALU carry");
            end else if(ac || av) $fatal(1,"ALU inactive flags");
            if(m2!==(cin?b:a)) $fatal(1,"mux2");
            if(mux_y!==((sel<N)?lanes[sel*W+:W]:{W{1'b0}})) $fatal(1,"mux");
            for(k=0;k<N;k++) if(demux_y[k*W+:W]!==((k==sel)?a:{W{1'b0}})) $fatal(1,"demux");
        end
        $display("PASS combinational W=%0d N=%0d cases=%0d",W,N,t);done=1;
    end
endmodule

module tb_combinational;
    wire d1,d2,d3,d4;
    comb_check #(1,1) c1(d1);comb_check #(4,3) c2(d2);
    comb_check #(8,5) c3(d3);comb_check #(16,8) c4(d4);
    logic [7:0] x;wire [2:0] idx,pidx;wire ev,pv;wire [7:0] decoded;
    logic [2:0] address;logic enable;
    encoder #(8) en(x,ev,idx);priority_encoder #(8) pe(x,pv,pidx);
    decoder #(3) de(address,enable,decoded);
    logic fa,fb,fc;wire fs,fo;full_adder full(fa,fb,fc,fs,fo);
    integer i,j,count,highest;
    initial begin
        for(i=0;i<256;i++) begin
            x=i;address=i%8;enable=(i/8)%2;{fa,fb,fc}=i%8;#1;
            count=0;highest=0;
            for(j=0;j<8;j++) if(x[j])begin count++;highest=j;end
            if(pv!==(i!=0)||pidx!==highest) $fatal(1,"priority encoder");
            if(ev!==(count==1)||idx!==((count==1)?highest:0)) $fatal(1,"encoder");
            if(decoded!==(enable?(1<<address):0)) $fatal(1,"decoder");
            if({fo,fs}!==int'(fa)+int'(fb)+int'(fc)) $fatal(1,"full adder");
        end
        wait(d1&&d2&&d3&&d4);$display("PASS tb_combinational");$finish;
    end
    initial begin #1000000;$fatal(1,"timeout");end
endmodule
