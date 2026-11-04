"""Build a searchable index and resolve actual RTL module dependencies."""
from pathlib import Path
import json,re
ROOT=Path(__file__).resolve().parent
GROUPS={
    'sorting': 'selection_sort bubble_sort insertion_sort quick_sort merge_sort heap_sort shell_sort gnome_sort cocktail_sort comb_sort odd_even_sort bitonic_sort counting_sort radix_sort bucket_sort rank_sort intro_sort tim_sort',
    'numerical': 'taylor_series exp_taylor sin_taylor cos_taylor exponential_fixed twiddle_rom fourier_series dft_fixed fft_radix2',
    'exam_algorithms': 'linear_search binary_search array_reverse prefix_sum dot_product matrix_multiply polynomial_horner integer_power factorial fibonacci integer_sqrt convolution',
    'floating_point': 'fp_arithmetic fp_stream fp_compare fp_classify fp16_adder fp16_subtractor fp16_multiplier fp16_divider',
    'combinational': 'mux mux2 demux decoder encoder priority_encoder full_adder adder add_sub comparator barrel_shifter parity popcount leading_zero_count alu divider',
    'sequential': 'dff register_en shift_register counter modulo_counter saturating_counter accumulator mac pipeline_delay',
    'memory': 'single_port_ram register_file rom sync_fifo',
    'algorithms': 'gcd shift_add_multiplier iterative_divider array_extrema',
    'fsm': 'sequence_detector sum_controller sum_datapath array_sum',
}
LABELS={
    'fp_compare':'مقایسهٔ floating-point با تشخیص NaN',
    'accumulator':'جمع انباشته', 'mac':'ضرب و جمع انباشته',
    'fp_arithmetic':'جمع، تفریق، ضرب و تقسیم FP16/FP32',
    'taylor_series':'سری تیلور عمومی exp/sin/cos','exp_taylor':'exp با تیلور در بازهٔ ±۱',
    'sin_taylor':'سینوس زاویهٔ رادیانی با تیلور','cos_taylor':'کسینوس زاویهٔ رادیانی با تیلور',
    'exponential_fixed':'اکسپوننشیال در بازهٔ ±۴ با کاهش بازه',
    'dft_fixed':'تبدیل فوریهٔ مستقیم و معکوس','fft_radix2':'تبدیل فوریهٔ سریع و معکوس',
    'twiddle_rom':'ضرایب ثابت فوریه','fourier_series':'محاسبهٔ سری فوریهٔ حقیقی با ضرایب ورودی',
    'linear_search':'جست‌وجوی خطی اولین تطبیق','binary_search':'جست‌وجوی دودویی اولین تطبیق',
    'array_reverse':'معکوس‌کردن آرایه','prefix_sum':'جمع پیشوندی فراگیر',
    'dot_product':'ضرب داخلی بردارها','matrix_multiply':'ضرب ماتریس‌های مستطیلی',
    'polynomial_horner':'محاسبهٔ چندجمله‌ای با هورنر','integer_power':'توان صحیح با مربع‌کردن متوالی',
    'factorial':'فاکتوریل با تشخیص overflow','fibonacci':'فیبوناچی با تشخیص overflow',
    'integer_sqrt':'کف جذر صحیح','convolution':'کانولوشن خطی کامل',
}
def entries():
    paths={p.stem:p for p in sorted((ROOT/'rtl').glob('*.v'))}
    rows=[]
    for name,path in paths.items():
        source=path.read_text(encoding='utf-8')
        declared=re.findall(r'^module\s+(\w+)',source,re.M)
        assert declared==[name],(path,declared)
        deps=[child for child in paths if child!=name and re.search(r'\b'+child+r'\s*(?:#\s*\(|[A-Za-z_]\w*\s*\()',source)]
        groups=[group for group,names in GROUPS.items() if name in names.split()]
        assert len(groups)==1,(name,groups)
        rows.append(dict(module=name,file='rtl/'+path.name,group=groups[0],dependencies=deps,
                         description=LABELS.get(name,'مرتب‌سازی '+name.replace('_sort','').replace('_',' ') if groups[0]=='sorting' else name)))
    return rows
def closure(name,rows):
    mapping={r['module']:r for r in rows};seen=set()
    def visit(current):
        if current in seen:return
        seen.add(current)
        for child in mapping[current]['dependencies']:visit(child)
    visit(name)
    return [mapping[x]['file'] for x in sorted(seen)]
def write_index():
    rows=entries();lines=['# فهرست ماژول‌ها','',
        f'{len(rows)} ماژول، هر کدام در فایل هم‌نام خودش. هم اسم انگلیسی و هم شرح فارسی قابل جست‌وجو هستند.',
        '', '[راهنمای آمادگی امتحان](STUDY_GUIDE.md) · [راهنمای محاسبات عددی](NUMERICAL.md)', '',
        '| فایل | گروه | کاربرد | تمام وابستگی‌های لازم |','|---|---|---|---|']
    for row in sorted(rows,key=lambda r:(r['group'],r['module'])):
        name=row['module'];deps=[p for p in closure(name,rows) if p!=row['file']]
        links=', '.join(f'[{Path(p).name}]({p})' for p in deps) or '—'
        lines.append(f"| [{name}.v]({row['file']}) | {row['group']} | {row['description']} | {links} |")
    (ROOT/'MODULE_INDEX.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
    (ROOT/'catalog.json').write_text(json.dumps(rows,indent=2,ensure_ascii=False),encoding='utf-8')
    print(f'Indexed {len(rows)} modules.')
if __name__=='__main__':write_index()
