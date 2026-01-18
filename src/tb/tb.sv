// ========================================================================= //
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
// ========================================================================= //

`include "common_defs.svh"

module tb #(

  parameter int W

, parameter string P_UUT_NAME
) (
  input wire logic                               vld_i
, input wire logic [W - 1:0]                     x_i
, input wire logic [$clog2(W) - 1:0]             pos_i

//
, output wire logic                              vld_o
, output wire logic [W - 1:0]                    x_o
, output wire logic [$clog2(W) - 1:0]            pos_o
, output wire logic                              any_o
, output wire logic [W - 1:0]                    y_o
, output wire logic [$clog2(W) - 1:0]            y_enc_o

, input wire logic                               arst_n
);

//========================================================================== //
//                                                                           //
// Wires                                                                     //
//                                                                           //
//========================================================================== //

logic                           in_vld_r;
logic [W - 1:0]                 in_x_r;
logic [$clog2(W) - 1:0]         in_pos_r;

logic [W - 1:0]                 uut_x_i;
logic [$clog2(W) - 1:0]         uut_pos_i;

logic                           uut_any_o;
logic [W - 1:0]                 uut_y_o;
logic [$clog2(W) - 1:0]         uut_y_enc_o;

logic                           out_vld_r;
logic                           out_any_r;
logic [$clog2(W) - 1:0]         out_pos_r;
logic [W - 1:0]                 out_x_r;
logic [W - 1:0]                 out_y_r;
logic [$clog2(W) - 1:0]         out_y_enc_r;

//========================================================================== //
//                                                                           //
// Clock                                                                     //
//                                                                           //
//========================================================================== //

// NOTES: Typically, I would inject the clock from the testbench, but for
// but in cocotb it seems like this is not supported when using Verilator
// When attempting to drive the clk from the testbench, a
// VPI related crash occurs. This is a known issue when using Verilator
// with cocotb.

logic clk = 0;

always #5 clk = ~clk;

//========================================================================== //
//                                                                           //
// UUT                                                                       //
//                                                                           //
//========================================================================== //

always_ff @(posedge clk or negedge arst_n) begin : vld_reg_PROC
  if (~arst_n)
    in_vld_r <= 1'b0;
  else
    in_vld_r <= vld_i;
end : vld_reg_PROC

always_ff @(posedge clk) begin : in_reg_PROC
  in_x_r <= x_i;
  in_pos_r <= pos_i;
end : in_reg_PROC

assign uut_x_i = in_x_r;
assign uut_pos_i = in_pos_r;

generate begin : uut_GEN
  if (P_UUT_NAME == "s") begin : s_GEN
  
    s #(.W(W)) u_uut (
    //
      .x_i                  (uut_x_i)
    , .pos_i                (uut_pos_i)
    //
    , .any_o                (uut_any_o)
    , .y_o                  (uut_y_o)
    , .y_enc_o              (uut_y_enc_o));

  end else begin : invalid_uut_name_GEN
    initial begin
      $error("Invalid UUT name: %s", P_UUT_NAME);
      $finish;
    end
  end

end : uut_GEN
endgenerate

always_ff @(posedge clk or negedge arst_n) begin : out_vld_reg_PROC
  if (~arst_n)
    out_vld_r <= 1'b0;
  else
    out_vld_r <= in_vld_r;
end : out_vld_reg_PROC

always_ff @(posedge clk or negedge arst_n) begin : out_any_reg_PROC
  if (~arst_n)
    out_any_r <= 1'b0;
  else
    out_any_r <= uut_any_o;
end : out_any_reg_PROC

always_ff @(posedge clk) begin : out_reg_PROC
  out_x_r <= uut_x_i;
  out_pos_r <= uut_pos_i;
  out_y_r <= uut_y_o;
  out_y_enc_r <= uut_y_enc_o;
end : out_reg_PROC

//========================================================================== //
//                                                                           //
// Output                                                                    //
//                                                                           //
//========================================================================== //

assign vld_o = out_vld_r;
assign x_o = out_x_r;
assign pos_o = out_pos_r;
assign any_o = out_any_r;
assign y_o = out_y_r;
assign y_enc_o = out_y_enc_r;

endmodule : tb
