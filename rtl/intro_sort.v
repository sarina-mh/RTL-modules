// Introspective quicksort: Lomuto partitioning with a per-partition depth budget;
// switches to in-place heapsort when the budget is exhausted. No recursion.
// DEPTH=0 directly exercises the heap fallback. N-entry explicit range stack.

// =====================================================================
// intro_sort: complete controller + datapath + top in one Verilog file.
// Pulse start while busy=0. Inputs are latched on the accepting edge.
// Reset and port conventions are preserved from the original module.
// Packed array lane i occupies bits [i*W +: W], unless stated otherwise.
// =====================================================================
// control[0]: for(k=0; k<N; k=k+1) mem[k] <= data_in[(k * W) +: W];
// control[1]: slo[0] <= 0;
// control[2]: shi[0] <= N - 1;
// control[3]: sd[0] <= DEPTH;
// control[4]: sp <= 1;
// control[5]: lo <= slo[sp - 1];
// control[6]: hi <= shi[sp - 1];
// control[7]: depth <= sd[sp - 1];
// control[8]: sp <= sp - 1;
// control[9]: pivot <= mem[hi];
// control[10]: i <= lo;
// control[11]: j <= lo;
// control[12]: mem[i] <= mem[j];
// control[13]: mem[j] <= mem[i];
// control[14]: i <= i + 1;
// control[15]: j <= j + 1;
// control[16]: mem[i] <= mem[hi];
// control[17]: mem[hi] <= mem[i];
// control[18]: slo[sp] <= lo;
// control[19]: shi[sp] <= i - 1;
// control[20]: sd[sp] <= depth - 1;
// control[21]: slo[sp + 1] <= i + 1;
// control[22]: shi[sp + 1] <= hi;
// control[23]: sd[sp + 1] <= depth - 1;
// control[24]: sp <= sp + 2;
// control[25]: slo[sp] <= lo;
// control[26]: shi[sp] <= i - 1;
// control[27]: sd[sp] <= depth - 1;
// control[28]: sp <= sp + 1;
// control[29]: slo[sp] <= i + 1;
// control[30]: shi[sp] <= hi;
// control[31]: sd[sp] <= depth - 1;
// control[32]: sp <= sp + 1;
// control[33]: for(k=0; k<N; k=k+1) data_out[(k * W) +: W] <= mem[k];
// control[34]: size <= hi - lo + 1;
// control[35]: root <= (hi - lo + 1) / 2 - 1;
// control[36]: build_root <= (hi - lo + 1) / 2 - 1;
// control[37]: mem[lo + root] <= mem[lo + child];
// control[38]: mem[lo + child] <= mem[lo + root];
// control[39]: root <= child;
// control[40]: root <= build_root - 1;
// control[41]: build_root <= build_root - 1;
// control[42]: mem[lo] <= mem[lo + size - 1];
// control[43]: mem[lo + size - 1] <= mem[lo];
// control[44]: size <= size - 1;
// control[45]: root <= 0;

// ---------------- CONTROLLER ----------------
module intro_sort_controller #
(
  parameter W = 8,
  parameter N = 8,
  parameter SIGNED = 0,
  parameter DEPTH = 2 * $clog2(N)
)
(
  input clk,
  input rst_n,
  input start,
  input [10:0] status,
  output reg [45:0] control,
  output reg busy,
  output reg done);

reg building;
reg [3:0] state;
reg next_building;
reg next_busy;
reg next_done;
reg [3:0] next_state;

// FSM state/handshake registers; all data writes are control strobes.

always @(posedge clk) if(!rst_n) begin
  busy <= 0;
  done <= 0;
  building <= 0;
  state <= 0;
end else begin
  building <= next_building;
  busy <= next_busy;
  done <= next_done;
  state <= next_state;
end


