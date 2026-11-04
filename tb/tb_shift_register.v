// ============================================================================
// Testbench: tb_shift_register
// Checks right-shift and left-shift instances, parallel load, init, and reset.
// ============================================================================
`timescale 1ns/1ps

module tb_shift_register;
    parameter WIDTH      = 8;
    parameter INIT_VALUE = 8'h5A;

    reg              clk;
    reg              rst;
    reg              shift_en;
    reg              init;
    reg              load_reg;
    reg              serial_in;
    reg  [WIDTH-1:0] parallel_in;

    wire [WIDTH-1:0] q_right;
    wire [WIDTH-1:0] q_left;
    wire             serial_out_right;
    wire             serial_out_left;

    integer errors;

    shift_register #(
        .WIDTH(WIDTH), .DIR(0), .INIT_VALUE(INIT_VALUE)
    ) dut_right (
        .clk(clk), .rst(rst), .shift_en(shift_en), .init(init),
        .load_reg(load_reg), .serial_in(serial_in),
        .parallel_in(parallel_in),
        .q(q_right), .serial_out(serial_out_right)
    );

    shift_register #(
        .WIDTH(WIDTH), .DIR(1), .INIT_VALUE(INIT_VALUE)
    ) dut_left (
        .clk(clk), .rst(rst), .shift_en(shift_en), .init(init),
        .load_reg(load_reg), .serial_in(serial_in),
        .parallel_in(parallel_in),
        .q(q_left), .serial_out(serial_out_left)
    );

    always #5 clk = ~clk;

    initial begin
        clk         = 1'b0;
        rst         = 1'b1;
        shift_en    = 1'b0;
        init        = 1'b0;
        load_reg    = 1'b0;
        serial_in   = 1'b0;
        parallel_in = {WIDTH{1'b0}};
        errors      = 0;

        #12;
        // Reset loads INIT_VALUE
        if (q_right !== INIT_VALUE || q_left !== INIT_VALUE) begin
            $display("FAIL shift_register reset: q_right=%h q_left=%h expected=%h",
                     q_right, q_left, INIT_VALUE);
            errors = errors + 1;
        end

        rst = 1'b0;

        // Parallel load
        parallel_in = 8'hA5;
        load_reg    = 1'b1;
        @(posedge clk); #1;
        if (q_right !== 8'hA5 || q_left !== 8'hA5) begin
            $display("FAIL shift_register load: q_right=%h q_left=%h expected=A5",
                     q_right, q_left);
            errors = errors + 1;
        end
        load_reg = 1'b0;

        // Shift right with serial_in = 1, shift left with serial_in = 1
        shift_en  = 1'b1;
        serial_in = 1'b1;
        @(posedge clk); #1;
        // A5 = 1010_0101
        // right: {1, A5[7:1]} = D2 ; left: {A5[6:0], 1} = 4B
        if (q_right !== 8'hD2) begin
            $display("FAIL shift_register right shift: q_right=%h expected=D2", q_right);
            errors = errors + 1;
        end
        if (q_left !== 8'h4B) begin
            $display("FAIL shift_register left shift: q_left=%h expected=4B", q_left);
            errors = errors + 1;
        end

        // Second shift with serial_in = 0
        serial_in = 1'b0;
        @(posedge clk); #1;
        if (q_right !== 8'h69) begin
            $display("FAIL shift_register right shift 2: q_right=%h expected=69", q_right);
            errors = errors + 1;
        end
        if (q_left !== 8'h96) begin
            $display("FAIL shift_register left shift 2: q_left=%h expected=96", q_left);
            errors = errors + 1;
        end
        shift_en = 1'b0;

        // Init has priority over load/shift
        init        = 1'b1;
        load_reg    = 1'b1;
        shift_en    = 1'b1;
        parallel_in = 8'hFF;
        @(posedge clk); #1;
        if (q_right !== INIT_VALUE || q_left !== INIT_VALUE) begin
            $display("FAIL shift_register init: q_right=%h q_left=%h expected=%h",
                     q_right, q_left, INIT_VALUE);
            errors = errors + 1;
        end

        if (errors == 0)
            $display("tb_shift_register: PASS");
        else
            $display("tb_shift_register: FAIL (%0d errors)", errors);

        $finish;
    end
endmodule
