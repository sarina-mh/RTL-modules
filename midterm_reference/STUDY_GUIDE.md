# الگوهای حل سؤال RTL برای میان‌ترم

هر مثال یک ماژول مستقل، پارامتری و تست‌شده دارد. تعداد سیکل و قالب عددی باید با صورت سؤال تطبیق داده شود؛ این فهرست پیش‌بینی قطعی سؤال استاد نیست.

## شروع از مثال مناسب

| صورت مسئله | نمونهٔ پیشنهادی |
|---|---|
| حلقه‌های تو در تو، پیدا کردن کمینه و swap | `selection_sort.v` |
| مقایسهٔ همسایه‌ها و شرط پایان | `bubble_sort.v` / `cocktail_sort.v` |
| نگهداری key و شیفت عناصر | `insertion_sort.v` / `shell_sort.v` |
| بازگشت یا تقسیم مسئله | `quick_sort.v` با پشتهٔ صریح / `merge_sort.v` به روش bottom-up |
| ساختمان دادهٔ heap | `heap_sort.v` |
| شمارش فراوانی یا پردازش بیت‌ها | `counting_sort.v` / `radix_sort.v` |
| شبکهٔ compare/swap | `bitonic_sort.v` |
| پیمایش با توقف زودهنگام | `linear_search.v` |
| نصف کردن بازه | `binary_search.v` |
| کاهش آرایه به یک نتیجه | `array_sum.v` / `array_extrema.v` / `dot_product.v` |
| کنترلر و دیتاپث مجزا | `sum_controller.v` + `sum_datapath.v` + `array_sum.v` |
| رابطهٔ بازگشتی عددی | `factorial.v` / `fibonacci.v` / `taylor_series.v` |
| محاسبهٔ چندجمله‌ای | `polynomial_horner.v` |
| توان سریع با پیمایش بیت‌های توان | `integer_power.v` |
| انتخاب بیت‌های جواب | `integer_sqrt.v` |
| پردازش ماتریسی یا سیگنال | `matrix_multiply.v` / `convolution.v` / `dft_fixed.v` |
| gcd و الگوریتم تکرار تا شرط | `gcd.v` |

## ۱۸ مرتب‌سازی موجود

| نام فایل | روش | مرتبهٔ زمانی معمول / بدترین حالت | شرط مهم |
|---|---|---|---|
| `selection_sort.v` | انتخاب کمینه و swap | N² / N² | هر N>=1 |
| `bubble_sort.v` | جابه‌جایی همسایه، خروج زودهنگام | N² / N² | کلیدهای برابر جابه‌جا نمی‌شوند |
| `insertion_sort.v` | درج key در پیشوند مرتب | N² / N² | یک شیفت در هر سیکل |
| `quick_sort.v` | partition و پشتهٔ صریح | N log N / N² | pivot آخر؛ آرایهٔ مرتب می‌تواند کند باشد |
| `merge_sort.v` | ادغام bottom-up | N log N / N log N | حافظهٔ کمکی N کلمه |
| `heap_sort.v` | max-heap | N log N / N log N | درجا |
| `intro_sort.v` | quicksort با fallback به heapsort | N log N / N log N | بودجهٔ عمق؛ DEPTH=0 مستقیماً heap را اجرا می‌کند |
| `tim_sort.v` | نسخهٔ آموزشی run ثابت: insertion سپس merge | N log N / N log N برای RUN ثابت | RUN>=1؛ بدون پشتهٔ adaptive و galloping نسخهٔ CPython |
| `shell_sort.v` | insertion با فاصلهٔ نصف‌شونده | وابسته به gap / N² | gap=N/2 سپس /2 |
| `cocktail_sort.v` | bubble رفت و برگشتی | N² / N² | مرزهای بالا و پایین |
| `comb_sort.v` | مقایسه با فاصلهٔ کوچک‌شونده | وابسته به داده / N² | shrink=1.3 |
| `gnome_sort.v` | حرکت جلو و عقب پس از swap | N² / N² | یک اشاره‌گر |
| `odd_even_sort.v` | پاس‌های زوج و فرد | N² / N² | N پاس |
| `bitonic_sort.v` | برنامهٔ شبکهٔ bitonic | N log² N / N log² N | N توان دو باشد |
| `counting_sort.v` | histogram کلید | N+2^W / N+2^W | W کوچک، ترجیحاً <=10 |
| `radix_sort.v` | radix دودویی LSD پایدار | W*N / W*N | signed با تغییر ترتیب بیت علامت |
| `bucket_sort.v` | پخش بر اساس بیت بالا و insertion داخل هر bucket | وابسته به توزیع / N²+B | 1<=BITS<=W؛ حافظه B*N؛ B=2^BITS |
| `rank_sort.v` | شمارش تعداد کلیدهای کوچک‌تر | N² / N² | tie با اندیس اولیه شکسته می‌شود |

