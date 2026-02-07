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

`ifndef RTL_ASSERTS_SVH
`define RTL_ASSERTS_SVH

`ifndef SYNTHESIS

`define C_STATIC_ASSERT(__cond, __msg)\
    initial if (!(__cond)) $error("[%m] C_STATIC_ASSERT: %s", __msg)

`define C_ASSERT(__cond, __clk, __arst_n, __msg)\
    /* verilator lint_off SYNCASYNCNET */\
    assert property (@(posedge __clk) disable iff (! __arst_n) __cond)\
      else $error("[%m] C_ASSERT: %s", __msg)\
    /* verilator lint_on SYNCASYNCNET */

`else

// NOP-out assertions on synthesis flow.
`define C_STATIC_ASSERT(__cond, __msg)
`define C_ASSERT(__cond, __clk, __arst_n, __msg)

`endif


`else
`undef RTL_ASSERTS_SVH

`undef C_STATIC_ASSERT
`undef C_ASSERT

`endif // RTL_ASSERTS_SVH
