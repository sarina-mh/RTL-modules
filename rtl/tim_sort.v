// Educational fixed-run TimSort-style hybrid: insertion-sort RUN-sized chunks,
// then stably merge them bottom-up. This is NOT CPython's adaptive natural-run
// stack/galloping implementation. RUN>=1; one shift/merge/copy per cycle.

// =====================================================================
// tim_sort: complete controller + datapath + top in one Verilog file.
// Pulse start while busy=0. Inputs are latched on the accepting edge.
// Reset and port conventions are preserved from the original module.
// Packed array lane i occupies bits [i*W +: W], unless stated otherwise.
// =====================================================================
// control[0]: for(k=0; k<N; k=k+1) mem[k] <= data_in[(k * W) +: W];
// control[1]: run_start <= 0;
// control[2]: run_end <= (RUN < N)? RUN : N;
// control[3]: i <= 1;
// control[4]: width <= RUN;
// control[5]: left <= 0;
// control[6]: run_start <= run_end;
// control[7]: run_end <= (run_end + RUN < N)? run_end + RUN : N;
// control[8]: i <= run_end + 1;
// control[9]: key <= mem[i];
// control[10]: j <= i - 1;
// control[11]: mem[j + 1] <= mem[j];
// control[12]: j <= j - 1;
// control[13]: mem[j + 1] <= key;
// control[14]: i <= i + 1;
// control[15]: middle <= (left + width < N)? left + width : N;
// control[16]: limit <= (left + 2 * width < N)? left + 2 * width : N;
// control[17]: i <= left;
// control[18]: j <= (left + width < N)? left + width : N;
// control[19]: p <= left;
// control[20]: p <= left;
// control[21]: temp[p] <= mem[i];
// control[22]: i <= i + 1;
// control[23]: temp[p] <= mem[j];
// control[24]: j <= j + 1;
// control[25]: p <= p + 1;
// control[26]: mem[p] <= temp[p];
// control[27]: p <= p + 1;
// control[28]: left <= limit;
// control[29]: width <= width * 2;
// control[30]: left <= 0;
// control[31]: for(k=0; k<N; k=k+1) data_out[(k * W) +: W] <= mem[k];

// ---------------- CONTROLLER ----------------
module tim_sort_controller #
(
  parameter W = 8,
  parameter N = 8,
  parameter SIGNED = 0,
  parameter RUN = 4
)
(
  input clk,
  input rst_n,
  input start,
  input [10:0] status,
  output reg [31:0] control,
  output reg busy,
  output reg done);

reg [3:0] state;
reg next_busy;
reg next_done;
reg [3:0] next_state;

// FSM state/handshake registers; all data writes are control strobes.

always @(posedge clk) if(!rst_n) begin
  busy <= 0;
  done <= 0;
  state <= 0;
end else begin
  busy <= next_busy;
  done <= next_done;
  state <= next_state;
end


always @(*) begin
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
      control[5] = 1'b1;
      next_state = 0;
      next_busy = 1;
    end else if(busy) case(state)
      0: if(status[0]) begin
        if(status[1]) begin
          if(RUN >= N) next_state = 7;
          else next_state = 3;
        end else begin
          control[6] = 1'b1;
          control[7] = 1'b1;
          control[8] = 1'b1;
        end
      end else begin
        control[9] = 1'b1;
        control[10] = 1'b1;
        next_state = 1;
      end
      1: if(status[2] && status[3]) begin
        control[11] = 1'b1;
        control[12] = 1'b1;
      end else begin
        control[13] = 1'b1;
        control[14] = 1'b1;
        next_state = 0;
      end
      3: begin
        control[15] = 1'b1;
        control[16] = 1'b1;
        control[17] = 1'b1;
        control[18] = 1'b1;
        control[19] = 1'b1;
        next_state = 4;
      end
      4: if(status[4]) begin
        control[20] = 1'b1;
        next_state = 5;
      end else begin
        if(status[5] && (status[6] || status[7])) begin
          control[21] = 1'b1;
          control[22] = 1'b1;
        end else begin
          control[23] = 1'b1;
          control[24] = 1'b1;
        end
        control[25] = 1'b1;
      end
      5: begin
        control[26] = 1'b1;
        if(status[8]) next_state = 6;
        else control[27] = 1'b1;
      end
      6: if(status[9]) begin
        control[28] = 1'b1;
        next_state = 3;
      end else if(status[10]) next_state = 7;
      else begin
        control[29] = 1'b1;
        control[30] = 1'b1;
        next_state = 3;
      end
      7: begin
        control[31] = 1'b1;
        next_busy = 0;
        next_done = 1;
      end
      default: next_state = 0;
    endcase
  end
end

endmodule

