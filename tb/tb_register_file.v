// ============================================================================
// Testbench: tb_register_file
// Checks writes, both asynchronous read ports, and write-enable behavior.
// ============================================================================
`timescale 1ns/1ps

module tb_register_file;
    parameter WIDTH      = 8;
    parameter DEPTH      = 4;
    parameter ADDR_WIDTH = 2;

    reg                    clk;
    reg                    rst;
    reg                    we;
    reg  [ADDR_WIDTH-1:0]  waddr;
    reg  [WIDTH-1:0]       wdata;
    reg  [ADDR_WIDTH-1:0]  raddr1;
    reg  [ADDR_WIDTH-1:0]  raddr2;
    wire [WIDTH-1:0]       rdata1;
    wire [WIDTH-1:0]       rdata2;

    integer errors;
    integer i;

    register_file #(
        .WIDTH(WIDTH), .DEPTH(DEPTH), .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .clk(clk), .rst(rst), .we(we),
        .waddr(waddr), .wdata(wdata),
        .raddr1(raddr1), .raddr2(raddr2),
        .rdata1(rdata1), .rdata2(rdata2)
    );

    always #5 clk = ~clk;

    task write_reg;
        input [ADDR_WIDTH-1:0] addr;
        input [WIDTH-1:0]      data;
        begin
            we    = 1'b1;
            waddr = addr;
            wdata = data;
            @(posedge clk); #1;
            we = 1'b0;
        end
    endtask

    task check_read;
        input [ADDR_WIDTH-1:0] addr1;
        input [ADDR_WIDTH-1:0] addr2;
        input [WIDTH-1:0]      exp1;
        input [WIDTH-1:0]      exp2;
        begin
            raddr1 = addr1;
            raddr2 = addr2;
            #1;
            if (rdata1 !== exp1) begin
                $display("FAIL register_file read1: addr=%0d got=%h expected=%h",
                         addr1, rdata1, exp1);
                errors = errors + 1;
            end
            if (rdata2 !== exp2) begin
                $display("FAIL register_file read2: addr=%0d got=%h expected=%h",
                         addr2, rdata2, exp2);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        clk    = 1'b0;
        rst    = 1'b1;
        we     = 1'b0;
        waddr  = {ADDR_WIDTH{1'b0}};
        wdata  = {WIDTH{1'b0}};
        raddr1 = {ADDR_WIDTH{1'b0}};
        raddr2 = {ADDR_WIDTH{1'b0}};
        errors = 0;

        #12;
        // All registers cleared
        for (i = 0; i < DEPTH; i = i + 1) begin
            raddr1 = i;
            raddr2 = i;
            #1;
            if (rdata1 !== 0 || rdata2 !== 0) begin
                $display("FAIL register_file reset: addr=%0d rdata1=%h rdata2=%h",
                         i, rdata1, rdata2);
                errors = errors + 1;
            end
        end

        rst = 1'b0;

        // Write all registers
        write_reg(2'd0, 8'h11);
        write_reg(2'd1, 8'h22);
        write_reg(2'd2, 8'h33);
        write_reg(2'd3, 8'h44);

        check_read(2'd0, 2'd2, 8'h11, 8'h33);
        check_read(2'd3, 2'd1, 8'h44, 8'h22);
        check_read(2'd1, 2'd1, 8'h22, 8'h22);

        // Overwrite one register
        write_reg(2'd0, 8'hAA);
        check_read(2'd0, 2'd3, 8'hAA, 8'h44);

        // Write disabled: data must not change
        we    = 1'b0;
        waddr = 2'd1;
        wdata = 8'h55;
        @(posedge clk); #1;
        check_read(2'd1, 2'd0, 8'h22, 8'hAA);

        if (errors == 0)
            $display("tb_register_file: PASS");
        else
            $display("tb_register_file: FAIL (%0d errors)", errors);

        $finish;
    end
endmodule
