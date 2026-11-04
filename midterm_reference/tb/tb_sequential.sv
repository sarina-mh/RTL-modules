`timescale 1ns/1ps
module seq_check #(parameter W=8,D=3,L=3)(output bit finished=0);
    localparam A=(D>1?$clog2(D):1),C=$clog2(D+1),MASK=(1<<W)-1;
    logic clk=0;always #5 clk=~clk;
    logic rst_n=0,en,load,clear,down,right,serial_in,valid,push,pop,we;
    logic [W-1:0] d,load_value,b;
    wire [W-1:0] qff,qr,qs,count,sat,acc,pdata,fdata,ramout,rfa,rfb,romdata;
    wire serial_out,pvalid,full,empty,terminal;
    wire [C-1:0] fcount;
    wire [A-1:0] mod_count;
    wire [2*W+3:0] macsum,smacsum;
    logic [A-1:0] addr,ra,rb;
    dff #(W) u0(clk,rst_n,d,qff);
    register_en #(W) u1(clk,rst_n,en,load,d,load_value,qr);
    shift_register #(W) u2(clk,rst_n,en,right,serial_in,load,d,qs,serial_out);
    counter #(W) u3(clk,rst_n,clear,en,down,load,load_value,count);
    modulo_counter #(D) u4(clk,rst_n,en,mod_count,terminal);
    saturating_counter #(W) u5(clk,rst_n,en,down,sat);
    accumulator #(W) u6(clk,rst_n,clear,en,d,acc);
    mac #(W,2*W+4,0) u7(clk,rst_n,clear,en,d,b,macsum);
    mac #(W,2*W+4,1) u8(clk,rst_n,clear,en,d,b,smacsum);
    pipeline_delay #(W,L) u9(clk,rst_n,en,valid,d,pdata,pvalid);
    sync_fifo #(W,D) u10(clk,rst_n,push,pop,d,fdata,full,empty,fcount);
    single_port_ram #(W,D) u11(clk,en,we,addr,d,ramout);
    register_file #(W,D) u12(clk,we,addr,ra,rb,d,rfa,rfb);
    rom #(W,D,A,{(D*W){1'b1}}) u13(addr,romdata);
    int ff=0,regval=0,shiftval=0,ctr=0,modval=0,satval=0,accval=0;
    longint unsigned macval=0,smacval=0,macmask;
    int pipe_data[L];bit pipe_valid[L];
    int fifo[$];int ram[D],rf[D];bit ram_init[D],rf_init[D];
    int expected_ram=0;bit check_ram=0;
    int t,k,removed,sd,sb;
    initial begin
        macmask=(64'd1<<(2*W+4))-1;
        for(k=0;k<L;k++)begin pipe_data[k]=0;pipe_valid[k]=0;end
        for(k=0;k<D;k++)begin ram_init[k]=0;rf_init[k]=0;end
        for(t=0;t<1800;t++) begin
            @(negedge clk);
            rst_n=(t!=0 && t!=901);en=$urandom_range(0,1);load=($urandom_range(0,7)==0);
            clear=($urandom_range(0,13)==0);down=$urandom_range(0,1);right=$urandom_range(0,1);
            serial_in=$urandom_range(0,1);valid=$urandom_range(0,1);push=$urandom_range(0,1);pop=$urandom_range(0,1);
            we=$urandom_range(0,1);d=$urandom;b=$urandom;load_value=$urandom;
            addr=$urandom;ra=$urandom;rb=$urandom;
            // Force FIFO full/empty, counter saturation and wrap boundaries.
            if(t<40)begin en=1;load=0;clear=0;down=0;push=1;pop=0;end
            if(t>=40&&t<80)begin down=1;push=0;pop=1;end
            #1;
            if(romdata!==((addr<D)?MASK:0))$fatal(1,"ROM");
            if(!rst_n)begin
                ff=0;regval=0;shiftval=0;ctr=0;modval=0;satval=0;accval=0;macval=0;smacval=0;
                fifo.delete();for(k=0;k<L;k++)begin pipe_data[k]=0;pipe_valid[k]=0;end
            end else begin
                ff=d;
                if(load)regval=load_value;else if(en)regval=d;
                if(load)shiftval=d;else if(en)shiftval=right?((shiftval>>1)|(int'(serial_in)<<(W-1))):((shiftval<<1)|serial_in);
                shiftval&=MASK;
                if(clear)ctr=0;else if(load)ctr=load_value;else if(en)ctr=(ctr+(down?-1:1))&MASK;
                if(en)begin
                    modval=(modval+1)%D;
                    if(down&&satval>0)satval--;else if(!down&&satval<MASK)satval++;
                end
                if(clear)begin accval=0;macval=0;smacval=0;end
                else if(en)begin
                    accval=(accval+int'(d))&MASK;macval=(macval+int'(d)*int'(b))&macmask;
                    sd=d[W-1]?int'(d)-(1<<W):int'(d);sb=b[W-1]?int'(b)-(1<<W):int'(b);
                    smacval=(smacval+sd*sb)&macmask;
                end
                if(en)begin
                    for(k=L-1;k>0;k--)begin pipe_data[k]=pipe_data[k-1];pipe_valid[k]=pipe_valid[k-1];end
                    pipe_data[0]=d;pipe_valid[0]=valid;
                end
                if(pop&&fifo.size()>0)removed=fifo.pop_front();
                if(push&&fifo.size()<D)fifo.push_back(d);
            end
            // Memories have no reset and retain data across system reset.
            if(en)begin
                if(addr<D)begin
                    expected_ram=ram[addr];check_ram=ram_init[addr];
                    if(we)begin ram[addr]=d;ram_init[addr]=1;end
                end else begin expected_ram=0;check_ram=1;end
            end
            if(we&&addr<D)begin rf[addr]=d;rf_init[addr]=1;end
            @(posedge clk);#1;
            if(qff!==ff || qr!==regval || qs!==shiftval || count!==ctr || mod_count!==modval || sat!==satval || acc!==accval)$fatal(1,"register/counter W=%0d t=%0d",W,t);
            if(serial_out!==(right?qs[0]:qs[W-1]))$fatal(1,"serial out");
            if(terminal!==(modval==D-1))$fatal(1,"mod terminal");
            if(macsum!==macval || smacsum!==smacval)$fatal(1,"MAC W=%0d t=%0d got %h expected %h",W,t,smacsum,smacval);
            if(pdata!==pipe_data[L-1] || pvalid!==pipe_valid[L-1])$fatal(1,"pipeline");
            if(fcount!==fifo.size() || full!==(fifo.size()==D) || empty!==(fifo.size()==0))$fatal(1,"FIFO flags");
            if(fdata!==((fifo.size()==0)?0:fifo[0]))$fatal(1,"FIFO data");
            if(check_ram&&ramout!==expected_ram)$fatal(1,"RAM read-first");
            if(ra>=D)begin if(rfa!==0)$fatal(1,"RF invalid a");end
            else if(rf_init[ra]&&rfa!==rf[ra])$fatal(1,"RF a");
            if(rb>=D)begin if(rfb!==0)$fatal(1,"RF invalid b");end
            else if(rf_init[rb]&&rfb!==rf[rb])$fatal(1,"RF b");
        end
        $display("PASS sequential/memory/FIFO W=%0d depth=%0d latency=%0d cycles=1800",W,D,L);finished=1;
    end
endmodule

module pattern_check #(parameter P=4,parameter [P-1:0] PAT=4'b1011,parameter OVERLAP=1)(output bit finished=0);
    logic clk=0;always #5 clk=~clk;
    logic rst_n=0,valid=0,bit_in=0;wire mealy,moore;
    sequence_detector #(P,PAT,OVERLAP) dut(clk,rst_n,valid,bit_in,mealy,moore);
    bit history[$],expected;int t,k,discard;
    initial begin
        @(posedge clk);#1;
        for(t=0;t<2000;t++)begin
            @(negedge clk);rst_n=(t!=999);valid=$urandom_range(0,1);bit_in=$urandom_range(0,1);
            expected=0;
            if(rst_n&&valid)begin
                history.push_back(bit_in);
                if(history.size()>P)discard=history.pop_front();
                if(history.size()==P)begin
                    expected=1;for(k=0;k<P;k++)if(history[k]!=PAT[P-1-k])expected=0;
                end
            end
            #1;
            // A synchronous reset does not gate combinational Mealy output.
            if(rst_n&&mealy!==expected)$fatal(1,"Mealy P=%0d overlap=%0d t=%0d valid=%b input=%b expected=%b got=%b reference=%p",P,OVERLAP,t,valid,bit_in,expected,mealy,history);
            if(!rst_n)begin history.delete();expected=0;end
            else if(expected&&!OVERLAP)history.delete();
            @(posedge clk);#1;if(moore!==expected)$fatal(1,"Moore");
        end
        $display("PASS sequence P=%0d overlap=%0d cycles=2000",P,OVERLAP);finished=1;
    end
endmodule

module tb_sequential;
    wire a,b,c,d,e,f;
    seq_check #(1,1,1) s0(a);seq_check #(8,3,3) s1(b);seq_check #(8,8,2) s2(c);
    pattern_check #(4,4'b1011,1) p0(d);pattern_check #(4,4'b1011,0) p1(e);pattern_check #(1,1'b1,1) p2(f);
    initial begin wait(a&&b&&c&&d&&e&&f);$display("PASS tb_sequential");$finish;end
    initial begin #100000;$fatal(1,"timeout");end
endmodule