// ---------------- DATAPATH ----------------
module tim_sort_datapath #
(
  parameter W = 8,
  parameter N = 8,
  parameter SIGNED = 0,
  parameter RUN = 4
)
(
  input clk,
  input rst_n,
  input [N*W-1:0] data_in,
  input [31:0] control,
  output [10:0] status,
  output reg [N*W-1:0] data_out);
reg [W-1:0] mem [0:N-1];
reg [W-1:0] temp [0:N-1];
reg [W-1:0] key;
integer run_start;
integer run_end;
integer i;
integer j;
integer width;
integer left;
integer middle;
integer limit;
integer p;
integer k;

function [0:0] greater;
  input [W-1:0] a;input [W-1:0] b;
  begin
    greater = (SIGNED)? $signed(a) > $signed(b) : a > b;
  end
endfunction


// Status predicates are generated by the datapath, never by the FSM.
assign status[0] = (i >= run_end);
assign status[1] = (run_end == N);
assign status[2] = (j >= run_start);
assign status[3] = greater(mem[(j >= 0)? j : 0], key);
assign status[4] = (p == limit);
assign status[5] = (i < middle);
assign status[6] = (j >= limit);
assign status[7] = (!greater(mem[(i < N)? i : 0], mem[(j < N)? j : 0]));
assign status[8] = (p == limit - 1);
assign status[9] = (limit < N);
assign status[10] = (2 * width >= N);

// Register-transfer operations. Later strobes retain nonblocking
// assignment priority when the same destination is written twice.

always @(posedge clk) if(!rst_n) begin
  data_out <= 0;
  key <= 0;
  run_start <= 0;
  run_end <= 0;
  i <= 0;
  j <= 0;
  width <= RUN;
  left <= 0;
  middle <= 0;
  limit <= 0;
  p <= 0;
  for(k=0; k<N; k=k+1) begin
    mem[k] <= 0;
    temp[k] <= 0;
  end
end else begin
  if(control[0]) begin
    for(k=0; k<N; k=k+1) mem[k] <= data_in[(k * W) +: W];
  end
  if(control[1]) begin
    run_start <= 0;
  end
  if(control[2]) begin
    run_end <= (RUN < N)? RUN : N;
  end
  if(control[3]) begin
    i <= 1;
  end
  if(control[4]) begin
    width <= RUN;
  end
  if(control[5]) begin
    left <= 0;
  end
  if(control[6]) begin
    run_start <= run_end;
  end
  if(control[7]) begin
    run_end <= (run_end + RUN < N)? run_end + RUN : N;
  end
  if(control[8]) begin
    i <= run_end + 1;
  end
  if(control[9]) begin
    key <= mem[i];
  end
  if(control[10]) begin
    j <= i - 1;
  end
  if(control[11]) begin
    mem[j + 1] <= mem[j];
  end
  if(control[12]) begin
    j <= j - 1;
  end
  if(control[13]) begin
    mem[j + 1] <= key;
  end
  if(control[14]) begin
    i <= i + 1;
  end
  if(control[15]) begin
    middle <= (left + width < N)? left + width : N;
  end
  if(control[16]) begin
    limit <= (left + 2 * width < N)? left + 2 * width : N;
  end
  if(control[17]) begin
    i <= left;
  end
  if(control[18]) begin
    j <= (left + width < N)? left + width : N;
  end
  if(control[19]) begin
    p <= left;
  end
  if(control[20]) begin
    p <= left;
  end
  if(control[21]) begin
    temp[p] <= mem[i];
  end
  if(control[22]) begin
    i <= i + 1;
  end
  if(control[23]) begin
    temp[p] <= mem[j];
  end
  if(control[24]) begin
    j <= j + 1;
  end
  if(control[25]) begin
    p <= p + 1;
  end
  if(control[26]) begin
    mem[p] <= temp[p];
  end
  if(control[27]) begin
    p <= p + 1;
  end
  if(control[28]) begin
    left <= limit;
  end
  if(control[29]) begin
    width <= width * 2;
  end
  if(control[30]) begin
    left <= 0;
  end
  if(control[31]) begin
    for(k=0; k<N; k=k+1) data_out[(k * W) +: W] <= mem[k];
  end
end

endmodule

// ---------------- TOP ----------------
module tim_sort #
(
  parameter W = 8,
  parameter N = 8,
  parameter SIGNED = 0,
  parameter RUN = 4
)
(
  input clk,
  input rst_n,
  input start,
  input [N*W-1:0] data_in,
  output [N*W-1:0] data_out,
  output busy,
  output done);
wire [31:0] control;
wire [10:0] status;
tim_sort_controller #(.W(W), .N(N), .SIGNED(SIGNED), .RUN(RUN)) controller (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .status(status),
    .control(control),
    .busy(busy),
    .done(done)
);
tim_sort_datapath #(.W(W), .N(N), .SIGNED(SIGNED), .RUN(RUN)) datapath (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .control(control),
    .status(status),
    .data_out(data_out)
);
endmodule
