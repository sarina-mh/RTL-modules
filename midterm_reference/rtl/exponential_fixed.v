// exp(x) for [-4,4]: evaluate exp(x/4), then square twice.
// W<=32, Q<=20, W>=Q+4; four internal guard bits; saturating signed output.
module exponential_fixed #(parameter W=32,Q=20,TERMS=12)(
    input clk,rst_n,start,input signed [W-1:0] x,output reg signed [W-1:0] result,
    output reg busy,done,out_of_range,overflow
);
    localparam signed [127:0] MAXIMUM=((128'sd1<<(W-1))-1)<<4;
    reg signed [31:0] reduced;reg child_start;wire child_busy,child_done,child_range,child_overflow;
    wire signed [31:0] base;
    reg signed [63:0] value;reg signed [127:0] product;
    reg [1:0] state;integer squares;
    exp_taylor #(32,Q+4,TERMS) core(clk,rst_n,child_start,reduced,base,child_busy,child_done,child_range,child_overflow);
    always @*product=(value*value)>>>(Q+4);
    always @(posedge clk)begin
        if(!rst_n)begin result<=0;busy<=0;done<=0;out_of_range<=0;overflow<=0;reduced<=0;child_start<=0;value<=0;state<=0;squares<=0;end
        else begin
            done<=0;child_start<=0;
            if(start&&!busy)begin
                reduced<=$signed(x)<<<2;child_start<=1;busy<=1;state<=0;overflow<=0;
                out_of_range<=($signed(x)>(64'sd4<<Q))||($signed(x)<-(64'sd4<<Q));
            end else if(busy)case(state)
                0:if(child_done)begin value<=base;squares<=0;state<=1;end
                1:begin
                    if(product>MAXIMUM)begin value<=MAXIMUM;overflow<=1;end else value<=product;
                    squares<=squares+1;if(squares==1)state<=2;
                end
                2:begin result<=value>>>4;busy<=0;done<=1;end
                default:state<=0;
            endcase
        end
    end
endmodule
