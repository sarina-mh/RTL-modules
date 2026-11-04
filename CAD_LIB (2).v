//=====================================================================
//  CAD_LIB.v  --  Parametric Verilog-2001 library (plain Verilog, no SystemVerilog)
//  Conventions:
//    clk  : rising edge          rst : ACTIVE-HIGH, SYNCHRONOUS reset
//    W    : data width           en  : enable
//    For async reset change:  always @(posedge clk or posedge rst)
//    For active-low reset  :  if (!rst_n) ...
//
//  TABLE OF CONTENTS
//   0  Syntax cheat-sheet (comments)
//   1  Mux / Demux / Decoder / Encoder
//   2  Adders          (2-input, 3-input, add/sub, ripple structural)
//   3  Subtractors     (2-input, 3-input, abs-diff, negate)
//   4  Multipliers     (2-input, 3-input, unsigned/signed)
//   5  Dividers        (2-input comb, 3-input comb, sequential restoring)
//   6  Comparators     (gt, lt, eq: 2-input & 3-input, signed/unsigned) + max/min
//   7  Registers       (en, load/clear, async, shift register, edge detect, sync)
//   8  Counters        (up, up/down, modulo, ring, johnson, gray)
//   9  Register file / RAM / ROM / FIFO / ping-pong buffer
//  10  Misc            (ALU, shifter, sign-ext, parity, LFSR, clock divider)
//  11  FSM templates   (Moore 3-process, Mealy example)
//  12  Datapath + Controller + Top EXAMPLE (sequential shift-add multiplier)
//  13  Testbench template (comments)
//  14  FILE I/O (open/close/read/write/readmem/writemem) - templates (comments)
//  (ready-to-run testbenches for these modules are in CAD_TB.v)
//=====================================================================


