// Complete selection sort: controller, datapath and top in this single file.
// Verilog-2005. Ascending order; W>=1, N>=1; SIGNED=1 uses two's complement.
// Element i occupies data_in[i*W +: W]. Pulse start while busy=0.
// Inputs are latched at acceptance. done pulses after the result is registered.
// Reset is active-low and synchronous. One comparison per SCAN cycle.

// ---------------- CONTROLLER: only state and control decisions ----------------
module selection_sort_controller #(parameter N=8)(
    input clk,rst_n,start,last_scan,last_pass,
    output reg load,scan,swap,next_pass,capture,
    output busy,done
);
    localparam IDLE=2'd0,SCAN=2'd1,SWAP=2'd2,REPORT=2'd3;
    reg [1:0] state,next_state;
    assign busy=(state==SCAN)||(state==SWAP);
    assign done=(state==REPORT);

    always @(posedge clk)
        if(!rst_n)state<=IDLE;else state<=next_state;

    always @*begin
        next_state=state;
        load=0;scan=0;swap=0;next_pass=0;capture=0;
        case(state)
            IDLE,REPORT:begin
                next_state=IDLE;
                if(start)begin load=1;next_state=(N==1)?SWAP:SCAN;end
            end
            SCAN:begin
                scan=1;
                if(last_scan)next_state=SWAP;
            end
            SWAP:begin
                swap=1;
                if(last_pass)begin capture=1;next_state=REPORT;end
                else begin next_pass=1;next_state=SCAN;end
            end
            default:next_state=IDLE;
        endcase
    end
endmodule

// ---------------- DATAPATH: storage, comparison, indices and swap ----------------
module selection_sort_datapath #(parameter W=8,N=8,SIGNED=0)(
    input clk,rst_n,load,scan,swap,next_pass,capture,
    input [N*W-1:0] data_in,
    output reg [N*W-1:0] data_out,
    output last_scan,last_pass
);
    reg [W-1:0] mem[0:N-1];
    integer i,j,minimum,k;
    wire less=SIGNED?($signed(mem[j])<$signed(mem[minimum])):(mem[j]<mem[minimum]);
    assign last_scan=(j==N-1);
    assign last_pass=(N==1)||(i==N-2);

    always @(posedge clk)begin
        if(!rst_n)begin
            i<=0;j<=0;minimum<=0;data_out<=0;
            for(k=0;k<N;k=k+1)mem[k]<=0;
        end else if(load)begin
            for(k=0;k<N;k=k+1)mem[k]<=data_in[k*W+:W];
            i<=0;j<=(N==1)?0:1;minimum<=0;
        end else begin
            if(scan)begin
                if(less)minimum<=j;
                if(!last_scan)j<=j+1;
            end
            if(swap)begin
                // Both RHS values are the old values: no temporary register.
                mem[i]<=mem[minimum];mem[minimum]<=mem[i];
            end
            if(next_pass)begin i<=i+1;j<=i+2;minimum<=i+1;end
            if(capture)begin
                // Capture the final swap on this same edge, including N=1.
                for(k=0;k<N;k=k+1)begin
                    if(k==i)data_out[k*W+:W]<=mem[minimum];
                    else if(k==minimum)data_out[k*W+:W]<=mem[i];
                    else data_out[k*W+:W]<=mem[k];
                end
            end
        end
    end
endmodule

// ---------------- TOP: instantiate and connect the two blocks ----------------
module selection_sort #(parameter W=8,N=8,SIGNED=0)(
    input clk,rst_n,start,input [N*W-1:0] data_in,
    output [N*W-1:0] data_out,output busy,done
);
    wire load,scan,swap,next_pass,capture,last_scan,last_pass;
    selection_sort_controller #(.N(N)) controller(
        .clk(clk),.rst_n(rst_n),.start(start),.last_scan(last_scan),.last_pass(last_pass),
        .load(load),.scan(scan),.swap(swap),.next_pass(next_pass),.capture(capture),
        .busy(busy),.done(done)
    );
    selection_sort_datapath #(.W(W),.N(N),.SIGNED(SIGNED)) datapath(
        .clk(clk),.rst_n(rst_n),.load(load),.scan(scan),.swap(swap),
        .next_pass(next_pass),.capture(capture),.data_in(data_in),.data_out(data_out),
        .last_scan(last_scan),.last_pass(last_pass)
    );
endmodule
