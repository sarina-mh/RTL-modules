// Module: parity. Original group: combinational.
module parity #(parameter W=8)(input [W-1:0] x, output odd);
    assign odd=^x;
endmodule
