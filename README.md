# Simple Multi-Cycle Processor in VHDL

## Overview

This project implements a simple 9-bit multi-cycle processor in VHDL. It was completed with the main control FSM, datapath control signals, register transfers, and ALU operation logic implemented by me.
The processor supports basic register transfer and arithmetic instructions using a shared internal bus, 8 general-purpose registers, an instruction register, an A register, and a G register for ALU results.

## Supported Instructions

| Opcode | Instruction  | Description                                            |
| ------ | ------------ | ------------------------------------------------------ |
| `000`  | `mv Rx, Ry`  | Copies the value from register `Ry` into register `Rx` |
| `001`  | `mvi Rx, #D` | Loads immediate input data `DIN` into register `Rx`    |
| `010`  | `add Rx, Ry` | Computes `Rx = Rx + Ry`                                |
| `011`  | `sub Rx, Ry` | Computes `Rx = Rx - Ry`                                |

## Instruction Format

The instruction input `DIN` is 9 bits wide:

```text
DIN[8:6] = opcode
DIN[5:3] = Rx
DIN[2:0] = Ry
```

Example:

```text
000 001 010
```

Means:

```text
mv R1, R2
```

## Processor Components

### Control FSM

The processor uses a finite-state machine with four states:

| State | Purpose                                        |
| ----- | ---------------------------------------------- |
| `T0`  | Load instruction into the instruction register |
| `T1`  | Decode instruction and begin execution         |
| `T2`  | Perform ALU operand transfer for add/sub       |
| `T3`  | Write ALU result back to destination register  |

Simple instructions like `mv` and `mvi` finish in `T1`.
Arithmetic instructions like `add` and `sub` require multiple cycles.

## Execution Examples

### `mv Rx, Ry`

```text
T0: IR <- DIN
T1: Rx <- Ry
Done <- 1
```

### `mvi Rx, #D`

```text
T0: IR <- DIN
T1: Rx <- DIN
Done <- 1
```

### `add Rx, Ry`

```text
T0: IR <- DIN
T1: A <- Rx
T2: G <- A + Ry
T3: Rx <- G
Done <- 1
```

### `sub Rx, Ry`

```text
T0: IR <- DIN
T1: A <- Rx
T2: G <- A - Ry
T3: Rx <- G
Done <- 1
```

## Datapath

The datapath contains:

* 8 general-purpose registers: `R0` to `R7`
* Instruction register: `IR`
* Temporary operand register: `A`
* ALU result register: `G`
* Shared 9-bit bus: `BusWires`
* 3-to-8 decoders for selecting source and destination registers
* ALU supporting addition and subtraction

Simulation was performed using a course-provided testbench, which is not included in this repository.

## Target Platform
Designed for FPGA implementation using Vivado, targeting boards such as the Basys 3.
