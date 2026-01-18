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
import shutil
import jinja2
import tempfile
import os
import cocotb

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


def compute_file_list(project: str) -> list[pathlib.Path]:
    if project not in PROJECTS:
        raise ValueError(f"Unknown project '{project}'")

    file_list = []
    file_list.extend(PROJECTS[project])
    file_list.extend(COMMON_FILES)
    return file_list


# All RTL include directories
INCLUDES = [
    PROJECT_ROOT / "rtl" / "common_defs.svh",
]

WS = [8]


def _render_tb(project: str, w: int) -> tuple[str, str]:
    template_dir = os.path.dirname(__file__)
    env = jinja2.Environment(
        loader=jinja2.FileSystemLoader(template_dir),
        trim_blocks=True,
        lstrip_blocks=True,
    )

    template = env.get_template("tb.sv.tmpl")

    module_name = f"tb_{project}_w_{w}"
    rendered_tb = template.render(
        w=w,
        uut_name=project,
        module_name=module_name,
    )

    return (module_name, rendered_tb)


def render_rtl_sources(
    project: str, w: int, dest_dir: pathlib.Path
) -> list[pathlib.Path]:
    rendered_fl = []

    # Copy RTL sources
    for src in compute_file_list(project):
        dest = dest_dir / src.name
        rendered_fl.append(dest)
        shutil.copyfile(src, dest)

    # Render and copy testbench
    module_name, rendered_tb = _render_tb(
        project, w
    )

    tb_path = dest_dir / f"{module_name}.sv"
    rendered_fl.append(tb_path)
    with open(tb_path, "w") as f:
        f.write(rendered_tb)

    # Copy include files
    for inc in INCLUDES:
        dest = dest_dir / inc.name
        shutil.copyfile(inc, dest)

    return (module_name, rendered_fl)

def compile_and_run(toplevel: str, rtl_files: list[pathlib.Path], root: pathlib.Path) -> None:
    from cocotb_tools.runner import get_runner

    runner = get_runner("verilator")
    runner.build(
        sources=rtl_files,
        hdl_toplevel=toplevel,
        build_dir=str(root),
        waves=True
    )

    runner.test(
        hdl_toplevel=toplevel, test_dir=os.path.dirname(__file__), test_module="tests")
    
    if os.path.exists(root / "waves.vcd"):
        print(f"Waveform generated at: {root / 'waves.vcd'}")
    else:
        print("No waveform generated.")

def run_testbench(project: str, w: int) -> bool:
    with tempfile.TemporaryDirectory() as tmpdir:
        # Copy all sources to a temporary directory and render top-level testbench
        module_name, rtl_files = render_rtl_sources(project, w, pathlib.Path(tmpdir))
        
        # Compile and run the testbench using cocotb
        compile_and_run(module_name, rtl_files, pathlib.Path(tmpdir))


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
