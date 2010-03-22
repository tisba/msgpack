% Copyright (c) 2010 Sebastian Cohnen
%  
% Permission is hereby granted, free of charge, to any person obtaining
% a copy of this software and associated documentation files (the
% "Software"), to deal in the Software without restriction, including
% without limitation the rights to use, copy, modify, merge, publish,
% distribute, sublicense, and/or sell copies of the Software, and to
% permit persons to whom the Software is furnished to do so, subject to
% the following conditions:
%  
% The above copyright notice and this permission notice shall be
% included in all copies or substantial portions of the Software.
%  
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
% EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
% MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
% NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
% LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
% OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
% WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

% ============
% = PREFIXES =
% ============
-define (MP_POS_FIXNUM, 2#0:1).
-define (MP_NEG_FIXNUM, 2#111:3).

-define (MP_UINT8,      16#cc:8).
-define (MP_UINT16,     16#cd:8).
-define (MP_UINT32,     16#ce:8).
-define (MP_UINT64,     16#cf:8).
                        
-define (MP_INT8,       16#d0).
-define (MP_INT16,      16#d1).
-define (MP_INT32,      16#d2).
-define (MP_INT64,      16#d3).
                        
-define (MP_NIL,        16#c0).
-define (MP_TRUE,       16#c3).
-define (MP_FALSE,      16#c2).
                        
-define (MP_FLOAT,      16#ca).
-define (MP_DOUBLE,     16#cb).
                        
-define (MP_FIXRAW,     2#101).
-define (MP_RAW16,      16#da).
-define (MP_RAW32,      16#db).

-define (MP_FIXARRAY,   2#1001).
-define (MP_ARRAY16,    16#dc).
-define (MP_ARRAY32,    16#dd).

-define (MP_FIXMAP,     2#1000).
-define (MP_MAP16,      16#de).
-define (MP_MAP32,      16#df).
