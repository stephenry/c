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

parser = argparse.ArgumentParser(description="Testbench CLI")
parser.add_argument(
    "-p",
    "--project",
    type=str,
    choices=common.ALL_PROJECTS,
    required=True,
    help="Project to test",
)

parser.add_argument(
    "-w",
    "--width",
    type=int,
    required=True,
    help="Width (W) parameter for the design under test",
)


def main():
    try:
        from .tb import run_testbench

        args = parser.parse_args()

        sys.exit(run_testbench(args.project, w=args.width))

    except EnvironmentError as e:
        print(f"Testbench failed with error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
