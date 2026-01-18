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

module s #(
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
// Wire(s)                                                                   //
//                                                                           //
// ========================================================================= //

logic                                  any;
logic [W - 1:0]                        pre_1;
logic [W - 1:0]                        pre_2;
logic [W - 1:0]                        pre_3;
logic [W - 1:0]                        pre_4;
logic [W - 1:0]                        pre_5;
logic [W - 1:0]                        pre_6;

logic [W - 1:0]                        post_1;
logic [W - 1:0]                        post_2;
logic [W - 1:0]                        post_3;
logic [W - 1:0]                        post_4;

logic [W - 1:0]                        y;
logic [$clog2(W) - 1:0]                y_enc;

// ========================================================================= //
//                                                                           //
// Logic.                                                                    //
//                                                                           //
// ========================================================================= //

// ------------------------------------------------------------------------- //
// For bits preceeding pos_i in a circular manner.
//
// For an input vector:
//
//     1101_0010_0101_1001
//
// Compute a left-leaning inclusive mask from the position 'pos_i'.
//
//     1111_1111_1000_0000         where pos=7          // (1)
//
maske #(.W(W), .P_INCLUSIVE(1'b1), .LEFT_NOT_RIGHT(1'b1))
   u_maske_pre (.x_i(pos_i), .y_o(pre_1));

// OR this mask with in input.
//
//     1111_1111_1101_1001                              // (2)
//
assign pre_2 = (x_i | pre_1);

// Perform a bit reverse on the result of (2). No logic overhead.
//
//     1001_1011_1111_1111                              // (3)
//
rev #(.W(W)) u_rev_0_pre (.x_i(pre_2), .y_o(pre_3));

// Increment vector from (3).
//
//     1001_1100_0000_0000                              // (4)
//
inc #(.W(W)) u_inc_pre (.x_i(pre_3), .y_o(pre_4), .carry_o(/* UNUSED */));

// Detect the bit which transitions from '1' to '0' in (3) to (4).
//
//     0000_0100_0000_0000                              // (5)
//
assign pre_5 = (~pre_3 & pre_4);

// Reverse (5) to obtain the final output.
//
//     0000_0000_0010_0000                              // (6)
//
// The 1-hot output indicates the first '0' preceeding pos_i.
//
rev #(.W(W)) u_rev_1_pre (.x_i(pre_5), .y_o(pre_6));


// ------------------------------------------------------------------------- //
// For bits succeeding pos_i in a circular manner.
//
// For an input vector:
//
//     1101_0010_0101_1001
//
// Reverse the input vector. No logic overhead.
//
//     1001_1010_0100_1011                              // (1)
//
rev #(.W(W)) u_rev_post (.x_i(x_i), .y_o(post_1));

// Increment the vector from (1).
//
//     1001_1010_0100_1100                              // (2)
//
inc #(.W(W)) u_inc_post (.x_i(post_1), .y_o(post_2), .carry_o(/* UNUSED */));

// Detect the bit which transitions from '1' to '0' in (1) to
//
//     0000_0000_0000_0100                              // (3)
//
assign post_3 = (~post_1 & post_2);

// Reverse (3) to obtain the final output.
//
//     0010_0000_0000_0000                              // (4)
//
// The 1-hot output indicates the first '0' succeeding pos_i.
//
rev #(.W(W)) u_rev_post2 (.x_i(post_3), .y_o(post_4));


// ------------------------------------------------------------------------- //
// If no bit is found in the bits preceeding pos_i, use the output
// from the succeeding bits logic.
//
assign y = (pre_2 != '1) ? pre_6 : post_4;


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

endmodule : s
