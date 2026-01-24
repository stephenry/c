## ========================================================================= ##
## Copyright (c) 2026, Stephen Henry
## All rights reserved.
##
## Redistribution and use in source and binary forms, with or without
## modification, are permitted provided that the following conditions are met:
##
## * Redistributions of source code must retain the above copyright notice, this
##   list of conditions and the following disclaimer.
##
## * Redistributions in binary form must reproduce the above copyright notice,
##   this list of conditions and the following disclaimer in the documentation
##   and/or other materials provided with the distribution.
##
## THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
## AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
## IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
## ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
## LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
## CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
## SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
## INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
## CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
## ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
## POSSIBILITY OF SUCH DAMAGE.
## ========================================================================= ##

_TOP_SV = """\
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

module {{module_name}} (

  input wire logic [{{W}} - 1:0]                 x_i
, input wire logic [$clog2({{W}}) - 1:0]         pos_i

//
, output wire logic                              any_o
, output wire logic [{{W}} - 1:0]                y_o
, output wire logic [$clog2({{W}}) - 1:0]        y_enc_o

//
, input wire logic                               clk
);

//========================================================================== //
//                                                                           //
// Wires                                                                     //
//                                                                           //
//========================================================================== //

logic [{{W}} - 1:0]             in_x_r;
logic [$clog2({{W}}) - 1:0]     in_pos_r;

logic                           uut_any_o;
logic [{{W}} - 1:0]             uut_y_o;
logic [$clog2({{W}}) - 1:0]     uut_y_enc_o;

logic                           out_any_r;
logic [{{W}} - 1:0]             out_y_r;
logic [$clog2({{W}}) - 1:0]     out_y_enc_r;

//========================================================================== //
//                                                                           //
// UUT                                                                       //
//                                                                           //
//========================================================================== //

// Input flops
//
always_ff @(posedge clk) begin : in_reg_PROC
  in_x_r <= x_i;
  in_pos_r <= pos_i;
end : in_reg_PROC

// Top-Level
//
{{uut}} {{uut_parameters}} u_uut (
  //
  .x_i                  (in_x_r)
, .pos_i                (in_pos_r)
//
, .any_o                (uut_any_o)
, .y_o                  (uut_y_o)
, .y_enc_o              (uut_y_enc_o)
);

// Output flops
//
always_ff @(posedge clk) begin : out_reg_PROC
  out_any_r <= uut_any_o;
  out_y_r <= uut_y_o;
  out_y_enc_r <= uut_y_enc_o;
end : out_reg_PROC

//========================================================================== //
//                                                                           //
// Output                                                                    //
//                                                                           //
//========================================================================== //

assign any_o = out_any_r;
assign y_o = out_y_r;
assign y_enc_o = out_y_enc_r;

endmodule : {{module_name}}
"""

import pathlib
import jinja2

_TOP_MODULE = "top"


def render_top(
    out_dir: pathlib.Path, uut: str, params: None | list = None
) -> tuple[pathlib.Path, str]:

    out_dir.mkdir(parents=True, exist_ok=True)

    def _extract_param(name: str) -> str:
        for param in params:
            if param[0] == name:
                return str(param[1])
        return None

    W = _extract_param("W")
    if W is None:
        raise ValueError("Parameter W must be specified for top-level generation.")

    if params is not None:
        pl = ", ".join(f".{param[0]}({param[1]})" for param in params)
        uut_parameters = f"#({pl})"
    else:
        uut_parameters = ""

    template = jinja2.Template(_TOP_SV)

    top_filename = f"{_TOP_MODULE}.sv"
    out_path = out_dir / top_filename

    with open(out_path, "w") as f:
        f.write(
            template.render(
                module_name=_TOP_MODULE, 
                uut=uut,
                uut_parameters=uut_parameters,
                W=W,
            )
        )

    return out_path.resolve(), _TOP_MODULE
