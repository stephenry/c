# U

## Synopsis

A collection of circuits to compute the leftmost 1'b0 relative to a bit-position
for an arbitrary sized W-bit vector. As follows:

| x                   | pos | y                   | y_enc  | any
|---------------------|:---:|---------------------|:-----:|:----:
| 1111_1111_1111_1110 |   0 | 0000_0000_0000_0001 |  0     |  1
| 0000_0000_0000_0000 |   0 | 1000_0000_0000_0000 |  15    |  1
| 0000_0000_0000_0000 |   1 | 0000_0000_0000_0001 |  0     |  1
| 0000_0000_0000_0000 |  15 | 0100_0000_0000_0000 |  14    |  1
| 0010_1010_0011_0111 |   8 | 0000_0000_1000_0000 |  7     |  1
| 1111_1111_1111_1111 |   x | xxxx_xxxx_xxxx_xxxx |  x     |  0

## Realizations

#### (E) Explicit [e.sv](./rtl/e/e.sv):

N-bit priorization network is explicit defined as [lookup-tables](./rtl/e/e_priority.sv)
and grouped together using a CLA-style kill-/propagate-/generate- network. A notable
aspect of the solution is the use of explicit embedded PLA tables which are preprocesed
by the build environment, synthesized to SystemVerilog using the Open Source ABC
synthesis tool and injected into rendered RTL.

#### (R) Rotator [r.sv](./rtl/s/s.sv):

The input vector is left-rotated such that the bit at pos becomes the LSB. A
priorization network is applied to the rotated vector to compute the location
of the first '0' relative to pos. The vector is then right-rotated to the
original position to compute the final result.

#### (S) Special [s.sv](./rtl/s/s.sv):

Solution relies on incrementer circuits to compute first '0' position in the
vector. Mask logic is used to propagate the carry across regions of the
input vector that are not relevant to the search. Use of incrementer
allows synthesis to infer optimized CLA structure for the search operation.

#### (N) Naive [n.sv](./rtl/n/n.sv):

The "naive"-solution consisting of the literal translation of the written
behavioural problem description to standard SystemVerilog. The solution consists
of two, W-bit loops: an outer loop to detect pos, and an inner loop to search
for the first '0' at every bit in the vector relative to that initial position.

## Physical Analysis

![Area/Frequency vs. W](./docs/sweep.png)

## Instructions

