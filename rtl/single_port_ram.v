// Module: single_port_ram. Original group: memory.
// Synchronous read, read-first on a same-address write. Storage is NOT reset.
module single_port_ram #(parameter W=8, DEPTH=16, A=(DEPTH>1?$clog2(DEPTH):1)) (
    input clk,en,we, input [A-1:0] address, input [W-1:0] data_in, output reg [W-1:0] data_out
);
    reg [W-1:0] mem[0:DEPTH-1];
    always @(posedge clk) if(en) begin
        if(address<DEPTH) begin data_out<=mem[address]; if(we) mem[address]<=data_in; end
        else data_out<=0;
    end
endmodule
