// Module: rom. Original group: memory.
// Constant packed ROM: word i is CONTENT[i*W +: W].
module rom #(parameter W=8, DEPTH=4, A=(DEPTH>1?$clog2(DEPTH):1),
    parameter [W*DEPTH-1:0] CONTENT=0)(input [A-1:0] address, output [W-1:0] data);
    assign data=(address<DEPTH)?CONTENT[address*W +: W]:{W{1'b0}};
endmodule
