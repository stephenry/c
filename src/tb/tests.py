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
from cocotb.triggers import Timer, RisingEdge, FallingEdge


async def reset_sequence(dut, cycles_n: int) -> None:
    dut.arst_n.value = 1
    await RisingEdge(dut.clk)

    dut.arst_n.value = 0
    for _ in range(cycles_n):
        await RisingEdge(dut.clk)

    dut.arst_n.value = 1
    await RisingEdge(dut.clk)


async def validate_output(dut, expected_outputs) -> None:

    for y, y_enc, any in expected_outputs:

        await FallingEdge(dut.clk)

        while not dut.vld_o.value:
            await FallingEdge(dut.clk)

        dut._log.info(
            f"input stimulus applied: x_o={dut.x_o.value.to_unsigned():#0{dut.W.value.to_unsigned()}b}, "
            f"pos_o={dut.pos_o.value.to_unsigned()}, "
            f"Validating outputs: y_o={dut.y_o.value.to_unsigned():#0{dut.W.value.to_unsigned()}b}, "
            f"y_enc_o={dut.y_enc_o.value.to_unsigned()}, any_o={bool(dut.any_o.value)}"
        )

        mismatchs = []

        if bool(dut.any_o.value) != any:
            mismatchs.append(
                f"Output any_o mismatch: expected {any}, got {bool(dut.any_o.value)}"
            )

        if any:

            if dut.y_o.value.to_unsigned() != y:
                mismatchs.append(
                    f"Output y_o mismatch: expected {y:#0{dut.W.value.to_unsigned()}b}, "
                    f"got {dut.y_o.value.to_unsigned():#0{dut.W.value.to_unsigned()}b}"
                )

            if dut.y_enc_o.value.to_unsigned() != y_enc:
                mismatchs.append(
                    f"Output y_enc_o mismatch: expected {y_enc}, "
                    f"got {dut.y_enc_o.value.to_unsigned()}"
                )

        if mismatchs:
            break

    if mismatchs:
        error_msg = "Validation failed with the following mismatches:\n" + "\n".join(
            mismatchs
        )
        dut._log.error(error_msg)
        for _ in range(5):
            await FallingEdge(dut.clk)
        assert False, error_msg
    else:
        dut._log.info("All outputs validated successfully.")


async def emit_stimulus(dut, stimulus: list[tuple[int, int]]) -> None:
    """Emit stimulus based on provided test cases.

    Each test case is a tuple of (x_i, pos_i).
    """
    dut.vld_i.value = 0
    await RisingEdge(dut.clk)

    for x, pos in stimulus:
        dut.vld_i.value = 1
        dut.x_i.value = x
        dut.pos_i.value = pos
        await RisingEdge(dut.clk)

    dut.vld_i.value = 0
    await RisingEdge(dut.clk)

    dut._log.info("All stimulus emitted.")


async def await_cycles(dut, cycles_n: int) -> None:
    for _ in range(cycles_n):
        await RisingEdge(dut.clk)


@cocotb.test()
async def test_directed(dut):
    """Run the test of known test cases as specified in the top-level module."""

    if dut.W.value != 16:
        print(f"Testbench only supports W=16 for now (W={dut.W.value}).")
        return

    # Perform reset
    await reset_sequence(dut, cycles_n=5)

    test_cases = [
        (0xFFFE, 0, 0x0001, 0, True),
        (0x0000, 0, 0x8000, 15, True),
        (0x0000, 1, 0x0001, 0, True),
        (0x0000, 15, 0x4000, 14, True),
        (0x2A37, 8, 0x0080, 7, True),
        (0xFFFF, 0, 0x0000, 0, False),
    ]

    cocotb.start_soon(emit_stimulus(dut, [(tc[0], tc[1]) for tc in test_cases]))

    await validate_output(dut, [(tc[2], tc[3], tc[4]) for tc in test_cases])

    # End of simulation wind-down.
    for _ in range(5):
        await RisingEdge(dut.clk)

    dut._log.info("Test Completed Successfully")
