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

module n_pos #(
  // POS
  parameter int POS = 0

  // Vector width
, parameter int W = 32

// Infer shifter/rotator
, parameter bit INFER = 1'b0
) (
  input wire logic [W - 1:0]                     x_i
//
, output wire logic [W - 1:0]                    y_o
);

// ========================================================================= //
//                                                                           //
// Wire(s)                                                                   //
//                                                                           //
// ========================================================================= //

logic [W - 1:0]                        x_1;
logic [W - 1:0]                        x_2;
logic [W - 1:0]                        x_3;
logic [W - 1:0]                        x_4;
logic [W - 1:0]                        x_5;
logic [W - 1:0]                        x_6;

logic [W - 1:0]                        y;

// ========================================================================= //
//                                                                           //
// Logic.                                                                    //
//                                                                           //
// ========================================================================= //

// ------------------------------------------------------------------------- //
// For a given vector position
//
//   0000_0100_0000_0000
//   abcd_efgh_ijkl_mnop (pos=10)
//         ^
//
// Rotate the vector left W - POS
//
//   ghij_klmn_opab_cdef                                   // (1) 
//
localparam int ROTATE_LEFT_1 = (W - POS) % W;

if (ROTATE_LEFT_1 != 0) begin: lsh_GEN
  assign x_1 = {
    x_i[(W - 1) - ROTATE_LEFT_1:0], x_i[W - 1:W - ROTATE_LEFT_1]};
end: lsh_GEN
else begin: nop_lsh_GEN
  assign x_1 = x_i;
end: nop_lsh_GEN

// Reverse the vector
//
//  fedc_bapo_nmkl_jihg                                    // (2)
//
rev #(.W(W)) u_rev_1 (.x_i(x_1), .y_o(x_2));

// Increment the vector
//
//  1000_0000_0000_0001                                    // (3)
//  fedc_bapo_nmkl_jihg
//
inc #(.W(W)) u_inc (.x_i(x_2), .y_o(x_3), .carry_o(/* UNUSED */));

// Bit which transition from '0' to '1' is first '0' in original vector.
//
//  0000_0000_0000_0001                                    // (4)
//  fedc_bapo_nmkl_jihg
//
assign x_4 = x_3 & ~x_2;

// Rotate the vector right to original position
//
//  0000_0000_0100_0000                                    // (5)
//  ponm klji hgfe dcba
//
localparam int ROTATE_RIGHT_4 = (W - POS) % W;

if (ROTATE_RIGHT_4 != 0) begin: rsh_GEN
  assign x_5 = {
    x_4[W - 1 - ROTATE_RIGHT_4:0], x_4[W - 1:W - ROTATE_RIGHT_4]};
end: rsh_GEN
else begin: nop_rsh_GEN
  assign x_5 = x_4;
end: nop_rsh_GEN

// Reverse the vector
//
//   0000_0010_0000_0000                                   // (6)
//   abcd efgh ijkl mnop
//
rev #(.W(W)) u_rev_2 (.x_i(x_5), .y_o(x_6));

// Result of x6 is y.
//
assign y = x_6;


// ========================================================================= //
//                                                                           //
// Output(s)                                                                 //
//                                                                           //
// ========================================================================= //

assign y_o = y;

endmodule : n_pos
