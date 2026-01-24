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
from collections.abc import Generator
import rtl
from typing import TypeAlias

plist: TypeAlias = list[tuple[str, int | str]]

# Trials to run
runlist = ["s"]
# runlist = rtl.ALL_PROJECTS

# W_SWEEP = range(8, 128, 8)
W_SWEEP = [16]

RADIX_SWEEP = [4]

F_SWEEP_MHZ = [100]
# F_SWEEP_MHZ = range(10, 200, 20)

BUILD_ROOT = pathlib.Path("build")


def _compute_rtl_dir(project: str, params: plist) -> pathlib.Path:
    dir_name = project
    for param, value in params:
        dir_name += f"_{param}{value}"
    return BUILD_ROOT / dir_name / "rtl"


def _compute_build_dir(project: str, params: plist) -> pathlib.Path:
    dir_name = project
    for param, value in params:
        dir_name += f"_{param}{value}"
    return BUILD_ROOT / dir_name / "syn"


def _width_parameterization():

    def _iterate_widths():
        for w in W_SWEEP:
            yield [("W", w)]

    return _iterate_widths


def _width_and_radix_parameterization():

    def _iterate_widths_and_radix():
        for w in W_SWEEP:
            for r in RADIX_SWEEP:
                yield [("W", w), ("RADIX_N", r)]

    return _iterate_widths_and_radix


projects = {
    # Sweep .W(x) parameter
    "s": _width_parameterization(),
    # Sweep .W(x) parameter
    "r": _width_parameterization(),
    # Sweep .W(x) and RADIX_N(x) parameters
    "e": _width_and_radix_parameterization(),
}


def compute_jobs() -> Generator[tuple[str, plist]]:

    # Validate project list
    if not all(x in projects for x in runlist):
        missing = [x for x in runlist if x not in projects]
        raise ValueError(f"Unknown projects in runlist: {missing}")

    for run_project in runlist:
        runlist_params = projects[run_project]

        for params in runlist_params():
            yield (run_project, params)


def run_job(project: str, params: plist, echo: bool = False) -> tuple[int, int, int]:
    rtl_dir = _compute_rtl_dir(project, params)

    # Render RTL to destination directory.
    import rtl

    (filelist, includedirs) = rtl.render_rtl(project, rtl_dir)

    # Render top-level file
    from .top import render_top

    (top_path, top_module) = render_top(rtl_dir, project, params=params)
    filelist.append(top_path)

    try:
        from .yosys import SynligRunner

        build_dir = _compute_build_dir(project, params)
        os.makedirs(build_dir, exist_ok=True)

        syn_v = (build_dir / "top_syn.v").resolve()

        # Run synthesis on top-level
        synlig = SynligRunner(
            path=build_dir,
            sources=filelist,
            include_paths=includedirs,
            top=top_module,
            syn_v=syn_v,
            echo=echo,
        )
        synlig.run()
        total_area, sequential_area = synlig.area()

        # Run timing on top-level
        from .sta import OpenSTARunner

        for f_mhz in reversed(F_SWEEP_MHZ):
            sta = OpenSTARunner(
                path=build_dir,
                frequency=f_mhz,
                top=top_module,
                syn_v=syn_v,
                echo=echo,
            )
            sta.run()
            if sta.passed():
                print(f"Timing passed at {f_mhz} MHz")
                f_max = f_mhz
                break

        return (total_area, sequential_area, f_max)

    except:
        pass


def main(args: list[str] = None):
    try:
        # Try to setup Synlig and OpenSTA environments
        from .sta import setup_environment as setup_sta_environment

        setup_sta_environment()

        from .yosys import setup_environment as setup_yosys_environment

        setup_yosys_environment()

    except EnvironmentError as e:
        # Oops! Environment not setup correctly
        print(f"Environment setup error: {e}")
        return

    for job in compute_jobs():
        (project, params) = job
        print(f"Running job: project={project}, params={params}")

        # Run synthesis and STA on current parameterization
        (total_area, sequential_area, f_max) = run_job(project, params)


if __name__ == "__main__":
    main()
