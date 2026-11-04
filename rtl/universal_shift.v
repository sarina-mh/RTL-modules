// ============================================================================
// ماژول: universal_shift  (شیفت رجیستر همه‌کاره)
// ----------------------------------------------------------------------------
// کار کلی:
//   یک شیفت رجیستر همه‌کاره است که با سیگنال mode چهار عملیات انجام می‌دهد:
//     mode = 00 : نگه‌داشتن مقدار (Hold)
//     mode = 01 : شیفت به راست (Shift Right)
//     mode = 10 : شیفت به چپ  (Shift Left)
//     mode = 11 : بارگذاری موازی (Parallel Load)
//   توجه: در Verilog عملگرهای >> و << هم همین شیفت را انجام می‌دهند، ولی
//   این ماژول نسخه‌ی سخت‌افزاری و قابل سنتز با کنترل کامل است.
//
// پارامترها:
//   WIDTH : عرض رجیستر (پیش‌فرض 8)
//
// ورودی‌ها:
//   clk          : کلاک
//   rst          : ریست همگام/غیرهمگام (اینجا غیرهمگام، فعال سطح بالا)
//   mode         : انتخاب عملیات (2 بیت)
//   serial_right : بیتی که هنگام شیفت راست از سمت MSB وارد می‌شود
//   serial_left  : بیتی که هنگام شیفت چپ از سمت LSB وارد می‌شود
//   parallel_in  : مقدار بارگذاری موازی (عرض WIDTH)
//
// خروجی‌ها:
//   q               : مقدار رجیستر (عرض WIDTH)
//   serial_out_right: بیتی که هنگام شیفت راست از LSB خارج می‌شود
//   serial_out_left : بیتی که هنگام شیفت چپ از MSB خارج می‌شود
// ============================================================================
module universal_shift #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst,
    input  wire [1:0]       mode,
    input  wire             serial_right,
    input  wire             serial_left,
    input  wire [WIDTH-1:0] parallel_in,
    output reg  [WIDTH-1:0] q,
    output wire             serial_out_right,
    output wire             serial_out_left
);

    assign serial_out_right = q[0];
    assign serial_out_left  = q[WIDTH-1];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            q <= {WIDTH{1'b0}};
        end else begin
            case (mode)
                2'b00: q <= q;                                  // Hold
                2'b01: q <= {serial_right, q[WIDTH-1:1]};       // Shift Right
                2'b10: q <= {q[WIDTH-2:0], serial_left};        // Shift Left
                2'b11: q <= parallel_in;                        // Parallel Load
            endcase
        end
    end

endmodule
