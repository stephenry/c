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

import pathlib
import os
import sys

WS = [16]


def compile_and_run(
    project: str, w: int, sources: list[pathlib.Path], include_dirs: list[pathlib.Path]
) -> None:
    from cocotb_tools.runner import get_runner

    def _escape_string(s: str) -> str:
        return f'"{s}"'

    parameters = {
        "W": w,
        "P_UUT_NAME": _escape_string(project),
    }

    from .rtl import PROJECT_ROOT

    build_dir = PROJECT_ROOT / "build" / f"{project}_w{w}"

    runner = get_runner("verilator")
    runner.build(
        sources=sources,
        hdl_toplevel="tb",
        build_dir=str(build_dir),
        waves=True,
        includes=include_dirs,
        parameters=parameters,
        build_args=["--trace", "--timing"],
    )

    test_module = pathlib.Path(__file__).parent / "tests.py"

    sys.path.insert(0, str(test_module.parent))

    runner.test(hdl_toplevel="tb", test_module="tests", waves=True)

    if os.path.exists(build_dir / "waves.vcd"):
        print(f"Waveform generated at: {build_dir / 'waves.vcd'}")
    else:
        print("No waveform generated.")


def run_testbench(project: str, w: int) -> bool:
    from .rtl import compute_file_list

    # Copy all sources to a temporary directory and render top-level testbench
    hdl_files, include_dirs = compute_file_list(project)

    # Compile and run the testbench using cocotb
    compile_and_run(project, w, hdl_files, include_dirs)

    return True


def main():
    from .rtl import PROJECTS

    for project in PROJECTS.keys():
        for w in WS:
            print(f"Running testbench for project '{project}' with width {w}")
            success = run_testbench(project, w=w)
            if not success:
                print(f"Testbench failed for project '{project}' with width {w}")
                return 1
            print(f"Testbench passed for project '{project}' with width {w}")
