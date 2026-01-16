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

`include "common_defs.vh"

// Circuit to compute the cicular left-most '0' in a vector 'x' for a
// given position. 'any' flag computes first '0' from lsb.
//
//   x                    (pos, any)   y                      y_enc
//   -----------------------------------------------------------------------
//   1111_1111_1111_1110     x, true   0000_0000_0000_0001    0
//
//   0000_0000_0000_0000     0, false  1000_0000_0000_0000    15
//
//   0000_0000_0000_0000     1, false  0000_0000_0000_0001    0
//
//   0000_0000_0000_0000    15, false  0100_0000_0000_0000    14

module s #(
  // Vector width
  parameter int W

  // Encoded width
, localparam int ENC_W = $clog2(W)
) (
  input wire logic [W - 1:0]                     i_x
, input wire logic [ENC_W - 1:0]                 i_pos
, input wire logic                               i_any

//
, output wire logic [W - 1:0]                    o_y
, output wire logic [EN_W - 1:0]                 o_y_enc
);

assign y = '0;
assign y_enc = '0;

endmodule : s