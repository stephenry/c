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

import argparse
import sys
import os
import common

if v := common.setup_verilator():
    print(f"Found Verilator installation: {v}")
else:
    print("Error: Could not find Verilator installation.")
    sys.exit(1)

if abc := common.setup_abc():
    print(f"Found ABC installation: {abc}")
else:
    print("Error: Could not find ABC installation.")
    sys.exit(1)


def run():
    from .tb import run_testbench

    # (W)idth sweep values
    WS = [4, 8, 16, 32, 64, 128]

    for project in common.ALL_PROJECTS:
        for w in WS:
            print(f"Running regression for project '{project}' with width {w}")
            success = run_testbench(project, w=w)
            if not success:
                print(f"Regression failed for project '{project}' with width {w}")
                sys.exit(1)
            print(f"Regression passed for project '{project}' with width {w}")

    # All pass
    sys.exit(0)
