# 2-to-1 MUX & Full Adder — Structural Verilog & ModelSim

Gate-level (structural) Verilog designs for a 2-to-1 multiplexer and a 1-bit full adder, each built from primitive AND / OR / NOT / XOR gate modules and verified with a testbench in ModelSim.

## Overview

| Design | Module | Testbench | Built From |
|---|---|---|---|
| 2-to-1 MUX | `mux2t1` (`mux.v`) | `mux_tb.v` | AND, OR, NOT |
| Full Adder | `fulladder` (`fulladder.v`) | `fulladder_tb.v` | AND, OR, XOR |

## Repository Structure

```
├── mux.v                 # Gate primitives + 2-to-1 mux
├── mux_tb.v               # Mux testbench
├── mux.mpf                 # ModelSim project file
├── mux_cr.mti               # ModelSim compile record
│
├── fulladder.v             # Gate primitives + full adder
├── fulladder_tb.v           # Full adder testbench
├── fulladder.mpf              # ModelSim project file
├── fulladder_cr.mti            # ModelSim compile record
│
├── transcript               # Simulation log
└── vsim.wlf                  # Waveform database
```

## Design

### 2-to-1 Multiplexer

Implemented structurally as `y = (D0 & ~s) | (D1 & s)`, using instantiated `andGate`, `orGate`, and `notGate` primitives:

```verilog
module mux2t1 (s, D0, D1, y);
input s, D0, D1;
output y;

wire nots, out_G2, out_G3;

notGate G1 (s, nots);
andGate G2 (D0, nots, out_G2);
andGate G3 (s, D1, out_G3);
orGate  G4 (out_G2, out_G3, y);
endmodule
```

**Truth table**

| s | D0 | D1 | y |
|---|----|----|---|
| 0 | 0  | x  | 0 |
| 0 | 1  | x  | 1 |
| 1 | x  | 0  | 0 |
| 1 | x  | 1  | 1 |

### Full Adder

Built from two XOR gates (sum), two AND gates and an OR gate (carry):

```verilog
module fulladder (A, B, Cin, S, Cout);
input A, B, Cin;
output S, Cout;
wire out_G1, out_G3, out_G4;

xorGate G1 (A, B, out_G1);
xorGate G2 (out_G1, Cin, S);
andGate G3 (Cin, out_G1, out_G3);
andGate G4 (B, A, out_G4);
orGate  G5 (out_G3, out_G4, Cout);
endmodule
```

**Truth table**

| A | B | Cin | S | Cout |
|---|---|-----|---|------|
| 0 | 0 | 0   | 0 | 0 |
| 0 | 1 | 0   | 1 | 0 |
| 1 | 0 | 0   | 1 | 0 |
| 1 | 1 | 0   | 0 | 1 |
| 0 | 0 | 1   | 1 | 0 |
| 0 | 1 | 1   | 0 | 1 |
| 1 | 0 | 1   | 0 | 1 |
| 1 | 1 | 1   | 1 | 1 |

## Testbenches

Both testbenches apply stimuli every 10 ns to cover all relevant input combinations — the mux testbench exercises both select states with each data pattern, and the full adder testbench sweeps the complete 3-input truth table.

## Running the Simulation

Tested with **ModelSim – Intel FPGA Edition (2020.1)**.

```tcl
vlib work
vlog mux.v mux_tb.v
vsim work.mux_tb
add wave -r sim:/mux_tb/*
run -all
```

```tcl
vlib work
vlog fulladder.v fulladder_tb.v
vsim work.Fulladder_tb
add wave -r sim:/Fulladder_tb/*
run -all
```

## Results

Both designs compiled and simulated with **0 errors**. Output waveforms match the expected truth tables and are available in `vsim.wlf` (open with `vsim -view vsim.wlf`).

## Author

Amr Khaled Sedik — ECE Engineering, Ain Shams University
