# گزارش نهایی تست

تاریخ گزارش (تهران): 2026-11-04

84 ماژول در فایل‌های مستقل، با کامنت انگلیسی و پارامترهای مستند. تمام هفت مجموعهٔ تست و lint زبان Verilog-2005 پاس شدند.

| مجموعه | نتیجه | زمان اجرای محلی، شامل build (ثانیه) |
|---|---|---|
| combinational | PASS | 27.35 |
| sequential | PASS | 1.81 |
| algorithms | PASS | 25.72 |
| floating_point | PASS | 33.78 |
| sorting | PASS | 2.25 |
| numerical | PASS | 2.98 |
| exam_algorithms | PASS | 1.78 |

## خروجی واقعی شبیه‌ساز

### combinational

```text
PASS combinational W=1 N=1 cases=4
PASS combinational W=4 N=3 cases=256
PASS combinational W=16 N=8 cases=24000
PASS combinational W=8 N=5 cases=24000
PASS tb_combinational
```

### sequential

```text
PASS sequential/memory/FIFO W=8 depth=8 latency=2 cycles=1800
PASS sequential/memory/FIFO W=8 depth=3 latency=3 cycles=1800
PASS sequential/memory/FIFO W=1 depth=1 latency=1 cycles=1800
PASS sequence P=1 overlap=1 cycles=2000
PASS sequence P=4 overlap=0 cycles=2000
PASS sequence P=4 overlap=1 cycles=2000
PASS tb_sequential
```

### algorithms

```text
PASS sorts/extrema/array_sum W=1 N=1 signed=0 cases=200
PASS sorts/extrema/array_sum W=13 N=5 signed=1 cases=200
PASS sorts/extrema/array_sum W=8 N=8 signed=0 cases=200
PASS tb_algorithms: 4096 GCD/multiply/divide transactions
```

### floating_point

```text
PASS floating_point E=3 F=2 vectors=4096 operations=4 stalls=1885
PASS floating_point E=8 F=23 vectors=16676 operations=4 stalls=7671
PASS floating_point E=5 F=10 vectors=70308 operations=4 stalls=32350
PASS tb_floating_point
```

### sorting

```text
PASS sorting W=1 N=1 signed=0 arrays=100 methods=18 extra_configs=2
PASS sorting W=4 N=4 signed=1 arrays=100 methods=18 extra_configs=2
PASS sorting W=4 N=5 signed=0 arrays=100 methods=18 extra_configs=2
PASS sorting W=8 N=8 signed=0 arrays=100 methods=18 extra_configs=2
PASS sorting W=8 N=8 signed=1 arrays=100 methods=18 extra_configs=2
PASS tb_sorting
```

### numerical

```text
PASS DFT/FFT N=1 Q=12 inverse=0 cases=24 max_error_LSB=0 tolerance=12
PASS Fourier series H=0 Q=12 phases=64 max_error_LSB=0
PASS Fourier series H=3 Q=20 phases=64 max_error_LSB=3
PASS DFT/FFT N=4 Q=12 inverse=1 cases=24 max_error_LSB=1 tolerance=24
PASS Fourier series H=8 Q=12 phases=64 max_error_LSB=5
PASS DFT/FFT N=8 Q=20 inverse=0 cases=24 max_error_LSB=4 tolerance=40
PASS Taylor/exp W=32 Q=20 cases=260 max_error_LSB=29 tolerance=64
PASS Taylor/exp W=16 Q=12 cases=260 max_error_LSB=5 tolerance=64
PASS DFT/FFT N=16 Q=12 inverse=0 cases=24 max_error_LSB=10 tolerance=72
PASS DFT/FFT N=64 Q=20 inverse=0 cases=24 max_error_LSB=38 tolerance=264
PASS tb_numerical
```

### exam_algorithms

```text
PASS exam arrays W=1 N=1 signed=0 cases=160 modules=8
PASS exam arrays W=8 N=5 signed=1 cases=160 modules=8
PASS exam arrays W=8 N=8 signed=0 cases=160 modules=8
PASS tb_exam_algorithms scalar_cases=1200 modules=4
```

## دامنهٔ آزمون‌ها

