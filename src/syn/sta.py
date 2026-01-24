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
    global OPENSTA_EXECUTABLE

    opensta_root = os.environ.get("OPENSTA_ROOT")
    if opensta_root is None:
        raise EnvironmentError("OPENSTA_ROOT environment variable is not set.")

    opensta = pathlib.Path(opensta_root) / "build" / "sta"
    if not opensta.exists():
        raise EnvironmentError(f"OpenSTA executable not found at: {opensta}")

    OPENSTA_EXECUTABLE = str(opensta.resolve())


class OpenSTARunner:
    def __init__(self, **kwargs):
        self._top = kwargs.get("top", "top")
        self._syn_v = kwargs.get("syn_v", f"{self._top}_syn.v")
        self._project = kwargs.get("project")
        self._path = kwargs.get("path")
        self._frequency = kwargs.get("frequency")

        # Optional arguments:
        self._echo = kwargs.get("echo", False)

        self._sdc_file = "design.sdc"
        self._opensta_file = "opensta.tcl"
        self._passed = False

    def run(self):
        self._render_sdc()
        self._render_opensta_script()
        ec, stdout = self._run_opensta()
        if self._echo:
            print(stdout)
        if ec != 0:
            pass
        self._passed = self._scan_opensta_output(stdout)

    def passed(self) -> bool:
        return self._passed

    def _render_sdc(self):
        with open(self._path / self._sdc_file, "w") as f:
            f.write(f"# SDC file\n")
            f.write(f"# Frequency: {self._frequency} MHz\n")
            period_ns = 1000 / self._frequency
            f.write(f"create_clock -name clk -period {period_ns:.3f} [get_ports clk]\n")

    def _render_opensta_script(self):
        from .env import STDCELL_LIB_PATH

        with open(self._path / self._opensta_file, "w") as f:
            f.write(f"# OpenSTA script\n")
            f.write(f"# Frequency: {self._frequency} MHz\n")
            cmds = [
                f"read_liberty {STDCELL_LIB_PATH}",
                f"read_verilog {self._syn_v}",
                f"link_design {self._top}",
                f"read_sdc {self._sdc_file}",
                f"report_checks",
            ]
            f.write("\n".join(cmds) + "\n")

    def _run_opensta(self) -> int:
        from subprocess import Popen, PIPE

        p = Popen(
            [OPENSTA_EXECUTABLE, "-exit", self._opensta_file],
            stdout=PIPE,
            stderr=PIPE,
            cwd=self._path,
        )
        output, err = p.communicate()
        return p.returncode, output.decode()

    def _scan_opensta_output(self, stdout: str):
        import re

        passed = True
        for line in stdout.splitlines():
            if re.search(r"slack \(VIOLATED\)", line):
                passed = False

        return passed
