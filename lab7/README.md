# Lab 7 — FSM-Based Counters: One-Hot Walking Bit & BCD — Verilog & ModelSim

Two independent finite-state-machine designs from the same lab: a 10-bit one-hot "walking bit" / LED-chaser counter clocked at 1Hz, and a 4-bit BCD (0–9) counter built explicitly as a 2-state FSM rather than a plain up-counter. Both simulated in ModelSim.

## Overview

| Project | Top Module | States | Behavior |
|---|---|---|---|
| One-Hot Walking Counter | `one_hot_counter` | `S0`, `S1`, `S2` | 10-bit bit walks left then right, repeating |
| BCD FSM Counter | `bcd_counter_FSM` | `S0`, `S1` | 4-bit count cycles 0–9, repeating |

## Repository Structure

```
├── clock_divider.v            # Input clock -> 1Hz toggle (one-hot project)
├── one_hot_counter_fsm.v        # Walking one-hot bit FSM
├── one_hot_counter.v              # Top module: clock divider + FSM
├── hot_counter.mpf                  # ModelSim project file (one-hot)
├── hot_counter_cr.mti                 # ModelSim compile record (one-hot)
│
├── bcd_counter_FSM.v              # 4-bit BCD counter as a 2-state FSM
├── bcd_FSM.mpf                       # ModelSim project file (BCD FSM)
├── bcd_FSM_cr.mti                      # ModelSim compile record (BCD FSM)
│
├── transcript                            # Simulation log
└── vsim.wlf                                # Waveform database
```

---

## Project 1: One-Hot "Walking Bit" Counter with 1Hz Clock Divider

A 10-bit one-hot counter that walks a single lit bit left across the vector, then bounces back and shifts right — a classic "Cylon eye" / LED chaser pattern — clocked at 1Hz from a 25MHz-style input clock.

### Clock Divider

Counts up to 25,000,000 input clock edges, then toggles `CLK1Hz` and resets the counter — turning (for example) a 50MHz board clock into a 1Hz clock suitable for visually observing the walking-bit pattern on real hardware:

```verilog
module clock_divider (clk, reset, CLK1Hz);
input clk, reset;
output CLK1Hz;
reg CLK1Hz;
reg [24:0] count;

always @(posedge clk or posedge reset)
    if (reset) begin
        count  <= 0;
        CLK1Hz <= 0;
    end else begin
        if (count < 25_000_000)
            count <= count + 1;
        else begin
            CLK1Hz = ~CLK1Hz;
            count  <= 0;
        end
    end
endmodule
```

### One-Hot Counter FSM

A 3-state machine (`S0` reset/init, `S1` shift-left, `S2` shift-right) that walks a single `1` bit across a 10-bit vector:

```verilog
module one_hot_counter_fsm (clk, reset, oneHot);
input clk, reset;
output [9:0] oneHot;

parameter S0 = 2'b00, S1 = 2'b01, S2 = 2'b10;
reg [9:0] oneHot;
reg [1:0] State;

always @(posedge clk or posedge reset)
    if (reset) begin
        State  = S0;
        oneHot <= 10'b0000_0000_01;
    end else begin
        case (State)
            S0: State <= S1;
            S1: if (oneHot < 10'b1000_0000_00)
                    oneHot <= oneHot << 1;
                else
                    State <= S2;
            S2: if (oneHot > 10'b0000_0000_01)
                    oneHot <= oneHot >> 1;
                else
                    State <= S1;
        endcase
    end
endmodule
```

**Behavior:** starting from `oneHot = 0000000001`, the FSM shifts the lit bit left one position per clock until it reaches the MSB, then reverses and shifts right back to the LSB, repeating indefinitely.

### Top Module

```verilog
module one_hot_counter (clk, reset, oneHot);
input clk, reset;
output [9:0] oneHot;
wire CLK1Hz;

clock_divider     clock_divider_1Hz (clk, reset, CLK1Hz);
one_hot_counter_fsm one_hot_cnt     (CLK1Hz, reset, oneHot);
endmodule
```

### Running the Simulation

Because the clock divider counts to 25 million real edges before toggling, driving it through the full top module in simulation is impractically slow. For functional verification, simulate `one_hot_counter_fsm` directly with a fast testbench clock, and verify `clock_divider` separately (or with a reduced divisor) if you need to check the full chain:

```tcl
vlib work
vlog one_hot_counter_fsm.v
vsim work.one_hot_counter_fsm
add wave sim:/one_hot_counter_fsm/*

force -freeze reset 1 0
force -freeze clk 0 0, 1 5 -repeat 10
run 20
force -freeze reset 0 0
run 400
```

`oneHot` should start at `10'b0000000001`, walk left one bit per clock until it reaches `10'b1000000000`, then walk back right to `10'b0000000001`, and repeat.

