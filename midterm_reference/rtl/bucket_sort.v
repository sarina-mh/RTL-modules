// Integer bucket sort: high key bits select a bucket; each bucket is insertion
// sorted, then concatenated. 1 <= BITS <= W; storage is N * 2**BITS words.
module bucket_sort #(parameter W=8,N=8,SIGNED=0,BITS=(W>1?2:1))(
    input clk,rst_n,start,input [N*W-1:0] data_in,
    output reg [N*W-1:0] data_out,output reg busy,done
);
    localparam B=(1<<BITS);
    reg [W-1:0] buckets[0:B*N-1],key;
    integer counts[0:B-1];reg [N*W-1:0] data;
    integer bucket,p,i,j,out_index,k;reg [2:0] state;
    wire [W-1:0] biased=data[p*W+:W]^(SIGNED?(1<<(W-1)):0);
    wire [BITS-1:0] destination=biased[W-1-:BITS];
    wire greater=SIGNED?($signed(buckets[bucket*N+((j>=0)?j:0)])>$signed(key)):
                              (buckets[bucket*N+((j>=0)?j:0)]>key);
    always @(posedge clk)begin
        if(!rst_n)begin busy<=0;done<=0;data_out<=0;data<=0;key<=0;bucket<=0;p<=0;i<=0;j<=0;out_index<=0;state<=0;
            for(k=0;k<B;k=k+1)counts[k]<=0;
            for(k=0;k<B*N;k=k+1)buckets[k]<=0;
        end else begin
            done<=0;
            if(start&&!busy)begin
                data<=data_in;p<=0;bucket<=0;out_index<=0;state<=0;busy<=1;
                for(k=0;k<B;k=k+1)counts[k]<=0;
            end else if(busy)case(state)
                0:begin
                    buckets[destination*N+counts[destination]]<=data[p*W+:W];
                    counts[destination]<=counts[destination]+1;
                    if(p==N-1)begin i<=1;state<=1;end else p<=p+1;
                end
                1:if(i>=counts[bucket])begin p<=0;state<=4;end
                  else begin key<=buckets[bucket*N+i];j<=i-1;state<=2;end
                2:if(j>=0 && greater)begin buckets[bucket*N+j+1]<=buckets[bucket*N+j];j<=j-1;end
                  else begin buckets[bucket*N+j+1]<=key;i<=i+1;state<=1;end
                4:if(p<counts[bucket])begin
                    data_out[out_index*W+:W]<=buckets[bucket*N+p];out_index<=out_index+1;p<=p+1;
                end else if(bucket==B-1)state<=5;
                  else begin bucket<=bucket+1;i<=1;state<=1;end
                5:begin busy<=0;done<=1;end
                default:state<=0;
            endcase
        end
    end
endmodule
