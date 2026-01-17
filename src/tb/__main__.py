import cocotb


def main():
    print("This is the main function.")


@cocotb.test()
def run_test(dut):
    pass


main()

import sys
import os
import pathlib


def add_two_integers(a: int, b: int) -> int:
    return a + b


print(add_two_integers(3, 5))
print(add_two_integers(1, 2))
print(add_two_integers(2, 4))


verilator_root = os.environ.get("VERILATOR_ROOT")
if verilator_root is None:
    raise EnvironmentError("VERILATOR_ROOT environment variable is not set.")


verilator = pathlib.Path(verilator_root) / "bin" / "verilator"
sys.path.insert(0, str(verilator))
print(sys.path)