To simulate the full top module (clock divider included), either force `clk` fast enough to complete a few 25,000,000-cycle divisions within your run time, or temporarily lower the divider's threshold for simulation purposes only.

### Design Notes

- **`CLK1Hz` is not explicitly declared as a wire in `one_hot_counter`.** Verilog's implicit net declaration rules mean an undeclared identifier used as a wire defaults to a 1-bit `wire`, so this compiles — but it typically produces an implicit-declaration warning (`vlog-2623` or similar) and is worth declaring explicitly (`wire CLK1Hz;`) for clarity and to catch typos.
- **Mixed blocking/non-blocking assignments in one always block.** `one_hot_counter_fsm` uses `State = S0;` (blocking) on reset but `State <= S1;` (non-blocking) elsewhere in the same clocked `always` block. Mixing `=` and `<=` for the same signal in a sequential block is legal but not recommended — style guides (e.g. IEEE 1364) recommend using non-blocking (`<=`) exclusively inside a clocked `always` block.
- **The `S1`/`S2` case items rely on implicit state-holding.** Neither branch explicitly reassigns `State` when staying in place, and there's no `default:` case item — this works here, but adding an explicit `default: State <= State;` makes the intent clearer and guards against unreachable-state lockup if `State` is ever corrupted (e.g. by an SEU in real hardware).

---

## Project 2: 4-Bit BCD Counter (FSM-Based)

A 0–9 BCD counter implemented as a 2-state finite state machine, rather than a plain up-counter — an FSM-style approach to the same counting behavior used in earlier labs.

```verilog
module bcd_counter_FSM (
    input clk,
    input reset,
    output reg [3:0] count
);

parameter S0 = 2'b00,
          S1 = 2'b01;

reg [1:0] State;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        State <= S0;
        count <= 4'b0000;
    end else begin
        case (State)
            S0: begin
                State <= S1;               // move to counting state
            end
            S1: begin
                if (count < 9)
                    count <= count + 1'b1; // keep counting up
                else begin
                    State <= S0;            // wrap back to init state
                    count <= 4'b0000;
                end
            end
            default: begin
                State <= S0;
            end
        endcase
    end
end
endmodule
```

**Behavior:** on reset, the FSM enters `S0` with `count = 0`. The next clock moves it to `S1`, where it increments `count` every cycle. Once `count` reaches 9, the FSM drops back to `S0` on the following clock (briefly re-arming) before returning to `S1` to count up again — so `count` cycles 0 → 9 → 0 → 9 … indefinitely, with a one-cycle pause at 0 each time it passes through `S0`.

This differs from a simple `always` block up-counter (like `bcd_counter_4bit.v` in other labs) in that the counting behavior is explicitly modeled as FSM states rather than a single unconditional increment — useful groundwork for FSMs that need more states later (e.g. pause, hold, or direction-reversal behavior).

### Running the Simulation

```tcl
vlib work
vlog bcd_counter_FSM.v
vsim work.bcd_counter_FSM
add wave sim:/bcd_counter_FSM/*

force -freeze sim:/bcd_counter_FSM/clk 0 0, 1 {50 ps} -r 100
force -freeze sim:/bcd_counter_FSM/reset 1 0
run
run
force -freeze sim:/bcd_counter_FSM/reset 0 0
run 1000
```

`count` should hold at `0` while `reset` is high, then begin incrementing once per clock after `reset` is released, wrapping back to `0` after reaching `9`.

### Design Notes

- **Watch for typos in `force` commands.** In one run captured in the transcript, `reset` was accidentally forced to the string value `St0` instead of `0` (`force -freeze sim:/bcd_counter_FSM/reset St0 0`) — an invalid value for a 1-bit signal. ModelSim doesn't hard-error on this, but it produces warnings and leaves `reset` in an unintended state (interpreted as unknown/`x` rather than deasserted), which stalls the counter instead of letting it run. Always double check `force` value syntax (`0`/`1` for single-bit signals) before assuming a stuck counter is an RTL bug.
- **One-cycle detour through `S0` each wrap.** Because `S1` transitions back to `S0` (rather than directly re-arming and staying in a counting state), there's a one-clock delay at `count = 0` every time the counter wraps, before it starts incrementing again. If you want a true continuous 0–9 free-run with no pause, consider merging the wrap-around logic into `S1` directly.

---

## Results

Both designs compile and simulate with **0 errors**. The one-hot counter correctly produces a bouncing walking-bit pattern across its 10-bit output, and the BCD FSM counter correctly cycles `count` through 0–9. Waveforms for both are available in `vsim.wlf` (open with `vsim -view vsim.wlf`).

## Author

Amr Khaled Sedik — Computer Engineering, Ain Shams University