always @(*) begin
  next_building = building;
  next_busy = busy;
  next_done = done;
  next_state = state;
  control = 0;
  begin
    next_done = 0;
    if(start && !busy) begin
      control[0] = 1'b1;
      control[1] = 1'b1;
      control[2] = 1'b1;
      control[3] = 1'b1;
      control[4] = 1'b1;
      next_state = 0;
      next_busy = 1;
    end else if(busy) case(state)
      0: if(status[0]) next_state = 4;
      else begin
        control[5] = 1'b1;
        control[6] = 1'b1;
        control[7] = 1'b1;
        control[8] = 1'b1;
        next_state = 1;
      end
      1: if(status[1]) next_state = 0;
      else if(status[2]) next_state = 5;
      else begin
        control[9] = 1'b1;
        control[10] = 1'b1;
        control[11] = 1'b1;
        next_state = 2;
      end
      2: if(status[3]) next_state = 3;
      else begin
        if(status[4]) begin
          control[12] = 1'b1;
          control[13] = 1'b1;
          control[14] = 1'b1;
        end
        control[15] = 1'b1;
      end
      3: begin
        control[16] = 1'b1;
        control[17] = 1'b1;
        if(status[5] && status[6]) begin
          control[18] = 1'b1;
          control[19] = 1'b1;
          control[20] = 1'b1;
          control[21] = 1'b1;
          control[22] = 1'b1;
          control[23] = 1'b1;
          control[24] = 1'b1;
        end else if(status[5]) begin
          control[25] = 1'b1;
          control[26] = 1'b1;
          control[27] = 1'b1;
          control[28] = 1'b1;
        end else if(status[6]) begin
          control[29] = 1'b1;
          control[30] = 1'b1;
          control[31] = 1'b1;
          control[32] = 1'b1;
        end
        next_state = 0;
      end
      4: begin
        control[33] = 1'b1;
        next_busy = 0;
        next_done = 1;
      end
      5: begin
        control[34] = 1'b1;
        control[35] = 1'b1;
        control[36] = 1'b1;
        next_building = 1;
        next_state = 6;
      end
      6: if(status[7] && status[8]) begin
        control[37] = 1'b1;
        control[38] = 1'b1;
        control[39] = 1'b1;
      end else next_state = 7;
      7: if(building && status[9]) begin
        control[40] = 1'b1;
        control[41] = 1'b1;
        next_state = 6;
      end else begin
        next_building = 0;
        next_state = 8;
      end
      8: if(status[10]) next_state = 0;
      else begin
        control[42] = 1'b1;
        control[43] = 1'b1;
        control[44] = 1'b1;
        control[45] = 1'b1;
        next_state = 6;
      end
      default: next_state = 0;
    endcase
  end
end

endmodule

// ---------------- DATAPATH ----------------
module intro_sort_datapath #
(
  parameter W = 8,
  parameter N = 8,
  parameter SIGNED = 0,
  parameter DEPTH = 2 * $clog2(N)
)
(
  input clk,
  input rst_n,
  input [N*W-1:0] data_in,
  input [45:0] control,
  output [10:0] status,
  output reg [N*W-1:0] data_out);
reg [W-1:0] mem [0:N-1];
reg [W-1:0] pivot;
reg signed [31:0] slo [0:N-1];
reg signed [31:0] shi [0:N-1];
reg signed [31:0] sd [0:N-1];
integer sp;
integer lo;
integer hi;
integer depth;
integer i;
integer j;
integer k;
integer size;
integer root;
integer build_root;
integer child;

function [0:0] greater;
  input [W-1:0] a;input [W-1:0] b;
  begin
    greater = (SIGNED)? $signed(a) > $signed(b) : a > b;
  end
endfunction


always @(*) begin
  child = 2 * root + 1;
  if(child + 1 < size) if(greater(mem[lo + child + 1], mem[lo + child])) child = child + 1;
end


// Status predicates are generated by the datapath, never by the FSM.
assign status[0] = (sp == 0);
assign status[1] = (lo >= hi);
assign status[2] = (depth == 0);
assign status[3] = (j == hi);
assign status[4] = (!greater(mem[j], pivot));
assign status[5] = (lo < i - 1);
assign status[6] = (i + 1 < hi);
assign status[7] = (child < size);
assign status[8] = greater(mem[lo + child], mem[lo + root]);
assign status[9] = (build_root > 0);
assign status[10] = (size <= 1);

// Register-transfer operations. Later strobes retain nonblocking
// assignment priority when the same destination is written twice.

always @(posedge clk) if(!rst_n) begin
  data_out <= 0;
  pivot <= 0;
  sp <= 0;
  lo <= 0;
  hi <= 0;
  depth <= 0;
  i <= 0;
  j <= 0;
  size <= 0;
  root <= 0;
  build_root <= 0;
  for(k=0; k<N; k=k+1) begin
    mem[k] <= 0;
    slo[k] <= 0;
    shi[k] <= 0;
    sd[k] <= 0;
  end
