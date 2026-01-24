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

import os
import pathlib


def setup_environment():
    global SYNLIG_EXECUTABLE

    synlig_root = os.environ.get("SYNLIG_ROOT")
    if synlig_root is None:
        raise EnvironmentError("SYNLIG_ROOT environment variable is not set.")

    synlig = pathlib.Path(synlig_root) / "synlig"
    if not synlig.exists():
        raise EnvironmentError(f"Synlig executable not found at: {synlig}")

    SYNLIG_EXECUTABLE = str(synlig.resolve())


class SynligRunner:
    def __init__(self, **kwargs):
        # Required arguments:
        self._path = kwargs.get("path")
        self._sources = kwargs.get("sources", [])
        self._include_paths = kwargs.get("include_paths", [])

        # Optional arguments:
        self._syn_v = kwargs.get("syn_v", "syn.v")
        self._script_tcl = kwargs.get("script_tcl", "synlig.tcl")
        self._top = kwargs.get("top", "top")
        self._echo = kwargs.get("echo", False)

        # Results
        self._total_area = None
        self._sequential_area = None

    def run(self):
        self._render_synlig_script()
        ec, stdout = self._run_synlig()
        if self._echo:
            print(stdout)
        if ec:
            raise RuntimeError("Synlig synthesis failed.")
        self._total_area, self._sequential_area = self._scan_synlig_output(stdout)

    def area(self) -> tuple[float, float]:
        return (self._total_area, self._sequential_area)

    def _render_synlig_script(self):
        from .env import STDCELL_LIB_PATH

        with open(self._path / self._script_tcl, "w") as f:
            f.write(f"# Synlig script\n")

            cmds = []

            include_files = [
                f"-I{str(include_path)}" for include_path in self._include_paths
            ]

            for src in self._sources:
                cmds.append(
                    f'read_systemverilog {" ".join(include_files)} -defer {str(src)}'
                )

            cmds += [
                "read_systemverilog -link",
                f"hierarchy -check -top {self._top}",
                "flatten",
                "proc",
                "opt",
                "dfflegalize",
                "techmap",
                f"dfflibmap -liberty {STDCELL_LIB_PATH}",
                f"abc -liberty {STDCELL_LIB_PATH}",
                "opt",
                "opt_clean -purge",
                "check",
                f"write_verilog -noattr -noexpr {str(self._syn_v)}",
                f"stat -liberty {STDCELL_LIB_PATH}",
            ]
            f.write("\n".join(cmds) + "\n")

    def _run_synlig(self) -> int:
        from subprocess import Popen, PIPE

        p = Popen(
            [SYNLIG_EXECUTABLE, "-s", self._script_tcl],
            stdout=PIPE,
            stderr=PIPE,
            cwd=self._path,
        )
        output, err = p.communicate()
        return (p.returncode, output.decode())

    def _scan_synlig_output(self, stdout: str):
        import re

        total_area = None
        sequential_area = None

        for line in stdout.splitlines():
            if m := re.search(r"Chip area for module \'\\top\': ([\d\.]+)", line):
                total_area = float(m.group(1))
            elif m := re.search(
                r"of which used for sequential elements: ([\d\.]+)", line
            ):
                sequential_area = float(m.group(1))

        return (total_area, sequential_area)
