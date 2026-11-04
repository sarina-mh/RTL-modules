// ============================================================================
// ماژول: comparator  (مقایسه‌کننده)
// ----------------------------------------------------------------------------
// کار کلی:
//   دو عدد a و b را مقایسه می‌کند و همه‌ی خروجی‌های ممکن مقایسه را به‌طور
//   هم‌زمان تولید می‌کند (ترکیبی).
//
// پارامترها:
//   WIDTH : عرض عملوندها (پیش‌فرض 8)
//
// ورودی‌ها:
//   a : عملوند اول  (عرض WIDTH)
//   b : عملوند دوم  (عرض WIDTH)
//
// خروجی‌ها:
//   eq : a == b
//   ne : a != b
//   gt : a >  b
//   lt : a <  b
//   ge : a >= b
//   le : a <= b
// ============================================================================
module comparator #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    output wire             eq,
    output wire             ne,
    output wire             gt,
    output wire             lt,
    output wire             ge,
    output wire             le
);

    assign eq = (a == b);
    assign ne = (a != b);
    assign gt = (a >  b);
    assign lt = (a <  b);
    assign ge = (a >= b);
    assign le = (a <= b);

endmodule
