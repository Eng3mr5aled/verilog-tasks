# ALU with 7-Segment Display & Keypad Encoder/Decoder — Verilog & ModelSim

Two combinational Verilog systems: a 2-bit ALU whose result is decoded onto a seven-segment display, and a 3-digit keypad-to-seven-segment display pipeline. Both simulated in ModelSim.

## Overview

| Design | Top Module | File | Function |
|---|---|---|---|
| ALU + 7-Seg | `ALU_to_decoder` | `ALU_to_decoder.v` | 2-bit ALU result displayed on one 7-seg digit + 2 LEDs |
| Keypad Encoder/Decoder | `encoder_to_decoder` | `encoder_to_decoder.v` | 3 one-hot keypad digits displayed on three 7-seg digits |

## Repository Structure

```
├── ALU_to_decoder.v            # ALU + 7-seg decoder (ALU, sevenSegments, ALU_to_decoder)
├── ALU_to_decoder.mpf            # ModelSim project file
├── ALU_to_decoder_cr.mti           # ModelSim compile record
│
├── encoder_to_decoder.v              # decoder_7seg, decimal_to_bcd, encoder_to_decoder
├── tb_encoder_to_decoder.v             # Testbench
├── encoder_to_decoder.mpf                # ModelSim project file
├── encoder_to_decoder_cr.mti               # ModelSim compile record
│
├── transcript                                # Combined simulation log
└── vsim.wlf                                    # Waveform database
```

## Design 1: ALU with 7-Segment Output

### ALU

An 8-function, 2-bit ALU selected by a 3-bit opcode:

```verilog
module ALU (A, B, ALU_sel, ALU_result);
input  [1:0] A, B;
input  [2:0] ALU_sel;
output [3:0] ALU_result;
```

| `ALU_sel` | Operation | Result |
|---|---|---|
| 000 | AND | `A & B` |
| 001 | OR | `A \| B` |
| 010 | Addition | `A + B` |
| 011 | Subtraction | `A - B` |
| 100 | Multiplication | `A * B` |
| 101 | Greater-than | `4'b1010` if `A>B`, else `4'b1011` |
| 110 | Less-than | `4'b1011` if `A<B`, else `4'b1010` |
| 111 | Equal | `4'b1100` if `A==B`, else `4'b0000` |

### Seven-Segment Display

`sevenSegments` maps the 4-bit ALU result onto a common 7-segment pattern, including special glyphs for hexadecimal-style digits (`A`, `b`) and an "=" symbol used to flag comparison results:

```verilog
module sevenSegments (bcd, dec);
input  [3:0] bcd;
output reg [6:0] dec;
```

### Top Module

`ALU_to_decoder` wires the ALU output into the seven-segment decoder, and also exposes the two low-order result bits directly on discrete LEDs:

```verilog
module ALU_to_decoder (A, B, ALU_sel, Segmentleds, leds);
input  [1:0] A, B;
input  [2:0] ALU_sel;
output [6:0] Segmentleds;
output [1:0] leds;

ALU ALU_dut (A, B, ALU_sel, ALU_result);
sevenSegments sevenSegments_dut (ALU_result, Segmentleds);
assign leds = ALU_result[1:0];
endmodule
```

## Design 2: Keypad Encoder → 7-Segment Decoder

### 7-Segment Decoder (vector output)

Same BCD-to-7-segment logic as prior labs, refactored to a single 7-bit output vector (`seg[0]`=a … `seg[6]`=g) instead of seven separate scalar ports:

```verilog
module decoder_7seg (input A, B, C, D, output [6:0] seg);
```

### Decimal-to-BCD Encoder

Takes a 10-bit one-hot keypad input and encodes the active line to 4-bit BCD:

```verilog
module decimal_to_bcd (input [9:0] i, output [3:0] a);
```

### Top Module

`encoder_to_decoder` instantiates three independent encoder→decoder chains, one per display digit:

```verilog
module encoder_to_decoder (
    input  [9:0] i, k, l,
    output [6:0] seg1, seg2, seg3
);
wire [3:0] bcd1, bcd2, bcd3;

decimal_to_bcd G1 (i, bcd1);
decimal_to_bcd G2 (k, bcd2);
decimal_to_bcd G3 (l, bcd3);

decoder_7seg D1 (bcd1[3], bcd1[2], bcd1[1], bcd1[0], seg1);
decoder_7seg D2 (bcd2[3], bcd2[2], bcd2[1], bcd2[0], seg2);
decoder_7seg D3 (bcd3[3], bcd3[2], bcd3[1], bcd3[0], seg3);
endmodule
```

### Testbench

`tb_encoder_to_decoder.v` drives all three keypad inputs to `0` initially, then applies two test cases (`5,2,9` and `0,7,4`) at 10 ns intervals using named port connections:

```verilog
encoder_to_decoder uut (
    .i(i), .k(k), .l(l),
    .seg1(seg1), .seg2(seg2), .seg3(seg3)
);
```

## Running the Simulation

Tested with **ModelSim – Intel FPGA Edition (2020.1)**.

**ALU + 7-segment (interactive, no testbench):**
```tcl
vlib work
vlog ALU_to_decoder.v
vsim work.ALU_to_decoder
add wave sim:/ALU_to_decoder/*
force -freeze sim:/ALU_to_decoder/A 2'b01 0
force -freeze sim:/ALU_to_decoder/B 2'b10 0
force -freeze sim:/ALU_to_decoder/ALU_sel 3'b010 0
run
```

**Keypad encoder/decoder:**
```tcl
vlib work
vlog encoder_to_decoder.v tb_encoder_to_decoder.v
vsim work.tb_encoder_to_decoder
add wave -r sim:/tb_encoder_to_decoder/*
run -all
```

## Notes on Debugging

An earlier version of the keypad testbench connected to the top module using scalar port names (`led_a1`, `led_b1`, …) left over from a previous design revision, after the top module had already been refactored to use 7-bit vector ports (`seg1`, `seg2`, `seg3`). This produced `vsim-3389` ("port not found") and `vsim-3365` ("too many port connections") errors. The fix was to update the testbench's port connections — by name, using `.i(i)`, `.seg1(seg1)`, etc. — to match the current module's actual port list rather than an older version's.

## Results

Both designs compiled and simulated with **0 errors** in their final versions. Waveforms are available in `vsim.wlf` (open with `vsim -view vsim.wlf`).

## Author

Amr Khaled Sedik — Computer Engineering, Ain Shams University
