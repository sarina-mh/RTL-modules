// Iterative radix-2 DIT FFT/IFFT; bit-reversed input loading, natural output.
// N in {1,2,4,8,16,32,64}; one butterfly per cycle; fixed-point W/Q.
// Forward is unnormalized. Inverse divides the final result by N.
// Intermediate butterfly overflow SATURATES and sets sticky overflow; inputs
// need sufficient headroom because inverse normalization happens at the end.

// =====================================================================
// fft_radix2: complete controller + datapath + top in one Verilog file.
// Pulse start while busy=0. Inputs are latched on the accepting edge.
// Reset and port conventions are preserved from the original module.
// Packed array lane i occupies bits [i*W +: W], unless stated otherwise.
// =====================================================================
// control[0]: for(k=0; k<N; k=k+1) begin re[reversed(k)] <= real_in[(k * W) +: W]; im[reversed(k)] <= imag_in[(k * W) +: W]; end
// control[1]: span <= 2;
// control[2]: base <= 0;
// control[3]: j <= 0;
// control[4]: overflow <= 0;
// control[5]: for(k=0; k<N; k=k+1) begin real_out[(k * W) +: W] <= (INVERSE)? $signed(re[k]) / N : re[k]; imag_out[(k * W) +: W] <= (INVERSE)? $signed(im[k]) / N : im[k]; end
// control[6]: re[upper] <= clip(ar);
// control[7]: im[upper] <= clip(ai);
// control[8]: re[lower] <= clip(br);
// control[9]: im[lower] <= clip(bi);
// control[10]: overflow <= 1;
// control[11]: j <= 0;
// control[12]: base <= 0;
// control[13]: span <= span * 2;
// control[14]: base <= base + span;
// control[15]: j <= j + 1;

// ---------------- CONTROLLER ----------------
module fft_radix2_controller #
(
  parameter W = 32,
  parameter Q = 20,
  parameter N = 8,
  parameter INVERSE = 0
)
(
  input clk,
  input rst_n,
  input start,
  input [10:0] status,
  output reg [15:0] control,
  output reg busy,
  output reg done);
