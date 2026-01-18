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

module maske #(
  // Width of encoded input
  parameter int W

, parameter bit P_INCLUSIVE

, parameter bit LEFT_NOT_RIGHT
) (
// -------------------------------------------------------------------------- //
// Decoded input
  input wire logic [$clog2(W) - 1:0]             x_i

// -------------------------------------------------------------------------- //
// Encoded output
, output wire logic [W - 1:0]                    y_o
);

// ========================================================================== //
//                                                                            //
//  Localparams                                                               //
//                                                                            //
// ========================================================================== //

localparam int X_W = $bits(x_i);

// ========================================================================== //
//                                                                            //
//  Wires                                                                     //
//                                                                            //
// ========================================================================== //

logic [W - 1:0]                        y;

// -------------------------------------------------------------------------- //
// Mask generation logic.
//
// Code appears overly complex, and it is! But, it is done like this
// to avoid lint-violations on bounary indices (i == 0 and i == W - 1) where
// comparisons become constant. Constant expressions for certain indices
// are okay in a loop, but some linters complain about them, so they have
// to be written out explicitly.
//
generate begin : mask_GEN
  
  for (genvar i = 0; i < W; i++) begin : idx_GEN

  if (i == 0) begin : first_BIT_GEN

    case ({P_INCLUSIVE, LEFT_NOT_RIGHT})
      2'b00: begin
        // Right exclusive
        assign y[i] = (x_i != 'b0);
      end
      2'b01: begin
        // Left exclusive
        assign y[i] = 1'b0;
      end
      2'b10: begin
        // Right inclusive
        assign y[i] = 1'b1;
      end
      2'b11: begin
        // Left inclusive
        assign y[i] = (x_i == 'b0);
      end
    endcase

  end : first_BIT_GEN
  else if (i == (W - 1)) begin : last_BIT_GEN

    case ({P_INCLUSIVE, LEFT_NOT_RIGHT})
      2'b00: begin
        // Right exclusive
        assign y[i] = 1'b0;
      end
      2'b01: begin
        // Left exclusive
        assign y[i] = (x_i != i[X_W - 1:0]);
      end
      2'b10: begin
        // Right inclusive
        assign y[i] = (x_i == i[X_W - 1:0]);
      end
      2'b11: begin
        // Left inclusive
        assign y[i] = 1'b1;
      end
    endcase

  end : last_BIT_GEN
  else begin : other_BITS_GEN

    case ({P_INCLUSIVE, LEFT_NOT_RIGHT})
      2'b00: begin
        // Right exclusive
        assign y[i] = (x_i > i[X_W - 1:0]);
      end
      2'b01: begin
        // Left exclusive
        assign y[i] = (x_i < i[X_W - 1:0]);
      end
      2'b10: begin
        // Right inclusive
        assign y[i] = (x_i >= i[X_W - 1:0]);
      end
      2'b11: begin
        // Left inclusive
        assign y[i] = (x_i <= i[X_W - 1:0]);
      end
    endcase

  end : other_BITS_GEN

  end : idx_GEN

end endgenerate


// ========================================================================== //
//                                                                            //
//  Outputs                                                                   //
//                                                                            //
// ========================================================================== //

assign y_o = y;

endmodule : maske
