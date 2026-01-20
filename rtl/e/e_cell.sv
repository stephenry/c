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

module e_cell #(
  // Vector width
  parameter int W = 4
) (
  input wire logic                               x_prior_and_sel_i
, input wire logic [W - 1:0]                     x_i
, input wire logic [W - 1:0]                     sel_i
//
, output wire logic                              vld_o
, output wire logic [W - 1:0]                    y_o
);

case (W)
  2: begin : e_select_w2

//! PLA_BEGIN
//! .i x_prior_and_sel_i sel_i[1:0] x_i[1:0] 
//! .o vld_o y_o[1:0]
//!
//!  1 -- 0- 1 10
//!  1 -- 10 1 01
//!
//!  0 10 10 1 01
//!
//! .e
//! PLA_END

  end : e_select_w2

  3: begin : e_select_w3

//! PLA_BEGIN
//! .i x_prior_and_sel_i sel_i[2:0] x_i[2:0] 
//! .o vld_o y_o[2:0]
//!
//!  1 --- 0-- 1 100
//!  1 --- 10- 1 010
//!  1 --- 110 1 001
//!
//!  0 100 10- 1 010
//!  0 100 110 1 001
//!  0 -10 -10 1 001
//!
//! .e
//! PLA_END

  end : e_select_w3

  4: begin : e_select_w4

//! PLA_BEGIN
//! .i x_prior_and_sel_i sel_i[3:0] x_i[3:0] 
//! .o vld_o y_o[3:0]
//!
//!  1 ---- 0--- 1 1000
//!  1 ---- 10-- 1 0100
//!  1 ---- 110- 1 0010
//!  1 ---- 1110 1 0001
//!
//!  0 1000 10-- 1 0100
//!  0 1000 110- 1 0010
//!  0 1000 1110 1 0001
//!  0 0100 -10- 1 0010
//!  0 0100 -110 1 0001
//!  0 0010 --10 1 0001
//!
//! .e
//! PLA_END

  end : e_select_w4

  5: begin : e_select_w5

//! PLA_BEGIN
//! .i x_prior_and_sel_i sel_i[4:0] x_i[4:0] 
//! .o vld_o y_o[4:0]
//!
//!  1 ----- 0---- 1 10000
//!  1 ----- 10--- 1 01000
//!  1 ----- 110-- 1 00100
//!  1 ----- 1110- 1 00010
//!  1 ----- 11110 1 00001
//!
//!  0 10000 10--- 1 01000
//!  0 10000 110-- 1 00100
//!  0 10000 1110- 1 00010
//!  0 10000 11110 1 00001
//!  0 01000 -10-- 1 00100
//!  0 01000 -110- 1 00010
//!  0 01000 -1110 1 00001
//!  0 00100 --10- 1 00010
//!  0 00100 --110 1 00001
//!  0 00010 ---10 1 00001
//!
//! .e
//! PLA_END

  end : e_select_w5

  6: begin : e_select_w6

//! PLA_BEGIN
//! .i x_prior_and_sel_i sel_i[5:0] x_i[5:0] 
//! .o vld_o y_o[5:0]
//!
//!  1 ------ 0----- 1 100000
//!  1 ------ 10---- 1 010000
//!  1 ------ 110--- 1 001000
//!  1 ------ 1110-- 1 000100
//!  1 ------ 11110- 1 000010
//!  1 ------ 111110 1 000001
//!
//!  0 100000 10---- 1 010000
//!  0 100000 110--- 1 001000
//!  0 100000 1110-- 1 000100
//!  0 100000 11110- 1 000010
//!  0 100000 111110 1 000001
//!  0 010000 -10--- 1 001000
//!  0 010000 -110-- 1 000100
//!  0 010000 -1110- 1 000010
//!  0 010000 -11110 1 000001
//!  0 001000 --10-- 1 000100
//!  0 001000 --110- 1 000010
//!  0 001000 --1110 1 000001
//!  0 000100 ---10- 1 000010
//!  0 000100 ---110 1 000001
//!  0 000010 ----10 1 000001
//!
//! .e
//! PLA_END

  end : e_select_w6

  7: begin : e_select_w7

