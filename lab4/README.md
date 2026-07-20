# BCD-to-7-Segment Decoder & Decimal-to-BCD Encoder — Verilog & ModelSim

Two combinational Verilog designs — a BCD-to-7-segment display decoder and a decimal-to-BCD encoder — simulated in ModelSim.

## Overview

| Design | Module | File | I/O |
|---|---|---|---|
| 7-Segment Decoder | `decoder_7seg` | `decoder_7.v` | 4-bit BCD in → 7 segment lines out |
| Decimal-to-BCD Encoder | `decimal_to_bcd` | `encoder.v` | 10-bit one-hot in → 4-bit BCD out |

## Repository Structure

```
├── decoder_7.v               # BCD-to-7-segment decoder
├── decoder_7.mpf               # ModelSim project file
├── decoder_7_cr.mti             # ModelSim compile record
│
├── encoder.v                     # Decimal-to-BCD encoder
│
├── transcript                       # Simulation log
└── vsim.wlf                          # Waveform database
```

## Design

### BCD-to-7-Segment Decoder

Takes a 4-bit BCD input (`A` = MSB … `D` = LSB) and drives the seven segments (`led_a`–`led_g`) of a common display using sum-of-products logic derived from the digit truth table:

```verilog
module decoder_7seg (A, B, C, D, led_a, led_b, led_c, led_d, led_e, led_f, led_g);
input A, B, C, D;
output led_a, led_b, led_c, led_d, led_e, led_f, led_g;

assign led_a = A | C | (B&D) | (~B&~D);
assign led_b = ~B | (~C&~D) | (C&D);
assign led_c = B | ~C | D;
assign led_d = (~B&~D) | (C&~D) | (B&~C&D) | (~B&C|A);
assign led_e = (~B&~D) | (C&~D);
assign led_f = A | (~C&~D) | (B&~C) | (B&~D);
assign led_g = A | (B&~C) | (~B&C) | (C&~D);
endmodule
```

### Decimal-to-BCD Encoder

Takes a 10-bit one-hot input (`i[9:0]`, one line per decimal digit) and encodes the active line into 4-bit BCD:

```verilog
module decimal_to_bcd (i, A);
input  [9:0] i;
output [3:0] A;

assign A[0] = i[1] | i[3] | i[5] | i[7] | i[9];
assign A[1] = i[2] | i[3] | i[6] | i[7];
assign A[2] = i[4] | i[5] | i[6] | i[7];
assign A[3] = i[8] | i[9];
endmodule
```

Assumes a single active input line at a time (standard one-hot decimal encoder); no priority logic is implemented.

## Simulation

Both modules were verified directly in the ModelSim GUI by forcing input signals and inspecting the waveform, rather than with a separate testbench:

```tcl
vlib work
vlog decoder_7.v
vsim work.decoder_7seg
add wave sim:/decoder_7seg/*
force -freeze sim:/decoder_7seg/A 1 0
force -freeze sim:/decoder_7seg/B 0 0
force -freeze sim:/decoder_7seg/C 0 0
force -freeze sim:/decoder_7seg/D 0 0
run
```

```tcl
vlog encoder.v
vsim work.decimal_to_bcd
add wave sim:/decimal_to_bcd/*
force -freeze {sim:/decimal_to_bcd/i[9]} 1 0
run
```

## Results

Both designs compiled and simulated with **0 errors**. Output waveforms are available in `vsim.wlf` (open with `vsim -view vsim.wlf`).

## Author

Amr Khaled Sedik — ECE Engineering, Ain Shams University
