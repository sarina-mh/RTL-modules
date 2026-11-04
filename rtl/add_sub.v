// ============================================================================
// ماژول: add_sub  (جمع/تفریق با فلگ)
// ----------------------------------------------------------------------------
// کار کلی:
//   همانطور که خودت گفتی، جدا ساختن جمع و تفریق کمی بی‌مزه است؛ این ماژول
//   هر دو را با یک فلگ (sub_flag) انجام می‌دهد.
//     sub_flag = 0  =>  result = a + b + cin
//     sub_flag = 1  =>  result = a - b - cin
//
// پارامترها:
//   WIDTH : عرض بیت عملوندها و نتیجه (پیش‌فرض 8)
//
// ورودی‌ها:
//   a        : عملوند اول (عرض WIDTH)
//   b        : عملوند دوم (عرض WIDTH)
//   sub_flag : انتخاب عملیات؛ 0 = جمع، 1 = تفریق
//   cin      : رقم نقلی/قرض ورودی
//
// خروجی‌ها:
//   result   : نتیجه‌ی جمع یا تفریق (عرض WIDTH)
//   cout     : رقم نقلی/قرض خروجی
//   overflow : سرریز علامت‌دار (بسته به عملیات)
// ============================================================================
module add_sub #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    input  wire             sub_flag,
    input  wire             cin,
    output reg  [WIDTH-1:0] result,
    output reg              cout,
    output reg              overflow
);

    always @(*) begin
        if (!sub_flag) begin
            // حالت جمع
            {cout, result} = {1'b0, a} + {1'b0, b} + cin;
            overflow = (a[WIDTH-1] == b[WIDTH-1]) &&
                       (result[WIDTH-1] != a[WIDTH-1]);
        end else begin
            // حالت تفریق
            {cout, result} = {1'b0, a} - {1'b0, b} - cin;
            overflow = (a[WIDTH-1] != b[WIDTH-1]) &&
                       (result[WIDTH-1] != a[WIDTH-1]);
        end
    end

endmodule
