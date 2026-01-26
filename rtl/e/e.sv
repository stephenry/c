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
  parameter int W = 32

  // Radix (In range: [2,8])
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
// Static Assertions                                                         //
//                                                                           //
// ========================================================================= //

`STATIC_ASSERT(W > 0,
  "Unsupported vector width W; must be > 0");

`STATIC_ASSERT((RADIX_N >= 2) && (RADIX_N <= 8),
  "Unsupported RADIX_N; must be in range [2, 8]");

// ========================================================================= //
//                                                                           //
// Wire(s)                                                                   //
//                                                                           //
// ========================================================================= //

logic [W - 1:0]                        y;
logic [$clog2(W) - 1:0]                y_enc;
logic                                  any;

// ========================================================================= //
//                                                                           //
// Logic.                                                                    //
//                                                                           //
// ========================================================================= //

if (W < 2) begin: gen_lt_2_GEN

// No priority encoder defined for W < 2
initial begin
  $error("Unsupported vector width W=%0d; minimum is 2", W);
end

end: gen_lt_2_GEN
else if (W <= 8) begin: no_multi_GEN

// 2 - 8: infer multi-level priority encoder
e_single #(.W(W)) u_e_single (
  .x_i                  (x_i)
, .pos_i                (pos_i)
//
, .y_o                  (y)
, .y_enc_o              (y_enc)
, .any_o                (any));

end: no_multi_GEN
else begin: multi_GEN

// > 8: use multi-level priority encoder
e_multi #(.W(W), .RADIX_N(RADIX_N)) u_e_multi (
  .x_i                  (x_i)
, .pos_i                (pos_i)
//
, .y_o                  (y)
, .y_enc_o              (y_enc)
, .any_o                (any));

end: multi_GEN


// ========================================================================= //
//                                                                           //
// Output(s)                                                                 //
//                                                                           //
// ========================================================================= //

assign any_o = any;
assign y_o = y;
assign y_enc_o = y_enc;

endmodule : e
