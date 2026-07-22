# BCD Counter with 7-Segment Display — Verilog & ModelSim

A synchronous BCD counter project built up in two stages: a single-digit 0–9 free-running counter, and its extension into a two-digit 00–59 (60-second) counter — the classic "seconds" counter used in digital clocks/timers. Both stages decode their count live onto seven-segment displays and are simulated in ModelSim.

## Overview

| Version | Top Module | Digits | Range | Files |
|---|---|---|---|---|
| v1 — Single digit | `counter_to_decoder` | 1 | 0–9 | `bcd_counter_4bit.v` (3-port), `decoder_7.v`, `counter_to_decoder.v` |
| v2 — Two digit | `counter_to_decoder` | 2 | 00–59 | `bcd_counter_4bit.v` (4-port, w/ `Enable`), `bcd_counter2.v`, `decoder_7.v`, `counter_to_decoder.v` |

v2 extends v1 by adding a second, cascaded counter stage: the units digit counts 0–9 as before, but now also emits an `Enable` pulse on wraparound; a new mod-6 tens-digit counter advances only on that pulse. Together they produce the full 00–59 sequence, one count per clock — v1's design is effectively the "units digit" building block reused inside v2.

## Repository Structure

```
├── bcd_counter_4bit.v        # Units digit counter — see Design below for v1 vs v2 port lists
├── bcd_counter2.v              # v2 only: tens digit, mod-6, gated by Enable
├── decoder_7.v                    # BCD-to-7-segment decoder (shared, instantiated once per digit)
├── counter_to_decoder.v             # Top module (v1: single digit; v2: cascaded two digit)
├── counter_to_decoder.mpf             # ModelSim project file (v1)
├── counter_to_decoder_cr.mti            # ModelSim compile record (v1)
├── counter_to_decoder2.mpf                # ModelSim project file (v2)
├── counter_to_decoder2_cr.mti               # ModelSim compile record (v2)
│
├── transcript                                 # Simulation log
└── vsim.wlf                                     # Waveform database
```

## Design

### v1 — Single-Digit Counter (0–9)

Synchronous up-counter with asynchronous reset. Wraps back to 0 once it hits 9:

```verilog
module bcd_counter (clk, reset, count);
input clk, reset;
output [3:0] count;
reg    [3:0] count;

always @ (posedge clk or posedge reset)
    if (reset)
        count <= 0;
    else if (count == 9)
        count <= 4'b0;
    else
        count <= count + 1'b1;
endmodule
```

```verilog
module counter_to_decoder (clk, reset, segment_leds);
input  clk, reset;
output [6:0] segment_leds;
wire   [3:0] count_wire;

bcd_counter    bcd_counter_dut  (clk, reset, count_wire);
decoder_7seg   decoder_7seg_dut (count_wire[3], count_wire[2], count_wire[1], count_wire[0],
                                  segment_leds[6], segment_leds[5], segment_leds[4],
                                  segment_leds[3], segment_leds[2], segment_leds[1], segment_leds[0]);
endmodule
```

### v2 — Two-Digit Counter (00–59)

`bcd_counter` is upgraded to also output an `Enable` pulse for one clock every time it wraps from 9 to 0:

```verilog
module bcd_counter (
    input clk,
    input reset,
    output reg [3:0] count,
    output reg Enable
);
    always @ (posedge clk or posedge reset) begin
        if (reset) begin
            count  <= 4'b0000;
            Enable <= 1'b0;
        end else if (count == 9) begin
            count  <= 4'b0000;
            Enable <= 1'b1;   // pulse high for one clock when wrapping
        end else begin
            count  <= count + 1'b1;
            Enable <= 1'b0;
        end
    end
endmodule
```

A new tens-digit counter only advances on that `Enable` pulse, and wraps mod-6:

```verilog
module bcd_counter2 (
    input clk,
    input reset,
    input Enable,
    output reg [3:0] count
);
    always @ (posedge clk or posedge reset) begin
        if (reset)
            count <= 4'b0000;
        else if (Enable) begin
            if (count == 5)
                count <= 4'b0000;
            else
                count <= count + 1'b1;
        end
    end
endmodule
```

The top module cascades both counters into two instances of the decoder:

```verilog
module counter_to_decoder (
    input clk,
    input reset,
    output [6:0] segment_leds1,   // units digit
    output [6:0] segment_leds2    // tens digit
);
    wire [3:0] count_wire1, count_wire2;
    wire enable;

    bcd_counter  bcd_counter1_dut (.clk(clk), .reset(reset), .count(count_wire1), .Enable(enable));
    bcd_counter2 bcd_counter2_dut (.clk(clk), .reset(reset), .Enable(enable),    .count(count_wire2));

    decoder_7seg decoder_7seg_dut1 (.A(count_wire1[3]), .B(count_wire1[2]), .C(count_wire1[1]), .D(count_wire1[0]),
                                     .led_a(segment_leds1[0]), .led_b(segment_leds1[1]), .led_c(segment_leds1[2]),
                                     .led_d(segment_leds1[3]), .led_e(segment_leds1[4]), .led_f(segment_leds1[5]),
                                     .led_g(segment_leds1[6]));

    decoder_7seg decoder_7seg_dut2 (.A(count_wire2[3]), .B(count_wire2[2]), .C(count_wire2[1]), .D(count_wire2[0]),
                                     .led_a(segment_leds2[0]), .led_b(segment_leds2[1]), .led_c(segment_leds2[2]),
                                     .led_d(segment_leds2[3]), .led_e(segment_leds2[4]), .led_f(segment_leds2[5]),
                                     .led_g(segment_leds2[6]));
endmodule
```

### 7-Segment Decoder (shared)

Standard combinational BCD-to-7-segment logic, used by both versions:

```verilog
module decoder_7seg (A, B, C, D, led_a, led_b, led_c, led_d, led_e, led_f, led_g);
```

## Running the Simulation

Tested with **ModelSim – Intel FPGA Edition (2020.1)**.

**v1 — single digit:**
```tcl
vlib work
vlog bcd_counter_4bit.v decoder_7.v counter_to_decoder.v
vsim work.counter_to_decoder
add wave sim:/counter_to_decoder/*
force -freeze sim:/counter_to_decoder/reset 1 0
force -freeze sim:/counter_to_decoder/clk 0 0, 1 5 -repeat 10
run 20
force -freeze sim:/counter_to_decoder/reset 0 0
run 200
```
`segment_leds` should cycle through the 0–9 digit patterns every clock period.

**v2 — two digit (00–59):**
```tcl
vlib work
vlog bcd_counter_4bit.v bcd_counter2.v decoder_7.v counter_to_decoder.v
vsim work.counter_to_decoder
add wave sim:/counter_to_decoder/*

force -freeze sim:/counter_to_decoder/reset 1 0
force -freeze sim:/counter_to_decoder/clk 0 0, 1 {50 ps} -r 100
run

force -freeze sim:/counter_to_decoder/reset 0 0
run 6000
```
`segment_leds1` (units) cycles 0–9 once per clock; `segment_leds2` (tens) advances by one only on every 10th clock — together showing 00, 01, 02, … 58, 59, 00, …

## Design Notes

A few things worth knowing if you're extending this project:

- **Keep counter port lists consistent between versions.** `bcd_counter` changes its port list from v1 (3 ports) to v2 (4 ports, adding `Enable`) — if you mix an old top module with the new counter file (or vice versa), you'll get connection-count mismatches at elaboration.
- **Module/port naming matters across files.** The two v2 counters must have distinct module names (`bcd_counter` vs `bcd_counter2`) even though they're structurally similar — ModelSim will silently overwrite an existing module of the same name (`vlog-2275`) if two files declare it, and only the last-compiled one survives.
- **Port width must match at instantiation.** Connecting a 1-bit `Enable` port to a 4-bit signal (or vice versa) compiles fine but triggers `vsim-3015` port-size-mismatch warnings at elaboration — double check bit widths agree between a module's `input`/`output` declarations and what's wired into it at the instantiation site.
- **Keep the decoder's port list consistent.** If `decoder_7seg` is refactored to use a single 7-bit `seg` vector instead of seven scalar `led_a..led_g` ports (as in some other labs in this series), every instantiation of it must be updated to match — otherwise you'll see `vsim-3063` ("port not found") and `vsim-2685` ("too few port connections") errors.

## Results

Both versions compile and simulate with **0 errors** in their final form. v1 correctly cycles a single seven-segment display through digits 0–9. v2's two-digit display correctly counts 00 through 59 and rolls over on the 60th clock. Waveforms are available in `vsim.wlf` (open with `vsim -view vsim.wlf`).

## Author

Amr Khaled Sedik — Computer Engineering, Ain Shams University
