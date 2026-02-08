# Offset Leading-Zero Detector – PPA Comparison of RTL Architectures

[![cocotb](https://img.shields.io/badge/verification-cocotb-4A90E2)](https://github.com/cocotb/cocotb)
[![SystemVerilog](https://img.shields.io/badge/language-SystemVerilog-blue)](https://ieeexplore.ieee.org/document/8299595)
[![SkyWater 130nm](https://img.shields.io/badge/PDK-SkyWater%20130nm-green)](https://github.com/google/skywater-pdk)

## Synopsis

A PPA comparison of four RTL styles for offset leading-zero detection using cocotb verification and open-source synthesis flow.

## Problem Statement

For an arbitrary W-bit vector ('x'), find the first '0'-bit
encountered in a right circular walk from a bit 'pos'. 

### Examples of offset leading-zero detection (W=16 for illustration)

| x                   | pos | y                   | y_enc  | any
|---------------------|:---:|---------------------|:-----:|:----:
| 1111_1111_1111_1110 |   0 | 0000_0000_0000_0001 |  0     |  1
| 0000_0000_0000_0000 |   0 | 1000_0000_0000_0000 |  15    |  1
| 0000_0000_0000_0000 |   1 | 0000_0000_0000_0001 |  0     |  1
| 0000_0000_0000_0000 |  15 | 0100_0000_0000_0000 |  14    |  1
| 0010_1010_0011_0111 |   8 | 0000_0000_1000_0000 |  7     |  1
| 1111_1111_1111_1111 |   X | XXXX_XXXX_XXXX_XXXX |  X     |  0

## Motivation

The above circuit was discussed on my company's Slack with competing
solutions provided. A number of individuals advocated for very
optimized, hand-written solutions while others advocated for high-level
solutions that offloaded complex onto the synthesis engine. Initial
analysis' suggest that synthesis can often produce a better final
result when it has an understanding of the intended function of the
logic. This is in contrast to highly optimized handwritten solutions
from which the high-level function might be less obvious.

I thought it would be interesting to: explore various design 
approaches to this problem an explore their relative PPA performance
using widely available open-source tools. I also wanted to
explore the use of cocotb for verification; a library that to
date I had limited exposure.

## Realizations

Various design strategies are explored. The following are presented:

The following circuits are presented:

#### (E) Explicit [e.sv](./rtl/e/e.sv):

Explicit prioritization networks are defined using PLA-based tables
and a CLA-like carry-chain is used to propagate the search operation
across multiple tables. PLA-Tables are rendered by the ABC synthesis
tool before they are passed to the logic simulator and/or synthesis
tool. The use of explicit [PLA Tables](./rtl/e/e_pri.sv) allows
superior X-propagation characteristics in the RTL, but one
would expect similar logic to be synthesized using a traditional
case-statement.

#### (R) Rotator [r.sv](./rtl/s/s.sv):

The input vector is rotated according to 'pos'. A standard
priorization network is applied to the rotated result to compute
the location of the first '0' in the vector. The 1-hot result
is rotated back into the original position to produce the
result. Although minimal logic is infered to compute the result,
the long combinatorial path through two barrel-shifter
networks (depth proportional to O(lognW)) and a priorization
network could present timing challenges for large 'W'.

#### (S) Special [s.sv](./rtl/s/s.sv):

Mask-based solution which relies on the carry-propagate property
of CLA-adders to deteect the first '0' bit vector. For a given
value of 'pos' an OR-mask is created and then applied to the
input vector. Once incremented, the first bit to transition
from '0' to '1' (the carry-out bit) is the first '0' in 
the vector. Synthesis is expected to infer an efficient CLA
structure for the increment operation, therefore this
design is expected to scale well for increasing 'W'

#### (N) Naive [n.sv](./rtl/n/n.sv):

The Brute-Force implementation. For each possible value of 'pos',
compute the first '0' in the input vector. Mux out the appropriate
prioritization network for a given pos to provide the result.
Prioritization can be performed efficiently as the vector can
be statically shifted into the correct position without logic
overhead. The exhaustive nature of the design however suggests
that area growth would become too great for increasing values of 'W'.

#### (K) Kogge Stone [k.sv](./rtl/k/k.sv)

A Radix-2 Kogge-Stone carry-chain is explicitly infered compute
the first '0' in the vector. Design is similar to 'S' except
the prioritization network is computed using the Kogge-Stone
network instead of a synthesizer inferred incrementor.

## Verification

![Alt](https://svg.wavedrom.com/github/stephenry/c/main/docs/wave.json5?v=2)

Functional correctness of the designs is verified using cocotb and
Verilator. The above diagram presents some representative stimulus
through a design. As the circuit is flop-bounded, the overall
latency from input to output is 2 cycles. 

The following test cases are present:

#### [Randomized](./src/tb/tests.py#L185)
Fully randomized stimulus across 10k input vectors.

#### [Edge Cases](./src/tb/tests.py#L205)
All-one and all-zero tests cases are exhaustively walked.

#### [Directed](./src/tb/tests.py#L161)
Test the specific test cases presented at the top of this document.

## Physical Analysis

![Area/Frequency vs. W](./docs/sweep.png)

### Discussion

The [Naive Solution (N)](./rtl/n/n.sv) demonstrates explosive area growth for
increasing 'W'. Its timing remains resilient to increasing 'W'
as there is minimal logic beyond the absolute minimal required
to compute the result.

The [Rotator Solution (R)](./rtl/r/r.sv) unsurprisingly demonstrates very poor
timing performance with increasing 'W'. The overall area
growth however is relatively surprising since barrel-shifters
and priorization networks can be inferred efficiently by
synthesis. A [previous study](http://www.github.com/stephenry/u)
has shown that prioritization networks such as [pri.sv](./rtl/common/pri.sv)
are not efficient. Discussion with colleagues suggests that
suprior PPA can be achieved by writing simplistic implementations
in RTL and allowing the synthesis tool to optimize as necessary.
There is perhaps some justification in this belief.

The and-written PLA-table based solution of  ['E'](./rtl/e/e.sv) yields
competitive results. From an area perspective it is efficient
for large 'W'. It appears to be less timing resilient than
the standard CLA-based solution 'S'. 

The [Kogge-Stone solution (K)](./rtl/k/k.sv) appears to provide the best of
both worlds: impressive area scaling with increasing 'W',
and timing performance comparable to the Naive solution.
From the results obtain, it is perhaps safe to conclude 
that 'k' presents the best overall solution from a PPA
perspective. It would perhaps be worthwhile investigating
this approach for higher Radix KS trees (where Radix
is defined as the number of leafs consumed on each layer.)

### Methodology

Source RTL was rendered using ABC and synthesized using the Synlig
Front-End for the open-source synthesis tool Yosys. The 130nm SkyWater
cell library was used and the 1.60v/100c timing corner used to
obtain timing results. Yosys does not implement an internal
timing model therefore the resultant netlist was passed to OpenSTA
to compute the highest operating frequency with zero Total Negative
Slack (TNS).

Each design is flop-bounded to simplify timing analysis. As each
solution is essentially combinatorial in nature, the area overhead
due to sequential cells was deducted from the total cell area to
from the final area estimate. The overall area due to sequential
cell area for a given 'W' is constant across each design.

#### Limitations

I am limited by the availability of open-source EDA tools. As such
the above PPA analysis was performed using only a netlist. In reality,
timing is heavily dependent on wire-delay. Wire delay can be estimated
at a high-level using Wire-Load Models or by forming a physical
placement and routing trial of the netlist. The true wire delay
can only be computed from a fully placed-/routed- and RC-extraced
design. I lack the tools to perform such detailed estimate, therefore
timing results are present in the absence of wiring delay.

Similarly, area cannot be computed purely from just cell-area. In
a final GDS, overall area is some function of utilization, floorplan
and routability. The cells themselves may be changed in the backend
for timing and/or power purposes.


## Instructions

The flow is scripted using Python. Verification is performed using
cocotb and Verilator. Synthesis is performed using Berkley's ABC
Synthesis tool, the Synlig front-end for Yosys and OpenSTA.

The [Dockerfile](./devcontainer/Dockerfile) is the recommended
environment for this project. 

### Installation

Performs necessary installation into the Python virtual-environment
and installs all tools.

```
poetry install
```

### Lint

Linting can be performed using:

```
poetry run lint # Run svlint flow
poetry run vlint # Run Verilator lint flow
```

### Simulation

A design can be tested by invoking:

```
poetry run driver -p $PROJECT -w $WIDTH  # Individual test instance
poetry run regress # Full design regression.
```

Where "$PROJECT" and "$WIDTH" denote the project and its width
respectively.

### Synthesis

To invoke synthesis, run the following command:

```
poetry run syn -p $PROJECT -w $WIDTH # Individual synthesis trial
poetry run synsweep # Run full synthesis flow across all designs
```

The 'synsweep' command can be used to recreate the [chart](./dcos/sweep.png).