end else begin
  if(control[0]) begin
    for(k=0; k<N; k=k+1) mem[k] <= data_in[(k * W) +: W];
  end
  if(control[1]) begin
    slo[0] <= 0;
  end
  if(control[2]) begin
    shi[0] <= N - 1;
  end
  if(control[3]) begin
    sd[0] <= DEPTH;
  end
  if(control[4]) begin
    sp <= 1;
  end
  if(control[5]) begin
    lo <= slo[sp - 1];
  end
  if(control[6]) begin
    hi <= shi[sp - 1];
  end
  if(control[7]) begin
    depth <= sd[sp - 1];
  end
  if(control[8]) begin
    sp <= sp - 1;
  end
  if(control[9]) begin
    pivot <= mem[hi];
  end
  if(control[10]) begin
    i <= lo;
  end
  if(control[11]) begin
    j <= lo;
  end
  if(control[12]) begin
    mem[i] <= mem[j];
  end
  if(control[13]) begin
    mem[j] <= mem[i];
  end
  if(control[14]) begin
    i <= i + 1;
  end
  if(control[15]) begin
    j <= j + 1;
  end
  if(control[16]) begin
    mem[i] <= mem[hi];
  end
  if(control[17]) begin
    mem[hi] <= mem[i];
  end
  if(control[18]) begin
    slo[sp] <= lo;
  end
  if(control[19]) begin
    shi[sp] <= i - 1;
  end
  if(control[20]) begin
    sd[sp] <= depth - 1;
  end
  if(control[21]) begin
    slo[sp + 1] <= i + 1;
  end
  if(control[22]) begin
    shi[sp + 1] <= hi;
  end
  if(control[23]) begin
    sd[sp + 1] <= depth - 1;
  end
  if(control[24]) begin
    sp <= sp + 2;
  end
  if(control[25]) begin
    slo[sp] <= lo;
  end
  if(control[26]) begin
    shi[sp] <= i - 1;
  end
  if(control[27]) begin
    sd[sp] <= depth - 1;
  end
  if(control[28]) begin
    sp <= sp + 1;
  end
  if(control[29]) begin
    slo[sp] <= i + 1;
  end
  if(control[30]) begin
    shi[sp] <= hi;
  end
  if(control[31]) begin
    sd[sp] <= depth - 1;
  end
  if(control[32]) begin
    sp <= sp + 1;
  end
  if(control[33]) begin
    for(k=0; k<N; k=k+1) data_out[(k * W) +: W] <= mem[k];
  end
  if(control[34]) begin
    size <= hi - lo + 1;
  end
  if(control[35]) begin
    root <= (hi - lo + 1) / 2 - 1;
  end
  if(control[36]) begin
    build_root <= (hi - lo + 1) / 2 - 1;
  end
  if(control[37]) begin
    mem[lo + root] <= mem[lo + child];
  end
  if(control[38]) begin
    mem[lo + child] <= mem[lo + root];
  end
  if(control[39]) begin
    root <= child;
  end
  if(control[40]) begin
    root <= build_root - 1;
  end
  if(control[41]) begin
    build_root <= build_root - 1;
  end
  if(control[42]) begin
    mem[lo] <= mem[lo + size - 1];
  end
  if(control[43]) begin
    mem[lo + size - 1] <= mem[lo];
  end
  if(control[44]) begin
    size <= size - 1;
  end
  if(control[45]) begin
    root <= 0;
  end
end

endmodule

// ---------------- TOP ----------------
module intro_sort #
(
  parameter W = 8,
  parameter N = 8,
  parameter SIGNED = 0,
  parameter DEPTH = 2 * $clog2(N)
)
(
  input clk,
  input rst_n,
  input start,
  input [N*W-1:0] data_in,
  output [N*W-1:0] data_out,
  output busy,
  output done);
wire [45:0] control;
wire [10:0] status;
intro_sort_controller #(.W(W), .N(N), .SIGNED(SIGNED), .DEPTH(DEPTH)) controller (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .status(status),
    .control(control),
    .busy(busy),
    .done(done)
);
intro_sort_datapath #(.W(W), .N(N), .SIGNED(SIGNED), .DEPTH(DEPTH)) datapath (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .control(control),
    .status(status),
    .data_out(data_out)
);
endmodule
