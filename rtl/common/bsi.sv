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

module bs #(
// Width
  parameter int W = 32
// Left or Right
, parameter bit P_RIGHT = 1'b0
// Arithmetic or Logical
, parameter bit P_ARITH = 1'b0
// Rotator or Shifter
, parameter bit P_ROTATE = 1'b0
// Width of Mux.
, parameter int SHIFT_W = $clog2(W)
) (
// -------------------------------------------------------------------------- //
// Command
  input wire logic [W - 1:0]                      x_i
, input wire logic [SHIFT_W - 1:0]                shift_i

// -------------------------------------------------------------------------- //
//
, output wire logic [W - 1:0]                     y_o
);

// ========================================================================== //
//                                                                            //
//  Wires                                                                     //
//                                                                            //
// ========================================================================== //

logic [W - 1:0]                           y;

// ========================================================================== //
//                                                                            //
//  Logic                                                                     //
//                                                                            //
// ========================================================================== //

// -------------------------------------------------------------------------- //
//
always_comb begin: bsi_PROC

  // Defer to synthesizer for implementation.
  case ({P_ARITH, P_ROTATE, P_RIGHT})
    3'b000:  y = $unsigned(i_x)  << i_shift;
    3'b001:  y = $unsigned(i_x)  >> i_shift;
    3'b010:  y = $unsigned(i_x) <<< i_shift;
    3'b011:  y = $unsigned(i_x) >>> i_shift;
    3'b100:  y =   $signed(i_x)  << i_shift;
    3'b101:  y =   $signed(i_x)  >> i_shift;
    3'b110:  y =   $signed(i_x) <<< i_shift;
    3'b111:  y =   $signed(i_x) >>> i_shift;
    default: y = 'x;
  endcase

end: bsi_PROC

// ========================================================================== //
//                                                                            //
//  Outputs                                                                   //
//                                                                            //
// ========================================================================== //

assign y_o = y;

endmodule : bs