//! PLA_BEGIN
//! .i x_prior_and_sel_i sel_i[6:0] x_i[6:0] 
//! .o vld_o y_o[6:0]
//!
//!  1 ------- 0------ 1 1000000
//!  1 ------- 10----- 1 0100000
//!  1 ------- 110---- 1 0010000
//!  1 ------- 1110--- 1 0001000
//!  1 ------- 11110-- 1 0000100
//!  1 ------- 111110- 1 0000010
//!  1 ------- 1111110 1 0000001
//!
//!  0 1000000 10----- 1 0100000
//!  0 1000000 110---- 1 0010000
//!  0 1000000 1110--- 1 0001000
//!  0 1000000 11110-- 1 0000100
//!  0 1000000 111110- 1 0000010
//!  0 1000000 1111110 1 0000001
//!  0 0100000 -10---- 1 0010000
//!  0 0100000 -110--- 1 0001000
//!  0 0100000 -1110-- 1 0000100
//!  0 0100000 -11110- 1 0000010
//!  0 0100000 -111110 1 0000001
//!  0 0010000 --10--- 1 0001000
//!  0 0010000 --110-- 1 0000100
//!  0 0010000 --1110- 1 0000010
//!  0 0010000 --11110 1 0000001
//!  0 0001000 ---10-- 1 0000100
//!  0 0001000 ---110- 1 0000010
//!  0 0001000 ---1110 1 0000001
//!  0 0000100 ----10- 1 0000010
//!  0 0000100 ----110 1 0000001
//!  0 0000010 -----10 1 0000001
//!
//! .e
//! PLA_END

  end : e_select_w7

  8: begin : e_select_w8

//! PLA_BEGIN
//! .i x_prior_and_sel_i sel_i[7:0] x_i[7:0] 
//! .o vld_o y_o[7:0]
//!
//!  1 -------- 0------- 1 10000000
//!  1 -------- 10------ 1 01000000
//!  1 -------- 110----- 1 00100000
//!  1 -------- 1110---- 1 00010000
//!  1 -------- 11110--- 1 00001000
//!  1 -------- 111110-- 1 00000100
//!  1 -------- 1111110- 1 00000010
//!  1 -------- 11111110 1 00000001
//!
//!  0 10000000 10------ 1 01000000
//!  0 10000000 110----- 1 00100000
//!  0 10000000 1110---- 1 00010000
//!  0 10000000 11110--- 1 00001000
//!  0 10000000 111110-- 1 00000100
//!  0 10000000 1111110- 1 00000010
//!  0 10000000 11111110 1 00000001
//!  0 01000000 -10----- 1 00100000
//!  0 01000000 -110---- 1 00010000
//!  0 01000000 -1110--- 1 00001000
//!  0 01000000 -11110-- 1 00000100
//!  0 01000000 -111110- 1 00000010
//!  0 01000000 -1111110 1 00000001
//!  0 00100000 --10---- 1 00010000
//!  0 00100000 --110--- 1 00001000
//!  0 00100000 --1110-- 1 00000100
//!  0 00100000 --11110- 1 00000010
//!  0 00100000 --111110 1 00000001
//!  0 00010000 ---10--- 1 00001000
//!  0 00010000 ---110-- 1 00000100
//!  0 00010000 ---1110- 1 00000010
//!  0 00010000 ---11110 1 00000001
//!  0 00001000 ----10-- 1 00000100
//!  0 00001000 ----110- 1 00000010
//!  0 00001000 ----1110 1 00000001
//!  0 00000100 -----10- 1 00000010
//!  0 00000100 -----110 1 00000001
//!  0 00000010 ------10 1 00000001
//!
//! .e
//! PLA_END

  end : e_select_w8

  default: begin : e_select_default
    // Unsupported width
    initial begin
      $error("e_select: Unsupported width W=%0d", W);
    end
  end
endcase

endmodule : e_cell
