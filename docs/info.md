<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

# Perceptron with Tiny MAC
This project implements a perceptron computing y = sign(3*x0 - 2*x1 + 1), where x0 and x1 are 4-bit signed inputs from ui_in[7:0]. The output y_reg is on uo_out[0], and sum_reg[7:1] is on uo_out[7:1]. The design uses a sequential 4x4-bit MAC.

## How it works
- Inputs x0 (ui_in[3:0]) and x1 (ui_in[7:4]) are multiplied by weights (3 and -2) and summed with a bias (1).
- The result is passed through a sign function to produce y_reg.
- The MAC operates in three cycles when ena=1, controlled by a finite state machine.

## How to test
- Set ena=1 (ENA pin).
- Apply a reset pulse (RST_N=0 then 1).
- Set ui_in[7:0] using DIP switches (e.g., x0=1, x1=1 as 8'b00010001).
- Observe uo_out[0] (y_reg) for the result (1 if sum ≥ 0, else 0).
- Monitor uo_out[7:1] for the upper sum bits.
