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
  parameter int W
// Width of Mux.
, parameter int SHIFT_W = $clog2(W)
// Allow synthesis inference
, parameter bit INFER = 'b0
) (
// -------------------------------------------------------------------------- //
// Command
  input wire logic [W - 1:0]                      x_i
, input wire logic [SHIFT_W - 1:0]                shift_i

// -------------------------------------------------------------------------- //
// Control
, input wire logic                                is_arith_i
, input wire logic                                is_rotate_i
, input wire logic                                is_right_i

// -------------------------------------------------------------------------- //
//
, output wire logic [W - 1:0]                     y_o
);

if (!INFER) begin : infer_GEN

// ========================================================================== //
//                                                                            //
//  Wires                                                                     //
//                                                                            //
// ========================================================================== //

localparam int ROUND_BITS = (3 * W);
localparam int ROUND_MSB = (ROUND_BITS - 1);
localparam int ROUND_LSB = 0;

logic                                       do_sign_extend;

logic [SHIFT_W - 1:0][ROUND_MSB:ROUND_LSB]  round_l;
logic [SHIFT_W - 1:0][ROUND_MSB:ROUND_LSB]  round_r;
logic [SHIFT_W:0][ROUND_MSB:ROUND_LSB]      round;

logic [2:0]                                 sel;
logic [W - 1:0]                             y;

// ========================================================================== //
//                                                                            //
//  Logic                                                                     //
//                                                                            //
// ========================================================================== //

// -------------------------------------------------------------------------- //
//
assign do_sign_extend =
  (is_arith_i & is_right_i & (~is_rotate_i) & x_i[W - 1]);

assign round[SHIFT_W] = { {W{do_sign_extend}}, x_i, {W{1'b0}} };

// -------------------------------------------------------------------------- //
//
for (genvar sh = (SHIFT_W - 1); sh >= 0; sh--) begin :sh_GEN

  for (genvar i = 0; i < (3 * W); i++) begin : bit_GEN

localparam int STRIDE = (1 << sh);

localparam int L_INDEX = (i + STRIDE);
localparam int R_INDEX = (i - STRIDE);

assign round_l[sh][i] = (L_INDEX <= ROUND_MSB) & round[sh + 1][L_INDEX];
assign round_r[sh][i] = (R_INDEX >= ROUND_LSB) & round[sh + 1][R_INDEX];

assign round[sh][i] =
  shift_i[sh] ? (is_right_i ? round_r : round_l) : round[sh + 1][i];

  end : bit_GEN

end : sh_GEN

// Mux-Madness; "sel" is effectively a mux with 3, W-bit inputs. In this case
// the "sel" can be non-onehot in the rotate-case to allow the wrapped state to
// be rotated back into the final word.
assign sel[2] = is_rotate_i & (~is_right_i);
assign sel[1] = 'b1;
assign sel[0] = is_rotate_i &   is_right_i;

sel #(.W(W), .N(3)) u_sel(.x_i(round[0]), .i_sel(sel), .y_o(y));

end : infer_GEN
else begin : ninfer_GEN

always_comb begin : shift_PROC

  case ({is_arith_i, is_rotate_i, is_right_i}) inside
    3'b000:  y = $unsigned(x_i)  << shift_i;
    3'b001:  y = $unsigned(x_i)  >> shift_i;
    3'b010:  y = $unsigned(x_i) <<< shift_i;
    3'b011:  y = $unsigned(x_i) >>> shift_i;
    3'b100:  y =   $signed(x_i)  << shift_i;
    3'b101:  y =   $signed(x_i)  >> shift_i;
    3'b110:  y =   $signed(x_i) <<< shift_i;
    3'b111:  y =   $signed(x_i) >>> shift_i;
    default: y = 'x;
  endcase

end : shift_PROC

end : ninfer_GEN

// ========================================================================== //
//                                                                            //
//  Outputs                                                                   //
//                                                                            //
// ========================================================================== //

assign y_o = y;

endmodule : bs
