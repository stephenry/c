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

module e_single #(
  // Vector width
  parameter int W = 32
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


// ========================================================================= //
//                                                                           //
// Wire(s)                                                                   //
//                                                                           //
// ========================================================================= //

logic [W - 1:0]                        pos_dec;
logic                                  priority_vld;
logic [W - 1:0]                        y;
logic [$clog2(W) - 1:0]                y_enc;
logic                                  any;

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
// Selection logic
e_priority #(.W(W)) u_e_priority (
  .cin_i                (1'b0)
, .x_i                  (x_i)
, .sel_i                (pos_dec)
//
, .vld_o                (priority_vld)
, .y_o                  (y)
, .cout_o               (/* UNUSED */));

// ------------------------------------------------------------------------- //
// 'Any' flag; indicate that a 'b0 is present in the input vector. The
// output at y_* is therefore valid.
// 
assign any = (priority_vld);

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

endmodule : e_single
