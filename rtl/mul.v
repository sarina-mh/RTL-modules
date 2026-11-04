// ============================================================================
// ماژول: mul  (ضرب‌کننده)
// ----------------------------------------------------------------------------
// کار کلی:
//   ضرب دو عدد را انجام می‌دهد. عرض نتیجه برابر مجموع عرض دو ورودی است تا
//   سرریز از دست نرود. هم حالت بدون علامت (unsigned) و هم علامت‌دار (signed)
//   با پارامتر SIGNED پشتیبانی می‌شود.
//
// پارامترها:
//   A_WIDTH : عرض عملوند a (پیش‌فرض 8)
//   B_WIDTH : عرض عملوند b (پیش‌فرض 8)
//   P_WIDTH : عرض حاصل‌ضرب (پیش‌فرض A_WIDTH + B_WIDTH)
//   SIGNED  : 0 = بدون علامت، 1 = علامت‌دار (پیش‌فرض 0)
//
// ورودی‌ها:
//   a : عملوند اول  (عرض A_WIDTH)
//   b : عملوند دوم  (عرض B_WIDTH)
//
// خروجی‌ها:
//   p : حاصل‌ضرب (عرض P_WIDTH)
// ============================================================================
module mul #(
    parameter A_WIDTH = 8,
    parameter B_WIDTH = 8,
    parameter P_WIDTH = A_WIDTH + B_WIDTH,
    parameter SIGNED  = 0
)(
    input  wire [A_WIDTH-1:0] a,
    input  wire [B_WIDTH-1:0] b,
    output wire [P_WIDTH-1:0] p
);

    generate
        if (SIGNED) begin : g_signed
            // ضرب علامت‌دار (مکمل دو)
            assign p = $signed(a) * $signed(b);
        end else begin : g_unsigned
            // ضرب بدون علامت
            assign p = a * b;
        end
    endgenerate

endmodule
