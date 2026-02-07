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
`include "math_pkg.svh"
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

module e #(
  // Vector width
`ifdef C_FLOW__OVERRIDE_TOP_W
  parameter int W = `C_FLOW__TOP_W
`else
  parameter int W
`endif

  // Radix (In range: [4,8])
, parameter int RADIX_N = 4
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

`C_STATIC_ASSERT((RADIX_N >= 2) && (RADIX_N <= 8),
  "Unsupported RADIX_N; must be in range [2, 8]");

// ========================================================================= //
//                                                                           //
// Localparams                                                               //
//                                                                           //
// ========================================================================= //

localparam int SEARCH_WORD_W = 2 * W;

// Priority network width must be reduced for small vector widths.
localparam int PRI_W = (W < RADIX_N) ? W : RADIX_N;

localparam int GROUPS_N = math_pkg::div_ceil(SEARCH_WORD_W, PRI_W);

typedef logic [GROUPS_N - 1:0]                     groups_t;
typedef logic [GROUPS_N - 1:0][PRI_W - 1:0]        groups_vec_t;

// Flag indicating whether the groups require padding to fill the last group.
localparam bit REQUIRES_PADDING = (GROUPS_N * PRI_W != SEARCH_WORD_W);

// Number of padding bits required (if any).
localparam int PADDING_BITS =
  REQUIRES_PADDING ? ((GROUPS_N * PRI_W) - W) : 0;


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

groups_vec_t                           groups_in;
groups_vec_t                           groups_sel;
groups_vec_t                           groups_y;
groups_t                               groups_vld;

logic [W - 1:0]                        y_hi;
logic [W - 1:0]                        y_lo;
groups_vec_t                           y_groups;

logic [W - 1:0]                        y_priority;
logic                                  y_priority_valid;

logic                                  UNUSED__nets;

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
// Compute selection vector.
dec #(.W(W)) u_dec (
  .x_i                       (pos_r)
, .y_o                       (pos_dec));

// ------------------------------------------------------------------------- //
// Compute input vector (padding if required).
if (REQUIRES_PADDING) begin : gen_groups_padding
  assign groups_in = { {PADDING_BITS{1'b0}}, x_r, x_r };
  assign groups_sel = { {PADDING_BITS{1'b0}}, pos_dec, pos_dec };
end
else begin : gen_groups_no_padding
  assign groups_in = { x_r, x_r };
  assign groups_sel = { pos_dec, pos_dec };
end : gen_groups_no_padding


// ------------------------------------------------------------------------- //
//
for (genvar i = 0; i < GROUPS_N; i++) begin : pri_GEN

logic                                  carry;

if (i == (GROUPS_N - 1)) begin: last_pri_GEN

  e_pri #(.W(PRI_W)) u_e_pri (
    .cin_i                   (1'b0)
  , .x_i                     (groups_in[i])
  , .sel_i                   (groups_sel[i])
  , .vld_o                   (groups_vld[i])
  , .y_o                     (groups_y[i])
  , .cout_o                  (pri_GEN[i].carry));

end: last_pri_GEN
else begin: not_last_pri_GEN

  e_pri #(.W(PRI_W)) u_e_pri (
    .cin_i                   (pri_GEN[i + 1].carry)
  , .x_i                     (groups_in[i])
  , .sel_i                   (groups_sel[i])
  , .vld_o                   (groups_vld[i])
  , .y_o                     (groups_y[i])
  , .cout_o                  (pri_GEN[i].carry));

end: not_last_pri_GEN

end : pri_GEN


// ------------------------------------------------------------------------- //
//
for (genvar i = 0; i < GROUPS_N; i++) begin : group_output_GEN

  assign y_groups[i] = ({PRI_W{groups_vld[i]}} & groups_y[i]);

end : group_output_GEN

// ------------------------------------------------------------------------- //
// Discard padding from final output (if present)
//
if (REQUIRES_PADDING) begin: y_groups_padding_GEN
  logic [PADDING_BITS - 1:0]           y_padding;

  assign {y_padding, y_hi, y_lo} = y_groups;

end: y_groups_padding_GEN
else begin: y_groups_no_padding_GEN

  assign {y_hi, y_lo} = y_groups;

end: y_groups_no_padding_GEN

// ------------------------------------------------------------------------- //
// Combine hi- and lo- priority networks to emulate rotator behaviour.
//
// Priority networks have no ability to detect collision on pos so, when
// 'any' is valid and the priority network hasn't hit on a '0', the only
// possible '0' is at pos_i.
//
assign y_priority = (y_hi | y_lo);
assign y_priority_valid = (y_priority != '0);
assign y_w = y_priority_valid ? y_priority : pos_dec;

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

// ========================================================================= //
//                                                                           //
// Unused(s)                                                                 //
//                                                                           //
// ========================================================================= //

// Avoid unused group signals.
assign UNUSED__nets = ^{ pri_GEN[0].carry };

// ========================================================================= //
//                                                                           //
// Output(s)                                                                 //
//                                                                           //
// ========================================================================= //

assign any_o = any_r;
assign y_o = y_r;
assign y_enc_o = y_enc_r;

endmodule : e

// Undefines
`include "common_defs.svh"
`include "math_pkg.svh"
`include "asserts.svh"
`include "flops.svh"
