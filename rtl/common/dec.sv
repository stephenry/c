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

module dec #(
  // Width of encoded input
  parameter int W

, parameter int OUT_W = W
) (
// -------------------------------------------------------------------------- //
// Decoded input
  input wire logic [$clog2(W) - 1:0]             x_i

// -------------------------------------------------------------------------- //
// Encoded output
, output wire logic [OUT_W - 1:0]                y_o
);

// ========================================================================== //
//                                                                            //
//  Wires                                                                     //
//                                                                            //
// ========================================================================== //

logic [OUT_W - 1:0]                         y;

// ========================================================================= //
//                                                                           //
// Logic.                                                                    //
//                                                                           //
// ========================================================================= //

// ------------------------------------------------------------------------- //
//
if (W < OUT_W) begin : w_lt_out_w_GEN

// OUT_W is larger than the dynamic range of the input. Padd the output
// with zeros as necessary.

  for (genvar i = 0; i < OUT_W; i++) begin: y_GEN

    if (i < W) begin: lt_w_GEN

assign y[i] = (x_i == i[$clog2(W) - 1:0]);

    end: lt_w_GEN
    else begin: ge_w_GEN

assign y[i] = 1'b0;

    end: ge_w_GEN

  end: y_GEN

end: w_lt_out_w_GEN
else begin : w_ge_out_w_GEN

// OUT_W is smaller than or equal to the dynamic range of the input.

  for (genvar i = 0; i < W; i++) begin: y_GEN

assign y[i] = (x_i == i[$clog2(W) - 1:0]);

  end: y_GEN

end: w_ge_out_w_GEN


// ========================================================================== //
//                                                                            //
//  Outputs                                                                   //
//                                                                            //
// ========================================================================== //

assign y_o = y;

endmodule : dec