`timescale 1ns/1ps   // same unit as CAD_TB.v (avoids mixed-timescale warnings)

//=====================================================================
// 0. SYNTAX CHEAT-SHEET
//=====================================================================
// --- Module & ports (ANSI style) ---
//   module name #(parameter W=8, parameter N=4) (
//       input              clk,
//       input  [W-1:0]     a,
//       output reg [W-1:0] y,        // reg if assigned inside always
//       output [W-1:0]     z );      // wire if assigned with assign
//   endmodule
//
// --- Types / literals ---
//   wire [7:0] w;  reg [7:0] r;  integer i;  reg [7:0] mem [0:15];  // memory
//   8'hFF  8'b1010_0101  8'd255  {W{1'b0}} (zeros)  {W{1'b1}} (ones)
//   {a,b} concat   {4{a}} replicate   a[7:4] part-select   a[i +: 4] indexed
//   reg signed [7:0] s;   $signed(x)   $unsigned(x)   >>> arithmetic shift
//
// --- Operators ---
//   + - * / %   & | ^ ~ ~^   && || !   == != < > <= >=   << >>   ? :
//   Reduction: &a  |a  ^a  ~&a  ~|a      (e.g.  (|a) == (a != 0))
//
// --- Procedural ---
//   Combinational: always @(*) begin ... y = ...;  end      (blocking  =)
//   Sequential   : always @(posedge clk) q <= d;            (non-block <=)
//   Rule: give EVERY output a default value in comb always (avoid latches)
//   case (sel) 2'd0: y = a;  2'd1: y = b;  default: y = 0; endcase
//   if / else if / else      for (i=0; i<N; i=i+1) ...     while / repeat
//
// --- Parameters ---
//   parameter  : can be overridden at instantiation
//   localparam : constant inside the module (use for FSM states)
//   Instantiate: mux2 #(.W(16)) u1 (.d0(a), .d1(b), .sel(s), .y(o));
//
// --- generate ---
//   genvar g;
//   generate for (g=0; g<N; g=g+1) begin : blk
//       full_adder fa (.a(a[g]), .b(b[g]), .cin(c[g]), .sum(s[g]), .cout(c[g+1]));
//   end endgenerate
//   generate if (COND) begin ... end else begin ... end endgenerate
//
// --- function / task ---
//   function [W-1:0] f; input [W-1:0] x; begin f = x + 1; end endfunction
//   (ceil log2 helper)
//   function integer clog2; input integer v; integer k;
//     begin v = v-1; for (k=0; v>0; k=k+1) v = v >> 1; clog2 = k; end endfunction
//
// --- Memory init ---
//   initial $readmemh("file.mem", mem);   // hex     ($readmemb for binary)
//
// --- Simulation-only system tasks ---
//   $display("a=%d b=%h", a, b);  $monitor(...);  $time;  $finish;  $stop;
//   $random;  $urandom_range (SV only)  $dumpfile/$dumpvars (VCD)
//   File I/O: $fopen $fclose $fdisplay $fwrite $fscanf $fgets $feof $readmemh ... -> see section 14
//
// --- Common pitfalls ---
//   * width mismatch: a+b assigned to W-bit loses carry, use {cout,sum}
//   * mixing signed/unsigned makes the WHOLE expression unsigned
//   * non-blocking (<=) in clocked blocks, blocking (=) in combinational blocks
//   * never drive the same reg from two always blocks
//   * missing default in case/if  ->  unintended latch


//=====================================================================
// 1. MUX / DEMUX / DECODER / ENCODER
//=====================================================================

// ---- 2-to-1 mux ----
module mux2 #(parameter W = 8)(
    input  [W-1:0] d0, d1,
    input          sel,
    output [W-1:0] y
);
    assign y = sel ? d1 : d0;
endmodule

// ---- 3-to-1 mux (sel 2 bits, sel==3 -> 0) ----
module mux3 #(parameter W = 8)(
    input  [W-1:0]     d0, d1, d2,
    input  [1:0]       sel,
    output reg [W-1:0] y
);
    always @(*) begin
        case (sel)
            2'd0:    y = d0;
            2'd1:    y = d1;
            2'd2:    y = d2;
            default: y = {W{1'b0}};
        endcase
    end
endmodule

// ---- 4-to-1 mux ----
module mux4 #(parameter W = 8)(
    input  [W-1:0]     d0, d1, d2, d3,
    input  [1:0]       sel,
    output reg [W-1:0] y
);
    always @(*) begin
        case (sel)
            2'd0: y = d0;
            2'd1: y = d1;
            2'd2: y = d2;
            default: y = d3;
        endcase
    end
endmodule

// ---- 8-to-1 mux ----
module mux8 #(parameter W = 8)(
    input  [W-1:0]     d0, d1, d2, d3, d4, d5, d6, d7,
    input  [2:0]       sel,
    output reg [W-1:0] y
);
    always @(*) begin
        case (sel)
            3'd0: y = d0;  3'd1: y = d1;  3'd2: y = d2;  3'd3: y = d3;
            3'd4: y = d4;  3'd5: y = d5;  3'd6: y = d6;
            default: y = d7;
        endcase
    end
endmodule

// ---- N-to-1 generic mux ----
// d is a flat bus: d = {d[N-1], ..., d[1], d[0]}      SW = ceil(log2(N))
// Example: mux_n #(.W(8), .N(5), .SW(3)) u (.d({e,d,c,b,a}), .sel(s), .y(y));
module mux_n #(parameter W = 8, parameter N = 4, parameter SW = 2)(
    input  [N*W-1:0] d,
    input  [SW-1:0]  sel,
    output [W-1:0]   y
);
    assign y = d[sel*W +: W];
endmodule

// ---- 1-to-2 demux ----
module demux2 #(parameter W = 8)(
    input  [W-1:0] d,
    input          sel,
    output [W-1:0] y0, y1
);
    assign y0 = (sel == 1'b0) ? d : {W{1'b0}};
    assign y1 = (sel == 1'b1) ? d : {W{1'b0}};
endmodule

// ---- AW-to-2^AW decoder with enable (one-hot output) ----
module decoder #(parameter AW = 3)(
    input  [AW-1:0]        sel,
    input                  en,
    output [(1<<AW)-1:0]   y
);
    assign y = en ? ({{((1<<AW)-1){1'b0}}, 1'b1} << sel) : {(1<<AW){1'b0}};
endmodule

// ---- Priority encoder (HIGHEST index wins). idx valid only if valid=1 ----
module priority_enc #(parameter N = 8, parameter AW = 3)(
    input  [N-1:0]     in,
    output reg [AW-1:0] idx,
    output reg         valid
);
    integer i;
    always @(*) begin
        idx   = {AW{1'b0}};
        valid = 1'b0;
        for (i = 0; i < N; i = i + 1)
            if (in[i]) begin idx = i; valid = 1'b1; end
    end
endmodule


//=====================================================================
// 2. ADDERS
//=====================================================================

module half_adder (input a, b, output sum, cout);
    assign sum  = a ^ b;
    assign cout = a & b;
endmodule

module full_adder (input a, b, cin, output sum, cout);
    assign sum  = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule

// ---- 2-input adder with carry in / carry out ----
module adder2 #(parameter W = 8)(
    input  [W-1:0] a, b,
    input          cin,
    output [W-1:0] sum,
    output         cout
);
    assign {cout, sum} = a + b + cin;
endmodule

// ---- 3-input adder: a + b + c, cout is 2 bits (0..2) ----
module adder3 #(parameter W = 8)(
    input  [W-1:0] a, b, c,
    output [W-1:0] sum,
    output [1:0]   cout
);
    wire [W+1:0] t = {2'b00, a} + {2'b00, b} + {2'b00, c};
    assign sum  = t[W-1:0];
    assign cout = t[W+1:W];
endmodule

// ---- Adder/Subtractor: sub=0 -> a+b , sub=1 -> a-b
//      cout : carry (for sub: cout=1 means NO borrow)
//      ovf  : signed overflow
module add_sub #(parameter W = 8)(
    input  [W-1:0] a, b,
    input          sub,
    output [W-1:0] y,
    output         cout,
    output         ovf
);
    wire [W-1:0] bx = b ^ {W{sub}};
    assign {cout, y} = a + bx + sub;
    assign ovf = (a[W-1] == bx[W-1]) && (y[W-1] != a[W-1]);
endmodule

// ---- Structural ripple-carry adder (generate example) ----
module ripple_adder #(parameter W = 8)(
    input  [W-1:0] a, b,
    input          cin,
    output [W-1:0] sum,
    output         cout
);
    wire [W:0] c;
    assign c[0] = cin;
    genvar g;
    generate
        for (g = 0; g < W; g = g + 1) begin : fa_gen
            full_adder fa (.a(a[g]), .b(b[g]), .cin(c[g]), .sum(sum[g]), .cout(c[g+1]));
        end
    endgenerate
    assign cout = c[W];
endmodule

// ---- Signed saturating adder ----
module sat_add_signed #(parameter W = 8)(
    input  [W-1:0] a, b,
    output [W-1:0] y
);
    wire [W-1:0] s   = a + b;
    wire         ovf = (a[W-1] == b[W-1]) && (s[W-1] != a[W-1]);
    assign y = ovf ? (a[W-1] ? {1'b1, {(W-1){1'b0}}} : {1'b0, {(W-1){1'b1}}}) : s;
endmodule


//=====================================================================
// 3. SUBTRACTORS
//=====================================================================

// ---- 2-input: a - b - bin ; borrow=1 if result negative (unsigned view) ----
module sub2 #(parameter W = 8)(
    input  [W-1:0] a, b,
    input          bin,
    output [W-1:0] diff,
    output         borrow
);
    wire [W:0] t = {1'b0, a} - {1'b0, b} - bin;
    assign diff   = t[W-1:0];
    assign borrow = t[W];
endmodule

// ---- 3-input: a - b - c ; neg=1 if true result is negative ----
module sub3 #(parameter W = 8)(
    input  [W-1:0] a, b, c,
    output [W-1:0] diff,
    output         neg
);
    wire [W+1:0] t = {2'b00, a} - {2'b00, b} - {2'b00, c};
    assign diff = t[W-1:0];
    assign neg  = t[W+1];
endmodule

// ---- |a - b| (unsigned) ----
module abs_diff #(parameter W = 8)(
    input  [W-1:0] a, b,
    output [W-1:0] y
);
    assign y = (a >= b) ? (a - b) : (b - a);
endmodule

// ---- Two's complement negate ----
module negate #(parameter W = 8)(
    input  [W-1:0] a,
    output [W-1:0] y
);
    assign y = ~a + 1'b1;
endmodule

// ---- Absolute value (signed input) ----
module abs_signed #(parameter W = 8)(
    input  [W-1:0] a,
    output [W-1:0] y
);
    assign y = a[W-1] ? (~a + 1'b1) : a;
endmodule


//=====================================================================
// 4. MULTIPLIERS   (full-width products, no truncation)
//=====================================================================

// ---- 2-input unsigned ----
module mult2 #(parameter WA = 8, parameter WB = 8)(
    input  [WA-1:0]      a,
    input  [WB-1:0]      b,
    output [WA+WB-1:0]   p
);
    assign p = a * b;
endmodule

// ---- 3-input unsigned ----
module mult3 #(parameter WA = 8, parameter WB = 8, parameter WC = 8)(
    input  [WA-1:0]         a,
    input  [WB-1:0]         b,
    input  [WC-1:0]         c,
    output [WA+WB+WC-1:0]   p
);
    assign p = a * b * c;
endmodule

// ---- 2-input signed ----
module mult2_signed #(parameter WA = 8, parameter WB = 8)(
    input  signed [WA-1:0]      a,
    input  signed [WB-1:0]      b,
    output signed [WA+WB-1:0]   p
);
    assign p = a * b;
endmodule

// ---- 3-input signed ----
module mult3_signed #(parameter WA = 8, parameter WB = 8, parameter WC = 8)(
    input  signed [WA-1:0]         a,
    input  signed [WB-1:0]         b,
    input  signed [WC-1:0]         c,
    output signed [WA+WB+WC-1:0]   p
);
    assign p = a * b * c;
endmodule

// ---- Multiply by constant using shifts: y = a << K  (a * 2^K) ----
module mult_pow2 #(parameter W = 8, parameter K = 2)(
    input  [W-1:0]   a,
    output [W+K-1:0] y
);
    assign y = {{K{1'b0}}, a} << K;
endmodule
// (Sequential shift-add multiplier: see section 12)


//=====================================================================
// 5. DIVIDERS
//=====================================================================

// ---- 2-input combinational: q = a/b, r = a%b. div0=1 when b==0 ----
module div2 #(parameter W = 8)(
    input  [W-1:0] a, b,
    output [W-1:0] q, r,
    output         div0
);
    assign div0 = (b == {W{1'b0}});
    assign q = div0 ? {W{1'b1}} : (a / b);
    assign r = div0 ? a         : (a % b);
endmodule

// ---- 3-input combinational: q = (a / b) / c  ----
module div3 #(parameter W = 8)(
    input  [W-1:0] a, b, c,
    output [W-1:0] q,
    output         div0
);
    assign div0 = (b == {W{1'b0}}) || (c == {W{1'b0}});
    assign q = div0 ? {W{1'b1}} : ((a / b) / c);
endmodule

// ---- Sequential restoring divider (W cycles). Needs W >= 2.
//      Pulse start for 1 cycle (a, b must be valid at that time).
//      done pulses 1 cycle when q/r are valid.
module div_seq #(parameter W = 8)(
    input              clk, rst, start,
    input  [W-1:0]     a, b,
    output [W-1:0]     q, r,
    output reg         busy, done, div0
);
    reg [W-1:0]  dvd;      // dividend shift reg -> becomes quotient
    reg [W-1:0]  dvs;      // divisor
    reg [W-1:0]  rem;      // partial remainder
    reg [15:0]   cnt;
    wire [W:0]   rem_sh  = {rem, dvd[W-1]};
    wire         ge      = (rem_sh >= {1'b0, dvs});
    wire [W:0]   rem_sub = rem_sh - {1'b0, dvs};

    always @(posedge clk) begin
        done <= 1'b0;
        if (rst) begin
            busy <= 1'b0; done <= 1'b0; div0 <= 1'b0;
            dvd <= {W{1'b0}}; dvs <= {W{1'b0}}; rem <= {W{1'b0}}; cnt <= 16'd0;
        end else if (!busy) begin
            if (start) begin
                if (b == {W{1'b0}}) begin
                    div0 <= 1'b1; done <= 1'b1;
                    dvd  <= {W{1'b1}}; rem <= a;
                end else begin
                    div0 <= 1'b0; busy <= 1'b1;
                    dvd  <= a; dvs <= b; rem <= {W{1'b0}}; cnt <= 16'd0;
                end
            end
        end else begin
            rem <= ge ? rem_sub[W-1:0] : rem_sh[W-1:0];
            dvd <= {dvd[W-2:0], ge};
            cnt <= cnt + 16'd1;
            if (cnt == W-1) begin busy <= 1'b0; done <= 1'b1; end
        end
    end
    assign q = dvd;
    assign r = rem;
endmodule


//=====================================================================
// 6. COMPARATORS  (SIGNED=0 unsigned, SIGNED=1 signed)
//=====================================================================

// ---- 2-input: greater than (a > b) ----
module cmp_gt #(parameter W = 8, parameter SIGNED = 0)(
    input  [W-1:0] a, b,
    output         gt
);
    assign gt = SIGNED ? ($signed(a) > $signed(b)) : (a > b);
endmodule

// ---- 2-input: less than (a < b) ----
module cmp_lt #(parameter W = 8, parameter SIGNED = 0)(
    input  [W-1:0] a, b,
    output         lt
);
    assign lt = SIGNED ? ($signed(a) < $signed(b)) : (a < b);
endmodule

// ---- 2-input: equal (a == b) ----
module cmp_eq #(parameter W = 8)(
    input  [W-1:0] a, b,
    output         eq
);
    assign eq = (a == b);
endmodule

// ---- 2-input: all three outputs together ----
module cmp2 #(parameter W = 8, parameter SIGNED = 0)(
    input  [W-1:0] a, b,
    output         gt, lt, eq
);
    assign gt = SIGNED ? ($signed(a) > $signed(b)) : (a > b);
    assign lt = SIGNED ? ($signed(a) < $signed(b)) : (a < b);
    assign eq = (a == b);
endmodule

// ---- 3-input: a strictly greater than BOTH b and c ----
module cmp_gt3 #(parameter W = 8, parameter SIGNED = 0)(
    input  [W-1:0] a, b, c,
    output         gt
);
    wire gb = SIGNED ? ($signed(a) > $signed(b)) : (a > b);
    wire gc = SIGNED ? ($signed(a) > $signed(c)) : (a > c);
    assign gt = gb & gc;
endmodule

// ---- 3-input: a strictly less than BOTH b and c ----
module cmp_lt3 #(parameter W = 8, parameter SIGNED = 0)(
    input  [W-1:0] a, b, c,
    output         lt
);
    wire lb = SIGNED ? ($signed(a) < $signed(b)) : (a < b);
    wire lc = SIGNED ? ($signed(a) < $signed(c)) : (a < c);
    assign lt = lb & lc;
endmodule

// ---- 3-input: all equal ----
module cmp_eq3 #(parameter W = 8)(
    input  [W-1:0] a, b, c,
    output         eq
);
    assign eq = (a == b) && (b == c);
endmodule

// ---- Max / Min (2-input) ----
module max2 #(parameter W = 8, parameter SIGNED = 0)(
    input  [W-1:0] a, b,
    output [W-1:0] y
);
    wire gt = SIGNED ? ($signed(a) > $signed(b)) : (a > b);
    assign y = gt ? a : b;
endmodule

module min2 #(parameter W = 8, parameter SIGNED = 0)(
    input  [W-1:0] a, b,
    output [W-1:0] y
);
    wire lt = SIGNED ? ($signed(a) < $signed(b)) : (a < b);
    assign y = lt ? a : b;
endmodule

// ---- Max / Min (3-input) ----
module max3 #(parameter W = 8, parameter SIGNED = 0)(
    input  [W-1:0] a, b, c,
    output [W-1:0] y
);
    wire [W-1:0] m1;
    max2 #(.W(W), .SIGNED(SIGNED)) u1 (.a(a),  .b(b), .y(m1));
    max2 #(.W(W), .SIGNED(SIGNED)) u2 (.a(m1), .b(c), .y(y));
endmodule

module min3 #(parameter W = 8, parameter SIGNED = 0)(
    input  [W-1:0] a, b, c,
    output [W-1:0] y
);
    wire [W-1:0] m1;
    min2 #(.W(W), .SIGNED(SIGNED)) u1 (.a(a),  .b(b), .y(m1));
    min2 #(.W(W), .SIGNED(SIGNED)) u2 (.a(m1), .b(c), .y(y));
endmodule

// ---- Zero detect / Sign flag ----
module is_zero #(parameter W = 8)(input [W-1:0] a, output z);
    assign z = (a == {W{1'b0}});
endmodule


//=====================================================================
// 7. REGISTERS
//=====================================================================

// ---- Register: sync reset, enable ----
module reg_en #(parameter W = 8, parameter RST_VAL = 0)(
    input              clk, rst, en,
    input  [W-1:0]     d,
    output reg [W-1:0] q
);
    always @(posedge clk) begin
        if (rst)     q <= RST_VAL;
        else if (en) q <= d;
    end
endmodule

// ---- Register: sync reset, sync clear, load enable (clr has priority over ld) ----
module reg_ld_clr #(parameter W = 8)(
    input              clk, rst, clr, ld,
    input  [W-1:0]     d,
    output reg [W-1:0] q
);
    always @(posedge clk) begin
        if (rst | clr) q <= {W{1'b0}};
        else if (ld)   q <= d;
    end
endmodule

// ---- Register: ASYNC reset ----
module reg_async #(parameter W = 8, parameter RST_VAL = 0)(
    input              clk, rst, en,
    input  [W-1:0]     d,
    output reg [W-1:0] q
);
    always @(posedge clk or posedge rst) begin
        if (rst)     q <= RST_VAL;
        else if (en) q <= d;
    end
endmodule

// ---- Pipeline stage (no enable) ----
module pipe_reg #(parameter W = 8)(
    input              clk, rst,
    input  [W-1:0]     d,
    output reg [W-1:0] q
);
    always @(posedge clk) begin
        if (rst) q <= {W{1'b0}};
        else     q <= d;
    end
endmodule

// ---- Universal shift register (W >= 2)
//      mode: 00 hold | 01 shift left (sin -> LSB) | 10 shift right (sin -> MSB) | 11 parallel load
//      Serial-out: sout_l = q[W-1] (when shifting left), sout_r = q[0] (when shifting right)
module shift_reg #(parameter W = 8)(
    input              clk, rst,
    input  [1:0]       mode,
    input              sin,
    input  [W-1:0]     d,
    output reg [W-1:0] q,
    output             sout_l, sout_r
);
    always @(posedge clk) begin
        if (rst) q <= {W{1'b0}};
        else begin
            case (mode)
                2'b01:   q <= {q[W-2:0], sin};
                2'b10:   q <= {sin, q[W-1:1]};
                2'b11:   q <= d;
                default: q <= q;
            endcase
        end
    end
    assign sout_l = q[W-1];
    assign sout_r = q[0];
endmodule

// ---- Rising / falling edge detector ----
module edge_detect (
    input  clk, rst, in,
    output rise, fall
);
    reg prev;
    always @(posedge clk) begin
        if (rst) prev <= 1'b0;
        else     prev <= in;
    end
    assign rise =  in & ~prev;
    assign fall = ~in &  prev;
endmodule

// ---- 2-FF synchronizer ----
module sync2 (
    input  clk, rst, in,
    output out
);
    reg s1, s2;
    always @(posedge clk) begin
        if (rst) begin s1 <= 1'b0; s2 <= 1'b0; end
        else     begin s1 <= in;   s2 <= s1;   end
    end
    assign out = s2;
endmodule


//=====================================================================
// 8. COUNTERS
//=====================================================================

// ---- Up counter: rst > clr > ld > en. tc = all ones ----
module counter_up #(parameter W = 8, parameter RST_VAL = 0)(
    input              clk, rst, clr, en, ld,
    input  [W-1:0]     d,
    output reg [W-1:0] q,
    output             tc
);
    always @(posedge clk) begin
        if (rst)      q <= RST_VAL;
        else if (clr) q <= {W{1'b0}};
        else if (ld)  q <= d;
        else if (en)  q <= q + 1'b1;
    end
    assign tc = (q == {W{1'b1}});
endmodule

// ---- Up/Down counter: up=1 count up, up=0 count down ----
module counter_updown #(parameter W = 8)(
    input              clk, rst, clr, en, ld, up,
    input  [W-1:0]     d,
    output reg [W-1:0] q
);
    always @(posedge clk) begin
        if (rst | clr) q <= {W{1'b0}};
        else if (ld)   q <= d;
        else if (en)   q <= up ? (q + 1'b1) : (q - 1'b1);
    end
endmodule

// ---- Modulo-MOD counter: 0 .. MOD-1 then wraps. tc=1 on last count (when en) ----
//      Make sure W >= ceil(log2(MOD))
module counter_mod #(parameter W = 8, parameter MOD = 10)(
    input              clk, rst, clr, en,
    output reg [W-1:0] q,
    output             tc
);
    always @(posedge clk) begin
        if (rst | clr) q <= {W{1'b0}};
        else if (en) begin
            if (q == MOD-1) q <= {W{1'b0}};
            else            q <= q + 1'b1;
        end
    end
    assign tc = en && (q == MOD-1);
endmodule

// ---- Down counter with load, done when q==0 (handy for delays/loops) ----
module counter_down #(parameter W = 8)(
    input              clk, rst, ld, en,
    input  [W-1:0]     d,
    output reg [W-1:0] q,
    output             zero
);
    always @(posedge clk) begin
        if (rst)                       q <= {W{1'b0}};
        else if (ld)                   q <= d;
        else if (en && q != {W{1'b0}}) q <= q - 1'b1;
    end
    assign zero = (q == {W{1'b0}});
endmodule

// ---- Ring counter (one-hot, W >= 2) ----
module ring_counter #(parameter W = 4)(
    input              clk, rst, en,
    output reg [W-1:0] q
);
    always @(posedge clk) begin
        if (rst)     q <= {{(W-1){1'b0}}, 1'b1};
        else if (en) q <= {q[W-2:0], q[W-1]};
    end
endmodule

// ---- Johnson (twisted ring) counter, 2W states ----
module johnson_counter #(parameter W = 4)(
    input              clk, rst, en,
    output reg [W-1:0] q
);
    always @(posedge clk) begin
        if (rst)     q <= {W{1'b0}};
        else if (en) q <= {q[W-2:0], ~q[W-1]};
    end
endmodule

// ---- Binary <-> Gray ----
module bin2gray #(parameter W = 4)(input [W-1:0] b, output [W-1:0] g);
    assign g = b ^ (b >> 1);
endmodule

module gray2bin #(parameter W = 4)(input [W-1:0] g, output reg [W-1:0] b);
    integer i;
    always @(*) begin
        b[W-1] = g[W-1];
        for (i = W-2; i >= 0; i = i - 1)
            b[i] = b[i+1] ^ g[i];
    end
endmodule


//=====================================================================
// 9. REGISTER FILE / MEMORIES / FIFO / PING-PONG
//=====================================================================

// ---- Register file: 1 write port, 2 read ports (async read, sync write)
//      N registers, AW = ceil(log2(N)). ZERO_R0=1 -> R0 hardwired to 0 (MIPS style)
module regfile #(parameter W = 8, parameter N = 8, parameter AW = 3, parameter ZERO_R0 = 0)(
    input              clk, rst, we,
    input  [AW-1:0]    waddr, raddr1, raddr2,
    input  [W-1:0]     wdata,
    output [W-1:0]     rdata1, rdata2
);
    reg [W-1:0] mem [0:N-1];
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < N; i = i + 1) mem[i] <= {W{1'b0}};
        end else if (we && !(ZERO_R0 && (waddr == {AW{1'b0}}))) begin
            mem[waddr] <= wdata;
        end
    end
    assign rdata1 = (ZERO_R0 && (raddr1 == {AW{1'b0}})) ? {W{1'b0}} : mem[raddr1];
    assign rdata2 = (ZERO_R0 && (raddr2 == {AW{1'b0}})) ? {W{1'b0}} : mem[raddr2];
endmodule

// ---- Register file with 3 read ports (e.g., a op b -> c style) ----
module regfile_3r #(parameter W = 8, parameter N = 8, parameter AW = 3)(
    input              clk, rst, we,
    input  [AW-1:0]    waddr, raddr1, raddr2, raddr3,
    input  [W-1:0]     wdata,
    output [W-1:0]     rdata1, rdata2, rdata3
);
    reg [W-1:0] mem [0:N-1];
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < N; i = i + 1) mem[i] <= {W{1'b0}};
        end else if (we) mem[waddr] <= wdata;
    end
    assign rdata1 = mem[raddr1];
    assign rdata2 = mem[raddr2];
    assign rdata3 = mem[raddr3];
endmodule

// ---- Single-port synchronous RAM (read-first, 1-cycle read latency) ----
module ram_sp #(parameter W = 8, parameter DEPTH = 256, parameter AW = 8)(
    input              clk, we,
    input  [AW-1:0]    addr,
    input  [W-1:0]     din,
    output reg [W-1:0] dout
);
    reg [W-1:0] mem [0:DEPTH-1];
    always @(posedge clk) begin
        if (we) mem[addr] <= din;
        dout <= mem[addr];
    end
endmodule

// ---- Simple dual-port RAM (1 write port, 1 read port) ----
module ram_sdp #(parameter W = 8, parameter DEPTH = 256, parameter AW = 8)(
    input              clk, we,
    input  [AW-1:0]    waddr, raddr,
    input  [W-1:0]     din,
    output reg [W-1:0] dout
);
    reg [W-1:0] mem [0:DEPTH-1];
    always @(posedge clk) begin
        if (we) mem[waddr] <= din;
        dout <= mem[raddr];
    end
endmodule

// ---- ROM loaded from a hex file ($readmemh). Async read ----
module rom #(parameter W = 16, parameter DEPTH = 256, parameter AW = 8, parameter FILE = "rom.mem")(
    input  [AW-1:0] addr,
    output [W-1:0]  dout
);
    reg [W-1:0] mem [0:DEPTH-1];
    initial $readmemh(FILE, mem);
    assign dout = mem[addr];
endmodule

// ---- Synchronous FIFO (first-word-fall-through read). AW = ceil(log2(DEPTH)) ----
module fifo_sync #(parameter W = 8, parameter DEPTH = 16, parameter AW = 4)(
    input              clk, rst,
    input              wr_en, rd_en,
    input  [W-1:0]     din,
    output [W-1:0]     dout,
    output             full, empty,
    output reg [AW:0]  count
);
    reg [W-1:0]  mem [0:DEPTH-1];
    reg [AW-1:0] wp, rp;
    wire do_wr = wr_en & ~full;
    wire do_rd = rd_en & ~empty;
    assign full  = (count == DEPTH);
    assign empty = (count == 0);
    always @(posedge clk) begin
        if (rst) begin
            wp <= 0; rp <= 0; count <= 0;
        end else begin
            if (do_wr) begin
                mem[wp] <= din;
                wp <= (wp == DEPTH-1) ? {AW{1'b0}} : wp + 1'b1;
            end
            if (do_rd) rp <= (rp == DEPTH-1) ? {AW{1'b0}} : rp + 1'b1;
            count <= count + do_wr - do_rd;
        end
    end
    assign dout = mem[rp];
endmodule

// ---- Ping-pong (double) buffer: producer writes bank[wsel], consumer reads bank[~wsel].
//      Pulse swap to exchange roles. Async read.
module ping_pong_buffer #(parameter W = 8, parameter DEPTH = 16, parameter AW = 4)(
    input              clk, rst,
    input              swap,
    input              we,
    input  [AW-1:0]    waddr, raddr,
    input  [W-1:0]     wdata,
    output [W-1:0]     rdata,
    output reg         wsel         // which bank is currently being written
);
    reg [W-1:0] bank0 [0:DEPTH-1];
    reg [W-1:0] bank1 [0:DEPTH-1];
    always @(posedge clk) begin
        if (rst)       wsel <= 1'b0;
        else if (swap) wsel <= ~wsel;
    end
    always @(posedge clk) begin
        if (we) begin
            if (wsel) bank1[waddr] <= wdata;
            else      bank0[waddr] <= wdata;
        end
    end
    assign rdata = wsel ? bank0[raddr] : bank1[raddr];
endmodule


//=====================================================================
// 10. MISC
//=====================================================================

// ---- Simple ALU. op: 000 add | 001 sub | 010 and | 011 or | 100 xor | 101 nor
//                      110 slt (signed) | 111 shift left by b[2:0]
module alu #(parameter W = 8)(
    input  [W-1:0]     a, b,
    input  [2:0]       op,
    output reg [W-1:0] y,
    output reg         cout,
    output             zero
);
    always @(*) begin
        cout = 1'b0;
        case (op)
            3'b000: {cout, y} = a + b;
            3'b001: {cout, y} = a - b;
            3'b010: y = a & b;
            3'b011: y = a | b;
            3'b100: y = a ^ b;
            3'b101: y = ~(a | b);
            3'b110: y = ($signed(a) < $signed(b)) ? {{(W-1){1'b0}}, 1'b1} : {W{1'b0}};
            3'b111: y = a << b[2:0];
            default: y = {W{1'b0}};
        endcase
    end
    assign zero = (y == {W{1'b0}});
endmodule

// ---- Barrel shifter. dir=0 left, dir=1 right ; arith=1 -> arithmetic right ----
module shifter #(parameter W = 8, parameter SW = 3)(
    input  [W-1:0]     a,
    input  [SW-1:0]    sh,
    input              dir, arith,
    output reg [W-1:0] y
);
    always @(*) begin
        if (!dir)       y = a << sh;
        else if (arith) y = $signed(a) >>> sh;
        else            y = a >> sh;
    end
endmodule

// ---- Sign / zero extension ----
module sign_ext #(parameter WI = 8, parameter WO = 16)(
    input  [WI-1:0] a,
    output [WO-1:0] y
);
    assign y = {{(WO-WI){a[WI-1]}}, a};
endmodule

module zero_ext #(parameter WI = 8, parameter WO = 16)(
    input  [WI-1:0] a,
    output [WO-1:0] y
);
    assign y = {{(WO-WI){1'b0}}, a};
endmodule

// ---- Parity: even_parity bit makes total number of ones even ----
module parity #(parameter W = 8)(
    input  [W-1:0] a,
    output         even_bit, odd_bit
);
    assign even_bit = ^a;
    assign odd_bit  = ~(^a);
endmodule

// ---- Galois LFSR. 8-bit maximal: TAPS=8'hB8 ; 16-bit maximal: TAPS=16'hB400 ----
module lfsr #(parameter W = 8, parameter [W-1:0] TAPS = 8'hB8, parameter [W-1:0] SEED = 8'h01)(
    input              clk, rst, en,
    output reg [W-1:0] q
);
    always @(posedge clk) begin
        if (rst)     q <= SEED;
        else if (en) q <= (q >> 1) ^ (q[0] ? TAPS : {W{1'b0}});
    end
endmodule

// ---- Clock-enable tick every DIV clocks (preferred over a divided clock) ----
module tick_gen #(parameter DIV = 100, parameter W = 16)(
    input  clk, rst,
    output tick
);
    reg [W-1:0] cnt;
    always @(posedge clk) begin
        if (rst || cnt == DIV-1) cnt <= {W{1'b0}};
        else                     cnt <= cnt + 1'b1;
    end
    assign tick = (cnt == DIV-1);
endmodule

// ---- Divided clock (toggle every HALF clocks -> period = 2*HALF) ----
module clk_div #(parameter HALF = 50, parameter W = 16)(
    input  clk, rst,
    output reg clk_out
);
    reg [W-1:0] cnt;
    always @(posedge clk) begin
        if (rst) begin cnt <= {W{1'b0}}; clk_out <= 1'b0; end
        else if (cnt == HALF-1) begin cnt <= {W{1'b0}}; clk_out <= ~clk_out; end
        else cnt <= cnt + 1'b1;
    end
endmodule

// ---- Tri-state buffer ----
module tristate #(parameter W = 8)(
    input  [W-1:0] d,
    input          oe,
    output [W-1:0] y
);
    assign y = oe ? d : {W{1'bz}};
endmodule


//=====================================================================
// 11. FSM TEMPLATES
//=====================================================================

// ---- MOORE FSM template (3 blocks: state reg | next-state | outputs) ----
//      Output depends ONLY on state.
module fsm_moore_template (
    input      clk, rst,
    input      go, done_in,
    output reg busy, finish
);
    localparam S_IDLE = 2'd0,
               S_RUN  = 2'd1,
               S_END  = 2'd2;
    reg [1:0] state, next;

    // 1) state register
    always @(posedge clk) begin
        if (rst) state <= S_IDLE;
        else     state <= next;
    end

    // 2) next-state logic (default: stay)
    always @(*) begin
        next = state;
        case (state)
            S_IDLE: if (go)      next = S_RUN;
            S_RUN:  if (done_in) next = S_END;
            S_END:               next = S_IDLE;
            default:             next = S_IDLE;
        endcase
    end

    // 3) output logic (default values first!)
    always @(*) begin
        busy = 1'b0; finish = 1'b0;
        case (state)
            S_RUN: busy   = 1'b1;
            S_END: finish = 1'b1;
            default: ;
        endcase
    end
endmodule

// ---- MEALY example: overlapping "101" sequence detector ----
//      Output depends on state AND input.
module seq101_mealy (
    input  clk, rst, in,
    output reg z
);
    localparam S0 = 2'd0, S1 = 2'd1, S2 = 2'd2;
    reg [1:0] state, next;
    always @(posedge clk) begin
        if (rst) state <= S0;
        else     state <= next;
    end
    always @(*) begin
        next = state; z = 1'b0;
        case (state)
            S0: next = in ? S1 : S0;
            S1: next = in ? S1 : S2;
            S2: begin
                    if (in) begin next = S1; z = 1'b1; end
                    else    next = S0;
                end
            default: next = S0;
        endcase
    end
endmodule


//=====================================================================
// 12. DATAPATH + CONTROLLER + TOP  --  complete example
//     Sequential shift-add multiplier  p = a * b  (W cycles + overhead)
//     Use this as the SKELETON for any exam question that asks for
//     "datapath, controller and top module".
//       datapath  : registers + operators, driven by control signals,
//                   reports STATUS signals (b0, cnt_done)
//       controller: FSM, reads status, generates control signals
//       top       : just instantiates & wires the two
//=====================================================================

module mult_datapath #(parameter W = 8)(
    input                 clk, rst,
    input  [W-1:0]        a, b,
    // control signals (from controller)
    input                 ld,         // load operands, clear P and counter
    input                 add_en,     // P <= P + A
    input                 shift_en,   // A <<= 1, B >>= 1, cnt++
    // status signals (to controller)
    output                b0,         // LSB of B
    output                cnt_done,   // last iteration
    // result
    output [2*W-1:0]      p
);
    reg [2*W-1:0] A, P;
    reg [W-1:0]   B;
    reg [15:0]    cnt;

    always @(posedge clk) begin
        if (rst) begin
            A <= 0; B <= 0; P <= 0; cnt <= 0;
        end else if (ld) begin
            A <= {{W{1'b0}}, a};
            B <= b;
            P <= 0;
            cnt <= 0;
        end else begin
            if (add_en) P <= P + A;
            if (shift_en) begin
                A   <= A << 1;
                B   <= B >> 1;
                cnt <= cnt + 1'b1;
            end
        end
    end

    assign b0       = B[0];
    assign cnt_done = (cnt == W-1);
    assign p        = P;
endmodule

module mult_controller (
    input      clk, rst,
    input      start,
    input      b0, cnt_done,           // status from datapath
    output reg ld, add_en, shift_en,   // control to datapath
    output reg done
);
    localparam IDLE  = 3'd0,
               LOAD  = 3'd1,
               CHECK = 3'd2,
               ADD   = 3'd3,
               SHIFT = 3'd4,
               DONE  = 3'd5;
    reg [2:0] state, next;

    always @(posedge clk) begin
        if (rst) state <= IDLE;
        else     state <= next;
    end

    always @(*) begin
        next = state;
        case (state)
            IDLE:  if (start) next = LOAD;
            LOAD:  next = CHECK;
            CHECK: next = b0 ? ADD : SHIFT;
            ADD:   next = SHIFT;
            SHIFT: next = cnt_done ? DONE : CHECK;
            DONE:  next = IDLE;
            default: next = IDLE;
        endcase
    end

    always @(*) begin
        ld = 1'b0; add_en = 1'b0; shift_en = 1'b0; done = 1'b0;
        case (state)
            LOAD:  ld       = 1'b1;
            ADD:   add_en   = 1'b1;
            SHIFT: shift_en = 1'b1;
            DONE:  done     = 1'b1;
            default: ;
        endcase
    end
endmodule

// ---- TOP: hold a,b stable from start until done. p is valid when done=1 ----
module mult_seq_top #(parameter W = 8)(
    input                 clk, rst, start,
    input  [W-1:0]        a, b,
    output [2*W-1:0]      p,
    output                done
);
    wire ld, add_en, shift_en, b0, cnt_done;

    mult_datapath #(.W(W)) dp (
        .clk(clk), .rst(rst), .a(a), .b(b),
        .ld(ld), .add_en(add_en), .shift_en(shift_en),
        .b0(b0), .cnt_done(cnt_done), .p(p)
    );

    mult_controller ctrl (
        .clk(clk), .rst(rst), .start(start),
        .b0(b0), .cnt_done(cnt_done),
        .ld(ld), .add_en(add_en), .shift_en(shift_en), .done(done)
    );
endmodule


//=====================================================================
// 13. TESTBENCH TEMPLATE (kept in comments so it does not break synthesis)
//=====================================================================
// `timescale 1ns/1ps
// module tb;
//     parameter W = 8;
//     reg              clk = 0, rst = 1, start = 0;
//     reg  [W-1:0]     a, b;
//     wire [2*W-1:0]   p;
//     wire             done;
//
//     mult_seq_top #(.W(W)) dut (.clk(clk), .rst(rst), .start(start),
//                                .a(a), .b(b), .p(p), .done(done));
//
//     always #5 clk = ~clk;                 // 10 ns clock
//
//     task run;                              // reusable stimulus
//         input [W-1:0] ta, tb_;
//         begin
//             a = ta; b = tb_;
//             @(posedge clk); start = 1;
//             @(posedge clk); start = 0;
//             wait (done);                   // wait for result
//             @(posedge clk);
//             $display("%0t: %0d * %0d = %0d  (%s)", $time, ta, tb_, p,
//                      (p == ta*tb_) ? "OK" : "FAIL");
//         end
//     endtask
//
//     initial begin
//         $dumpfile("wave.vcd"); $dumpvars(0, tb);
//         repeat (3) @(posedge clk);
//         rst = 0;
//         run(8'd5,   8'd7);
//         run(8'd255, 8'd255);
//         run(8'd0,   8'd9);
//         repeat (10) run($random, $random);   // random tests
//         $finish;
//     end
// endmodule
//
// ModelSim quick flow:
//   vlib work
//   vlog CAD_LIB.v tb.v
//   vsim -novopt tb        (or: vsim -voptargs=+acc tb)
//   add wave -r /tb/*
//   run -all


