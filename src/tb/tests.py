## ========================================================================= ##
## Copyright (c) 2026, Stephen Henry
## All rights reserved.
##
## Redistribution and use in source and binary forms, with or without
## modification, are permitted provided that the following conditions are met:
##
## * Redistributions of source code must retain the above copyright notice, this
##   list of conditions and the following disclaimer.
##
## * Redistributions in binary form must reproduce the above copyright notice,
##   this list of conditions and the following disclaimer in the documentation
##   and/or other materials provided with the distribution.
##
## THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
## AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
## IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
## ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
## LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
## CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
## SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
## INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
## CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
## ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
## POSSIBILITY OF SUCH DAMAGE.
## ========================================================================= ##

import cocotb

from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge


async def reset_sequence(dut, cycles_n: int) -> None:
    dut.arst_n.value = 1
    await RisingEdge(dut.clk)

    dut.arst_n.value = 0
    for _ in range(cycles_n):
        await RisingEdge(dut.clk)

    dut.arst_n.value = 1
    await RisingEdge(dut.clk)


@cocotb.test()
async def simple_testbench(dut):

    if dut.W.value != 16:
        print(f"Testbench only supports W=16 for now (W={dut.W.value}).")
        return

    await reset_sequence(dut, cycles_n=5)

    test_cases = [
        (0xFFFF, 0, 0x0001, 0, 1),
        (0x0000, 0, 0x8000, 15, 1),
        (0x0000, 1, 0x0001, 0, 1),
        (0x0000, 15, 0x4000, 14, 1),
        (0x2A37, 8, 0x0080, 7, 1),
        (0xFFFF, 0, 0x0000, 0, 0),
    ]

    for test_case in test_cases:
        dut.x_i.value = test_case[0]
        dut.pos_i.value = test_case[1]
        await RisingEdge(dut.clk)

    for _ in range(5):
        await RisingEdge(dut.clk)

    dut._log.info("Test Completed Successfully")
