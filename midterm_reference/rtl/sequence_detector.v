// Module: sequence_detector. Original group: fsm.
// Pattern arrives MSB first. A hit consumes the final bit on the next clock edge.
// hit_mealy depends on bit_in/valid; hit_moore is the registered hit pulse.
// OVERLAP=0 discards all history following a match. P >= 1.
module sequence_detector #(parameter P=4,parameter [P-1:0] PATTERN=4'b1011,parameter OVERLAP=1)(
    input clk,rst_n,valid,bit_in,output hit_mealy,output reg hit_moore
);
    reg [P-1:0] history;integer count;
    wire [P-1:0] candidate=(history<<1)|bit_in;
    assign hit_mealy=valid && (count>=P-1) && (candidate==PATTERN);
    always @(posedge clk)
        if(!rst_n) begin history<=0;count<=0;hit_moore<=0;end
        else begin
            hit_moore<=hit_mealy;
            if(valid) begin
                if(hit_mealy&&!OVERLAP) begin history<=0;count<=0;end
                else begin history<=candidate;if(count<P) count<=count+1;end
            end
        end
endmodule