//=====================================================================
// 14. FILE I/O  (SIMULATION ONLY - not synthesizable, put in testbench)
//     Exception: $readmemh/$readmemb inside `initial` DO synthesize
//     (used to initialise ROM/RAM contents).
//     Paths are relative to the simulator working directory
//     (ModelSim: the folder shown by `pwd`, change with `cd <dir>`).
//=====================================================================
//
// ---------- 14.1  Quick reference ----------
//  OPEN / CLOSE
//    integer fd;
//    fd = $fopen("file.txt", "r");   // modes: "r" read | "w" write (overwrite)
//                                    //        "a" append | "r+","w+","a+" read/write
//    if (fd == 0) begin $display("cannot open file"); $finish; end   // 0 = failure
//    $fclose(fd);                    // always close (flushes data)
//    $fflush(fd);                    // force write to disk without closing
//    fd=1 is the console (stdout):  $fdisplay(1, "hello");
//
//  WRITE (fd is the first argument)
//    $fdisplay(fd, "a=%0d b=%h", a, b);   // + newline
//    $fwrite  (fd, "a=%0d ", a);          // no newline
//    $fmonitor(fd, "t=%0t y=%b", $time, y); // writes every time an arg changes
//    $fstrobe (fd, ...);                  // writes at end of current time step
//    format letters: %d dec | %h hex | %b bin | %o oct | %c char | %s string
//                    %t time | %m hierarchy name | %0d = no leading spaces/zeros
//
//  READ
//    r = $fscanf(fd, "%d %h", a, b);  // returns number of items matched (EOF if none)
//    c = $fgetc(fd);                  // one character, -1 at end of file (use integer c)
//    r = $fgets(line, fd);            // reads a whole line into reg [8*N-1:0] line
//                                     //   returns 0 at end of file
//    e = $feof(fd);                   // non-zero when end of file reached
//    r = $sscanf(line, "%h %h", a, b);// parse a string (like fscanf on a string)
//    $ungetc(c, fd);  $fseek(fd, pos, 0);  pos = $ftell(fd);  $rewind(fd);
//    r = $fread(mem_or_reg, fd);      // binary read (SV / most simulators)
//
//  STRING BUILDING
//    $sformat(str, "out_%0d.txt", i); // build a file name   (str: reg [8*40-1:0])
//    $swrite(str, "v=%0d", v);
//
//  MEMORY FILES
//    $readmemh("data.mem", mem);               // hex  file -> memory
//    $readmemb("data.mem", mem);               // bin  file -> memory
//    $readmemh("data.mem", mem, 0, 15);        // only addresses 0..15
//    $writememh("dump.mem", mem);              // memory -> hex file (ModelSim OK)
//    $writememb("dump.mem", mem);              // memory -> bin file
//    .mem file format:  words separated by space/newline, "// comment",
//                       "@10" sets the next address (hex), x / z / "_" allowed.
//         // example data.mem
//         @0
//         00FF 1A2B 0003
//         @10
//         FFFF
//
//  RUN-TIME ARGUMENTS (vsim +NAME=value)
//    reg [8*64-1:0] fname;
//    if ($value$plusargs("FILE=%s", fname)) fd = $fopen(fname, "r");
//    if ($test$plusargs("VERBOSE")) ...
//
// ---------- 14.2  Template: read test vectors, write results ----------
// vec.txt (decimal, one pair per line):      5 7
//                                            255 255
//
//  integer fin, fout, r, n;
//  reg [7:0]  a, b;
//  initial begin
//      fin  = $fopen("vec.txt",    "r");
//      fout = $fopen("result.txt", "w");
//      if (fin == 0 || fout == 0) begin
//          $display("ERROR: cannot open files"); $finish;
//      end
//      n = 0;
//      while (!$feof(fin)) begin
//          r = $fscanf(fin, "%d %d\n", a, b);     // r == 2 means a valid line
//          if (r == 2) begin
//              // ... drive DUT with a, b, wait for result ...
//              @(posedge clk); #1;
//              $fdisplay(fout, "%0d: %0d * %0d = %0d", n, a, b, p);
//              n = n + 1;
//          end
//      end
//      $fclose(fin);
//      $fclose(fout);
//      $display("done, %0d vectors", n);
//      $finish;
//  end
//
// ---------- 14.3  Template: line by line with $fgets + $sscanf ----------
//  reg [8*80-1:0] line;
//  integer code, r;
//  reg [15:0] a, b;
//  initial begin
//      fin = $fopen("vec_hex.txt", "r");
//      while (!$feof(fin)) begin
//          code = $fgets(line, fin);
//          if (code != 0) begin
//              r = $sscanf(line, "%h %h", a, b);   // skip bad/comment lines when r != 2
//              if (r == 2) begin /* use a, b */ end
//          end
//      end
//      $fclose(fin);
//  end
//
// ---------- 14.4  Template: read a file character by character ----------
//  integer c;
//  initial begin
//      fin = $fopen("text.txt", "r");
//      c = $fgetc(fin);
//      while (c != -1) begin          // -1 = EOF
//          $write("%c", c);
//          c = $fgetc(fin);
//      end
//      $fclose(fin);
//  end
//
// ---------- 14.5  Template: log file with append + console copy ----------
//  integer log;
//  initial begin
//      log = $fopen("log.txt", "a");            // append
//      $fdisplay(log, "[%0t] reset released", $time);
//      $fdisplay(1,   "[%0t] reset released", $time);   // 1 = console
//      // write to both at once with a multi-channel descriptor:
//      //   mcd = log | 1;   $fdisplay(mcd, "text");    (valid only for $fopen(name) without mode)
//  end
//
// ---------- 14.6  Template: self-checking against an expected-results file ----------
//  integer fexp, rexp, errors;
//  reg [15:0] exp_val;
//  initial begin
//      fexp = $fopen("expected.txt", "r");
//      errors = 0;
//      // for each result produced by the DUT:
//      r = $fscanf(fexp, "%d\n", exp_val);
//      if (r == 1 && p !== exp_val) begin
//          errors = errors + 1;
//          $display("MISMATCH: got %0d expected %0d", p, exp_val);
//      end
//      // at the end:
//      $fclose(fexp);
//      if (errors == 0) $display("ALL PASSED"); else $display("%0d errors", errors);
//  end
//
// ---------- 14.7  Template: load memory from file / dump it back ----------
//  reg [15:0] img [0:783];
//  initial begin
//      $readmemh("input.mem", img);               // before simulation starts
//      #1000;
//      $writememh("output_dump.mem", img);        // after processing
//  end
//
// ---------- 14.8  Template: write a CSV for plotting / Python ----------
//  initial begin
//      fout = $fopen("wave.csv", "w");
//      $fdisplay(fout, "time,a,b,y");             // header line
//  end
//  always @(posedge clk)
//      $fdisplay(fout, "%0t,%0d,%0d,%0d", $time, a, b, y);
//  // call $fclose(fout) before $finish
//
// ---------- 14.9  Common pitfalls ----------
//   * Always check  fd == 0  after $fopen (wrong path is the #1 problem).
//   * $fclose before $finish, otherwise the output file may be empty/incomplete.
//   * $fscanf returns the number of matched items - test it (r == 2 ...),
//     the last empty line otherwise re-uses the previous values.
//   * %d reads decimal, %h hex: match the format of your vector file.
//   * line buffer width must fit the longest line: reg [8*N-1:0].
//   * $readmemh with a short file leaves the rest of memory as x.
//   * File I/O tasks other than $readmem* are ignored/unsupported by Quartus synthesis.