localparam LOGN = (N > 1)? $clog2(N) : 0;
localparam signed [63:0] MAXIMUM = (64'sd1 << W - 1) - 1;
localparam signed [63:0] MINIMUM = -(64'sd1 << W - 1);
reg reporting;
reg next_busy;
reg next_done;
reg next_reporting;

// FSM state/handshake registers; all data writes are control strobes.

always @(posedge clk) if(!rst_n) begin
  busy <= 0;
  done <= 0;
  reporting <= 0;
end else begin
  busy <= next_busy;
  done <= next_done;
  reporting <= next_reporting;
end


always @(*) begin
  next_busy = busy;
  next_done = done;
  next_reporting = reporting;
  control = 0;
  begin
    next_done = 0;
    if(start && !busy) begin
      control[0] = 1'b1;
      control[1] = 1'b1;
      control[2] = 1'b1;
      control[3] = 1'b1;
      next_reporting = N == 1;
      next_busy = 1;
      control[4] = 1'b1;
    end else if(busy) begin
      if(reporting) begin
        control[5] = 1'b1;
        next_busy = 0;
        next_done = 1;
      end else begin
        control[6] = 1'b1;
        control[7] = 1'b1;
        control[8] = 1'b1;
        control[9] = 1'b1;
        if(status[0] || status[1] || status[2] || status[3] || status[4] || status[5] || status[6] || status[7]) control[10] = 1'b1;
        if(status[8]) begin
          control[11] = 1'b1;
          if(status[9]) begin
            control[12] = 1'b1;
            if(status[10]) next_reporting = 1;
            else control[13] = 1'b1;
          end else control[14] = 1'b1;
        end else control[15] = 1'b1;
      end
    end
  end
end

endmodule

// ---------------- DATAPATH ----------------
module fft_radix2_datapath #
(
  parameter W = 32,
  parameter Q = 20,
  parameter N = 8,
  parameter INVERSE = 0
)
(
  input clk,
  input rst_n,
  input [N*W-1:0] real_in,
  input [N*W-1:0] imag_in,
  input [15:0] control,
  output [10:0] status,
  output reg [N*W-1:0] real_out,
  output reg [N*W-1:0] imag_out,
  output reg overflow);
localparam LOGN = (N > 1)? $clog2(N) : 0;
localparam signed [63:0] MAXIMUM = (64'sd1 << W - 1) - 1;
localparam signed [63:0] MINIMUM = -(64'sd1 << W - 1);
reg signed [W-1:0] re [0:N-1];
reg signed [W-1:0] im [0:N-1];
integer span;
integer base;
integer j;
integer k;
integer upper;
integer lower;
wire [5:0] phase;
assign phase = j * (64 / span);
wire signed [W-1:0] wr;
wire signed [W-1:0] wi_forward;
wire signed [W-1:0] wi;
assign wi = (INVERSE)? -wi_forward : wi_forward;
reg signed [127:0] pr;
reg signed [127:0] pi;
reg signed [63:0] tr;
reg signed [63:0] ti;
reg signed [63:0] ar;
reg signed [63:0] ai;
reg signed [63:0] br;
reg signed [63:0] bi;

fft_radix2_helper_twiddle_rom
#(
  W,
  Q
)
table_rom
(
  phase,
  wr,
  wi_forward
);


function [31:0] reversed;
  input [31:0] value;
  integer bit_index;
  begin
    reversed = 0;
    for(bit_index=0; bit_index<LOGN; bit_index=bit_index+1) reversed = (reversed << 1) | (value >> bit_index) & 1;
  end
endfunction


function [W-1:0] clip;
  input signed [63:0] value;
  begin
    if(value > MAXIMUM) clip = MAXIMUM;
    else if(value < MINIMUM) clip = MINIMUM;
    else clip = value;
  end
endfunction


always @(*) begin
  upper = base + j;
  lower = base + j + span / 2;
  pr = 0;
  pi = 0;
  tr = 0;
  ti = 0;
  ar = 0;
  ai = 0;
  br = 0;
  bi = 0;
  if((upper < N) && (lower < N)) begin
    pr = $signed(re[lower]) * $signed(wr) - $signed(im[lower]) * $signed(wi);
    pi = $signed(re[lower]) * $signed(wi) + $signed(im[lower]) * $signed(wr);
    tr = pr >>> Q;
    ti = pi >>> Q;
    ar = $signed(re[upper]) + tr;
    ai = $signed(im[upper]) + ti;
    br = $signed(re[upper]) - tr;
    bi = $signed(im[upper]) - ti;
  end
end


// Status predicates are generated by the datapath, never by the FSM.
assign status[0] = (ar > MAXIMUM);
assign status[1] = (ar < MINIMUM);
assign status[2] = (ai > MAXIMUM);
assign status[3] = (ai < MINIMUM);
assign status[4] = (br > MAXIMUM);
assign status[5] = (br < MINIMUM);
assign status[6] = (bi > MAXIMUM);
assign status[7] = (bi < MINIMUM);
assign status[8] = (j == span / 2 - 1);
assign status[9] = (base + span >= N);
assign status[10] = (span == N);

// Register-transfer operations. Later strobes retain nonblocking
// assignment priority when the same destination is written twice.

always @(posedge clk) if(!rst_n) begin
  real_out <= 0;
  imag_out <= 0;
  overflow <= 0;
  span <= 2;
  base <= 0;
  j <= 0;
  for(k=0; k<N; k=k+1) begin
    re[k] <= 0;
    im[k] <= 0;
  end
end else begin
  if(control[0]) begin
    for(k=0; k<N; k=k+1) begin
      re[reversed(k)] <= real_in[(k * W) +: W];
      im[reversed(k)] <= imag_in[(k * W) +: W];
    end
  end
  if(control[1]) begin
    span <= 2;
  end
  if(control[2]) begin
    base <= 0;
  end
  if(control[3]) begin
    j <= 0;
  end
  if(control[4]) begin
    overflow <= 0;
  end
  if(control[5]) begin
    for(k=0; k<N; k=k+1) begin
      real_out[(k * W) +: W] <= (INVERSE)? $signed(re[k]) / N : re[k];
      imag_out[(k * W) +: W] <= (INVERSE)? $signed(im[k]) / N : im[k];
    end
  end
  if(control[6]) begin
    re[upper] <= clip(ar);
  end
  if(control[7]) begin
    im[upper] <= clip(ai);
  end
  if(control[8]) begin
    re[lower] <= clip(br);
  end
  if(control[9]) begin
    im[lower] <= clip(bi);
  end
  if(control[10]) begin
    overflow <= 1;
  end
  if(control[11]) begin
    j <= 0;
  end
  if(control[12]) begin
    base <= 0;
  end
  if(control[13]) begin
    span <= span * 2;
  end
  if(control[14]) begin
    base <= base + span;
  end
  if(control[15]) begin
    j <= j + 1;
  end
end

endmodule

// ---------------- TOP ----------------
module fft_radix2 #
(
  parameter W = 32,
  parameter Q = 20,
  parameter N = 8,
  parameter INVERSE = 0
)
(
  input clk,
  input rst_n,
  input start,
  input [N*W-1:0] real_in,
  input [N*W-1:0] imag_in,
  output [N*W-1:0] real_out,
  output [N*W-1:0] imag_out,
  output busy,
  output done,
  output overflow);
wire [15:0] control;
wire [10:0] status;
fft_radix2_controller #(.W(W), .Q(Q), .N(N), .INVERSE(INVERSE)) controller (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .status(status),
    .control(control),
    .busy(busy),
    .done(done)
);
fft_radix2_datapath #(.W(W), .Q(Q), .N(N), .INVERSE(INVERSE)) datapath (
    .clk(clk),
    .rst_n(rst_n),
    .real_in(real_in),
    .imag_in(imag_in),
    .control(control),
    .status(status),
    .real_out(real_out),
    .imag_out(imag_out),
    .overflow(overflow)
);
endmodule


// ---------------- PRIVATE HELPERS ----------------
module fft_radix2_helper_twiddle_rom #(parameter W=32,Q=20)(input [5:0] phase,
    output reg signed [W-1:0] real_part,imag_part);
    reg signed [63:0] r,i;
    always @*begin
        r=0;i=0;
        case(phase)
            6'd0:begin r=64'sd1073741824;i=64'sd0;end
            6'd1:begin r=64'sd1068571464;i=-64'sd105245103;end
            6'd2:begin r=64'sd1053110176;i=-64'sd209476638;end
            6'd3:begin r=64'sd1027506862;i=-64'sd311690799;end
            6'd4:begin r=64'sd992008094;i=-64'sd410903207;end
            6'd5:begin r=64'sd946955747;i=-64'sd506158392;end
            6'd6:begin r=64'sd892783698;i=-64'sd596538995;end
            6'd7:begin r=64'sd830013654;i=-64'sd681174602;end
            6'd8:begin r=64'sd759250125;i=-64'sd759250125;end
            6'd9:begin r=64'sd681174602;i=-64'sd830013654;end
            6'd10:begin r=64'sd596538995;i=-64'sd892783698;end
            6'd11:begin r=64'sd506158392;i=-64'sd946955747;end
            6'd12:begin r=64'sd410903207;i=-64'sd992008094;end
            6'd13:begin r=64'sd311690799;i=-64'sd1027506862;end
            6'd14:begin r=64'sd209476638;i=-64'sd1053110176;end
            6'd15:begin r=64'sd105245103;i=-64'sd1068571464;end
            6'd16:begin r=64'sd0;i=-64'sd1073741824;end
            6'd17:begin r=-64'sd105245103;i=-64'sd1068571464;end
            6'd18:begin r=-64'sd209476638;i=-64'sd1053110176;end
            6'd19:begin r=-64'sd311690799;i=-64'sd1027506862;end
            6'd20:begin r=-64'sd410903207;i=-64'sd992008094;end
            6'd21:begin r=-64'sd506158392;i=-64'sd946955747;end
            6'd22:begin r=-64'sd596538995;i=-64'sd892783698;end
            6'd23:begin r=-64'sd681174602;i=-64'sd830013654;end
            6'd24:begin r=-64'sd759250125;i=-64'sd759250125;end
            6'd25:begin r=-64'sd830013654;i=-64'sd681174602;end
            6'd26:begin r=-64'sd892783698;i=-64'sd596538995;end
            6'd27:begin r=-64'sd946955747;i=-64'sd506158392;end
            6'd28:begin r=-64'sd992008094;i=-64'sd410903207;end
            6'd29:begin r=-64'sd1027506862;i=-64'sd311690799;end
            6'd30:begin r=-64'sd1053110176;i=-64'sd209476638;end
            6'd31:begin r=-64'sd1068571464;i=-64'sd105245103;end
            6'd32:begin r=-64'sd1073741824;i=64'sd0;end
            6'd33:begin r=-64'sd1068571464;i=64'sd105245103;end
            6'd34:begin r=-64'sd1053110176;i=64'sd209476638;end
            6'd35:begin r=-64'sd1027506862;i=64'sd311690799;end
            6'd36:begin r=-64'sd992008094;i=64'sd410903207;end
            6'd37:begin r=-64'sd946955747;i=64'sd506158392;end
            6'd38:begin r=-64'sd892783698;i=64'sd596538995;end
            6'd39:begin r=-64'sd830013654;i=64'sd681174602;end
            6'd40:begin r=-64'sd759250125;i=64'sd759250125;end
            6'd41:begin r=-64'sd681174602;i=64'sd830013654;end
            6'd42:begin r=-64'sd596538995;i=64'sd892783698;end
            6'd43:begin r=-64'sd506158392;i=64'sd946955747;end
            6'd44:begin r=-64'sd410903207;i=64'sd992008094;end
            6'd45:begin r=-64'sd311690799;i=64'sd1027506862;end
            6'd46:begin r=-64'sd209476638;i=64'sd1053110176;end
            6'd47:begin r=-64'sd105245103;i=64'sd1068571464;end
            6'd48:begin r=64'sd0;i=64'sd1073741824;end
            6'd49:begin r=64'sd105245103;i=64'sd1068571464;end
            6'd50:begin r=64'sd209476638;i=64'sd1053110176;end
            6'd51:begin r=64'sd311690799;i=64'sd1027506862;end
            6'd52:begin r=64'sd410903207;i=64'sd992008094;end
            6'd53:begin r=64'sd506158392;i=64'sd946955747;end
            6'd54:begin r=64'sd596538995;i=64'sd892783698;end
            6'd55:begin r=64'sd681174602;i=64'sd830013654;end
            6'd56:begin r=64'sd759250125;i=64'sd759250125;end
            6'd57:begin r=64'sd830013654;i=64'sd681174602;end
            6'd58:begin r=64'sd892783698;i=64'sd596538995;end
            6'd59:begin r=64'sd946955747;i=64'sd506158392;end
            6'd60:begin r=64'sd992008094;i=64'sd410903207;end
            6'd61:begin r=64'sd1027506862;i=64'sd311690799;end
            6'd62:begin r=64'sd1053110176;i=64'sd209476638;end
            6'd63:begin r=64'sd1068571464;i=64'sd105245103;end
            default:begin r=0;i=0;end
        endcase
        real_part=r >>> (30-Q);imag_part=i >>> (30-Q);
    end
endmodule
