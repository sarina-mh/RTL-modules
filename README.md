# RTL Modules

A Verilog library, exam reference, and interactive documentation set for
digital-design practice. The repository contains two independent libraries:

- **`rtl/`** — 90 synthesizable Verilog-2005 modules: the original building
  blocks plus a large exam-reference set (sorting, searching, array algorithms,
  fixed-point numerical routines, floating point, memory, and FSM examples).
  Many algorithm files contain a **controller + datapath + public top** in one
  file.
- **`CAD_LIB (2).v`** — a standalone 76-module parametric Verilog-2001
  reference/cheat-sheet with a different naming scheme and reset convention.
  Compile it separately from `rtl/`.

Two pure-Verilog self-checking testbenches live in `tb/`, and `index.html`
provides an offline interactive view of the original 19-module library.

---

## Table of Contents

1. [At a Glance](#at-a-glance)
2. [Repository Layout](#repository-layout)
3. [Quick Start](#quick-start)
4. [Library Conventions](#library-conventions)
5. [Module Catalog](#module-catalog)
6. [Representative Top-Level Interfaces](#representative-top-level-interfaces)
7. [Controller / Datapath / Top Pattern](#controller--datapath--top-pattern)
8. [Testbenches](#testbenches)
9. [CAD_LIB (2).v](#cad_lib-2v)
10. [Interactive HTML Documentation](#interactive-html-documentation)
11. [Design Notes and Gotchas](#design-notes-and-gotchas)
12. [Verification Status](#verification-status)

---

## At a Glance

| Item | Count | Notes |
|------|------:|-------|
| `rtl/*.v` files | 90 | Verilog-2005, synthesizable |
| Public top modules in `rtl/` | 90 | One per file, named after the file |
| Total module declarations | 192 | Tops plus private helpers |
| Internal controller/datapath/helper modules | 102 | Private helpers inside the same files |
| Sorting algorithms | 18 | Covered by `tb_sorting.v` |
| Search/array modules | 10 | Includes max/min, prefix sum, dot product, matrix multiply, convolution |
| Numerical/integer/fixed-point modules | 17 | Taylor, exp, Fourier, DFT, FFT, integer math |
| Floating-point modules | 8 | `fp_arithmetic`, classify/compare/stream, four FP16 wrappers |
| `tb/*.v` testbenches | 2 | Pure Verilog-2005, self-checking |
| `CAD_LIB (2).v` modules | 76 | Separate Verilog-2001 reference library |

---

## Repository Layout

```
.
├── rtl/                     # 90 Verilog-2005 modules (main library)
│   ├── add.v
│   ├── alu.v
│   ├── array_max_min.v
│   ├── selection_sort.v
│   ├── quick_sort.v
│   ├── dft_fixed.v
│   ├── fp_arithmetic.v
│   ├── sync_fifo.v
│   └── ...                  # see Module Catalog
├── tb/
│   ├── tb_sorting.v         # 18 sorting algorithms, W/N/signed sweeps
│   └── tb_array_max_min.v   # array max/min, legacy interface
├── CAD_LIB (2).v            # standalone 76-module Verilog-2001 reference
├── index.html               # interactive docs (original 19-module snapshot)
└── README.md
```

---

## Quick Start

### 1. Run the committed testbenches

```bash
# Sorting: 18 algorithms, three parameter configurations, 80 arrays each
iverilog -g2005 -s tb_sorting -o sorting_sim rtl/*.v tb/tb_sorting.v
vvp sorting_sim

# Array maximum/minimum: legacy interface
iverilog -g2005 -s tb_array_max_min -o minmax_sim rtl/array_max_min.v tb/tb_array_max_min.v
vvp minmax_sim
```

Expected result:

```text
PASS Verilog sorting W=1 N=1 signed=0 methods=18 arrays=80
PASS Verilog sorting W=8 N=8 signed=0 methods=18 arrays=80
PASS Verilog sorting W=8 N=8 signed=1 methods=18 arrays=80
PASS tb_sorting (pure Verilog-2005)

PASS max/min W=1 N=1 cases=100
PASS max/min W=8 N=8 cases=100
PASS tb_array_max_min (pure Verilog-2005)
```

### 2. Compile the main RTL library

```bash
# Parse/elaborate the whole rtl/ library
iverilog -g2005 -o rtl_lib.vvp rtl/*.v

# Optional lint
verilator --lint-only -Wall rtl/*.v
```

Do **not** add `CAD_LIB (2).v` to the same compilation: it redefines several
module names used in `rtl/` (`add_sub`, `alu`, `parity`, `rom`, `mux2`,
`full_adder`, and others).

### 3. Open the interactive documentation

Open `index.html` in a browser. Diagrams and syntax highlighting are rendered
locally; the page works offline (web fonts fall back to system fonts).

---

## Library Conventions

### Main library (`rtl/`)

#### Language and synthesis

- Verilog-2005, synthesizable, no SystemVerilog-only constructs.
- No real-number arithmetic in RTL; all numerical examples are fixed-point.
- `$clog2` is used for automatic index widths.

#### Parameters

Common parameter names:

| Parameter | Meaning |
|-----------|---------|
| `W` | Data width (bits) |
| `N` | Number of elements / taps / stages |
| `SIGNED` | `1` = two's-complement interpretation |
| `Q` | Fractional bits for fixed-point (`value = raw / 2**Q`) |
| `TERMS` | Number of Taylor-series terms |
| `AW` | Accumulator/result width |
| `I` / `A` / `S` / `C` | Index/address/select/count widths |

#### Packed arrays

Array ports are flattened; element `i` occupies:

```verilog
data[i*W +: W]
```

Element `0` is in the least-significant bits. The same layout is used on
inputs and outputs, so modules can be chained directly.

#### Start / busy / done handshake

Most sequential algorithm modules use:

| Signal | Meaning |
|--------|---------|
| `start` | Pulse high for one clock while `busy = 0` |
| `busy` | High while the operation is running |
| `done` | Registered, one-clock-wide completion pulse |
| outputs | Valid when `done` is high; held until the next `start` |

The input data is latched on the accepting `start` edge. `start` while `busy`
is high is ignored.

#### Reset styles (important)

The library is intentionally mixed because it preserves legacy interfaces:

| Style | Modules |
|-------|---------|
| **Synchronous active-low `rst_n`** (majority) | `counter`, `dff`, `register_en`, `shift_register`, `accumulator`, `mac`, all 18 sorting modules, `binary_search`, `linear_search`, `array_sum`, `array_reverse`, `prefix_sum`, `dot_product`, `matrix_multiply`, `convolution`, numerical modules, floating-point stream wrappers, `sync_fifo`, `sequence_detector` |
| **Asynchronous active-high `rst`** (legacy) | `array_max_min`, `up_down_counter`, `universal_shift`, `residue_n` |
| **Asynchronous active-low `rst_n`** | `flip_flop` |
| **Combinational (no reset)** | `add`, `sub`, `add_sub`, `adder`, `full_adder`, `alu`, `mul`, `divider`, `comparator`, `mux`, `mux2`, `demux`, `decoder`, `encoder`, `priority_encoder`, `barrel_shifter`, `parity`, `popcount`, `leading_zero_count`, `array_extrema`, `rom`, `fp_arithmetic`, `fp_classify`, `fp_compare` |

Always check the file header when mixing modules.

#### Signedness

- `SIGNED = 1` enables two's-complement comparison/sorting/MAC behavior.
- `add`/`sub`/`add_sub` report signed `overflow` separately from carry/borrow.
- `mul` supports unsigned or signed operation via `SIGNED`.
- `fp_arithmetic` uses IEEE-style sign/exponent/fraction fields, not integer
  signedness.

#### Memory behavior

| Module | Behavior |
|--------|----------|
| `register_file` | Two asynchronous read ports, one synchronous write; storage is **not** reset |
| `single_port_ram` | Synchronous read, read-first on same-address write; storage is **not** reset |
| `rom` | Constant packed contents; word `i` is `CONTENT[i*W +: W]` |
| `sync_fifo` | First-word fall-through; full allows replacement only with a simultaneous pop; empty simultaneous push/pop accepts the push and rejects the pop |

Write RAM/register-file locations before reading them.

#### Fixed-point numerical modules

For `taylor_series`, `exp_taylor`, `sin_taylor`, `cos_taylor`,
`exponential_fixed`, `fourier_series`, `dft_fixed`, and `fft_radix2`:

- The signed integer `raw` represents `raw / 2**Q`.
- Supported ranges are documented in each file; typical limits are
  `8 <= W <= 32`, `4 <= Q <= 24`, `W >= Q+4`.
- `TERMS` controls accuracy and latency.
- `out_of_range` and/or `overflow` report domain/scale problems.
- DFT/FFT use `N` in `{1,2,4,8,16,32,64}`; twiddle constants are in
  `twiddle_rom.v` (no runtime `$sin`/`$cos`).
- FFT loads bit-reversed input and produces natural-order output.

#### Floating point

- `fp_arithmetic` is **combinational** and parameterized by `E` (exponent bits)
  and `F` (fraction bits). Defaults `E=5, F=10` are binary16; `E=8, F=23` is
  binary32.
- `OP` selects `0=add`, `1=subtract`, `2=multiply`, `3=divide`.
- Rounding is round-to-nearest, ties-to-even; subnormal, signed zero, infinity,
  and canonical quiet NaN are supported. No exception flags or alternate
  rounding modes.
- `fp_stream` and the four `fp16_*` wrappers add a one-entry elastic
  `in_valid`/`in_ready` → `out_valid`/`out_ready` interface.
- Division uses integer `/` and `%` on significands and may infer a large
  circuit.

### `CAD_LIB (2).v`

- Plain Verilog-2001, single file, 76 modules.
- `clk` rising edge; `rst` is **active-high synchronous** (add
  `or posedge rst` in the sensitivity list if you need asynchronous reset).
- Contains a table of contents, a syntax cheat-sheet, FSM templates, and a
  sequential shift-add multiplier controller/datapath/top example.
- Compile it **separately** from `rtl/` due to duplicate module names.
- The `CAD_TB.v` referenced in its header is not included in this repository.

---

## Module Catalog

Each row lists the file, its public top module (same name as the file), and a
short description. Internal `_controller` / `_datapath` / `_helper_*` modules are
private to the file unless you intentionally instantiate them.

### Arithmetic & Logic

| File | Public top | Description |
|------|-----------|-------------|
| [`add.v`](rtl/add.v) | `add` | Parameterized combinational adder with carry-in/out and signed overflow |
| [`sub.v`](rtl/sub.v) | `sub` | Parameterized combinational subtractor with borrow and signed overflow |
| [`add_sub.v`](rtl/add_sub.v) | `add_sub` | Combined adder/subtractor; for subtraction `carry=1` means **no** unsigned borrow |
| [`adder.v`](rtl/adder.v) | `adder` | `W`-bit adder with carry-in and carry-out |
| [`full_adder.v`](rtl/full_adder.v) | `full_adder` | 1-bit full adder |
| [`alu.v`](rtl/alu.v) | `alu` | 8-operation ALU: add, subtract, AND, OR, XOR, left shift, arithmetic right shift, signed less-than; `zero`/`negative`/`carry`/`overflow` |
| [`mul.v`](rtl/mul.v) | `mul` | Unsigned or signed multiplier with full-width product |
| [`divider.v`](rtl/divider.v) | `divider` | Combinational restoring unsigned divider; quotient saturates on divide-by-zero |
| [`comparator.v`](rtl/comparator.v) | `comparator` | Full relational comparator (`eq`, `ne`, `gt`, `lt`, `ge`, `le`) |
| [`mux.v`](rtl/mux.v) | `mux` | Parameterized `N`:1 multiplexer with packed inputs |
| [`mux2.v`](rtl/mux2.v) | `mux2` | 2:1 multiplexer |
| [`demux.v`](rtl/demux.v) | `demux` | 1:`N` demultiplexer |
| [`decoder.v`](rtl/decoder.v) | `decoder` | Binary-to-one-hot decoder with enable |
| [`encoder.v`](rtl/encoder.v) | `encoder` | One-hot encoder; `valid` requires exactly one asserted bit |
| [`priority_encoder.v`](rtl/priority_encoder.v) | `priority_encoder` | Priority encoder; highest index wins |
| [`barrel_shifter.v`](rtl/barrel_shifter.v) | `barrel_shifter` | Left/right shifts, arithmetic right shift, and rotate |
| [`parity.v`](rtl/parity.v) | `parity` | Even/odd parity generator and checker |
| [`popcount.v`](rtl/popcount.v) | `popcount` | Population count (number of set bits) |
| [`leading_zero_count.v`](rtl/leading_zero_count.v) | `leading_zero_count` | Leading-zero count |

### Sequential & Memory

| File | Public top | Description |
|------|-----------|-------------|
| [`flip_flop.v`](rtl/flip_flop.v) | `flip_flop` | Parameterized D flip-flop; asynchronous active-low reset, enable, `q`/`q_bar` |
| [`dff.v`](rtl/dff.v) | `dff` | Parameterized D flip-flop with synchronous active-low reset |
| [`counter.v`](rtl/counter.v) | `counter` | Up/down loadable counter with clear and enable |
| [`up_down_counter.v`](rtl/up_down_counter.v) | `up_down_counter` | Legacy up/down counter with `serial_in` carry-in and `done`; async active-high reset |
| [`residue_n.v`](rtl/residue_n.v) | `residue_n` | Modulo-`N` counter/residue with `done`; async active-high reset |
| [`modulo_counter.v`](rtl/modulo_counter.v) | `modulo_counter` | Mod-`N` counter with terminal-count output; sync active-low reset |
| [`saturating_counter.v`](rtl/saturating_counter.v) | `saturating_counter` | Up/down counter that saturates at 0 and all-ones |
| [`register_en.v`](rtl/register_en.v) | `register_en` | Register with load/enable; priority reset > load > capture > hold |
| [`shift_register.v`](rtl/shift_register.v) | `shift_register` | Shift register with init, parallel load, and shift enable; sync active-low reset |
| [`universal_shift.v`](rtl/universal_shift.v) | `universal_shift` | Legacy universal shift register (hold/left/right/load); async active-high reset |
| [`pipeline_delay.v`](rtl/pipeline_delay.v) | `pipeline_delay` | `LATENCY >= 1` pipeline; enable stalls data and validity together |
| [`accumulator.v`](rtl/accumulator.v) | `accumulator` | Accumulator with clear and enable; sync active-low reset |
| [`mac.v`](rtl/mac.v) | `mac` | Multiply-accumulate; full-precision product, accumulation wraps at `AW` |
| [`register_file.v`](rtl/register_file.v) | `register_file` | Two asynchronous read ports, one synchronous write; storage is not reset |
| [`rom.v`](rtl/rom.v) | `rom` | Constant packed ROM; word `i` is `CONTENT[i*W +: W]` |
| [`single_port_ram.v`](rtl/single_port_ram.v) | `single_port_ram` | Synchronous read, read-first on same-address write; storage is not reset |
| [`sync_fifo.v`](rtl/sync_fifo.v) | `sync_fifo` | First-word fall-through FIFO with `full`/`empty`/`count` |

### Sorting (18)

| File | Public top | Description |
|------|-----------|-------------|
| [`selection_sort.v`](rtl/selection_sort.v) | `selection_sort` | Selection sort; controller + datapath + top; one comparison per SCAN cycle |
| [`bubble_sort.v`](rtl/bubble_sort.v) | `bubble_sort` | Bubble sort; one adjacent comparison per cycle; early exit after a clean pass |
| [`insertion_sort.v`](rtl/insertion_sort.v) | `insertion_sort` | Insertion sort; load a key, shift one predecessor per cycle, then insert |
| [`quick_sort.v`](rtl/quick_sort.v) | `quick_sort` | Iterative Lomuto quicksort; explicit `N`-entry stack replaces recursion |
| [`merge_sort.v`](rtl/merge_sort.v) | `merge_sort` | Stable bottom-up merge sort; one merge output or copy-back per cycle |
| [`heap_sort.v`](rtl/heap_sort.v) | `heap_sort` | In-place max-heap sort; one sift-down comparison/swap per cycle |
| [`shell_sort.v`](rtl/shell_sort.v) | `shell_sort` | Shell sort with halving gaps and gapped insertion |
| [`gnome_sort.v`](rtl/gnome_sort.v) | `gnome_sort` | Gnome sort; walk forward when ordered, swap/backtrack on inversion |
| [`cocktail_sort.v`](rtl/cocktail_sort.v) | `cocktail_sort` | Bidirectional bubble (cocktail shaker) sort |
| [`comb_sort.v`](rtl/comb_sort.v) | `comb_sort` | Comb sort with 1.3 shrink factor; final gap-1 pass repeats until no swaps |
| [`odd_even_sort.v`](rtl/odd_even_sort.v) | `odd_even_sort` | Odd-even transposition sort; alternating even/odd adjacent passes |
| [`radix_sort.v`](rtl/radix_sort.v) | `radix_sort` | Stable binary LSD radix sort; sign bit flipped in the last pass for signed data |
| [`counting_sort.v`](rtl/counting_sort.v) | `counting_sort` | Counting sort for small keys; histogram grows as `2**W` |
| [`bucket_sort.v`](rtl/bucket_sort.v) | `bucket_sort` | High key bits select a bucket; insertion sort inside each bucket |
| [`bitonic_sort.v`](rtl/bitonic_sort.v) | `bitonic_sort` | Iterative bitonic comparator network; `N` must be a power of two |
| [`rank_sort.v`](rtl/rank_sort.v) | `rank_sort` | Stable enumeration/rank sort; counts smaller keys plus earlier equal keys |
| [`intro_sort.v`](rtl/intro_sort.v) | `intro_sort` | Introspective quicksort with depth budget and heapsort fallback |
| [`tim_sort.v`](rtl/tim_sort.v) | `tim_sort` | Educational fixed-run TimSort-style insertion + bottom-up merge |

All sorting modules are ascending. `SIGNED=1` enables two's-complement
comparison. `tb_sorting.v` instantiates all 18 through their public tops.

### Search & Array Algorithms

| File | Public top | Description |
|------|-----------|-------------|
| [`linear_search.v`](rtl/linear_search.v) | `linear_search` | Sequential linear search; first match wins; `index=0` on miss |
| [`binary_search.v`](rtl/binary_search.v) | `binary_search` | Lower-bound binary search on an ascending sorted array; first match wins |
| [`array_max_min.v`](rtl/array_max_min.v) | `array_max_min` | Controller + datapath + top max/min scanner; **legacy async active-high reset** and direct `data_in` scan |
| [`array_extrema.v`](rtl/array_extrema.v) | `array_extrema` | Combinational min/max/argmax; ties retain the first element |
| [`array_reverse.v`](rtl/array_reverse.v) | `array_reverse` | Controller + datapath + top; copies one element per cycle into the reversed position |
| [`array_sum.v`](rtl/array_sum.v) | `array_sum` | Controller + datapath + top; accumulates one element per RUN cycle |
| [`prefix_sum.v`](rtl/prefix_sum.v) | `prefix_sum` | Inclusive unsigned prefix sum; `AW` defaults to full precision |
| [`dot_product.v`](rtl/dot_product.v) | `dot_product` | Sequential dot product; `AW >= 2*W + ceil(log2(N))` retains precision |
| [`matrix_multiply.v`](rtl/matrix_multiply.v) | `matrix_multiply` | Row-major `A[R,K] * B[K,C]`; one multiply-accumulate per clock |
| [`convolution.v`](rtl/convolution.v) | `convolution` | Full linear convolution; output length `NA+NB-1`; one valid MAC per cycle |

### Numerical, Integer & Fixed-Point

| File | Public top | Description |
|------|-----------|-------------|
| [`taylor_series.v`](rtl/taylor_series.v) | `taylor_series` | Generic fixed-point Taylor engine; `MODE=0` exp, `1` sin, `2` cos |
| [`exp_taylor.v`](rtl/exp_taylor.v) | `exp_taylor` | `exp(x)` Taylor wrapper (`MODE=0`) |
| [`sin_taylor.v`](rtl/sin_taylor.v) | `sin_taylor` | `sin(x)` Taylor wrapper (`MODE=1`) |
| [`cos_taylor.v`](rtl/cos_taylor.v) | `cos_taylor` | `cos(x)` Taylor wrapper (`MODE=2`) |
| [`exponential_fixed.v`](rtl/exponential_fixed.v) | `exponential_fixed` | `exp(x)` on `[-4,4]` via `exp(x/4)^4` range reduction; saturating output |
| [`fourier_series.v`](rtl/fourier_series.v) | `fourier_series` | Finite real Fourier series on `theta=2*pi*phase/64` |
| [`dft_fixed.v`](rtl/dft_fixed.v) | `dft_fixed` | Direct complex DFT/IDFT; `N` divides 64; forward unnormalized, inverse `/N` |
| [`fft_radix2.v`](rtl/fft_radix2.v) | `fft_radix2` | Iterative radix-2 DIT FFT/IFFT; bit-reversed load, natural output |
| [`twiddle_rom.v`](rtl/twiddle_rom.v) | `twiddle_rom` | Constant `exp(-j*2*pi*phase/64)` coefficients, Q30 rescaled to `Q` |
| [`integer_power.v`](rtl/integer_power.v) | `integer_power` | Exponentiation by squaring, modulo `2**W`; defines `a**0=1` |
| [`integer_sqrt.v`](rtl/integer_sqrt.v) | `integer_sqrt` | `floor(sqrt(x))` by trial bits |
| [`factorial.v`](rtl/factorial.v) | `factorial` | Unsigned `n!`, wraps modulo `2**W`, reports overflow; `0! = 1` |
| [`fibonacci.v`](rtl/fibonacci.v) | `fibonacci` | `F(0)=0`, `F(1)=1`; result wraps modulo `2**W`; sticky overflow |
| [`polynomial_horner.v`](rtl/polynomial_horner.v) | `polynomial_horner` | Horner evaluation of `c[0]+c[1]*x+...`; arithmetic wraps modulo `2**W` |
| [`gcd.v`](rtl/gcd.v) | `gcd` | Euclidean subtraction GCD; one subtraction per cycle; no divider inferred |
| [`iterative_divider.v`](rtl/iterative_divider.v) | `iterative_divider` | `W`-step restoring divider; divide-by-zero completes with quotient all ones |
| [`shift_add_multiplier.v`](rtl/shift_add_multiplier.v) | `shift_add_multiplier` | Controller + datapath + top sequential shift-add multiplier |

### Floating Point

| File | Public top | Description |
|------|-----------|-------------|
| [`fp_arithmetic.v`](rtl/fp_arithmetic.v) | `fp_arithmetic` | Combinational binary FP add/sub/mul/div; `E`/`F` parameters; round-to-nearest-even; subnormal/Inf/NaN |
| [`fp_classify.v`](rtl/fp_classify.v) | `fp_classify` | Classifies sign, zero, subnormal, normal, infinity, and NaN |
| [`fp_compare.v`](rtl/fp_compare.v) | `fp_compare` | Ordered comparison; NaN makes `unordered=1`; signed zeros compare equal |
| [`fp_stream.v`](rtl/fp_stream.v) | `fp_stream` | One-entry elastic `ready`/`valid` wrapper around `fp_arithmetic` |
| [`fp16_adder.v`](rtl/fp16_adder.v) | `fp16_adder` | Binary16 `OP=0` wrapper with ready/valid stream interface |
| [`fp16_subtractor.v`](rtl/fp16_subtractor.v) | `fp16_subtractor` | Binary16 `OP=1` wrapper with ready/valid stream interface |
| [`fp16_multiplier.v`](rtl/fp16_multiplier.v) | `fp16_multiplier` | Binary16 `OP=2` wrapper with ready/valid stream interface |
| [`fp16_divider.v`](rtl/fp16_divider.v) | `fp16_divider` | Binary16 `OP=3` wrapper with ready/valid stream interface |

### FSM / Control

| File | Public top | Description |
|------|-----------|-------------|
| [`sequence_detector.v`](rtl/sequence_detector.v) | `sequence_detector` | MSB-first pattern detector with Moore and Mealy outputs; `OVERLAP` selects overlap behavior |

---

## Representative Top-Level Interfaces

These are the public interfaces you will normally instantiate. Internal
`_controller` / `_datapath` modules are intentionally private.

| Module | Parameters | Ports |
|--------|-----------|-------|
| `selection_sort` | `W=8, N=8, SIGNED=0` | `clk, rst_n, start, data_in[N*W], data_out[N*W], busy, done` |
| `binary_search` | `W=8, N=8, SIGNED=0, I=ceil(log2(N))` | `clk, rst_n, start, data_in[N*W], target[W], found, index[I], busy, done` |
| `array_max_min` | `N=8, WIDTH=8` | `clk, rst, start, data_in[N*WIDTH], max_val, min_val, done, busy` (legacy async active-high reset) |
| `array_sum` | `W=8, N=8, AW=W+ceil(log2(N))` | `clk, rst_n, start, data_in[N*W], sum[AW], busy, done` |
| `array_reverse` | `W=8, N=8` | `clk, rst_n, start, data_in[N*W], data_out[N*W], busy, done` |
| `fp_arithmetic` | `E=5, F=10, OP=0, W=1+E+F` | `a[W], b[W], result[W]` (combinational) |
| `fp_stream` | `E=5, F=10, OP=0, W=1+E+F` | `clk, rst_n, in_valid, in_ready, a, b, out_valid, out_ready, result` |
| `sync_fifo` | `W=8, DEPTH=4, A=ceil(log2(DEPTH)), C=ceil(log2(DEPTH+1))` | `clk, rst_n, push, pop, data_in[W], data_out[W], full, empty, count[C]` |
| `register_file` | `W=8, DEPTH=16, A=ceil(log2(DEPTH))` | `clk, we, write_address, read_address_a, read_address_b, write_data, read_data_a, read_data_b` (no reset) |
| `alu` | `W=8` | `a[W], b[W], op[3], y[W], zero, negative, carry, overflow` |
| `mac` | `W=8, AW=2*W+4, SIGNED=0` | `clk, rst_n, clear, en, a[W], b[W], sum[AW]` |
| `taylor_series` | `W=32, Q=20, TERMS=12, MODE=0` | `clk, rst_n, start, x[W] (signed), result[W], busy, done, out_of_range, overflow` |
| `dft_fixed` / `fft_radix2` | `W=32, Q=20, N=8, INVERSE=0` | `clk, rst_n, start, real_in[N*W], imag_in[N*W], real_out[N*W], imag_out[N*W], busy, done, overflow` |
| `matrix_multiply` | `W=8, R=2, K=3, C=2, SIGNED=0, AW=2*W+ceil(log2(K))` | `clk, rst_n, start, a[R*K*W], b[K*C*W], result[R*C*AW], busy, done` |
| `convolution` | `W=8, NA=4, NB=3, SIGNED=0, AW=2*W+ceil(log2(min(NA,NB)))` | `clk, rst_n, start, a[NA*W], b[NB*W], result[(NA+NB-1)*AW], busy, done` |
| `gcd` | `W=16` | `clk, rst_n, start, a[W], b[W], result[W], busy, done` |
| `iterative_divider` | `W=8` | `clk, rst_n, start, a[W], b[W], quotient[W], remainder[W], busy, done, divide_by_zero` |
| `shift_add_multiplier` | `W=8` | `clk, rst_n, start, a[W], b[W], product[2*W], busy, done` |
| `sequence_detector` | `P=4, PATTERN=4'b1011, OVERLAP=1` | `clk, rst_n, valid, bit_in, hit_mealy, hit_moore` |

Example instantiation:

```verilog
selection_sort #(.W(8), .N(8), .SIGNED(0)) u_sort (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .data_in(data_in),
    .data_out(data_out),
    .busy(busy),
    .done(done)
);
```

---

## Controller / Datapath / Top Pattern

The refactor puts a complete controller, datapath, and public top in the same
file for many algorithms. The pattern is:

```verilog
// Private controller: state + control strobes
module selection_sort_controller #(parameter N=8)(
    input clk, rst_n, start, last_scan, last_pass,
    output reg load, scan, swap, next_pass, capture,
    output busy, done
);
    // IDLE -> SCAN -> SWAP -> REPORT -> IDLE
endmodule

// Private datapath: storage, comparison, indices, swap
module selection_sort_datapath #(parameter W=8, N=8, SIGNED=0)(
    input clk, rst_n, load, scan, swap, next_pass, capture,
    input [N*W-1:0] data_in,
    output reg [N*W-1:0] data_out,
    output last_scan, last_pass
);
    // registers + memory + comparison + swap
endmodule

// Public top: connect controller and datapath
module selection_sort #(parameter W=8, N=8, SIGNED=0)(
    input clk, rst_n, start,
    input [N*W-1:0] data_in,
    output [N*W-1:0] data_out,
    output busy, done
);
    // instantiate controller and datapath
endmodule
```

Design rules used throughout:

- The controller only decides **when** to load, scan, swap, or capture.
- The datapath owns the registers, memory, comparators, and index arithmetic.
- Status predicates (`last_scan`, `last_pass`, `k < N`, comparison results) are
  produced by the datapath, not the FSM.
- Control strobes are one-hot/decoded outputs of the FSM.
- `done` is registered; outputs are captured before `done` is asserted.
- Nonblocking assignments are used in sequential blocks; blocking assignments
  are used for combinational control/status logic.

This structure is used by `selection_sort`, `bubble_sort`, `insertion_sort`,
`quick_sort`, `binary_search`, `array_reverse`, `array_sum`,
`shift_add_multiplier`, `array_max_min`, and others.

---

## Testbenches

### `tb/tb_sorting.v`

Pure Verilog-2005, no SystemVerilog and no Python.

- Instantiates all 18 sorting algorithms through their public tops.
- Runs three configurations: `W=1,N=1`, `W=8,N=8` unsigned, `W=8,N=8` signed.
- 80 arrays per configuration, mixing zeros, ramps, reverse ramps, all-ones,
  and random data.
- Builds an independent rank oracle (stable tie-breaking by original index).
- Checks `done` handshake, `busy` behavior, and one-cycle `done`.
- Includes a per-run cycle timeout and a global timeout.

Run:

```bash
iverilog -g2005 -s tb_sorting -o sorting_sim rtl/*.v tb/tb_sorting.v
vvp sorting_sim
```

### `tb/tb_array_max_min.v`

Pure Verilog-2005.

- Tests `array_max_min` with `W=1,N=1` and `W=8,N=8`.
- 100 random cases per configuration.
- Keeps `data_in` stable until `done` (the legacy module scans the input
  directly).
- Checks both `max_val` and `min_val`, plus timeout and handshake.

Run:

```bash
iverilog -g2005 -s tb_array_max_min -o minmax_sim rtl/array_max_min.v tb/tb_array_max_min.v
vvp minmax_sim
```

### Coverage note

Only these two testbenches are committed in the current tree. The other 71
`rtl/` files compile together and are exercised indirectly by the sorting and
max/min suites where applicable, but they do not have dedicated committed
testbenches after the refactor. Add directed/random testbenches for the
modules you rely on; the file headers document the exact interfaces and corner
cases.

---

## CAD_LIB (2).v

`CAD_LIB (2).v` is a separate, single-file Verilog-2001 reference library. It is
useful as a syntax/architecture cheat-sheet and as a source of small,
independent building blocks. It is **not** part of the `rtl/` library and is not
covered by the two committed testbenches.

Header conventions:

- `clk` rising edge.
- `rst` active-high **synchronous** reset.
- `W` data width, `N` count/size.
- Plain Verilog-2001; no SystemVerilog.

Table of contents from the file:

| Section | Contents |
|---------|----------|
| 1 | Mux / demux / decoder / encoder |
| 2 | Adders (2-input, 3-input, add/sub, ripple structural) |
| 3 | Subtractors (2-input, 3-input, absolute difference, negate) |
| 4 | Multipliers (2-input, 3-input, unsigned/signed) |
| 5 | Dividers (2-input combinational, 3-input combinational, sequential restoring) |
| 6 | Comparators (gt/lt/eq, 2-input and 3-input, signed/unsigned) + max/min |
| 7 | Registers (enable, load/clear, async, shift, edge detect, synchronizer) |
| 8 | Counters (up, up/down, modulo, ring, Johnson, gray) |
| 9 | Register file / RAM / ROM / FIFO / ping-pong buffer |
| 10 | Misc (ALU, shifter, sign/zero extend, parity, LFSR, clock divider) |
| 11 | FSM templates (Moore 3-process, Mealy example) |
| 12 | Datapath + controller + top example (sequential shift-add multiplier) |
| 13 | Testbench template (comments) |
| 14 | File I/O templates (comments) |

Module list by section:

| Section | Modules |
|---------|---------|
| 1 | `mux2`, `mux3`, `mux4`, `mux8`, `mux_n`, `demux2`, `decoder`, `priority_enc` |
| 2 | `half_adder`, `full_adder`, `adder2`, `adder3`, `add_sub`, `ripple_adder`, `sat_add_signed` |
| 3 | `sub2`, `sub3`, `abs_diff`, `negate`, `abs_signed` |
| 4 | `mult2`, `mult3`, `mult2_signed`, `mult3_signed`, `mult_pow2` |
| 5 | `div2`, `div3`, `div_seq` |
| 6 | `cmp_gt`, `cmp_lt`, `cmp_eq`, `cmp2`, `cmp_gt3`, `cmp_lt3`, `cmp_eq3`, `max2`, `min2`, `max3`, `min3`, `is_zero` |
| 7 | `reg_en`, `reg_ld_clr`, `reg_async`, `pipe_reg`, `shift_reg`, `edge_detect`, `sync2` |
| 8 | `counter_up`, `counter_updown`, `counter_mod`, `counter_down`, `ring_counter`, `johnson_counter`, `bin2gray`, `gray2bin` |
| 9 | `regfile`, `regfile_3r`, `ram_sp`, `ram_sdp`, `rom`, `fifo_sync`, `ping_pong_buffer` |
| 10 | `alu`, `shifter`, `sign_ext`, `zero_ext`, `parity`, `lfsr`, `tick_gen`, `clk_div`, `tristate` |
| 11 | `fsm_moore_template`, `seq101_mealy` |
| 12 | `mult_datapath`, `mult_controller`, `mult_seq_top` |

Compile it alone:

```bash
iverilog -g2005 -o cadlib.vvp "CAD_LIB (2).v"
```

Do not compile it together with `rtl/*.v`: module names such as `add_sub`,
`alu`, `parity`, `rom`, `mux2`, and `full_adder` overlap.

---

## Interactive HTML Documentation

`index.html` is a self-contained documentation site for the **original
19-module library**:

- a visual block diagram for every module,
- an FSM state diagram for every sequential controller,
- full RTL and testbench source for every module,
- an English/Persian UI toggle in the header (code comments stay English),
- guides for designing datapaths and FSMs.

Diagrams are rendered locally as SVG, and code is highlighted locally, so the
page works offline. Web fonts fall back to system fonts when there is no
network connection.

> **Snapshot note:** `index.html` was generated from the original 19-module
> sources. The later controller/datapath refactor and the extended 90-file
> library are documented in this README. Regenerate the HTML from the current
> `rtl/` sources if you need an exact snapshot of every interface.

---

## Design Notes and Gotchas

- **Reset polarity is not uniform.** Most modules use synchronous active-low
  `rst_n`; `array_max_min`, `up_down_counter`, `universal_shift`, and
  `residue_n` use asynchronous active-high `rst`; `flip_flop` uses asynchronous
  active-low `rst_n`. Check the file header.
- **Do not compile `CAD_LIB (2).v` with `rtl/`.** Several module names collide.
- **Packed arrays:** element `i` is `data[i*W +: W]`; keep the same layout on
  both sides of a connection.
- **`start` is a pulse.** Assert it for one clock while `busy = 0`; it is
  ignored while busy.
- **`done` is a pulse.** Sample outputs on the cycle where `done` is high;
  outputs are held until the next `start`.
- **Memory is not reset.** Write RAM/register-file locations before reading.
- **Signed behavior** requires `SIGNED=1` on sorting, comparison, and MAC
  modules; otherwise values are unsigned.
- **Fixed-point scaling:** `raw / 2**Q`; check each numerical module for its
  valid input range and `TERMS`/`Q` limits.
- **Floating-point arithmetic** is educational: round-to-nearest-even,
  subnormal/Inf/NaN supported, but no exception flags or alternate rounding
  modes. Division may infer a large circuit.
- **Bitonic sort** requires `N` to be a power of two.
- **DFT/FFT** require `N` in `{1,2,4,8,16,32,64}`; FFT uses bit-reversed input
  loading.
- **`tim_sort`** is an educational fixed-run hybrid, not CPython's adaptive
  natural-run implementation.
- **`intro_sort`** uses an explicit `N`-entry range stack; `DEPTH=0` goes
  directly to the heapsort fallback.
- **`array_max_min` preserves the legacy interface**: it scans `data_in`
  directly, so keep the input stable until `done`.
- **`register_file` and `single_port_ram` have no reset**; `sync_fifo` is
  first-word fall-through.

---

## Verification Status

Verified locally with Icarus Verilog:

- `tb_sorting.v` — **PASS** for `W=1,N=1`, `W=8,N=8` unsigned, and
  `W=8,N=8` signed; 18 methods × 80 arrays each.
- `tb_array_max_min.v` — **PASS** for `W=1,N=1` and `W=8,N=8`; 100 cases each.
- `rtl/*.v` compiles together with `-g2005`.
- `CAD_LIB (2).v` compiles standalone with `-g2005`.

The remaining modules do not have dedicated committed testbenches. They are
synthesizable educational examples; always run your own directed tests for the
parameter ranges and corner cases you use in a design.

---

## License

No license is specified in this repository. Add one if you intend to
redistribute the code.
