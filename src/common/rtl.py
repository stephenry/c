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
import re
import typing
import tempfile

from .env import PROJECT_ROOT


# Specific RTL files for each project
_PROJECTS = {
    "s": [
        "s.sv",
    ],
    "r": [
        "r.sv",
    ],
    "e": [
        "e.sv",
        "e_multi.sv",
        "e_multi_cell.sv",
        "e_priority.sv",
    ],
}

for project, files in _PROJECTS.items():
    _PROJECTS[project] = [PROJECT_ROOT / "rtl" / project / f for f in files]

ALL_PROJECTS = _PROJECTS.keys()

# Common RTL files used across multiple projects
_COMMON_FILES = [
    "enc.sv",
    "inc.sv",
    "maske.sv",
    "mux.sv",
    "rev.sv",
    "bs.sv",
    "bsi.sv",
    "sel.sv",
    "pri.sv",
    "dec.sv",
]

for i, f in enumerate(_COMMON_FILES):
    _COMMON_FILES[i] = PROJECT_ROOT / "rtl" / "common" / f

# All RTL include directories
_INCLUDE_FILES = [
    PROJECT_ROOT / "rtl" / "common_defs.svh",
    PROJECT_ROOT / "rtl" / "math_pkg.svh",
]

_ABC_EXE = os.environ.get("ABC_EXE", None)


class PLARenderer:
    def __init__(self, pla_region: list[str]):
        self._i_token_mappings = list()
        self._o_token_mappings = list()
        self._terms = list()
        self._pla_region = pla_region

    def render(self) -> list[str]:

        for line in self._remove_encapsulation(self._pla_region):
            if line.startswith(".i"):
                self._process_directive(line, self._i_token_mappings)
            elif line.startswith(".o"):
                self._process_directive(line, self._o_token_mappings)
            elif line.startswith(".e"):
                pass
            elif "0" in line or "1" in line or "-" in line:
                self._process_cube(line)
            elif not line:
                pass
            else:
                pass

        with (
            tempfile.NamedTemporaryFile(mode="w+", delete=False) as cmdfile,
            tempfile.NamedTemporaryFile(mode="w+", delete=False) as scriptfile,
            tempfile.NamedTemporaryFile(delete=False) as verilogfile,
        ):

            # Write espresso/PLA script.
            self._write_pla_script(cmdfile)
            cmdfile.flush()

            # Write ABC script.
            self._write_abc_script(scriptfile, cmdfile.name, verilogfile.name)
            scriptfile.flush()

            if not self._invoke_abc(scriptfile.name):
                raise RuntimeError("ABC invocation failed.")

            # Extract expressions from synthesized Verilog output.
            with open(verilogfile.name, "r") as synthesized_verilog:
                return self._render_verilog(synthesized_verilog)

    def _render_verilog(self, synthesized_verilog) -> list[str]:
        out = list()

        for line in synthesized_verilog.readlines():
            if "assign" not in line:
                continue

            for orig, repl in self._i_token_mappings:
                line = line.replace(repl, orig)

            for orig, repl in self._o_token_mappings:
                line = line.replace(repl, orig)

            line = line.lstrip()

            out.append(line)

        return out

    def _process_cube(self, line: str) -> None:
        i_n = len(self._i_token_mappings)
        o_n = len(self._o_token_mappings)

        i_cube = ""
        o_cube = ""
        for ch in line:
            if ch not in ["0", "1", "-"]:
                continue

            if len(i_cube) < len(self._i_token_mappings):
                i_cube += ch
            else:
                o_cube += ch

        self._terms.append((i_cube, o_cube))

    def _remove_encapsulation(self, lines: list[str]) -> list[str]:
        comments_removed = list()
        for line in lines:
            if not line:
                continue

            comments_removed.append(line.lstrip("//!").lstrip())

        return re.sub(r"\\\n", "", "".join(comments_removed)).split("\n")

    def _process_directive(self, line: str, mappings) -> None:
        tokens = line.split()
        for token in tokens[1:]:
            if m := re.match(r"(\w+)\[(\d+):(\d+)\]", token):
                name, msb, lsb = m.groups()
                for k in reversed(range(int(lsb), int(msb) + 1)):
                    mappings.append((f"{name}[{k}]", f"{name}_{k}"))
            else:
                mappings.append((token, token))

    def _write_pla_script(self, of) -> None:
        # Write command file
        of.write(f".i {len(self._i_token_mappings)}\n")
        of.write(f".o {len(self._o_token_mappings)}\n")

        ins = " ".join([m[1] for m in self._i_token_mappings])
        of.write(f".ilb {ins}\n")

        outs = " ".join([m[1] for m in self._o_token_mappings])
        of.write(f".ob {outs}\n")

        # Write script
        for i_cube, o_cube in self._terms:
            of.write(f"{i_cube} {o_cube}\n")

        of.write(".e\n")

    def _write_abc_script(self, scriptfile, cmdfilename, verilogfilename) -> None:
        scriptfile.write(f"read_pla {cmdfilename}\n")
        scriptfile.write(f"write_verilog {verilogfilename}\n")

    def _invoke_abc(self, scriptfilename) -> None:
        import subprocess

        cp = subprocess.run([_ABC_EXE, "-f", scriptfilename])
        return cp.returncode == 0


def _compute_src_list(project: str) -> list[pathlib.Path]:
    if project not in _PROJECTS:
        raise ValueError(f"Unknown project '{project}'")

    file_list = []
    file_list.extend(_PROJECTS[project])
    file_list.extend(_COMMON_FILES)

    return file_list


def _render_pass_abc(i: typing.TextIO, o: typing.TextIO) -> None:
    out_render = list()
    in_pla_region = False
    pla_region = list()

    for line in i.readlines():

        if re.search(r"PLA_END", line):
            out_render.extend(PLARenderer(pla_region).render())
            in_pla_region = False
            pla_region = list()

        elif in_pla_region:
            pla_region.append(line)

        elif re.search(r"PLA_BEGIN", line):
            in_pla_region = True

        else:
            out_render.append(line)

    o.write("".join(out_render))


def _render_pass(i: typing.TextIO, o: typing.TextIO) -> None:
    out_render = []

    for line in i.readlines():
        out_render.append(line)

    o.write("".join(out_render))


def _render_one_file(src: pathlib.Path, dest: pathlib.Path) -> None:
    with open(src, "r") as i, open(dest, "w") as o:

        if _ABC_EXE:
            # Use ABC-based rendering pass
            _render_pass_abc(i, o)
        else:
            # Otherwise, raw copy of source file
            _render_pass(i, o)


def _render_file_list(file_list: list[pathlib.Path], out_dir: pathlib.Path) -> None:
    if not os.path.exists(out_dir):
        os.makedirs(out_dir, exist_ok=True)

    for f in file_list:
        _render_one_file(f, out_dir / f.name)


def render_rtl(
    design: str, out_dir: pathlib.Path
) -> tuple[list[pathlib.Path], list[pathlib.Path]]:

    if design not in _PROJECTS:
        raise ValueError(f"Unknown project '{design}'")

    file_list = _compute_src_list(design)

    _render_file_list(file_list, out_dir)

    include_dirs = set()
    include_dirs.add(out_dir)
    include_dirs.update(
        os.path.dirname(file) for file in _INCLUDE_FILES
    )

    return (file_list, list(include_dirs))
