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

module r #(
  // Vector width
  parameter int W = 32

// Infer shifter/rotator
, parameter bit INFER = 1'b1
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

`C_STATIC_ASSERT(W > 0,
  "Unsupported vector width W; must be > 0");

// ========================================================================= //
//                                                                           //
// Wire(s)                                                                   //
//                                                                           //
// ========================================================================= //

logic [W - 1:0]                        res_1;
logic [$clog2(W):0]                    shift_1;
logic [W - 1:0]                        res_2;
logic [W - 1:0]                        res_3;
logic [W - 1:0]                        res_4;
logic [$clog2(W):0]                    shift_4;

logic                                  any;
logic [W - 1:0]                        y;
logic [$clog2(W) - 1:0]                y_enc;

// ========================================================================= //
//                                                                           //
// Logic.                                                                    //
//                                                                           //
// ========================================================================= //

// ------------------------------------------------------------------------- //
//
// For an input vector (pos 9):
//
//     1101_0010_0101_1001
//            ^
//
// Left-Rotate the vector such that the bit at pos_i is the LSB.
//
//     0010_1100_1110_1001                                 // (1)
//                       ^
//
assign shift_1 = W[$clog2(W):0] - {1'b0, pos_i};

if (INFER) begin : gen_infer_bs

  // Use inferred shifter/rotator.
  bsi #(.W(W), .P_ARITH(1'b0), .P_ROTATE(1'b1), .P_RIGHT(1'b0)) u_bsi_1 (
    .x_i             (x_i)
  , .shift_i         (shift_1[$clog2(W) - 1:0])
  , .y_o             (res_1)
  );
end
else begin : gen_explicit_bs

  // Use explicit shifter/rotator.
  bs #(.W(W)) u_bs_1 (
    .x_i             (x_i)
  , .shift_i         (shift_1[$clog2(W) - 1:0])
  , .is_arith_i      (1'b0)
  , .is_rotate_i     (1'b1)
  , .is_right_i      (1'b0)
  , .y_o             (res_1)
);
end : gen_explicit_bs

// Invert bits.
//
//     1101_0011_0001_0110                                 // (2)
//                       ^
//
assign res_2 = ~res_1;

// Detect first '1' from MSB side.
//
//     1000_0000_0000_0000                                 // (3)
//                       ^
//
pri #(.W(W), .FROM_LSB(1'b0)) u_pri_3 (.i_x(res_2), .o_y(res_3));

// Right-Rotate the output vector back to original position.
//
//     0000_0001_0000_0000                                 // (4)
//            ^
//
// The 1-hot output indicates the first '0' succeeding pos_i.
//
assign shift_4 = W[$clog2(W):0] - {1'b0, pos_i};

if (INFER) begin : gen_infer_bs_4

  // Use inferred shifter/rotator.
  bsi #(.W(W), .P_ARITH(1'b0), .P_ROTATE(1'b1), .P_RIGHT(1'b1)) u_bsi_4 (
    .x_i             (res_3)
  , .shift_i         (shift_4[$clog2(W) - 1:0])
  , .y_o             (res_4));
end
else begin : gen_explicit_bs_4

  // Use explicit shifter/rotator.
  bs #(.W(W)) u_bs_4 (
    .x_i             (res_3)
  , .shift_i         (shift_4[$clog2(W) - 1:0])
  , .is_arith_i      (1'b0)
  , .is_rotate_i     (1'b1)
  , .is_right_i      (1'b1)
  , .y_o             (res_4));
end : gen_explicit_bs_4


// ------------------------------------------------------------------------- //
// If no bit is found in the bits preceeding pos_i, use the output
// from the succeeding bits logic.
//
assign y = res_4;


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

endmodule : r
