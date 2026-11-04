// Module: register_file. Original group: memory.
// Two asynchronous read ports, one synchronous write port. Storage is NOT reset.
module register_file #(parameter W=8, DEPTH=16, A=(DEPTH>1?$clog2(DEPTH):1)) (
    input clk,we, input [A-1:0] write_address,read_address_a,read_address_b,
    input [W-1:0] write_data, output [W-1:0] read_data_a,read_data_b
);
    reg [W-1:0] mem[0:DEPTH-1];
    always @(posedge clk) if(we && write_address<DEPTH) mem[write_address]<=write_data;
    assign read_data_a=(read_address_a<DEPTH)?mem[read_address_a]:{W{1'b0}};
    assign read_data_b=(read_address_b<DEPTH)?mem[read_address_b]:{W{1'b0}};
endmodule
