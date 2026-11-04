# فهرست ماژول‌ها

84 ماژول، هر کدام در فایل هم‌نام خودش. هم اسم انگلیسی و هم شرح فارسی قابل جست‌وجو هستند.

[راهنمای آمادگی امتحان](STUDY_GUIDE.md) · [راهنمای محاسبات عددی](NUMERICAL.md)

| فایل | گروه | کاربرد | تمام وابستگی‌های لازم |
|---|---|---|---|
| [array_extrema.v](rtl/array_extrema.v) | algorithms | array_extrema | — |
| [gcd.v](rtl/gcd.v) | algorithms | gcd | — |
| [iterative_divider.v](rtl/iterative_divider.v) | algorithms | iterative_divider | — |
| [shift_add_multiplier.v](rtl/shift_add_multiplier.v) | algorithms | shift_add_multiplier | — |
| [add_sub.v](rtl/add_sub.v) | combinational | add_sub | — |
| [adder.v](rtl/adder.v) | combinational | adder | — |
| [alu.v](rtl/alu.v) | combinational | alu | [add_sub.v](rtl/add_sub.v) |
| [barrel_shifter.v](rtl/barrel_shifter.v) | combinational | barrel_shifter | — |
| [comparator.v](rtl/comparator.v) | combinational | comparator | — |
| [decoder.v](rtl/decoder.v) | combinational | decoder | — |
| [demux.v](rtl/demux.v) | combinational | demux | — |
| [divider.v](rtl/divider.v) | combinational | divider | — |
| [encoder.v](rtl/encoder.v) | combinational | encoder | — |
| [full_adder.v](rtl/full_adder.v) | combinational | full_adder | — |
| [leading_zero_count.v](rtl/leading_zero_count.v) | combinational | leading_zero_count | — |
| [mux.v](rtl/mux.v) | combinational | mux | — |
| [mux2.v](rtl/mux2.v) | combinational | mux2 | — |
| [parity.v](rtl/parity.v) | combinational | parity | — |
| [popcount.v](rtl/popcount.v) | combinational | popcount | — |
| [priority_encoder.v](rtl/priority_encoder.v) | combinational | priority_encoder | — |
| [array_reverse.v](rtl/array_reverse.v) | exam_algorithms | معکوس‌کردن آرایه | — |
| [binary_search.v](rtl/binary_search.v) | exam_algorithms | جست‌وجوی دودویی اولین تطبیق | — |
| [convolution.v](rtl/convolution.v) | exam_algorithms | کانولوشن خطی کامل | — |
| [dot_product.v](rtl/dot_product.v) | exam_algorithms | ضرب داخلی بردارها | — |
| [factorial.v](rtl/factorial.v) | exam_algorithms | فاکتوریل با تشخیص overflow | — |
| [fibonacci.v](rtl/fibonacci.v) | exam_algorithms | فیبوناچی با تشخیص overflow | — |
| [integer_power.v](rtl/integer_power.v) | exam_algorithms | توان صحیح با مربع‌کردن متوالی | — |
| [integer_sqrt.v](rtl/integer_sqrt.v) | exam_algorithms | کف جذر صحیح | — |
| [linear_search.v](rtl/linear_search.v) | exam_algorithms | جست‌وجوی خطی اولین تطبیق | — |
| [matrix_multiply.v](rtl/matrix_multiply.v) | exam_algorithms | ضرب ماتریس‌های مستطیلی | — |
| [polynomial_horner.v](rtl/polynomial_horner.v) | exam_algorithms | محاسبهٔ چندجمله‌ای با هورنر | — |
| [prefix_sum.v](rtl/prefix_sum.v) | exam_algorithms | جمع پیشوندی فراگیر | — |
| [fp16_adder.v](rtl/fp16_adder.v) | floating_point | fp16_adder | [fp_arithmetic.v](rtl/fp_arithmetic.v), [fp_stream.v](rtl/fp_stream.v) |
| [fp16_divider.v](rtl/fp16_divider.v) | floating_point | fp16_divider | [fp_arithmetic.v](rtl/fp_arithmetic.v), [fp_stream.v](rtl/fp_stream.v) |
| [fp16_multiplier.v](rtl/fp16_multiplier.v) | floating_point | fp16_multiplier | [fp_arithmetic.v](rtl/fp_arithmetic.v), [fp_stream.v](rtl/fp_stream.v) |
| [fp16_subtractor.v](rtl/fp16_subtractor.v) | floating_point | fp16_subtractor | [fp_arithmetic.v](rtl/fp_arithmetic.v), [fp_stream.v](rtl/fp_stream.v) |
| [fp_arithmetic.v](rtl/fp_arithmetic.v) | floating_point | جمع، تفریق، ضرب و تقسیم FP16/FP32 | — |
| [fp_classify.v](rtl/fp_classify.v) | floating_point | fp_classify | — |
| [fp_compare.v](rtl/fp_compare.v) | floating_point | مقایسهٔ floating-point با تشخیص NaN | — |
| [fp_stream.v](rtl/fp_stream.v) | floating_point | fp_stream | [fp_arithmetic.v](rtl/fp_arithmetic.v) |
| [array_sum.v](rtl/array_sum.v) | fsm | array_sum | [sum_controller.v](rtl/sum_controller.v), [sum_datapath.v](rtl/sum_datapath.v) |
| [sequence_detector.v](rtl/sequence_detector.v) | fsm | sequence_detector | — |
| [sum_controller.v](rtl/sum_controller.v) | fsm | sum_controller | — |
| [sum_datapath.v](rtl/sum_datapath.v) | fsm | sum_datapath | — |
| [register_file.v](rtl/register_file.v) | memory | register_file | — |
| [rom.v](rtl/rom.v) | memory | rom | — |
| [single_port_ram.v](rtl/single_port_ram.v) | memory | single_port_ram | — |
| [sync_fifo.v](rtl/sync_fifo.v) | memory | sync_fifo | — |
| [cos_taylor.v](rtl/cos_taylor.v) | numerical | کسینوس زاویهٔ رادیانی با تیلور | [taylor_series.v](rtl/taylor_series.v) |
| [dft_fixed.v](rtl/dft_fixed.v) | numerical | تبدیل فوریهٔ مستقیم و معکوس | [twiddle_rom.v](rtl/twiddle_rom.v) |
| [exp_taylor.v](rtl/exp_taylor.v) | numerical | exp با تیلور در بازهٔ ±۱ | [taylor_series.v](rtl/taylor_series.v) |
| [exponential_fixed.v](rtl/exponential_fixed.v) | numerical | اکسپوننشیال در بازهٔ ±۴ با کاهش بازه | [exp_taylor.v](rtl/exp_taylor.v), [taylor_series.v](rtl/taylor_series.v) |
| [fft_radix2.v](rtl/fft_radix2.v) | numerical | تبدیل فوریهٔ سریع و معکوس | [twiddle_rom.v](rtl/twiddle_rom.v) |
| [fourier_series.v](rtl/fourier_series.v) | numerical | محاسبهٔ سری فوریهٔ حقیقی با ضرایب ورودی | [twiddle_rom.v](rtl/twiddle_rom.v) |
| [sin_taylor.v](rtl/sin_taylor.v) | numerical | سینوس زاویهٔ رادیانی با تیلور | [taylor_series.v](rtl/taylor_series.v) |
| [taylor_series.v](rtl/taylor_series.v) | numerical | سری تیلور عمومی exp/sin/cos | — |
| [twiddle_rom.v](rtl/twiddle_rom.v) | numerical | ضرایب ثابت فوریه | — |
| [accumulator.v](rtl/accumulator.v) | sequential | جمع انباشته | — |
| [counter.v](rtl/counter.v) | sequential | counter | — |
| [dff.v](rtl/dff.v) | sequential | dff | — |
| [mac.v](rtl/mac.v) | sequential | ضرب و جمع انباشته | — |
| [modulo_counter.v](rtl/modulo_counter.v) | sequential | modulo_counter | — |
| [pipeline_delay.v](rtl/pipeline_delay.v) | sequential | pipeline_delay | — |
| [register_en.v](rtl/register_en.v) | sequential | register_en | — |
| [saturating_counter.v](rtl/saturating_counter.v) | sequential | saturating_counter | — |
| [shift_register.v](rtl/shift_register.v) | sequential | shift_register | — |
| [bitonic_sort.v](rtl/bitonic_sort.v) | sorting | مرتب‌سازی bitonic | — |
| [bubble_sort.v](rtl/bubble_sort.v) | sorting | مرتب‌سازی bubble | — |
| [bucket_sort.v](rtl/bucket_sort.v) | sorting | مرتب‌سازی bucket | — |
| [cocktail_sort.v](rtl/cocktail_sort.v) | sorting | مرتب‌سازی cocktail | — |
| [comb_sort.v](rtl/comb_sort.v) | sorting | مرتب‌سازی comb | — |
| [counting_sort.v](rtl/counting_sort.v) | sorting | مرتب‌سازی counting | — |
| [gnome_sort.v](rtl/gnome_sort.v) | sorting | مرتب‌سازی gnome | — |
| [heap_sort.v](rtl/heap_sort.v) | sorting | مرتب‌سازی heap | — |
| [insertion_sort.v](rtl/insertion_sort.v) | sorting | مرتب‌سازی insertion | — |
| [intro_sort.v](rtl/intro_sort.v) | sorting | مرتب‌سازی intro | — |
| [merge_sort.v](rtl/merge_sort.v) | sorting | مرتب‌سازی merge | — |
| [odd_even_sort.v](rtl/odd_even_sort.v) | sorting | مرتب‌سازی odd even | — |
| [quick_sort.v](rtl/quick_sort.v) | sorting | مرتب‌سازی quick | — |
| [radix_sort.v](rtl/radix_sort.v) | sorting | مرتب‌سازی radix | — |
| [rank_sort.v](rtl/rank_sort.v) | sorting | مرتب‌سازی rank | — |
| [selection_sort.v](rtl/selection_sort.v) | sorting | مرتب‌سازی selection | — |
| [shell_sort.v](rtl/shell_sort.v) | sorting | مرتب‌سازی shell | — |
| [tim_sort.v](rtl/tim_sort.v) | sorting | مرتب‌سازی tim | — |
