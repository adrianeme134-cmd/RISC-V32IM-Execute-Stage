# RISC-V RV32IM Execute Stage RTL & Verification

![SystemVerilog](https://img.shields.io/badge/SystemVerilog-RTL%20%2B%20Verification-blue)
![RISC-V](https://img.shields.io/badge/RISC--V-RV32IM-orange)
![Vivado XSim](https://img.shields.io/badge/Vivado%20XSim-Simulation-green)
![Python](https://img.shields.io/badge/Python-Golden%20Model-yellow)
![UVM](https://img.shields.io/badge/UVM-Environment%20Scaffold-purple)

## Overview

This project implements and verifies the execute stage for a 32-bit RISC-V RV32IM-style CPU core. The execute stage performs integer ALU operations, branch comparisons, multiply operations, and multi-cycle divide/remainder operations using a restoring divider with a pipeline stall interface.

The project emphasizes both RTL design and verification: the datapath is written in SystemVerilog, the divider uses a multi-cycle FSM, and the verification flow includes directed tests, randomized testing, assertions, waveform dumping, and a Python-generated golden reference vector file for unsigned division.

## Project Highlights

- Designed a 32-bit execute-stage ALU for RV32I/RV32M-style operations
- Implemented branch comparison logic for signed and unsigned branch instructions
- Added RV32M multiply support for `MUL`, `MULH`, `MULHSU`, and `MULHU`
- Built a multi-cycle restoring divider for `DIV`, `DIVU`, `REM`, and `REMU`
- Generated file-driven division test vectors using a Python golden model
- Verified RTL behavior with task-based SystemVerilog tests and assertions
- Used `stall_o` to model pipeline backpressure during long-latency division
- Started a UVM-style divider verification environment with agent, driver, monitor, sequencer, transaction, environment, test, scoreboard, interface, and top-level testbench scaffolding

## Repository Contents

| File | Description |
| --- | --- |
| `rv32_pkg.sv` | Shared package containing datapath parameters, opcode constants, funct fields, and ALU operation encodings |
| `execute.sv` | Execute-stage RTL containing ALU, branch, multiply, and divide/remainder operation selection |
| `division.sv` | Multi-cycle unsigned restoring divider with `IDLE` and `STALL` FSM states |
| `execute_tb1.sv` | Task-based execute-stage testbench with directed and randomized tests |
| `division_tb.sv` | File-driven divider testbench that reads expected quotient/remainder vectors |
| `Division_Golden_Model.py` | Python golden model that generates directed and randomized unsigned division vectors |
| `dut_transaction.sv` | UVM transaction scaffold for one divide operation, including dividend/divisor and expected/actual quotient/remainder fields |
| `dut_interface.sv` | UVM interface scaffold for grouping divider DUT signals between the driver, monitor, and top-level testbench |
| `dut_driver.sv` | UVM driver scaffold intended to convert transactions into divider input/control signal activity |
| `dut_monitor.sv` | UVM monitor scaffold intended to observe divider outputs and forward completed results |
| `dut_scoreboard.sv` | UVM scoreboard scaffold intended to compare expected and actual divider results |
| `dut_sequencer.sv` | UVM sequencer scaffold intended to pass generated transactions to the driver |
| `dut_agent.sv` | UVM agent implementation that creates monitor/driver/sequencer handles and connects the driver to the sequencer when active |
| `dut_env.sv` | UVM environment scaffold intended to instantiate the agent and scoreboard |
| `dut_test.sv` | UVM test scaffold intended to create the environment and launch directed/random sequences |
| `dut_top_tb.sv` | UVM top-level testbench scaffold showing the intended Sequence -> Sequencer -> Driver -> DUT -> Monitor -> Scoreboard flow |

## Execute Stage Architecture

The execute stage receives two 32-bit operands and a 5-bit ALU operation select. The combinational ALU path computes the selected operation, while the final ALU result is registered on the rising edge of `clk_i`.

### Main Interfaces

| Signal | Direction | Description |
| --- | --- | --- |
| `clk_i` | Input | Main clock |
| `rst_ni` | Input | Active-low reset |
| `op_a_i` | Input | First 32-bit operand |
| `op_b_i` | Input | Second 32-bit operand or immediate value |
| `ALU_OP` | Input | Encoded ALU operation select |
| `alu_res_o` | Output | Registered ALU result |
| `branch_taken_o` | Output | Branch decision result |
| `stall_o` | Output | High while the divider is executing |

## Supported Operation Groups

### Integer ALU Operations

- `ADD`
- `SUB`
- `SLL`
- `SLT`
- `SLTU`
- `XOR`
- `SRL`
- `SRA`
- `OR`
- `AND`

### Branch Compare Operations

- `BEQ`
- `BNE`
- `BLT`
- `BLTU`
- `BGE`
- `BGEU`

### Multiply Operations

- `MUL`: lower 32 bits of multiplication result
- `MULH`: upper 32 bits of signed x signed multiplication
- `MULHSU`: upper 32 bits of signed x unsigned multiplication
- `MULHU`: upper 32 bits of unsigned x unsigned multiplication

### Divide and Remainder Operations

- `DIV`: signed division
- `DIVU`: unsigned division
- `REM`: signed remainder
- `REMU`: unsigned remainder

The signed divide/remainder path converts operands into unsigned magnitudes, uses the unsigned divider, then fixes the sign of the quotient or remainder afterward. Division-by-zero and signed overflow cases are handled at the execute-stage level.

## Divider Design

The divider is implemented as a restoring division unit. It uses a small FSM with two states:

| State | Purpose |
| --- | --- |
| `IDLE` | Latches the dividend/divisor and waits for `Division_START` |
| `STALL` | Performs one restoring-division iteration per cycle and asserts `stall_o` |

During division, the divider:

1. Initializes the remainder with the dividend.
2. Aligns the divisor into the upper 32 bits of the internal divisor register.
3. Subtracts the shifted divisor from the current remainder.
4. Keeps the subtraction result and shifts in a quotient bit of `1` if the result is non-negative.
5. Restores the old remainder and shifts in a quotient bit of `0` if the result is negative.
6. Repeats until the 32-bit quotient is complete.

The `stall_o` signal stays high while the divider is in the `STALL` state so that the rest of the CPU pipeline can hold state during a long-latency divide operation.

## Verification Strategy

This project uses two complementary verification paths.

### Execute-Stage Testbench

`execute_tb1.sv` contains task-based tests for individual ALU operations. Each task drives operands and an ALU operation, waits for the result to update, and checks the DUT output with SystemVerilog assertions.

The testbench includes:

- Directed tests for arithmetic, comparison, branch, multiply, divide, and remainder instructions
- Randomized operand testing across the supported operation set
- Signed and unsigned comparison checks
- High-word multiply checks for `MULH`, `MULHSU`, and `MULHU`
- Stall-aware divide/remainder tests that wait for `stall_o` before checking results
- VCD waveform dumping through `$dumpfile` and `$dumpvars`

### Divider Regression Testbench

`division_tb.sv` verifies the standalone divider using a file-driven flow:

1. `Division_Golden_Model.py` generates `division_vectors.txt`.
2. The testbench reads dividend, divisor, expected quotient, and expected remainder values from the file.
3. The testbench launches the divider with `Division_START`.
4. It waits for `stall_o` to deassert.
5. It compares the RTL quotient and remainder against the expected values.
6. It reports total passed and failed tests.

The Python generator includes directed edge cases and 100,000 randomized unsigned division vectors.

### UVM Divider Environment Scaffold

The repository also includes the start of a UVM-style verification environment for the divider DUT. This is currently a scaffold/in-progress environment rather than a completed regression flow. The goal is to move beyond task-based testing and toward a reusable verification structure built around transactions, a sequencer, driver, monitor, scoreboard, agent, environment, and top-level test.

Current UVM-related files describe the intended flow:

```text
Sequence -> Sequencer -> Driver -> DUT
                                 |
                              Monitor -> Scoreboard
```

The most developed UVM component is `dut_agent.sv`. The agent:

- Extends `uvm_agent`
- Registers with the UVM factory using `uvm_component_utils`
- Creates a monitor during `build_phase`
- Creates the driver and sequencer only when the agent is active
- Connects `driver.seq_item_port` to `sequencer.seq_item_export` during `connect_phase`

The remaining UVM files are currently scaffolds documenting the intended responsibility of each component:

- `dut_transaction.sv`: represents one divide transaction
- `dut_interface.sv`: groups DUT signals for class-based access
- `dut_driver.sv`: will drive dividend, divisor, start, and control behavior into the DUT
- `dut_monitor.sv`: will capture completed quotient/remainder results
- `dut_scoreboard.sv`: will compare observed results against expected values
- `dut_sequencer.sv`: will forward transaction items from sequences to the driver
- `dut_env.sv`: will connect the agent and scoreboard
- `dut_test.sv`: will create the environment and launch tests/sequences
- `dut_top_tb.sv`: will instantiate the DUT/interface and call `run_test()`

This scaffold shows the planned direction for extending the divider verification from directed/file-driven testing into a more reusable UVM-based environment.

## Assertion-Based Checks

The divider includes an assertion checking that the FSM returns to `IDLE` after the expected division counter completion point. The testbenches also use immediate assertions to stop the simulation when an operation result does not match the expected value.

## How to Run

These commands assume a Vivado/XSim environment and that all files are in the same directory.

### 1. Generate Division Test Vectors

```bash
python3 Division_Golden_Model.py
```

This creates:

```text
division_vectors.txt
```

### 2. Run the Standalone Divider Regression

```bash
xvlog -sv rv32_pkg.sv division.sv division_tb.sv
xelab division_tb -s division_sim
xsim division_sim -runall
```

### 3. Run the Execute-Stage Testbench

```bash
xvlog -sv rv32_pkg.sv division.sv execute.sv execute_tb1.sv
xelab execute_tb1 -s execute_sim
xsim execute_sim -runall
```

If your simulator requires explicit package visibility in the testbench, add this after the ``timescale line in the testbench:

```systemverilog
import rv32_pkg::*;
```

### 4. UVM Environment Status

The UVM files are currently included as an in-progress verification scaffold. The current task-based and file-driven testbenches are the executable verification flows. The UVM environment should be completed before advertising it as a passing regression.

Recommended next steps for making the UVM flow executable:

1. Define the full `dut_transaction` class with randomized fields and expected result fields.
2. Implement the driver class to apply divider transactions through `dut_interface`.
3. Implement the monitor class to sample `stall_o`, quotient, and remainder after completion.
4. Implement the scoreboard comparison logic.
5. Build a sequence that reuses the Python-style directed/random divide cases.
6. Add a top-level compile/run script for the UVM test.

## Expected Output

The divider regression prints pass/fail messages for each vector and ends with total test counts:

```text
total tests successfully completed: <pass_count>
total tests failed: <fail_count>
```

The execute-stage testbench prints each directed/randomized operation and stops with `$fatal` if an assertion fails.

## Skills Demonstrated

- SystemVerilog RTL design
- RISC-V execute-stage datapath design
- RV32M multiply/divide instruction support
- Multi-cycle FSM design
- Pipeline stall/backpressure signaling
- Signed and unsigned arithmetic handling
- Directed and randomized verification
- Assertion-based verification
- Python golden model generation
- File-driven simulation testing
- Vivado/XSim simulation workflow
- UVM environment organization and agent/component scaffolding
- Waveform-based debug

## Current Status and Future Improvements

Current implementation focus:

- Execute-stage ALU and RV32M operation support
- Multi-cycle restoring divider integration
- Task-based execute-stage verification
- File-driven unsigned divider regression
- In-progress UVM divider verification scaffold

Planned improvements:

- Add functional coverage groups for each ALU operation and edge-case class
- Expand directed tests for `OR`, `AND`, `SRL`, `SRA`, and pass-through operations
- Tighten signed remainder regression coverage
- Complete the UVM transaction, driver, monitor, scoreboard, sequence, environment, and top-level test implementation
- Add a Makefile or script-based one-command simulation flow
- Save regression logs and waveform screenshots under a `results/` or `docs/` directory
- Refactor files into `rtl/`, `tb/`, `models/`, and `scripts/` folders for a cleaner portfolio repository

## Suggested Repository Structure

```text
riscv-rv32im-execute-stage/
├── README.md
├── rtl/
│   ├── execute.sv
│   ├── division.sv
│   └── rv32_pkg.sv
├── tb/
│   ├── execute_tb1.sv
│   ├── division_tb.sv
│   └── uvm/
│       ├── dut_transaction.sv
│       ├── dut_interface.sv
│       ├── dut_driver.sv
│       ├── dut_monitor.sv
│       ├── dut_scoreboard.sv
│       ├── dut_sequencer.sv
│       ├── dut_agent.sv
│       ├── dut_env.sv
│       ├── dut_test.sv
│       └── dut_top_tb.sv
├── models/
│   └── Division_Golden_Model.py
├── results/
│   └── regression logs and coverage reports
└── docs/
    └── waveform screenshots and block diagrams
```

## Project Summary

This project demonstrates a hardware-focused RTL and verification workflow for a RISC-V execute stage. It combines datapath design, signed/unsigned arithmetic, multi-cycle control, stall signaling, Python-based golden modeling, file-driven simulation, assertion-based checking, and the start of a UVM-based verification architecture for future regression growth.
