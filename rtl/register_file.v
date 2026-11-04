// ============================================================================
// Module: register_file  (Register file)
// ----------------------------------------------------------------------------
// Description:
//   An array of DEPTH registers, each WIDTH bits wide. It has one write port
//   and two read ports (asynchronous/combinational read). rst clears all
//   registers to zero.
//
// Parameters:
//   WIDTH      : Width of each register (default 32)
//   DEPTH      : Number of registers (default 32)
//   ADDR_WIDTH : Address width; automatically ceil(log2(DEPTH))
//
// Inputs:
//   clk    : Clock
//   rst    : Asynchronous reset, active high (clears all registers)
//   we     : Write enable
//   waddr  : Write address
//   wdata  : Write data
//   raddr1 : Read address, port 1
//   raddr2 : Read address, port 2
//
// Outputs:
//   rdata1 : Read data, port 1
//   rdata2 : Read data, port 2
// ============================================================================
module register_file #(
    parameter WIDTH      = 32,
    parameter DEPTH      = 32,
    parameter ADDR_WIDTH = $clog2(DEPTH)
)(
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  we,
    input  wire [ADDR_WIDTH-1:0] waddr,
    input  wire [WIDTH-1:0]      wdata,
    input  wire [ADDR_WIDTH-1:0] raddr1,
    input  wire [ADDR_WIDTH-1:0] raddr2,
    output wire [WIDTH-1:0]      rdata1,
    output wire [WIDTH-1:0]      rdata2
);

    // Register array
    reg [WIDTH-1:0] mem [0:DEPTH-1];

    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < DEPTH; i = i + 1)
                mem[i] <= {WIDTH{1'b0}};
        end else if (we) begin
            mem[waddr] <= wdata;
        end
    end

    // Combinational (asynchronous) read
    assign rdata1 = mem[raddr1];
    assign rdata2 = mem[raddr2];

endmodule
