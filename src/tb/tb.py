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


def _project_root(anchor: str = "README.md") -> pathlib.Path:
    def _recurse(path: pathlib.Path) -> pathlib.Path:
        if (path / anchor).exists():
            return path
        elif path.anchor != "" and path == path.parent:
            raise FileNotFoundError(
                f"Could not find project root with anchor '{anchor}'"
            )
        else:
            return _recurse(path.parent)

    return _recurse(pathlib.Path(__file__).parent)


# Project root directory
PROJECT_ROOT: pathlib.Path = _project_root("README.md")

# Specific RTL files for each project
PROJECTS = {
    "s": [
        "s.sv",
    ]
}

for project, files in PROJECTS.items():
    PROJECTS[project] = [PROJECT_ROOT / "rtl" / project / f for f in files]

# Common RTL files used across multiple projects
COMMON_FILES = [
    "enc.sv",
    "inc.sv",
    "maske.sv",
    "mux.sv",
    "rev.sv",
]

for i, f in enumerate(COMMON_FILES):
    COMMON_FILES[i] = PROJECT_ROOT / "rtl" / "common" / f

TB_FILES = [
    "tb.sv",
]

for i, f in enumerate(TB_FILES):
    TB_FILES[i] = pathlib.Path(__file__).parent / f


def compute_file_list(project: str) -> list[pathlib.Path]:
    if project not in PROJECTS:
        raise ValueError(f"Unknown project '{project}'")

    file_list = []
    file_list.extend(PROJECTS[project])
    file_list.extend(COMMON_FILES)
    file_list.extend(TB_FILES)
    return file_list


# All RTL include directories
INCLUDE_DIRS = [
    PROJECT_ROOT / "rtl",
]

WS = [16]


def compile_and_run(project: str, w: int, sources: list[pathlib.Path]) -> None:
    from cocotb_tools.runner import get_runner

    def _escape_string(s: str) -> str:
        return f'"{s}"'

    parameters = {
        "W": w,
        "P_UUT_NAME": _escape_string(project),
    }

    runner = get_runner("verilator")
    runner.build(
        sources=sources,
        hdl_toplevel="tb",
        build_dir="./build",
        waves=True,
        includes=INCLUDE_DIRS,
        parameters=parameters,
        build_args=["--trace", "--timing"],
    )

    test_module = pathlib.Path(__file__).parent / "tests.py"

    sys.path.insert(0, str(test_module.parent))

    runner.test(hdl_toplevel="tb", test_module="tests", waves=True)

    if os.path.exists("waves.vcd"):
        print(f"Waveform generated at: waves.vcd")
    else:
        print("No waveform generated.")


def run_testbench(project: str, w: int) -> bool:
    # Copy all sources to a temporary directory and render top-level testbench
    hdl_files = compute_file_list(project)

    # Compile and run the testbench using cocotb
    compile_and_run(project, w, hdl_files)

    return True


def main():
    for project in PROJECTS.keys():
        for w in WS:
            print(f"Running testbench for project '{project}' with width {w}")
            success = run_testbench(project, w=w)
            if not success:
                print(f"Testbench failed for project '{project}' with width {w}")
                return 1
            print(f"Testbench passed for project '{project}' with width {w}")
