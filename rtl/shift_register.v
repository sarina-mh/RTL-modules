// ============================================================================
// ماژول: shift_register  (شیفت رجیستر)
// ----------------------------------------------------------------------------
// کار کلی:
//   یک شیفت رجیستر با کنترل‌های خواسته‌شده است:
//     init     : مقدار رجیستر را به INIT_VALUE برمی‌گرداند (مقداردهی اولیه)
//     load_reg : بارگذاری موازی از parallel_in
//     shift_en : فعال‌کردن شیفت (با هر کلاک یک بیت شیفت می‌دهد)
//   اولویت‌ها: rst > init > load_reg > shift_en
//   جهت شیفت با پارامتر DIR انتخاب می‌شود.
//
// پارامترها:
//   WIDTH      : عرض رجیستر (پیش‌فرض 8)
//   DIR        : 0 = شیفت به راست، 1 = شیفت به چپ (پیش‌فرض 0)
//   INIT_VALUE : مقداری که با init در رجیستر قرار می‌گیرد (پیش‌فرض 0)
//
// ورودی‌ها:
//   clk         : کلاک
//   rst         : ریست غیرهمگام (فعال سطح بالا)
//   shift_en    : فعال‌کننده‌ی شیفت
//   init        : مقداردهی اولیه
//   load_reg    : بارگذاری موازی
//   serial_in   : بیتی که در هر شیفت وارد رجیستر می‌شود
//   parallel_in : داده‌ی بارگذاری موازی (عرض WIDTH)
//
// خروجی‌ها:
//   q         : مقدار رجیستر (عرض WIDTH)
//   serial_out: بیتی که از سمت مقابل خارج می‌شود
// ============================================================================
module shift_register #(
    parameter WIDTH      = 8,
    parameter DIR        = 0,
    parameter INIT_VALUE = 0
)(
    input  wire             clk,
    input  wire             rst,
    input  wire             shift_en,
    input  wire             init,
    input  wire             load_reg,
    input  wire             serial_in,
    input  wire [WIDTH-1:0] parallel_in,
    output reg  [WIDTH-1:0] q,
    output wire             serial_out
);

    // بیت خروجی سریال از سمتی که شیفت به آن سمت است.
    assign serial_out = (DIR == 0) ? q[0] : q[WIDTH-1];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            q <= INIT_VALUE;
        end else if (init) begin
            q <= INIT_VALUE;
        end else if (load_reg) begin
            q <= parallel_in;
        end else if (shift_en) begin
            if (DIR == 0)
                q <= {serial_in, q[WIDTH-1:1]};   // شیفت راست
            else
                q <= {q[WIDTH-2:0], serial_in};   // شیفت چپ
        end
    end

endmodule
