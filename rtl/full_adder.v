// Module: full_adder. Original group: combinational.
module full_adder(input a,b,cin, output sum,cout);
    assign sum=a^b^cin;
    assign cout=(a&b)|(a&cin)|(b&cin);
endmodule
