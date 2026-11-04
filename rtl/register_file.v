// ============================================================================
// ماژول: register_file  (فایل ثبات)
// ----------------------------------------------------------------------------
// کار کلی:
//   آرایه‌ای از DEPTH ثبات، هر کدام با عرض WIDTH. یک پورت نوشتن و دو پورت
//   خواندن دارد (خواندن ترکیبی/هم‌زمان). با rst همه‌ی ثبات‌ها صفر می‌شوند.
//
// پارامترها:
//   WIDTH      : عرض هر ثبات (پیش‌فرض 32)
//   DEPTH      : تعداد ثبات‌ها (پیش‌فرض 32)
//   ADDR_WIDTH : عرض آدرس؛ به‌صورت خودکار ceil(log2(DEPTH)) (پیش‌فرض محاسبه‌شده)
//
// ورودی‌ها:
//   clk    : کلاک
//   rst    : ریست غیرهمگام (فعال سطح بالا) برای صفر کردن همه‌ی ثبات‌ها
//   we     : فعال‌کننده‌ی نوشتن
//   waddr  : آدرس نوشتن
//   wdata  : داده‌ی نوشتن
//   raddr1 : آدرس پورت خواندن اول
//   raddr2 : آدرس پورت خواندن دوم
//
// خروجی‌ها:
//   rdata1 : داده‌ی پورت خواندن اول
//   rdata2 : داده‌ی پورت خواندن دوم
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

    // آرایه‌ی ثبات‌ها
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

    // خواندن ترکیبی (Asynchronous Read)
    assign rdata1 = mem[raddr1];
    assign rdata2 = mem[raddr2];

endmodule