- بلوک‌های پایه با عرض‌های ۱، ۴، ۸ و ۱۶؛ حافظه/FIFO با عمق ۱،۳،۸؛ reset، enable، full/empty و read-first.
- ۱۸ مرتب‌سازی روی ۵ پیکربندی و هر کدام ۱۰۰ آرایه؛ signed/unsigned، تکراری، مرتب، معکوس و تصادفی. Bitonic فقط روی N توان دو تست می‌شود. DEPTH=0 برای IntroSort و RUN=1 برای TimSort نیز جدا تست می‌شوند؛ TimSort نسخهٔ آموزشی fixed-run است.
- ۴۸۰ مجموعهٔ برداری برای جست‌وجو، reverse، prefix sum، dot product، ضرب ماتریس مستطیلی، هورنر و کانولوشن؛ ۱۲۰۰ مورد برای توان، فاکتوریل، فیبوناچی و جذر.
- FP: مجموع ۹۱٬۰۸۰ جفت ورودی × ۴ عمل = ۳۶۴٬۳۲۰ نتیجهٔ مرجع؛ هم مسیر ترکیبی و هم stream بررسی می‌شوند. مرجع با Fraction دقیق و nearest-even، همراه cross-check مستقل struct است.
- Taylor/exp: دو قالب عددی، هر کدام ۲۶۰ ورودی؛ مرجع math پایتون، حد پذیرش ۶۴ LSB با ۱۲ جمله؛ domain error، saturation و reset نیز بررسی می‌شوند.
- Fourier series: تمام ۶۴ فاز برای H=0،3،8؛ مرجع مستقل مجموع sin/cos پایتون.
- DFT/FFT: اندازه‌های ۱،۴،۸،۱۶،۶۴، forward و inverse، ورودی صفر/ضربه/DC/کسینوسی/مختلط تصادفی؛ مرجع cmath. overflow و اشباع و reset جدا تست می‌شوند.
- همهٔ topها با parser سخت‌گیر Verilog-2005 بررسی شدند؛ خطای latch، multiple-driver یا حلقهٔ ترکیبی گزارش نشده است. هشدارهای عرض برای تبدیل‌های عمدی و پارامترهای integer در log کامپایل وجود دارند.

## بازتولید

```bash
python3 run_tests.py
python3 check_lint.py
python3 write_report.py
python3 package_reference.py
```

خلاصهٔ ماشینی: results.json، lint_results.json، vector_manifest.json و numeric_vector_manifest.json. هش منابع با نرمال‌سازی پایان‌خط LF در source_hashes.json است. خروجی کامل محلی build/*.txt است؛ بردارهای بزرگ با اسکریپت بازتولید می‌شوند. CI نیز همین فرمان‌ها را روی Linux اجرا می‌کند.

## حدود ارزیابی

محیط تولید گزارش: Windows؛ Verilator 5.050 2026-07-01 rev vUNKNOWN-built20260702. آزمون ۴حالته، اثبات رسمی، synthesis، مساحت یا timing انجام نشده است. مجموعهٔ جدید از ماژول‌های قدیمی ریشهٔ ریپو جداست؛ این گزارش وضعیت تست مجموعهٔ midterm_reference را بیان می‌کند.

نتایج FP16/FP32 شامل تمام جفت‌های ورودی نیستند. تیلور و فوریه تقریب fixed-point با بازه و خطای مستند هستند؛ حدود Q، تعداد جمله، اندازهٔ تبدیل و headroom در NUMERICAL.md آمده است. تقسیم FP و ضرب‌های عددی می‌توانند سخت‌افزار بزرگی بسازند. این کتابخانه پرچم exception و rounding mode اضافی IEEE را پیاده نکرده است.

اصلاح ابزار محلی: استفاده از -O2 برای رفع خطای لینک GCC/libstdc++ با -Os. نگهداری signedness در MAC و استفاده از مرجع rank مستقل در تست سورت نیز در آزمون‌های قبلی بررسی و اصلاح شده‌اند. مرجع تشخیص دنباله prefix/suffix است؛ در مرجع FIFO مقدار برگشتی pop استفاده می‌شود تا شبیه‌سازهای قدیمی‌تر اثر جانبی آن را حذف نکنند.
