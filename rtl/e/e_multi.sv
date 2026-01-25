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

// Circuit to compute the cicular left-most '0' in a vector 'x' for a
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

module e_multi #(
  // Vector width
  parameter int W = 32

  // Radix (In range: [4,8])
, parameter int RADIX_N = 4
) (
  input wire logic [W - 1:0]                     x_i
, input wire logic [$clog2(W) - 1:0]             pos_i

//
, output wire logic [W - 1:0]                    y_o
, output wire logic [$clog2(W) - 1:0]            y_enc_o
, output wire logic                              any_o
);

// ========================================================================= //
//                                                                           //
// Localparams                                                               //
//                                                                           //
// ========================================================================= //

localparam int SEARCH_WORD_W = 2 * W;

localparam int GROUPS_N = math_pkg::div_ceil(SEARCH_WORD_W, RADIX_N);

typedef logic [GROUPS_N - 1:0]                     groups_t;
typedef logic [GROUPS_N - 1:0][RADIX_N - 1:0]      groups_vec_t;

localparam int GROUPS_VEC_W = $bits(groups_vec_t);

// Flag indicating whether the groups require padding to fill the last group.
localparam bit REQUIRES_PADDING = (GROUPS_N * RADIX_N != SEARCH_WORD_W);

// Number of padding bits required (if any).
localparam int PADDING_BITS =
  REQUIRES_PADDING ? ((GROUPS_N * RADIX_N) - W) : 0;

// ========================================================================= //
//                                                                           //
// Wire(s)                                                                   //
//                                                                           //
// ========================================================================= //

logic [W - 1:0]                        pos_dec;

groups_t                               groups_c;
groups_vec_t                           groups_in;
groups_vec_t                           groups_sel;
groups_vec_t                           groups_y;
groups_t                               groups_vld;

groups_t                               groups_region;
groups_t                               groups_select;

logic [W - 1:0]                        y_hi;
logic [W - 1:0]                        y_lo;
groups_vec_t                           y_groups;

logic                                  any;

logic [W - 1:0]                        y_priority;
logic                                  y_priority_valid;
logic [W - 1:0]                        y;
logic [$clog2(W) - 1:0]                y_enc;

// ========================================================================= //
//                                                                           //
// Logic.                                                                    //
//                                                                           //
// ========================================================================= //

// ------------------------------------------------------------------------- //
// Compute selection vector.
dec #(.W(W)) u_dec (
  .x_i                       (pos_i)
, .y_o                       (pos_dec));

// ------------------------------------------------------------------------- //
// Compute input vector (padding if required).
if (REQUIRES_PADDING) begin : gen_groups_padding
  assign groups_in = { {PADDING_BITS{1'b0}}, x_i, x_i };
  assign groups_sel = { {PADDING_BITS{1'b0}}, pos_dec, pos_dec };
end
else begin : gen_groups_no_padding

  assign groups_in = { x_i, x_i };
  assign groups_sel = { pos_dec, pos_dec };
end : gen_groups_no_padding


// ------------------------------------------------------------------------- //
//
for (genvar i = 0; i < GROUPS_N; i++) begin : group_GEN

if (i == (GROUPS_N - 1)) begin: last_group_GEN

  e_priority #(.W(RADIX_N)) u_e_priority (
    .cin_i                   (1'b0)
  , .x_i                     (groups_in[i])
  , .sel_i                   (groups_sel[i])
  , .vld_o                   (groups_vld[i])
  , .y_o                     (groups_y[i])
  , .cout_o                  (groups_c[i]));

end: last_group_GEN
else begin: not_last_group_GEN

  e_priority #(.W(RADIX_N)) u_e_priority (
    .cin_i                   (groups_c[i + 1])
  , .x_i                     (groups_in[i])
  , .sel_i                   (groups_sel[i])
  , .vld_o                   (groups_vld[i])
  , .y_o                     (groups_y[i])
  , .cout_o                  (groups_c[i]));

end: not_last_group_GEN

end : group_GEN


// ------------------------------------------------------------------------- //
//
for (genvar i = 0; i < GROUPS_N; i++) begin : group_output_GEN

  assign y_groups[i] = ({RADIX_N{groups_vld[i]}} & groups_y[i]);

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
assign y = y_priority_valid ? y_priority : pos_dec;

// ------------------------------------------------------------------------- //
// 'Any' flag; indicate that a 'b0 is present in the input vector. The
// output at y_* is therefore valid.
// 
assign any = (x_i != '1);


// ------------------------------------------------------------------------- //
// Compute encoded output.
enc #(.W(W)) u_enc (.x_i(y), .y_o(y_enc));


// ========================================================================= //
//                                                                           //
// Output(s)                                                                 //
//                                                                           //
// ========================================================================= //

assign any_o = any;
assign y_o = y;
assign y_enc_o = y_enc;

endmodule : e_multi
