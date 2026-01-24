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

def plot_results(plot_dir: pathlib.Path, results: dict) -> None:
    pass

import matplotlib.pyplot as plt

# Data from your table (area in µm²)
widths = args['w_sweep']

area = {}
frequency = {}
for project, s1 in results.items():
    area[project] = []
    frequency[project] = []
    for w, r in s1.items():
        area[project].append(r.combinatorial_area())
        frequency[project].append(r.f_max())

fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(10, 8), sharex=True)

for label, areas in area.items():
    ax1.plot(widths, areas, marker='o', label=label)
ax1.set_ylabel('Cell Area (µm²)')
ax1.grid(True, ls="--", alpha=0.7)
ax1.legend(ncol=2)

for label, f_maxs in frequency.items():
    ax2.plot(widths, f_maxs, marker='s', label=label)
ax2.set_xlabel('Width (W)')
ax2.set_ylabel('Max Frequency (MHz)')
ax2.grid(True, ls="--", alpha=0.7)
ax2.set_xscale('log', base=2)
ax2.set_xticks(widths)
ax2.set_xticklabels(widths)

plt.suptitle('PPA Comparison vs. Vector Width (Sky130 HD, Slow Corner)')
plt.tight_layout()
plt.savefig('ppa_separate.png', dpi=300)
import shutil
shutil.move('ppa_separate.png', SYN_ROOT + '/ppa_separate.png')