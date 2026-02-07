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

import common
import pathlib
import subprocess
import sys


def lint_one_verilator(v_exe: pathlib.Path, project: str, w: int) -> int:
    print(f"Linting project={project} w={w}...")

    lint_root = common.PROJECT_ROOT / "build_lint" / f"{project}_w{w}"
    lint_root.mkdir(parents=True, exist_ok=True)

    filelist, included_dirs = common.render_rtl(project, lint_root)

    commands_list = [
        "--lint-only",
        "-Wall",
        "-DC_FLOW__OVERRIDE_TOP_W" f"-DC_FLOW__TOP_W={w}",
        f'--top-module "{project}"',
        "-GW=32",
        "--unused-regexp UNUSED_*",
    ]
    commands_list.extend([f"-I{str(d)}" for d in included_dirs])
    commands_list.extend([str(f) for f in filelist])

    command_file = lint_root / "verilator_cmds.txt"
    with command_file.open("w") as f:
        for cmd in commands_list:
            f.write(cmd + "\n")

    cp = subprocess.run([str(v_exe), "-f", str(command_file)])
    return cp.returncode == 0


def lint_all_verilator() -> int:
    v_exe = common.setup_verilator()
    if not v_exe:
        # Verilator not found, cannot proceed.
        return 1

    for project in common.ALL_PROJECTS:

        for w in range(4, 64, 10):

            if not lint_one_verilator(v_exe, project, w):
                print(f"Linting failed for project={project} w={w}")
                return 1

    print(f"Linting PASS!")
    return 0


def lint_one_svlint(svlint_exe: pathlib.Path, project: str, w: int) -> int:
    print(f"Linting project={project} w={w}...")

    lint_root = common.PROJECT_ROOT / "build_lint" / f"{project}_w{w}"
    lint_root.mkdir(parents=True, exist_ok=True)

    filelist, included_dirs = common.render_rtl(project, lint_root)

    commands_list = [
        "+define+C_FLOW__OVERRIDE_TOP_W",
        f"+define+C_FLOW__TOP_W={w}",
    ]
    commands_list.extend([f"+incdir+{str(d)}" for d in included_dirs])
    commands_list.extend([str(f) for f in filelist])

    command_file = lint_root / "svlint_cmds.txt"
    with command_file.open("w") as f:
        for cmd in commands_list:
            f.write(cmd + "\n")

    cp = subprocess.run([str(svlint_exe), "-f", str(command_file)])
    return cp.returncode == 0


def lint_all_svlint() -> int:
    svlint_exe = common.setup_svlint()
    if not svlint_exe:
        # SVLINT not found, cannot proceed.
        return 1

    for project in common.ALL_PROJECTS:

        for w in range(4, 64, 10):
            print(f"Linting {project} w={w}...")

            if not lint_one_svlint(svlint_exe, project, w):
                print(f"Linting failed for project={project} w={w}")
                return 1

    print(f"Linting PASS!")
    return 0


if __name__ == "__main__":
    if common.setup_svlint():
        sys.exit(lint_all_svlint())
    elif common.setup_verilator():
        sys.exit(lint_all_verilator())
    else:
        print("Error: Could not find SVLINT or Verilator installation.")
        sys.exit(1)
