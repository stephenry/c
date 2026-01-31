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
from cocotb.triggers import RisingEdge, FallingEdge

import random

random.seed(42)

async def reset_sequence(dut, cycles_n: int) -> None:
    dut.arst_n.value = 1
    await RisingEdge(dut.clk)

    dut.arst_n.value = 0
    for _ in range(cycles_n):
        await RisingEdge(dut.clk)

    dut.arst_n.value = 1
    await RisingEdge(dut.clk)


async def await_cycles(dut, cycles_n: int) -> None:
    for _ in range(cycles_n):
        await RisingEdge(dut.clk)

async def driver(dut, test_cases):
    # Drive stimulus
    for x, pos in test_cases:
        dut.x_i.value = x
        dut.pos_i.value = pos
        await RisingEdge(dut.clk)

    dut.x_i.value = 0
    dut.pos_i.value = 0
    await RisingEdge(dut.clk)

async def checker(dut, expected):

    for _ in range(2):
        await FallingEdge(dut.clk)
    
    for y_exp, y_enc_exp, any_exp in expected:
        await FallingEdge(dut.clk)

        any_actual = dut.any_o.value
        assert any_actual == any_exp, \
            f"any_o mismatch: expected {any_exp}, got {any_actual}"

        if any_actual:
            # Then, check results.
            assert y_exp == dut.y_o.value, \
                f"y_o mismatch: expected {y_exp}, got {dut.y_o.value}"

            assert y_enc_exp == dut.y_enc_o.value, \
                f"y_enc_o mismatch: expected {y_enc_exp}, got {dut.y_enc}"


def generate_stimulus(w, x, pos):
    import cocotb.types as ct

    W = w.to_unsigned()

    x_la = ct.LogicArray.from_unsigned(x, range=W)
    pos_la = ct.LogicArray.from_unsigned(pos, range=(W - 1).bit_length())

    return x_la, pos_la

def generate_expected(w, x, pos):
    assert pos.to_unsigned() < w.to_unsigned(), "Position out of range"

    import cocotb.types as ct

    W = w.to_unsigned()
    Y_ENC_W = (W - 1).bit_length()

    # Any:
    any_cond = (x != ct.LogicArray(W * '1', range=W))
    any_l = ct.Logic(any_cond)

    # Don't care by default.
    y = ct.LogicArray(W * '0', range=W)
    y_enc = ct.LogicArray(Y_ENC_W * '0', range=Y_ENC_W)
    
    if any_cond:
        for i in range(W):
            j = (pos.to_unsigned() - i - 1) % W
            if x[j] == 0:
                y = ct.LogicArray.from_unsigned(1 << j, range=W)
                y_enc = ct.LogicArray.from_unsigned(j, range=Y_ENC_W)
                break

    return y, y_enc, any_l


@cocotb.test()
async def test_directed(dut):
    """Run the test of known test cases as specified in the top-level module."""

    if dut.W.value != 16:
        print(f"Testbench only supports W=16 for now (W={dut.W.value}).")
        return

    # Perform reset
    await reset_sequence(dut, cycles_n=5)

    # Generate stimulus form RTL top-level header; constrained for W=16 only.
    directed = [
        (0xFFFE, 0),
        (0x0000, 0),
        (0x0000, 1),
        (0x0000, 15),
        (0x2A37, 8),
        (0xFFFF, 0),
    ]

    stimulus = []
    for x, pos in directed:
        stimulus.append(generate_stimulus(dut.W.value, x, pos))

    expected = []
    for x, pos in stimulus:
        y, y_enc, any_o = generate_expected(dut.W.value, x, pos)
        expected.append((y, y_enc, any_o))

    for a, b in zip(stimulus, expected):
        x, pos = a
        y, y_enc, any_o = b
        dut._log.info(f"Stimulus: x={x}, pos={pos} => Expected: y={y}, y_enc={y_enc}, any_o={any_o}")

    tasks = [
        cocotb.start_soon(driver(dut, stimulus)),
        cocotb.start_soon(checker(dut, expected))
    ]

    await cocotb.triggers.Combine(*tasks)

    # End of simulation wind-down.
    for _ in range(5):
        await RisingEdge(dut.clk)

    dut._log.info("Test Completed Successfully")

@cocotb.test()
async def test_randomized(dut):

    W = dut.W.value.to_unsigned()
    ENC_W = (W - 1).bit_length()

    # Perform reset
    await reset_sequence(dut, cycles_n=5)

    stimulus = []
    for _ in range(10):
        import cocotb.types as ct

        x = random.randint(0, (1 << W) - 1)
        pos = random.randint(0, W - 1)

        stimulus.append(generate_stimulus(dut.W.value, x, pos))

    expected = []
    for x, pos in stimulus:
        expected.append(generate_expected(dut.W.value, x, pos))

    for a, b in zip(stimulus, expected):
        x, pos = a
        y, y_enc, any_o = b
        dut._log.info(f"Stimulus: x={x}, pos={pos} => Expected: y={y}, y_enc={y_enc}, any_o={any_o}")

    tasks = [
        cocotb.start_soon(driver(dut, stimulus)),
        cocotb.start_soon(checker(dut, expected))
    ]

    await cocotb.triggers.Combine(*tasks)

    # End of simulation wind-down.
    for _ in range(5):
        await RisingEdge(dut.clk)

    dut._log.info("Test Completed Successfully")
