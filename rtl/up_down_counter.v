// ============================================================================
// ماژول: up_down_counter  (شمارنده‌ی بالا/پایین)
// ----------------------------------------------------------------------------
// کار کلی:
//   یک شمارنده‌ی بالا/پایین با محدوده‌ی قابل تنظیم است.
//   - count_up = 1 : به سمت بالا می‌شمارد
//   - count_up = 0 : به سمت پایین می‌شمارد
//   - count_en = 1 : شمارش فعال است
//   - serial_in    : رقم نقلی/ورودی سریالی برای زنجیره‌کردن شمارنده‌ها
//                    (اگر بخواهی شمارنده به‌تنهایی کار کند آن را 1 بگذار)
//   - done         : رسیدن به آخرین حالت (در حالت بالا: MAX_VALUE و در حالت
//                    پایین: MIN_VALUE)
//   در رسیدن به مرز، شمارنده دور می‌زند (Wrap).
//
// پارامترها:
//   WIDTH     : عرض شمارنده (پیش‌فرض 8)
//   MIN_VALUE : کمترین مقدار (پیش‌فرض 0)
//   MAX_VALUE : بیشترین مقدار (پیش‌فرض 2^WIDTH - 1)
//
// ورودی‌ها:
//   clk       : کلاک
//   rst       : ریست غیرهمگام (فعال سطح بالا) که مقدار را MIN_VALUE می‌کند
//   count_en  : فعال‌کننده‌ی شمارش
//   count_up  : جهت شمارش؛ 1 = بالا، 0 = پایین
//   serial_in : رقم نقلی ورودی / فعال‌کننده‌ی سریالی
//
// خروجی‌ها:
//   value : مقدار جاری شمارنده
//   done  : رسیدن به مرز شمارش
// ============================================================================
module up_down_counter #(
    parameter WIDTH     = 8,
    parameter MIN_VALUE = 0,
    parameter MAX_VALUE = (1 << WIDTH) - 1
)(
    input  wire             clk,
    input  wire             rst,
    input  wire             count_en,
    input  wire             count_up,
    input  wire             serial_in,
    output reg  [WIDTH-1:0] value,
    output wire             done
);

    // done بسته به جهت شمارش، رسیدن به سقف یا کف را نشان می‌دهد.
    assign done = count_up ? (value == MAX_VALUE) : (value == MIN_VALUE);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            value <= MIN_VALUE;
        end else if (count_en && serial_in) begin
            if (count_up) begin
                if (value >= MAX_VALUE)
                    value <= MIN_VALUE;   // دور زدن در سقف
                else
                    value <= value + 1'b1;
            end else begin
                if (value <= MIN_VALUE)
                    value <= MAX_VALUE;   // دور زدن در کف
                else
                    value <= value - 1'b1;
            end
        end
    end

endmodule
