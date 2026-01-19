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

module sel #(
// Width of selection vector
  parameter int              W
// Number of selection bits
, parameter int              N
) (
// -------------------------------------------------------------------------- //
// Selection Vector
  input wire logic [(N * W) - 1:0]               i_x
//
, input wire logic [N - 1:0]                     i_sel

// -------------------------------------------------------------------------- //
// Encoded output
, output wire logic [W - 1:0]                    o_y
);

// ========================================================================== //
//                                                                            //
//  Wires                                                                     //
//                                                                            //
// ========================================================================== //

logic [N - 1:0][W - 1:0]               grp;

// ========================================================================== //
//                                                                            //
//  Logic                                                                     //
//                                                                            //
// ========================================================================== //

// -------------------------------------------------------------------------- //
//
for (genvar i = 0; i < N; i++) begin : bin_GEN

assign grp[i] = i_x[(W * i) +: W];

end : bin_GEN

// -------------------------------------------------------------------------- //
//
mux #(.N(N), .W(W)) u_idx_mux (.i_x(grp), .i_sel, .o_y);

endmodule : sel
