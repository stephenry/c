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
import shutil

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


def setup_verilator() -> pathlib.Path | None:
    # Search global VERILATOR_ROOT environment variable.
    verilator_root = os.environ.get("VERILATOR_ROOT")
    if verilator_root:
        verilator = pathlib.Path(verilator_root) / "bin" / "verilator"
        os.environ["PATH"] += os.pathsep + str(verilator.parent)
        return verilator

    # Otherwise, search path
    if verilator := shutil.which("verilator"):
        verilator_path = pathlib.Path(verilator).resolve()
        os.environ["VERILATOR_ROOT"] = str(verilator_path.parent.parent)
        return verilator
    
    # Otherwise, search some known paths
    paths = [
        pathlib.Path("/Users/shenry/github/verilator/"),
    ]

    for path in paths:
        verilator = path / "bin" / "verilator"
        if verilator.exists():
            os.environ["VERILATOR_ROOT"] = str(path)
            os.environ["PATH"] += os.pathsep + str(verilator.parent)
            return verilator

    # Verilator not found.    
    return None

def setup_abc() -> pathlib.Path | None:
    # Search global ABC_PATH environment variable.
    abc_path = os.environ.get("ABC_EXE")
    if abc_path:
        abc = pathlib.Path(abc_path)
        os.environ["PATH"] += os.pathsep + str(abc.parent)
        return abc

    # Otherwise, search path
    if abc := shutil.which("abc"):
        abc_path = pathlib.Path(abc).resolve()
        os.environ["ABC_EXE"] = str(abc_path)
        return abc

    # Otherwise, search some known paths
    paths = [
        pathlib.Path("/Users/shenry/github/abc")
    ]

    for path in paths:
        abc = path / "abc"
        if abc.exists():
            os.environ["ABC_EXE"] = str(abc)
            os.environ["PATH"] += os.pathsep + str(abc.parent)
            return abc

    # ABC not found.    
    return None
