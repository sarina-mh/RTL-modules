// Module: pipeline_delay. Original group: sequential.
// LATENCY >= 1; clock enable stalls both data and validity together.
module pipeline_delay #(parameter W=8, LATENCY=3)(input clk,rst_n,en,in_valid,
    input [W-1:0] data_in, output [W-1:0] data_out, output out_valid);
    reg [W-1:0] data[0:LATENCY-1]; reg [LATENCY-1:0] valid;
    integer i;
    assign data_out=data[LATENCY-1]; assign out_valid=valid[LATENCY-1];
    always @(posedge clk)
        if(!rst_n) begin valid<=0; for(i=0;i<LATENCY;i=i+1) data[i]<=0; end
        else if(en) begin
            data[0]<=data_in; valid[0]<=in_valid;
            for(i=1;i<LATENCY;i=i+1) begin data[i]<=data[i-1]; valid[i]<=valid[i-1]; end
        end
endmodule
