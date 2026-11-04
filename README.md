# RTL Modules

## Extended exam reference (84 modules)

The [midterm_reference](midterm_reference/README.md) directory adds a separately
tested library with one named file per module:

- [Searchable module index](midterm_reference/MODULE_INDEX.md), including `fp_compare`,
  accumulator/MAC, FP16/FP32 arithmetic and the four FP16 stream wrappers.
- [18 sorting algorithms and exam patterns](midterm_reference/STUDY_GUIDE.md),
  searches, prefix sums, dot/matrix products, Horner evaluation, integer power,
  factorial, Fibonacci, integer square root and convolution.
- [Taylor series, exp, Fourier series, DFT and radix-2 FFT/IFFT](midterm_reference/NUMERICAL.md),
  with fixed-point domains, precision and saturation documented.
- [Verification report](midterm_reference/TEST_REPORT.md) and seven repeatable suites.

These modules use **synchronous active-low `rst_n`** and have their own interfaces.
Compile this directory as a separate library: module names overlap with the
original `rtl/` modules below. Existing root-level RTL/testbench interfaces are
preserved. Run the extension with:

```bash
python3 midterm_reference/run_tests.py
python3 midterm_reference/check_lint.py
```

GitHub Actions runs these checks for updates to the extension. The original
library documentation follows.


A collection of parameterized, synthesizable Verilog modules for digital-design
and RTL courses. The library covers arithmetic building blocks, sequential
building blocks, and array algorithms (sorting, max/min, binary search).

Every module is fully parameterized, uses descriptive port names, and carries a
header comment documenting its purpose, parameters, inputs, and outputs.

---

## Table of Contents

