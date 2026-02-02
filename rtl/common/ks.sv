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

module ks #(
  // Width of input
  parameter int W = `C_FLOW__TOP_W
) (
// -------------------------------------------------------------------------- //
// Inputs
  input wire logic [W - 1:0]                     p_i
, input wire logic [W - 1:0]                     g_i

// -------------------------------------------------------------------------- //
// Outputs
, output wire logic [W - 1:0]                    p_o
, output wire logic [W - 1:0]                    g_o
);

// ========================================================================== //
//                                                                            //
//  Wires                                                                     //
//                                                                            //
// ========================================================================== //

logic [W - 1:0]                         p;
logic [W - 1:0]                         g;

// ========================================================================== //
//                                                                            //
// Logic.                                                                     //
//                                                                            //
// ========================================================================== //

// ------------------------------------------------------------------------- //
//
for (genvar rnd = 0; rnd < $clog2(W); rnd++) begin : rnds_GEN

  logic [W - 1:0]                          rnd_p;
  logic [W - 1:0]                          rnd_g;

  localparam int STEP = (1 << rnd);

  for (genvar i = 0; i < W; i++) begin: bits_GEN

    if (i < STEP) begin: gen_lower_bits

      if (rnd == 0) begin: rnd_zero

assign rnd_p[i] = p_i[i];
assign rnd_g[i] = g_i[i];

      end: rnd_zero
      else begin: rnd_non_zero

assign rnd_p[i] = rnds_GEN[rnd - 1].rnd_p[i];
assign rnd_g[i] = rnds_GEN[rnd - 1].rnd_g[i];

      end: rnd_non_zero

    end: gen_lower_bits
    else begin: gen_upper_bits

      if (rnd == 0) begin: rnd_zero

assign rnd_p[i] = p_i[i] & p_i[i - STEP];
assign rnd_g[i] = g_i[i] | (p_i[i] & g_i[i - STEP]);

      end: rnd_zero
      else begin: rnd_non_zero

assign rnd_p[i] =
  rnds_GEN[rnd - 1].rnd_p[i] & rnds_GEN[rnd - 1].rnd_p[i - STEP];

assign rnd_g[i] =
  rnds_GEN[rnd - 1].rnd_g[i] |
  (rnds_GEN[rnd - 1].rnd_p[i] & rnds_GEN[rnd - 1].rnd_g[i - STEP]);

      end: rnd_non_zero

    end: gen_upper_bits

  end : bits_GEN

end : rnds_GEN

// ------------------------------------------------------------------------- //
//
assign g = rnds_GEN[$clog2(W) - 1].rnd_g;
assign p = rnds_GEN[$clog2(W) - 1].rnd_p;

// ========================================================================== //
//                                                                            //
//  Outputs                                                                   //
//                                                                            //
// ========================================================================== //

// ------------------------------------------------------------------------- //
//
assign p_o = p;
assign g_o = g;

endmodule: ks
