`timescale 1ns/1ps
module fp_check #(parameter E=5,F=10,W=1+E+F)(output bit finished=0);
    localparam MAX=80000;
    logic clk=0;always #5 clk=~clk;
    logic rst_n=0,in_valid=0,out_ready=0;
    logic [W-1:0] a=0,b=0;
    wire [3:0] in_ready,out_valid;wire [W-1:0] result[4];
    wire lt,eq,gt,unordered,sign,zz,subnormal,normal,inf,nan;
    wire [W-1:0] selected;logic select_b=0;
    wire [W-1:0] comb[4];
    genvar op;
    generate
        if(E==5&&F==10) begin : half
            fp16_adder u0(clk,rst_n,in_valid,in_ready[0],a,b,out_valid[0],out_ready,result[0]);
            fp16_subtractor u1(clk,rst_n,in_valid,in_ready[1],a,b,out_valid[1],out_ready,result[1]);
            fp16_multiplier u2(clk,rst_n,in_valid,in_ready[2],a,b,out_valid[2],out_ready,result[2]);
            fp16_divider u3(clk,rst_n,in_valid,in_ready[3],a,b,out_valid[3],out_ready,result[3]);
        end else begin : generic_stream
            for(op=0;op<4;op++)begin : arithmetic
                fp_stream #(E,F,op) dut(clk,rst_n,in_valid,in_ready[op],a,b,out_valid[op],out_ready,result[op]);
            end
        end
        for(op=0;op<4;op++)begin : combinational
            fp_arithmetic #(E,F,op) dut(a,b,comb[op]);
        end
    endgenerate
    fp_compare #(E,F) cmp(a,b,lt,eq,gt,unordered);
    fp_classify #(E,F) classify(a,sign,zz,subnormal,normal,inf,nan);
    mux2 #(W) mx(a,b,select_b,selected);
    logic [W-1:0] va[MAX],vb[MAX],expected[MAX][4];
    logic [3:0] compare[MAX];logic [4:0] classes[MAX];
    integer fd,scan,count=0,sent=0,consumed=0,cycle=0,k,stalls=0,consecutive=0;
    bit take_in,take_out,previous=0;
    string filename;
    initial begin
        filename=$sformatf("build/vectors/fp_%0d_%0d.txt",E,F);
        fd=$fopen(filename,"r");if(!fd)$fatal(1,"missing %s",filename);
        while(!$feof(fd))begin
            if(count==MAX)$fatal(1,"increase MAX");
            scan=$fscanf(fd,"%h %h %h %h %h %h %h %h\n",va[count],vb[count],expected[count][0],expected[count][1],expected[count][2],expected[count][3],compare[count],classes[count]);
            if(scan==8)count++;else if(!$feof(fd))$fatal(1,"bad vector");
        end
        $fclose(fd);if(count==0)$fatal(1,"no vectors");
        repeat(2)@(negedge clk);rst_n=1;
        while(consumed<count)begin
            @(negedge clk);cycle++;
            in_valid=(sent<count)&&(cycle%19!=0);out_ready=(cycle%13>=4);select_b=cycle%2;
            if(sent<count)begin a=va[sent];b=vb[sent];end
            #1;
            if(in_ready!=={4{!out_valid[0]||out_ready}})$fatal(1,"ready mismatch");
            if(out_valid!=={4{consumed<sent}})$fatal(1,"valid mismatch");
            if(consumed<sent)for(k=0;k<4;k++)if(result[k]!==expected[consumed][k])$fatal(1,"FP E=%0d F=%0d op=%0d vector=%0d a=%h b=%h got=%h expected=%h",E,F,k,consumed,va[consumed],vb[consumed],result[k],expected[consumed][k]);
            if(sent<count)begin
                for(k=0;k<4;k++)if(comb[k]!==expected[sent][k])$fatal(1,"FP combinational E=%0d F=%0d op=%0d vector=%0d a=%h b=%h got=%h expected=%h",E,F,k,sent,a,b,comb[k],expected[sent][k]);
                if({lt,eq,gt,unordered}!==compare[sent])$fatal(1,"FP compare");
                if({zz,subnormal,normal,inf,nan}!==classes[sent]||sign!==a[W-1])$fatal(1,"FP classify");
                if(selected!==(select_b?b:a))$fatal(1,"FP mux");
            end
            take_in=in_valid&&in_ready[0];take_out=out_valid[0]&&out_ready;
            if(out_valid[0]&&!out_ready)stalls++;
            @(posedge clk);
            if(take_out)consumed++;
            if(take_in)begin sent++;if(previous)consecutive++;end previous=take_in;
            #1;
            if(out_valid!=={4{consumed<sent}})$fatal(1,"registered latency");
            if(consumed<sent)for(k=0;k<4;k++)if(result[k]!==expected[consumed][k])$fatal(1,"registered result");
            if(cycle>count*5)$fatal(1,"FP timeout");
        end
        // Reset a held result while the consumer applies backpressure.
        @(negedge clk);out_ready=0;in_valid=1;a=va[0];b=vb[0];
        @(posedge clk);#1;if(out_valid!==4'b1111)$fatal(1,"reset setup");
        @(negedge clk);rst_n=0;
        @(posedge clk);#1;if(out_valid!==0)$fatal(1,"reset flush");
        if(!stalls||!consecutive)$fatal(1,"stream coverage");
        $display("PASS floating_point E=%0d F=%0d vectors=%0d operations=4 stalls=%0d",E,F,count,stalls);finished=1;
    end
endmodule

module tb_floating_point;
    wire a,b,c;
    fp_check #(3,2) small_format(a);fp_check #(5,10) binary16(b);fp_check #(8,23) binary32(c);
    initial begin wait(a&&b&&c);$display("PASS tb_floating_point");$finish;end
    initial begin #10000000;$fatal(1,"timeout");end
endmodule
