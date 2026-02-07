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

// Circuit to compute the first-zero (left-most) '0' in the input vector.

module k_ff #(
  // Width of input
  parameter int W

, parameter bit DETECT_ZERO = 1'b1
) (
// ------------------------------------------------------------------------ //
// Input vector                                                             //
// ------------------------------------------------------------------------ //

  input wire logic [W - 1:0]                     x_i

// ------------------------------------------------------------------------ //
// Output                                                                   //
// ------------------------------------------------------------------------ //

, output wire logic [W - 1:0]                   y_o
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
// Wire(s)                                                                   //
//                                                                           //
// ========================================================================= //

logic [W - 1:0]                        p;
logic [W - 1:0]                        g;
logic [W - 1:0]                        p_final;
logic [W - 1:0]                        g_final;
logic [W - 1:0]                        y;

logic                                  UNUSED__nets;

// ========================================================================= //
//                                                                           //
// Logic.                                                                    //
//                                                                           //
// ========================================================================= //

// ------------------------------------------------------------------------- //
//  DETECT_ZERO: propagate carry on '1'
// !DETECT_ZERO: propagate carry on '0'
//
assign p = DETECT_ZERO ? x_i : (~x_i);

// ------------------------------------------------------------------------- //
//  DETECT_ZERO: generate carry on '0'
// !DETECT_ZERO: generate carry on '1'
//
assign g = DETECT_ZERO ? (~x_i) : x_i;

// ------------------------------------------------------------------------- //
// Kogge-Stone Carry-Save Adder to compute carry-chain.
//
ks #(.W(W)) u_ks (.p_i(p), .g_i(g), .p_o(p_final), .g_o(g_final));

// ------------------------------------------------------------------------- //
//
//
if (DETECT_ZERO) begin: detect_zero_GEN
  // DETECT_ZERO: output '1' at first '0' position.
  assign y = (~x_i) & {p_final[W - 2:0], 1'b1};
end: detect_zero_GEN
else begin: detect_one_GEN
  // !DETECT_ZERO: output '1' at first '1' position.
  assign y =   x_i  & {p_final[W - 2:0], 1'b1};
end: detect_one_GEN


// ========================================================================= //
//                                                                           //
// Unused(s)                                                                 //
//                                                                           //
// ========================================================================= //

// ------------------------------------------------------------------------- //
// Carry-out is unused.
//
assign UNUSED__nets = &{ g_final, p_final[W - 1] };

// ========================================================================= //
//                                                                           //
// Output(s)                                                                 //
//                                                                           //
// ========================================================================= //

assign y_o = y;

endmodule: k_ff

// Undefines
`include "common_defs.svh"
`include "asserts.svh"
