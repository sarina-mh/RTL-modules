"""Render the verification report from the completed, required test results."""
from pathlib import Path
import json,platform,subprocess
from datetime import datetime,timedelta,timezone
from catalog import entries
from test_config import SUITES
from environment import command
ROOT=Path(__file__).resolve().parent
results=json.loads((ROOT/'results.json').read_text())
lint=json.loads((ROOT/'lint_results.json').read_text())
assert {r['name'] for r in results}==set(SUITES) and all(r['passed'] for r in results)
assert lint['passed'] and lint['modules']==len(entries())
today=datetime.now(timezone(timedelta(hours=3,minutes=30))).date().isoformat()
simulator=subprocess.check_output(command('verilator --version'),text=True,encoding='utf-8').strip()
lines=['# گزارش نهایی تست','', 'تاریخ گزارش (تهران): '+today, '',
       f"{len(entries())} ماژول در فایل‌های مستقل، با کامنت انگلیسی و پارامترهای مستند. تمام هفت مجموعهٔ تست و lint زبان Verilog-2005 پاس شدند.", '',
       '| مجموعه | نتیجه | زمان اجرای محلی، شامل build (ثانیه) |','|---|---|---|']
for r in results:lines.append(f"| {r['name']} | PASS | {r['seconds']} |")
lines.extend(['', '## خروجی واقعی شبیه‌ساز',''])
for r in results:
    lines.extend([f"### {r['name']}",'','```text',*r['output'],'```',''])
lines.extend(['## دامنهٔ آزمون‌ها','',
    '- بلوک‌های پایه با عرض‌های ۱، ۴، ۸ و ۱۶؛ حافظه/FIFO با عمق ۱،۳،۸؛ reset، enable، full/empty و read-first.',
    '- ۱۸ مرتب‌سازی روی ۵ پیکربندی و هر کدام ۱۰۰ آرایه؛ signed/unsigned، تکراری، مرتب، معکوس و تصادفی. Bitonic فقط روی N توان دو تست می‌شود. DEPTH=0 برای IntroSort و RUN=1 برای TimSort نیز جدا تست می‌شوند؛ TimSort نسخهٔ آموزشی fixed-run است.',
    '- ۴۸۰ مجموعهٔ برداری برای جست‌وجو، reverse، prefix sum، dot product، ضرب ماتریس مستطیلی، هورنر و کانولوشن؛ ۱۲۰۰ مورد برای توان، فاکتوریل، فیبوناچی و جذر.',
    '- FP: مجموع ۹۱٬۰۸۰ جفت ورودی × ۴ عمل = ۳۶۴٬۳۲۰ نتیجهٔ مرجع؛ هم مسیر ترکیبی و هم stream بررسی می‌شوند. مرجع با Fraction دقیق و nearest-even، همراه cross-check مستقل struct است.',
    '- Taylor/exp: دو قالب عددی، هر کدام ۲۶۰ ورودی؛ مرجع math پایتون، حد پذیرش ۶۴ LSB با ۱۲ جمله؛ domain error، saturation و reset نیز بررسی می‌شوند.',
    '- Fourier series: تمام ۶۴ فاز برای H=0،3،8؛ مرجع مستقل مجموع sin/cos پایتون.',
    '- DFT/FFT: اندازه‌های ۱،۴،۸،۱۶،۶۴، forward و inverse، ورودی صفر/ضربه/DC/کسینوسی/مختلط تصادفی؛ مرجع cmath. overflow و اشباع و reset جدا تست می‌شوند.',
    '- همهٔ topها با parser سخت‌گیر Verilog-2005 بررسی شدند؛ خطای latch، multiple-driver یا حلقهٔ ترکیبی گزارش نشده است. هشدارهای عرض برای تبدیل‌های عمدی و پارامترهای integer در log کامپایل وجود دارند.', '',
    '## بازتولید','', '```bash','python3 run_tests.py','python3 check_lint.py','python3 write_report.py','python3 package_reference.py','```','',
    'خلاصهٔ ماشینی: results.json، lint_results.json، vector_manifest.json و numeric_vector_manifest.json. هش منابع با نرمال‌سازی پایان‌خط LF در source_hashes.json است. خروجی کامل محلی build/*.txt است؛ بردارهای بزرگ با اسکریپت بازتولید می‌شوند. CI نیز همین فرمان‌ها را روی Linux اجرا می‌کند.', '',
    '## حدود ارزیابی','',
    'محیط تولید گزارش: '+platform.system()+'؛ '+simulator+'. آزمون ۴حالته، اثبات رسمی، synthesis، مساحت یا timing انجام نشده است. مجموعهٔ جدید از ماژول‌های قدیمی ریشهٔ ریپو جداست؛ این گزارش وضعیت تست مجموعهٔ midterm_reference را بیان می‌کند.', '',
    'نتایج FP16/FP32 شامل تمام جفت‌های ورودی نیستند. تیلور و فوریه تقریب fixed-point با بازه و خطای مستند هستند؛ حدود Q، تعداد جمله، اندازهٔ تبدیل و headroom در NUMERICAL.md آمده است. تقسیم FP و ضرب‌های عددی می‌توانند سخت‌افزار بزرگی بسازند. این کتابخانه پرچم exception و rounding mode اضافی IEEE را پیاده نکرده است.', '',
    'اصلاح ابزار محلی: استفاده از -O2 برای رفع خطای لینک GCC/libstdc++ با -Os. نگهداری signedness در MAC و استفاده از مرجع rank مستقل در تست سورت نیز در آزمون‌های قبلی بررسی و اصلاح شده‌اند. مرجع تشخیص دنباله prefix/suffix است؛ در مرجع FIFO مقدار برگشتی pop استفاده می‌شود تا شبیه‌سازهای قدیمی‌تر اثر جانبی آن را حذف نکنند.', ''])
(ROOT/'TEST_REPORT.md').write_text('\n'.join(lines),encoding='utf-8')
print('Wrote report from seven passing suites and strict lint.')
