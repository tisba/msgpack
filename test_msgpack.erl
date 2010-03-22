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

-module (test_msgpack).

-include_lib("eunit/include/eunit.hrl").
-include("msgpack.hrl").

pack_basics_test_() ->
  [
    ?_assertEqual(<<?MP_NIL>>,   msgpack:pack_nil()),
    ?_assertEqual(<<?MP_TRUE>>,  msgpack:pack_bool(true)),
    ?_assertEqual(<<?MP_FALSE>>, msgpack:pack_bool(false))   
  ].

auto_pack_integers_test_() ->
  [
    % test 7 to 64 bit unsigned integer encoding
    ?_assertEqual(<<?MP_POS_FIXNUM, 0:7>>,                    msgpack:pack_int(0)),
    ?_assertEqual(<<?MP_UINT8,      16#FF:8>>,                msgpack:pack_int(16#FF)),
    ?_assertEqual(<<?MP_UINT16,     16#FFFF:16>>,             msgpack:pack_int(16#FFFF)),
    ?_assertEqual(<<?MP_UINT32,     16#FFFFFFFF:32>>,         msgpack:pack_int(16#FFFFFFFF)),
    ?_assertEqual(<<?MP_UINT64,     16#FFFFFFFFFFFFFFFF:64>>, msgpack:pack_int(16#FFFFFFFFFFFFFFFF)),
    
    % test guards
    ?_assertException(error, function_clause, msgpack:pack_int([])), % muh!
    ?_assertException(error, function_clause, msgpack:pack_int(0.1)), % muh!
    ?_assertException(error, function_clause, msgpack:pack_int(-16#FFFFFFFFFFFFFF-1)), % too small!
    ?_assertException(error, function_clause, msgpack:pack_int(16#FFFFFFFFFFFFFFFF+1)) % too big!
  ].

unpack_integers_test_() ->
  [
    % integer within the range [0, 127] in 1 bytes
    ?_assertEqual(0,    msgpack:unpackmsg(<<?MP_POS_FIXNUM, 2#0000000:7>>)),
    ?_assertEqual(1,    msgpack:unpackmsg(<<?MP_POS_FIXNUM, 2#0000001:7>>)),
    ?_assertEqual(127,  msgpack:unpackmsg(<<?MP_POS_FIXNUM, 2#1111111:7>>)),
    
    % integer within the range [-32, -1] in 1 bytes
    ?_assertEqual(-1,   msgpack:unpackmsg(<<?MP_NEG_FIXNUM, 2#11111:5>>)),
    ?_assertEqual(-32,  msgpack:unpackmsg(<<?MP_NEG_FIXNUM, 0:5>>)),
    ?_assertEqual(-16,  msgpack:unpackmsg(<<?MP_NEG_FIXNUM, 2#10000:5>>)),
    
    % unsigned 8-bit integer in 2 bytes
    ?_assertEqual(msgpack:unpackmsg(<<?MP_UINT8, 0>>), 0), % min
    ?_assertEqual(msgpack:unpackmsg(<<?MP_UINT8, 1>>), 1),
    ?_assertEqual(msgpack:unpackmsg(<<?MP_UINT8, 255>>), 255) %max
  ].

pack_floats_test_() ->
  [
    ?_assertEqual(0.1, msgpack:unpackmsg(<<?MP_DOUBLE, 0.1/float>>)),
    ?_assertEqual(0.123, msgpack:unpackmsg(<<?MP_DOUBLE, 0.123/float>>)),

    ?_assertException(error, function_clause, msgpack:pack_float(123)) % not a float!
  ].

auto_pack_raw_bytes_test_() ->
  [
    ?_assertEqual(<<?MP_FIXRAW:3, 0:5>>, msgpack:pack_raw(<<>>)), % pack 0 bytes
    ?_assertEqual(<<?MP_FIXRAW:3, 5:5, "abcde">>, msgpack:pack_raw(<<"abcde">>)), % pack 5 bytes
    ?_assertEqual(<<?MP_RAW16, 32:16, "abcdefghabcdefghabcdefghabcdefgh">>, msgpack:pack_raw(<<"abcdefghabcdefghabcdefghabcdefgh">>)), % pack 32 bytes
    % ?_assertEqual(<<?MP_RAW32, >>, msgpack:pack_raw(<<>>)),
    % todo: how to build large binary?
    
    % check the guards!
    ?_assertException(error, function_clause, msgpack:pack_raw([])), % not binary!
    ?_assertException(error, function_clause, msgpack:pack_raw(123)) % not binary!
    % TODO: need to check, if binary is too large!
  ].
  
pack_arrays_test_() ->
  [
    % fix array (up to 15 elements)
    ?_assertEqual(<<?MP_FIXARRAY:4, 3:4, 1,1,1>>, msgpack:pack_array([1,1,1])),
    ?_assertEqual(<<?MP_FIXARRAY:4, 15:4,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14>>, msgpack:pack_array(lists:seq(0,14))), % array with 15 elements

    % array 16
    ?_assertEqual(<<?MP_ARRAY16,0,16,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15>>, msgpack:pack_array(lists:seq(0,15))), % array with 16 elements
    ?_assertEqual(<<?MP_FIXARRAY:4, 5:4,
                      1,2,?MP_FIXARRAY:4,2:4,
                            ?MP_FIXRAW:3,3:5, "abc",
                            ?MP_FIXRAW:3,2:5, "de",
                      4,5>>,
                  msgpack:pack_array([1,2,[<<"abc">>,<<"de">>],4,5])),
    
    ?_assertException(error, function_clause, msgpack:pack_array(1)) % not a list!
  ].
