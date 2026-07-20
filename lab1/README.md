# Basic Logic Gates — Verilog & ModelSim

Verilog implementations of fundamental 2-input logic gates (AND, OR), each verified with a self-checking testbench and simulated in ModelSim.

## Overview

| Gate | Module | Testbench | Expression |
|------|--------|-----------|------------|
| AND  | `andGate.v` | `testbenchandGate.v` | `c = a & b` |
| OR   | `orGate.v`  | `testbenchorGate.v`  | `c = a \| b` |

## Repository Structure

```
├── andGate.v              # AND gate RTL
├── testbenchandGate.v     # AND gate testbench
├── andGate.mpf            # ModelSim project file
├── andGate_cr.mti         # ModelSim compile record
│
├── orGate.v                # OR gate RTL
├── testbenchorGate.v       # OR gate testbench
├── orGate.mpf               # ModelSim project file
├── orGate_cr.mti            # ModelSim compile record
│
├── transcript              # Simulation log
└── vsim.wlf                # Waveform database
```

## Design

Each gate is a simple combinational module with two inputs and one output:

```verilog
module andGate (a, b, c);
input a, b;
output c;
assign c = a & b;
endmodule
```

```verilog
module orGate (a, b, c);
input a, b;
output c;
assign c = a | b;
endmodule
```

## Testbenches

Each testbench drives all four input combinations (`00`, `01`, `10`, `11`) at 10 ns intervals to exercise the full truth table:

```verilog
module andGate_tb;
reg A, B;
wire C;
andGate andGate_dut (A, B, C);
initial begin
  #10 A = 0; B = 0;
  #10 A = 0; B = 1;
  #10 A = 1; B = 0;
  #10 A = 1; B = 1;
end
endmodule
```

## Running the Simulation

Tested with **ModelSim – Intel FPGA Edition (2020.1)**.

```tcl
vlib work
vlog andGate.v testbenchandGate.v
vsim work.andGate_tb
add wave -r sim:/andGate_tb/*
run -all
```

Repeat with `orGate.v` / `testbenchorGate.v` for the OR gate.

## Results

Both designs compiled and simulated with **0 errors**. Waveforms confirm correct gate behavior across all input combinations and are available in `vsim.wlf` (open with `vsim -view vsim.wlf`).

## Author

Amr Khaled Sedik — ECE Engineering, Ain Shams University
