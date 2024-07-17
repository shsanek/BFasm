# BFASM

<img src="https://github.com/user-attachments/assets/a4c9a7e7-d7ab-4ee1-878a-05be4c025ab0" alt="INITIAL" width="200"/>

This is a project to generate Brainfuck code to execute BFASM assembler on a 16-bit RAM virtual machine. The virtual machine works with 2-byte cells (16 bits). There are 2^16 cells or 128KB of memory available for addressing. The machine has 6 general purpose registers (r0-r5), stack operations, conditional jump commands and basic integer 16-bit arithmetic commands. The project has an entertaining and educational purpose.

## BF Code

[BF Code](Sources/Products/result.bf) - this is the system kernel code along with the `BFasm` parser

## Verified Interpreters

Not all interpreters are capable of executing the kernel at normal speed. And others may have console input/output, which makes inserting large programs a problem.

1. [nayuki.io](https://www.nayuki.io/page/brainfuck-interpreter-javascript) - works good
2. [brainfuck.michd.me](https://brainfuck.michd.me/) - some work is needed for input, not work copy/past to input
3. [mitxela](https://mitxela.com/other/brainfuck) - not work copy/past to input
4. [bf.doleczek.pl/](https://www.bf.doleczek.pl/) - not work copy/past to input

## Example Programs

The built-in assembler does not support labels. For convenience, I link examples using `AsmBuilder`

1. [Sieve of Eratosthenes](Sources/AsmBuilder/example/SieveOfEratosthenes.bfasm) - after `run`, you need to provide the last number to check as input
2. [BF interpellator](Sources/AsmBuilder/example/bfemu.bfasm) - after `run` should be followed by a brain fuck program with a `;`, then the data for the input. I have tested this program very loosely so it may not work correctly for some cases.


## Virtual Machine Command Description

| Command  | Description                                                                                  |
|----------|---------------------------------------------------------------------------------------------|
| `mov`    | Moves the operand value to the specified register or memory.                                |
| `inc`    | Increments the value in the specified register or memory by 1.                              |
| `dec`    | Decrements the value in the specified register or memory by 1.                              |
| `exit`   | Terminates execution and saves the error code.                                              |
| `add`    | Adds the operand value to the specified register or memory.                                 |
| `sub`    | Subtracts the operand value from the specified register or memory and sets zero and overflow flags. |
| `mul`    | Multiplies the operand value with the value in the specified register or memory.            |
| `div`    | Divides the value in the specified register or memory by the operand value and pushes the remainder to the fast stack s0. |
| `cmp`    | Compares the value in the specified register or memory with the operand and sets zero and overflow flags. |
| `mod`    | Divides the value in the specified register or memory by the operand value, saving the remainder in the register or memory, and pushes the result to the fast stack s0. |
| `jmp`    | Jumps to the address specified in the register or memory.                                   |
| `j!=`    | Jumps to the address specified in the register or memory if the zero flag is not set.       |
| `j==`    | Jumps to the address specified in the register or memory if the zero flag is set.           |
| `j<`     | Jumps to the address specified in the register or memory if the overflow flag is set.       |
| `j=>`    | Jumps to the address specified in the register or memory if the overflow flag is not set.   |
| `j=<`    | Jumps to the address specified in the register or memory if the overflow flag or zero flag is set. |
| `j>`     | Jumps to the address specified in the register or memory if the overflow flag and zero flag are not set. |
| `input`  | Reads input data and saves it to the specified register or memory.                          |
| `resIn`  | Resets the read necessity flag.                                                             |
| `out`    | Outputs the value from the specified register or memory.                                    |
| `push`   | Increases the stack and copies the value from the specified register or memory into it.     |
| `pop`    | Decreases the stack and loads the value from it into the specified register or memory.      |
| `get`    | Loads the value from the stack with the specified offset.                                   |
| `call`   | Increases the stack, saves the current command address to the stack, and jumps to the address specified in the register or memory. |
| `ret`    | Switches execution to the address specified in the stack and decreases the stack.           |
| `#`      | Reads a comment without executing actions.                                                  |
| `run`    | Starts executing the code above. No semicolon needed after this command.                    |

### Memory

Each command occupies 1 or 2 memory cells (2 if there is a constant). The program will be loaded from cell 0. The `cs` register will point to the cell following the program.

## Memory Stack

This stack is located in memory and managed using `push` and `pop`. The stack grows upwards and is located immediately after the loaded program. You can access remote stack values using the `cs` register (after copying it to a general-purpose register) or using `get`. `cs` is a pointer to the head with the last value.

## Command Structure

A command can have 0 to 2 arguments. The first argument can be modified depending on the command. The second argument is an operand and is not modified.

### Arguments

Arguments can be:

- **Registers**: `r0`, `r1`, `r2`, `r3`, `r4`, `r5`
- **Memory pointers** (only through registers): `ptr r0`, `ptr r1`, `ptr r2`, `ptr r3`, `ptr r4`, `ptr r5`
- **Constants**: A decimal number, e.g., `12345` increases the memory space occupied by the command by 1. (only one per command)
- **Special values**:
  - `cs` - Memory pointer in the current stack value
  - `s0` - Top value of the fast stack

### Command Syntax

Each command should end with a semicolon `;`, including comments, but after the `run` command, a semicolon is not needed.

### Example Command

```asm
sub r0, r1;
```
### Fast Stack
The fast stack is a core stack (not in memory) containing only 8 16-bit values. When this stack overflows, values are irreversibly lost. Some commands can save additional data to this stack, such as mul and div.

#### Fast Stack Operations
For pop/push operations to the fast stack, refer to s0. If s0 is used for reading, a pop occurs; if for writing, a push occurs.

#### Fast Stack Operation Examples
The command `mov s0, 12;` performs a push.
The command `mov r0, s0;` performs a pop.
The command `sub s0, r1;` first performs a pop, then a push.
