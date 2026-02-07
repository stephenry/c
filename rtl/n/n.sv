//========================================================================== //
// Copyright (c) 2026, Stephen Henry
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice, this
//   list of conditions and the following disclaimer.
//
// * Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//========================================================================== //

`include "common_defs.svh"
`include "asserts.svh"
`include "flops.svh"

// Circuit to compute the circular left-most '0' in a vector 'x' for a
// given position. 'any' flag indicates output validity.
//
//   x                       pos   y                      y_enc    any
//   -----------------------------------------------------------------------
//
//   1111_1111_1111_1110     0     0000_0000_0000_0001    0        1
//                     ^
//
//   0000_0000_0000_0000     0     1000_0000_0000_0000    15       1
//                     ^
//
//   0000_0000_0000_0000     1     0000_0000_0000_0001    0        1
//                    ^
//
//   0000_0000_0000_0000    15     0100_0000_0000_0000    14       1
//   ^
//
//   0010_1010_0011_0111     8     0000_0000_1000_0000    7        1
//           ^
//
//   1111_1111_1111_1111     x     xxxx_xxxx_xxxx_xxxx    x        0

module n #(
  // Vector width
`ifdef C_FLOW__OVERRIDE_TOP_W
  parameter int W = `C_FLOW__TOP_W
`else
  parameter int W
`endif
) (
  input wire logic [W - 1:0]                     x_i
, input wire logic [$clog2(W) - 1:0]             pos_i

//
, output wire logic [W - 1:0]                    y_o
, output wire logic [$clog2(W) - 1:0]            y_enc_o
, output wire logic                              any_o

//
, input wire logic                               clk
, input wire logic                               arst_n
);

// ========================================================================= //
//                                                                           //
// Static Assertions                                                         //
//                                                                           //
// ========================================================================= //

`C_STATIC_ASSERT(W > 0,
  "Unsupported vector width W; must be > 0");

// ========================================================================= //
//                                                                           //
// Flop(s)                                                                   //
//                                                                           //
// ========================================================================= //

// Inputs:
`C_DFF(logic [W - 1:0], x, clk);
`C_DFF(logic [$clog2(W) - 1:0], pos, clk);

// Outputs:
`C_DFF(logic [W - 1:0], y, clk);
`C_DFF(logic [$clog2(W) - 1:0], y_enc, clk);
`C_DFF_RST(logic, any, clk, arst_n);

// ========================================================================= //
//                                                                           //
// Wire(s)                                                                   //
//                                                                           //
// ========================================================================= //

logic [W - 1:0]                        pos_dec;
logic [W - 1:0][W - 1:0]               y_matrix;

// ========================================================================= //
//                                                                           //
// Logic.                                                                    //
//                                                                           //
// ========================================================================= //

// ------------------------------------------------------------------------- //
// Stage input flops
assign x_w = x_i;
assign pos_w = pos_i;

// ------------------------------------------------------------------------- //
//
dec #(.W(W)) u_dec (.x_i(pos_r), .y_o(pos_dec));

// ------------------------------------------------------------------------- //
//
for (genvar i = 0; i < W; i++) begin: for_each_pos_GEN
  n_pos #(.POS(i), .W(W)) u_pos(.x_i(x_r), .y_o(y_matrix[i]));
end: for_each_pos_GEN

// ------------------------------------------------------------------------- //
//
mux #(.N(W), .W(W)) u_max (.x_i(y_matrix), .sel_i(pos_dec), .y_o(y_w));

// ------------------------------------------------------------------------- //
// 'Any' flag; indicate that a 'b0 is present in the input vector. The
// output at y_* is therefore valid.
//
assign any_w = (x_r != '1);

// ------------------------------------------------------------------------- //
// Compute encoded output.
enc #(.W(W)) u_enc (.x_i(y_w), .y_o(y_enc_w));

// ========================================================================= //
//                                                                           //
// Assertions                                                                //
//                                                                           //
// ========================================================================= //


// Validate that output bit-vector is one-hot when emitting a valid output.
`C_ASSERT(any_r |-> $onehot(y_r), clk, arst_n,
  "Expect 1hot output when 'any' is high");

// Validate that 'any' is high when output is not all '0'.
`C_ASSERT((x_r != '1) |=> any_r, clk, arst_n,
  "Expect 'any' to be high when output is not all '0'");

// Validate that output bit is '0' when 'any' is high.
`C_ASSERT(any_w |-> (x_r & (1 << y_enc_w)) == '0, clk, arst_n,
  "Expect output bit to be '0' when 'any' is high");

if (W < (1 << $clog2(W))) begin: constrain_is_valid_pos_GEN
  // Validate pos for non-power-of-2 widths.
  `C_ASSERT(pos_r < W[$clog2(W) - 1:0], clk, arst_n,
    "POS input must be less than W");
end: constrain_is_valid_pos_GEN

// ========================================================================= //
//                                                                           //
// Output(s)                                                                 //
//                                                                           //
// ========================================================================= //

assign any_o = any_r;
assign y_o = y_r;
assign y_enc_o = y_enc_r;

endmodule : n

// Undefines
`include "asserts.svh"
`include "flops.svh"