همه صعودی‌اند؛ SIGNED=1 مقایسهٔ مکمل دو را فعال می‌کند. عنصر صفر در کم‌ارزش‌ترین W بیت باس است. سورت روی رکورد همراه payload پیاده نشده؛ اگر دادهٔ جانبی دارید باید هنگام swap/حرکت همراه کلید منتقل شود.

## قرارداد الگوریتم‌های عدد صحیح

- `linear_search` و `binary_search`: اولین اندیس تطبیق را می‌دهند؛ در miss، found=0 و index=0. ورودی binary باید از قبل صعودی و با همان signedness مرتب باشد.
- `prefix_sum`: جمع فراگیر؛ [1,2,3] -> [1,3,6]؛ خروجی هر lane به عرض AW است.
- `dot_product`: [1,2,3]·[4,5,6]=32؛ AW پیش‌فرض برای جمع N حاصل‌ضرب جا دارد.
- `matrix_multiply`: A ابعاد R×K و B ابعاد K×C؛ هر دو row-major هستند. lane خروجی r*C+c است. AW پیش‌فرض 2W+ceil(log2(K)) است.
- `convolution`: کانولوشن خطی کامل، طول NA+NB-1؛ [1,2] و [3,4] -> [3,10,8]. هر lane خروجی AW بیت است؛ با circular convolution فرق دارد.
- `polynomial_horner`: coefficients[0] جملهٔ ثابت است. c0+c1*x+...؛ خروجی modulo 2^W است. برای ضریب نقطهٔ ثابت، پس از هر ضرب شیفت Q لازم است؛ نسخهٔ موجود برای چندجمله‌ای صحیح است.
- `integer_power`: توان با مربع متوالی، نتیجه modulo 2^W؛ a^0=1 حتی برای a=0.
- `factorial`: 0!=1؛ خروجی modulo 2^W و پرچم overflow است. در W=32، 12! جا می‌شود و 13! overflow می‌دهد.
- `fibonacci`: F(0)=0 و F(1)=1؛ overflow مربوط به خود F(n) است، نه مقدار کمکی بعدی.
- `integer_sqrt`: floor(sqrt(x))؛ مثلاً 15 -> 3 و 16 -> 4.

## تبدیل شبه‌کد به مدار

۱. متغیرهای ماندگار حلقه را مشخص کنید: i، j، key، sum، حد بازه و حافظه‌ها رجیستر می‌شوند.

۲. هر کار چرخه‌ای را به یک حالت تبدیل کنید: LOAD، COMPARE، UPDATE، ADVANCE، REPORT. برای دو نوشتن همزمان در یک آرایه بررسی کنید که ابزار حافظهٔ مناسب دارد یا به رجیستر تبدیل می‌کند.

۳. start فقط هنگام بیکاری پذیرفته شود. داده را همان لحظه ذخیره کنید؛ سپس ورودی بیرونی می‌تواند تغییر کند. done را فقط پس از ثبت آخرین نتیجه فعال کنید.

۴. در بلوک ترتیبی از nonblocking استفاده کنید: اگر `sum <= sum+term` و همان لبه `result <= sum` بنویسید، آخرین term در result نیست؛ باید `result <= sum+term` باشد.

۵. قبل از خواندن آرایه شرط اندیس را کنترل کنید. اندیس منفی، N و عرض صفر برای N=1 از خطاهای متداول‌اند.

۶. معنای سرریز و signedness را از ابتدا انتخاب کنید: wrap، saturation یا پرچم. جمع را با یک بیت بیشتر و حاصل‌ضرب را با 2W بیت نگه دارید.

## تمرین‌های پیشنهادی

- selection_sort را نزولی کنید و برای دادهٔ تکراری تست بگذارید.
- در linear_search تعداد تطبیق‌ها را هم بشمارید.
- array_sum را به میانگین، min یا شمارش شرطی تغییر دهید.
- polynomial_horner را برای ضرایب fixed-point بازنویسی کنید.
- در convolution فقط خروجی valid را حساب کنید.
- GCD را از تفریق به remainder تبدیل کنید و هزینهٔ سخت‌افزار را مقایسه کنید.
- برای سری تیلور تعداد جمله را کم کنید و خطای تقریب را اندازه بگیرید.

برای اجرای واقعی نمونه‌ها به `tb/tb_sorting.sv`، `tb/tb_exam_algorithms.sv` و `tb/tb_numerical.sv` رجوع کنید.