1. [Repository Structure](#repository-structure)
2. [Global Conventions](#global-conventions)
3. [Module Catalog](#module-catalog)
4. [Detailed Reference](#detailed-reference)
   - [Arithmetic and Logic](#arithmetic-and-logic)
     - [add](#add)
     - [sub](#sub)
     - [add_sub](#add_sub)
     - [mul](#mul)
     - [mux](#mux)
     - [comparator](#comparator)
     - [parity](#parity)
   - [Sequential Building Blocks](#sequential-building-blocks)
     - [flip_flop](#flip_flop)
     - [shift_register](#shift_register)
     - [universal_shift](#universal_shift)
     - [up_down_counter](#up_down_counter)
     - [residue_n](#residue_n)
     - [register_file](#register_file)
   - [Array Algorithms](#array-algorithms)
     - [selection_sort](#selection_sort)
     - [insertion_sort](#insertion_sort)
     - [bubble_sort](#bubble_sort)
     - [quick_sort](#quick_sort)
     - [array_max_min](#array_max_min)
     - [binary_search](#binary_search)
5. [Handshake and Timing](#handshake-and-timing)
6. [Algorithm Complexity](#algorithm-complexity)
7. [Simulation and Linting](#simulation-and-linting)
8. [Testbenches](#testbenches)
9. [Notes and Limitations](#notes-and-limitations)

---

## Repository Structure

```
RTL-modules/
├── README.md
├── rtl/
│   ├── add.v
│   ├── sub.v
│   ├── add_sub.v
│   ├── mul.v
│   ├── mux.v
│   ├── comparator.v
│   ├── parity.v
│   ├── flip_flop.v
│   ├── shift_register.v
│   ├── universal_shift.v
│   ├── up_down_counter.v
│   ├── residue_n.v
│   ├── register_file.v
│   ├── selection_sort.v
│   ├── insertion_sort.v
│   ├── bubble_sort.v
│   ├── quick_sort.v
│   ├── array_max_min.v
│   └── binary_search.v
└── tb/
    ├── tb_add.v
    ├── tb_sub.v
    ├── tb_add_sub.v
    ├── tb_mul.v
    ├── tb_mux.v
    ├── tb_comparator.v
    ├── tb_parity.v
    ├── tb_flip_flop.v
    ├── tb_shift_register.v
    ├── tb_universal_shift.v
    ├── tb_up_down_counter.v
    ├── tb_residue_n.v
    ├── tb_register_file.v
    ├── tb_selection_sort.v
    ├── tb_insertion_sort.v
    ├── tb_bubble_sort.v
    ├── tb_quick_sort.v
    ├── tb_array_max_min.v
    └── tb_binary_search.v
```

---

## Global Conventions

### Language and synthesis

- Verilog-2001 / Verilog-2005 compatible.
- `$clog2` is used for automatic address/select/index widths.
- All modules are intended to be synthesizable.
- No SystemVerilog-only constructs are used.

### Parameters

- Every width, depth, modulus, and array size is a parameter with a sane default.
- Override parameters at instantiation time with `#(...)`.
- Derived widths (such as `ADDR_WIDTH`, `SEL_WIDTH`, `IDX_W`) default to
  `ceil(log2(size))`.

### Clocks and resets

- Clocked modules use `clk`.
- Unless stated otherwise, reset is **asynchronous and active high** (`rst`).
- The only exception is `flip_flop`, whose reset is **asynchronous and active
  low** (`rst_n`).

### Flattened arrays

Array ports are packed into a single vector:

```verilog
// Element k of an N-element array with WIDTH-bit elements:
data_in[k*WIDTH +: WIDTH]
```

- Element `0` occupies the least-significant bits.
- Element `N-1` occupies the most-significant bits.
- The output uses the same layout, so `data_out` can be connected directly to
  `data_in` of another array module.

### Start / busy / done handshake

All array-algorithm modules use the same handshake:

| Signal  | Meaning |
|---------|---------|
| `start` | Pulse high for at least one clock while `busy` is low to begin. |
| `busy`  | High while the operation is running. |
| `done`  | Registered, one-clock-wide pulse when the output is valid. |

The input array is sampled into internal memory on the `start` edge, so
`data_in` only needs to be stable while `start` is asserted.

### Signedness

- `add`, `sub`, and `add_sub` provide a signed `overflow` output.
- `mul` supports signed operation via the `SIGNED` parameter.
- All sorting, max/min, and binary-search comparisons are **unsigned**. If you
  need signed ordering, reinterpret the elements before comparing.

---

## Module Catalog

| Module | RTL file | Testbench | Category | One-line description |
|--------|----------|-----------|----------|----------------------|
| `add` | `rtl/add.v` | `tb/tb_add.v` | Arithmetic | Combinational adder with carry and signed overflow |
| `sub` | `rtl/sub.v` | `tb/tb_sub.v` | Arithmetic | Combinational subtractor with borrow and signed overflow |
| `add_sub` | `rtl/add_sub.v` | `tb/tb_add_sub.v` | Arithmetic | Combined adder/subtractor selected by a flag |
| `mul` | `rtl/mul.v` | `tb/tb_mul.v` | Arithmetic | Unsigned or signed multiplier |
| `mux` | `rtl/mux.v` | `tb/tb_mux.v` | Logic | Parameterized N-to-1 multiplexer |
| `comparator` | `rtl/comparator.v` | `tb/tb_comparator.v` | Logic | Full set of relational outputs (`==`, `!=`, `>`, `<`, `>=`, `<=`) |
| `parity` | `rtl/parity.v` | `tb/tb_parity.v` | Logic | Even/odd parity generator and checker |
| `flip_flop` | `rtl/flip_flop.v` | `tb/tb_flip_flop.v` | Sequential | D flip-flop with enable and complemented output |
| `shift_register` | `rtl/shift_register.v` | `tb/tb_shift_register.v` | Sequential | Shift register with init, parallel load, and shift enable |
| `universal_shift` | `rtl/universal_shift.v` | `tb/tb_universal_shift.v` | Sequential | Hold / shift-left / shift-right / parallel-load register |
| `up_down_counter` | `rtl/up_down_counter.v` | `tb/tb_up_down_counter.v` | Sequential | Up/down counter with terminal-count output |
| `residue_n` | `rtl/residue_n.v` | `tb/tb_residue_n.v` | Sequential | Modulo-N counter (residue generator) |
| `register_file` | `rtl/register_file.v` | `tb/tb_register_file.v` | Sequential | One write port and two asynchronous read ports |
| `selection_sort` | `rtl/selection_sort.v` | `tb/tb_selection_sort.v` | Array | In-place selection sort over multiple cycles |
| `insertion_sort` | `rtl/insertion_sort.v` | `tb/tb_insertion_sort.v` | Array | In-place insertion sort over multiple cycles |
| `bubble_sort` | `rtl/bubble_sort.v` | `tb/tb_bubble_sort.v` | Array | In-place bubble sort over multiple cycles |
| `quick_sort` | `rtl/quick_sort.v` | `tb/tb_quick_sort.v` | Array | Iterative quicksort with an explicit stack |
| `array_max_min` | `rtl/array_max_min.v` | `tb/tb_array_max_min.v` | Array | Finds maximum and minimum of an array |
| `binary_search` | `rtl/binary_search.v` | `tb/tb_binary_search.v` | Array | Binary search over a sorted array |

---

## Detailed Reference

### Arithmetic and Logic

#### add

Combinational adder.

**Parameters**

| Name | Default | Description |
|------|---------|-------------|
| `WIDTH` | `8` | Operand and result width |

**Ports**

| Direction | Name | Width | Description |
|-----------|------|-------|-------------|
| input | `a` | `WIDTH` | First operand |
| input | `b` | `WIDTH` | Second operand |
| input | `cin` | 1 | Carry-in |
| output | `sum` | `WIDTH` | Sum |
| output | `cout` | 1 | Carry-out |
| output | `overflow` | 1 | Signed overflow |

```verilog
add #(.WIDTH(16)) u_add (
    .a(a), .b(b), .cin(1'b0),
    .sum(sum), .cout(cout), .overflow(ovf)
);
```

#### sub

Combinational subtractor.

**Parameters**

| Name | Default | Description |
|------|---------|-------------|
| `WIDTH` | `8` | Operand and result width |

**Ports**

| Direction | Name | Width | Description |
|-----------|------|-------|-------------|
| input | `a` | `WIDTH` | First operand |
| input | `b` | `WIDTH` | Second operand |
| input | `bin` | 1 | Borrow-in |
| output | `diff` | `WIDTH` | Difference |
| output | `bout` | 1 | Borrow-out |
| output | `overflow` | 1 | Signed overflow |

```verilog
sub #(.WIDTH(16)) u_sub (
    .a(a), .b(b), .bin(1'b0),
    .diff(diff), .bout(bout), .overflow(ovf)
);
```

#### add_sub

Combined adder/subtractor controlled by `sub_flag`.

**Parameters**

| Name | Default | Description |
|------|---------|-------------|
| `WIDTH` | `8` | Operand and result width |

**Ports**

| Direction | Name | Width | Description |
|-----------|------|-------|-------------|
| input | `a` | `WIDTH` | First operand |
| input | `b` | `WIDTH` | Second operand |
| input | `sub_flag` | 1 | `0` = add, `1` = subtract |
| input | `cin` | 1 | Carry-in / borrow-in |
| output | `result` | `WIDTH` | Result |
| output | `cout` | 1 | Carry-out / borrow-out |
| output | `overflow` | 1 | Signed overflow |

Behavior:

```
sub_flag = 0 : result = a + b + cin
sub_flag = 1 : result = a - b - cin
```

```verilog
add_sub #(.WIDTH(8)) u_alu (
    .a(a), .b(b), .sub_flag(sub), .cin(1'b0),
    .result(result), .cout(cout), .overflow(ovf)
);
```

#### mul

Multiplier. The product width defaults to the sum of the operand widths.

**Parameters**

| Name | Default | Description |
|------|---------|-------------|
| `A_WIDTH` | `8` | Width of `a` |
| `B_WIDTH` | `8` | Width of `b` |
| `P_WIDTH` | `A_WIDTH + B_WIDTH` | Width of `p` |
| `SIGNED` | `0` | `0` = unsigned, `1` = signed |

**Ports**

| Direction | Name | Width | Description |
|-----------|------|-------|-------------|
| input | `a` | `A_WIDTH` | First operand |
| input | `b` | `B_WIDTH` | Second operand |
| output | `p` | `P_WIDTH` | Product |

```verilog
mul #(.A_WIDTH(8), .B_WIDTH(8), .SIGNED(1)) u_mul (
    .a(a), .b(b), .p(p)
);
```

#### mux

Parameterized multiplexer. Inputs are packed into one vector.

**Parameters**

| Name | Default | Description |
|------|---------|-------------|
| `WIDTH` | `8` | Width of each input/output |
| `N` | `4` | Number of inputs |
| `SEL_WIDTH` | `ceil(log2(N))` | Width of `sel` |

**Ports**

| Direction | Name | Width | Description |
|-----------|------|-------|-------------|
| input | `in` | `N*WIDTH` | Packed inputs (`in[k*WIDTH +: WIDTH]`) |
| input | `sel` | `SEL_WIDTH` | Selected input index |
| output | `out` | `WIDTH` | Selected input |

```verilog
mux #(.WIDTH(8), .N(4)) u_mux (
    .in({d3, d2, d1, d0}), .sel(sel), .out(y)
);
```

#### comparator

Combinational comparator producing all relational outputs.

**Parameters**

| Name | Default | Description |
|------|---------|-------------|
| `WIDTH` | `8` | Operand width |

**Ports**

| Direction | Name | Width | Description |
|-----------|------|-------|-------------|
| input | `a` | `WIDTH` | First operand |
| input | `b` | `WIDTH` | Second operand |
| output | `eq` | 1 | `a == b` |
| output | `ne` | 1 | `a != b` |
| output | `gt` | 1 | `a > b` |
| output | `lt` | 1 | `a < b` |
| output | `ge` | 1 | `a >= b` |
| output | `le` | 1 | `a <= b` |

```verilog
comparator #(.WIDTH(8)) u_cmp (
    .a(a), .b(b),
    .eq(eq), .ne(ne), .gt(gt), .lt(lt), .ge(ge), .le(le)
);
```

#### parity

Parity generator and checker.

**Parameters**

| Name | Default | Description |
|------|---------|-------------|
| `WIDTH` | `8` | Data width |
| `EVEN` | `1` | `1` = even parity, `0` = odd parity |

**Ports**

| Direction | Name | Width | Description |
|-----------|------|-------|-------------|
| input | `data` | `WIDTH` | Input data |
| input | `parity_in` | 1 | Received parity bit |
| input | `check_mode` | 1 | `0` = generate, `1` = check |
| output | `parity_out` | 1 | Generated parity bit |
| output | `error` | 1 | Parity mismatch (check mode only) |

```verilog
parity #(.WIDTH(8), .EVEN(1)) u_parity (
    .data(data), .parity_in(rx_parity), .check_mode(1'b1),
    .parity_out(parity_out), .error(parity_error)
);
```

---

### Sequential Building Blocks

#### flip_flop

D flip-flop with enable, asynchronous active-low reset, and complemented output.

**Parameters**

| Name | Default | Description |
|------|---------|-------------|
| `WIDTH` | `1` | Data width |
| `RESET_VALUE` | `0` | Value loaded on reset |

**Ports**

| Direction | Name | Width | Description |
|-----------|------|-------|-------------|
| input | `clk` | 1 | Clock |
| input | `rst_n` | 1 | Asynchronous reset, active low |
| input | `en` | 1 | Enable |
| input | `d` | `WIDTH` | Input data |
| output | `q` | `WIDTH` | Output |
| output | `q_bar` | `WIDTH` | Complemented output |

```verilog
flip_flop #(.WIDTH(8), .RESET_VALUE(8'h00)) u_ff (
    .clk(clk), .rst_n(rst_n), .en(en), .d(d), .q(q), .q_bar(q_bar)
);
```

#### shift_register

Shift register with initialization, parallel load, and shift enable.

Priority: `rst` > `init` > `load_reg` > `shift_en`.

**Parameters**

| Name | Default | Description |
|------|---------|-------------|
| `WIDTH` | `8` | Register width |
| `DIR` | `0` | `0` = shift right, `1` = shift left |
| `INIT_VALUE` | `0` | Value loaded by `init` |

**Ports**

| Direction | Name | Width | Description |
|-----------|------|-------|-------------|
| input | `clk` | 1 | Clock |
| input | `rst` | 1 | Asynchronous reset, active high |
| input | `shift_en` | 1 | Shift enable |
| input | `init` | 1 | Initialize to `INIT_VALUE` |
| input | `load_reg` | 1 | Parallel load enable |
| input | `serial_in` | 1 | Serial bit shifted in |
| input | `parallel_in` | `WIDTH` | Parallel load data |
| output | `q` | `WIDTH` | Register value |
| output | `serial_out` | 1 | Serial bit shifted out |

```verilog
shift_register #(.WIDTH(8), .DIR(0), .INIT_VALUE(8'hA5)) u_sr (
    .clk(clk), .rst(rst), .shift_en(shift_en), .init(init),
    .load_reg(load_reg), .serial_in(serial_in),
    .parallel_in(parallel_in), .q(q), .serial_out(serial_out)
);
```

#### universal_shift

Universal shift register with four modes.

| `mode` | Operation |
|--------|-----------|
| `2'b00` | Hold |
| `2'b01` | Shift right |
| `2'b10` | Shift left |
| `2'b11` | Parallel load |

**Parameters**

| Name | Default | Description |
|------|---------|-------------|
| `WIDTH` | `8` | Register width |

**Ports**

| Direction | Name | Width | Description |
|-----------|------|-------|-------------|
| input | `clk` | 1 | Clock |
| input | `rst` | 1 | Asynchronous reset, active high |
| input | `mode` | 2 | Operation select |
| input | `serial_right` | 1 | Bit shifted in on the MSB side (right shift) |
| input | `serial_left` | 1 | Bit shifted in on the LSB side (left shift) |
| input | `parallel_in` | `WIDTH` | Parallel load data |
| output | `q` | `WIDTH` | Register value |
| output | `serial_out_right` | 1 | Bit shifted out on the LSB side |
| output | `serial_out_left` | 1 | Bit shifted out on the MSB side |

```verilog
universal_shift #(.WIDTH(8)) u_usr (
    .clk(clk), .rst(rst), .mode(mode),
    .serial_right(1'b0), .serial_left(1'b0),
    .parallel_in(din), .q(q),
    .serial_out_right(sr), .serial_out_left(sl)
);
```

#### up_down_counter

Up/down counter with configurable range and wraparound.

- `count_en` enables counting.
- `count_up` selects direction.
- `serial_in` is a carry-in / serial enable used to chain counters; tie it to
  `1` for standalone operation.
- `done` indicates `MAX_VALUE` when counting up or `MIN_VALUE` when counting down.

**Parameters**

| Name | Default | Description |
|------|---------|-------------|
| `WIDTH` | `8` | Counter width |
| `MIN_VALUE` | `0` | Minimum value |
| `MAX_VALUE` | `2^WIDTH - 1` | Maximum value |

**Ports**

| Direction | Name | Width | Description |
|-----------|------|-------|-------------|
| input | `clk` | 1 | Clock |
| input | `rst` | 1 | Asynchronous reset, active high (loads `MIN_VALUE`) |
| input | `count_en` | 1 | Count enable |
| input | `count_up` | 1 | `1` = up, `0` = down |
| input | `serial_in` | 1 | Carry-in / serial enable |
| output | `value` | `WIDTH` | Current value |
| output | `done` | 1 | Boundary reached |

```verilog
up_down_counter #(.WIDTH(8), .MIN_VALUE(0), .MAX_VALUE(200)) u_cnt (
    .clk(clk), .rst(rst), .count_en(en), .count_up(up),
    .serial_in(1'b1), .value(value), .done(done)
);
```

#### residue_n

Modulo-N counter. Counts `0 .. N-1` and wraps; the output is always the
residue modulo `N`. `done` is high while `value == N-1`.

**Parameters**

| Name | Default | Description |
|------|---------|-------------|
| `N` | `10` | Counter modulus |
| `WIDTH` | `ceil(log2(N))` | Output width |

**Ports**

| Direction | Name | Width | Description |
|-----------|------|-------|-------------|
| input | `clk` | 1 | Clock |
| input | `rst` | 1 | Asynchronous reset, active high |
| input | `en` | 1 | Count enable |
| output | `value` | `WIDTH` | Current residue (`0 .. N-1`) |
| output | `done` | 1 | `value == N-1` |

```verilog
residue_n #(.N(10)) u_mod (
    .clk(clk), .rst(rst), .en(en), .value(value), .done(done)
);
```

#### register_file

Register file with one write port and two asynchronous read ports.

**Parameters**

| Name | Default | Description |
|------|---------|-------------|
| `WIDTH` | `32` | Width of each register |
| `DEPTH` | `32` | Number of registers |
| `ADDR_WIDTH` | `ceil(log2(DEPTH))` | Address width |

**Ports**

| Direction | Name | Width | Description |
|-----------|------|-------|-------------|
| input | `clk` | 1 | Clock |
| input | `rst` | 1 | Asynchronous reset, active high (clears all) |
| input | `we` | 1 | Write enable |
| input | `waddr` | `ADDR_WIDTH` | Write address |
| input | `wdata` | `WIDTH` | Write data |
| input | `raddr1` | `ADDR_WIDTH` | Read address 1 |
| input | `raddr2` | `ADDR_WIDTH` | Read address 2 |
| output | `rdata1` | `WIDTH` | Read data 1 |
| output | `rdata2` | `WIDTH` | Read data 2 |

```verilog
register_file #(.WIDTH(32), .DEPTH(32)) u_rf (
    .clk(clk), .rst(rst), .we(we),
    .waddr(waddr), .wdata(wdata),
    .raddr1(rs1), .raddr2(rs2),
    .rdata1(rd1), .rdata2(rd2)
);
```

---

### Array Algorithms

All array modules share the same ports and handshake:

- `clk`, `rst`, `start`
- `data_in` : flattened input array (`N*WIDTH` bits)
- `data_out` : flattened output array (sorting modules only)
- `done`, `busy`

#### selection_sort

In-place selection sort. For each position `i`, scans the remaining elements,
finds the minimum, and swaps it into position `i`. One comparison per clock.

**Parameters**

| Name | Default | Description |
|------|---------|-------------|
| `N` | `8` | Number of elements |
| `WIDTH` | `8` | Element width |

**Ports**

| Direction | Name | Width | Description |
|-----------|------|-------|-------------|
| input | `clk` | 1 | Clock |
| input | `rst` | 1 | Asynchronous reset, active high |
| input | `start` | 1 | Start pulse |
| input | `data_in` | `N*WIDTH` | Input array |
| output | `data_out` | `N*WIDTH` | Sorted array |
| output | `done` | 1 | One-cycle completion pulse |
| output | `busy` | 1 | Operation in progress |

```verilog
selection_sort #(.N(8), .WIDTH(8)) u_sort (
    .clk(clk), .rst(rst), .start(start),
    .data_in(arr_in), .data_out(arr_out),
    .done(done), .busy(busy)
);
```

#### insertion_sort

In-place insertion sort. For `i = 1 .. N-1`, captures `key = mem[i]` and shifts
larger elements of the sorted prefix one position right. One shift per clock.

**Parameters**

| Name | Default | Description |
|------|---------|-------------|
| `N` | `8` | Number of elements |
| `WIDTH` | `8` | Element width |

**Ports**: identical to `selection_sort`.

```verilog
insertion_sort #(.N(8), .WIDTH(8)) u_sort (
    .clk(clk), .rst(rst), .start(start),
    .data_in(arr_in), .data_out(arr_out),
    .done(done), .busy(busy)
);
```

#### bubble_sort

In-place bubble sort. Repeated passes compare adjacent elements and swap them
when out of order. One comparison per clock.

**Parameters**

| Name | Default | Description |
|------|---------|-------------|
| `N` | `8` | Number of elements |
| `WIDTH` | `8` | Element width |

**Ports**: identical to `selection_sort`.

```verilog
bubble_sort #(.N(8), .WIDTH(8)) u_sort (
    .clk(clk), .rst(rst), .start(start),
    .data_in(arr_in), .data_out(arr_out),
    .done(done), .busy(busy)
);
```

#### quick_sort

Iterative quicksort. Recursion is replaced by an explicit LIFO stack of
`(low, high)` index pairs. Uses the last element as the pivot (Lomuto
partitioning) and performs one comparison per clock.

**Parameters**

| Name | Default | Description |
|------|---------|-------------|
| `N` | `8` | Number of elements |
| `WIDTH` | `8` | Element width |
| `STACK_DEPTH` | `N + 2` | Depth of the explicit index stack |

**Ports**: identical to `selection_sort`.

```verilog
quick_sort #(.N(8), .WIDTH(8), .STACK_DEPTH(10)) u_sort (
    .clk(clk), .rst(rst), .start(start),
    .data_in(arr_in), .data_out(arr_out),
    .done(done), .busy(busy)
);
```

#### array_max_min

Finds the maximum and minimum elements. Scans one element per clock; the first
element initializes both results.

**Parameters**

| Name | Default | Description |
|------|---------|-------------|
| `N` | `8` | Number of elements |
| `WIDTH` | `8` | Element width |

**Ports**

| Direction | Name | Width | Description |
|-----------|------|-------|-------------|
| input | `clk` | 1 | Clock |
| input | `rst` | 1 | Asynchronous reset, active high |
| input | `start` | 1 | Start pulse |
| input | `data_in` | `N*WIDTH` | Input array |
| output | `max_val` | `WIDTH` | Maximum element |
| output | `min_val` | `WIDTH` | Minimum element |
| output | `done` | 1 | One-cycle completion pulse |
| output | `busy` | 1 | Operation in progress |

```verilog
array_max_min #(.N(8), .WIDTH(8)) u_maxmin (
    .clk(clk), .rst(rst), .start(start), .data_in(arr_in),
    .max_val(max_val), .min_val(min_val),
    .done(done), .busy(busy)
);
```

#### binary_search

Binary search over a sorted array. One comparison per clock. If the key is
found, `found` is asserted and `index` holds its position; otherwise `found`
stays low and `index` is zero.

**Parameters**

| Name | Default | Description |
|------|---------|-------------|
| `N` | `8` | Number of elements |
| `WIDTH` | `8` | Element and key width |
| `IDX_W` | `ceil(log2(N))` | Index width |

**Ports**

| Direction | Name | Width | Description |
|-----------|------|-------|-------------|
| input | `clk` | 1 | Clock |
| input | `rst` | 1 | Asynchronous reset, active high |
| input | `start` | 1 | Start pulse |
| input | `data_in` | `N*WIDTH` | Sorted input array |
| input | `key` | `WIDTH` | Value to search for |
| output | `found` | 1 | Key present |
| output | `index` | `IDX_W` | Position of the key |
| output | `done` | 1 | One-cycle completion pulse |
| output | `busy` | 1 | Operation in progress |

```verilog
binary_search #(.N(8), .WIDTH(8)) u_bs (
    .clk(clk), .rst(rst), .start(start),
    .data_in(sorted_arr), .key(key),
    .found(found), .index(index),
    .done(done), .busy(busy)
);
```

---

## Handshake and Timing

The array modules use a simple `start` / `busy` / `done` protocol:

```
             __    _______________________________________    __
clk       __|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__
             __
start     __|  |______________________________________________________
                _____________________________
busy      _____|                             |______________________
                                                        __
done      _____________________________________________|  |__________
```

- Assert `start` for at least one rising edge while `busy` is low.
- On that edge, `data_in` is captured into internal memory.
- `busy` rises on the next cycle and stays high during computation.
- `done` pulses high for exactly one clock when the result is valid.
- After `done`, the module returns to idle and can be started again.

`done` is registered, so it appears in the cycle **after** the final internal
operation. Read `data_out`, `max_val`/`min_val`, or `found`/`index` while
`done` is high.

---

## Algorithm Complexity

For an array of `N` elements:

| Module | Comparisons | Clock cycles (approx.) | Notes |
|--------|-------------|------------------------|-------|
| `selection_sort` | `N(N-1)/2` | `N(N-1)/2 + 2N` | One comparison per cycle |
| `insertion_sort` | `O(N^2)` worst, `O(N)` best | `O(N^2)` | One shift per cycle |
| `bubble_sort` | `N(N-1)/2` | `N(N-1)/2 + 2N` | No early-exit optimization |
| `quick_sort` | `O(N log N)` average, `O(N^2)` worst | `O(N log N)` average | Explicit stack, one comparison per cycle |
| `array_max_min` | `N-1` | `N + 2` | One element per cycle |
| `binary_search` | `ceil(log2(N))` | `ceil(log2(N)) + 2` | Requires a sorted array |

---

## Simulation and Linting

### Icarus Verilog

```bash
# Lint/compile a single module
iverilog -g2005 -o /tmp/mod.vvp rtl/add.v

# Compile all modules together
iverilog -g2005 -o /tmp/all.vvp rtl/*.v

# Run a simulation
vvp /tmp/all.vvp
```

### Verilator

```bash
verilator --lint-only -Wall rtl/*.v
```

---

## Testbenches

Every module has a self-checking testbench in `tb/`. Each testbench prints
`PASS` or `FAIL`, reports the number of errors, and calls `$finish`. The
array-algorithm testbenches also contain a timeout watchdog so a broken design
cannot hang the simulation forever.

| Testbench | DUT | What it checks |
|-----------|-----|----------------|
| `tb_add.v` | `add` | Sum and carry-out over normal and edge cases |
| `tb_sub.v` | `sub` | Difference and borrow-out over normal and edge cases |
| `tb_add_sub.v` | `add_sub` | Both add and subtract modes |
| `tb_mul.v` | `mul` | Unsigned and signed multiplication |
| `tb_mux.v` | `mux` | Every select value and two input patterns |
| `tb_comparator.v` | `comparator` | All six relational outputs |
| `tb_parity.v` | `parity` | Even/odd generation and checker error |
| `tb_flip_flop.v` | `flip_flop` | Async reset, capture, hold, and `q_bar` |
| `tb_shift_register.v` | `shift_register` | Reset, load, right/left shift, and init priority |
| `tb_universal_shift.v` | `universal_shift` | Hold, shift right/left, load, and serial outputs |
| `tb_up_down_counter.v` | `up_down_counter` | Up/down counting, wrap, `done`, `serial_in` gating |
| `tb_residue_n.v` | `residue_n` | Modulo-N counting, wrap, `done`, and enable |
| `tb_register_file.v` | `register_file` | Writes, both read ports, and write-enable |
| `tb_selection_sort.v` | `selection_sort` | Sorted output against a reference sort |
| `tb_insertion_sort.v` | `insertion_sort` | Sorted output against a reference sort |
| `tb_bubble_sort.v` | `bubble_sort` | Sorted output against a reference sort |
| `tb_quick_sort.v` | `quick_sort` | Sorted output against a reference sort |
| `tb_array_max_min.v` | `array_max_min` | Maximum and minimum of a known array |
| `tb_binary_search.v` | `binary_search` | Hits, misses, first/last positions |

### Running all testbenches

Linux/macOS:

```bash
for tb in tb/*.v; do
    name=$(basename "$tb" .v)
    iverilog -g2005 -o "/tmp/$name.vvp" rtl/*.v "$tb" || continue
    vvp "/tmp/$name.vvp"
done
```

Windows PowerShell:

```powershell
$iverilog = 'C:\iverilog\bin\iverilog.exe'
$vvp      = 'C:\iverilog\bin\vvp.exe'
$rtl      = Get-ChildItem rtl -Filter *.v | ForEach-Object { $_.FullName }

foreach ($tb in Get-ChildItem tb -Filter *.v) {
    $out = Join-Path $env:TEMP ("sim_" + $tb.BaseName + ".vvp")
    & $iverilog -g2005 -o $out @rtl $tb.FullName
    if ($LASTEXITCODE -eq 0) { & $vvp $out }
}
```

### Running one testbench

```bash
iverilog -g2005 -o tb_add.vvp rtl/add.v tb/tb_add.v
vvp tb_add.vvp
```

All 19 testbenches in this repository pass with Icarus Verilog using the
`-g2005` flag.

---

## Notes and Limitations

- **Unsigned comparisons**: sorting, max/min, and binary search compare
  elements as unsigned values. Reinterpret signed data if needed.
- **Fixed array size**: `N` is a compile-time parameter; there is no dynamic
  array length.
- **Internal memory**: sorting modules copy `data_in` into internal registers on
  `start`, so the input only needs to be stable for that cycle.
- **`start` while busy**: ignored; the module must return to idle before a new
  operation.
- **`done` is a pulse**: do not use it as a level-sensitive enable.
- **`quick_sort` stack depth**: `STACK_DEPTH = N + 2` is sufficient for the
  worst case of this implementation. Increase it only if you modify the
  partitioning strategy.
- **`binary_search` requires sorted input**; otherwise results are undefined.
- **Reset polarity**: all modules use active-high `rst` except `flip_flop`,
  which uses active-low `rst_n`.
- **`mul` synthesis**: uses the `*` operator; the synthesis tool maps it to the
  technology multiplier (or a shift-add network).

---

## License

No license specified. Add one if you intend to redistribute this code.
