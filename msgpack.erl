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

-module (msgpack).

-include("msgpack.hrl").

-export ([pack_nil/0,
          pack_bool/1,
          pack_int/1,
          pack_float/1,
          pack_raw/1,
          pack_array/1,
          pack_map/1,
          pack/1,
          unpackmsg/1]).

unpackmsg(<<Data/binary>>) ->
  {Result, _} = unpack(Data),
  Result.

pack(Obj) ->
  pack_object(Obj).


% ===========
% = Packing =
% ===========
pack_nil() ->
  <<?MP_NIL>>.

pack_bool(true) ->
  <<?MP_TRUE>>;
  
pack_bool(false) ->
  <<?MP_FALSE>>.



% =================
% = Pack integers =
% =================

% automatically choose the shortest encoding of an (un)singed integer

% integer within the range [0, 127] in 1 bytes
pack_int(N) when is_integer(N), N >= 0, N =< 16#F ->
  <<?MP_POS_FIXNUM, N:7>>;

% unsigned 8-bit integer in 2 bytes
pack_int(N) when is_integer(N), N >= 0, N =< 16#FF ->
  <<?MP_UINT8, N:8>>;

% unsigned 16-bit integer in 3 bytes
pack_int(N) when is_integer(N), N >= 0, N =< 16#FFFF ->
  <<?MP_UINT16, N:16>>;

% unsigned 32-bit integer in 5 bytes
pack_int(N) when is_integer(N), N >= 0, N =< 16#FFFFFFFF ->
  <<?MP_UINT32, N:32>>;

% unsigned 64-bit integer in 9 bytes
pack_int(N) when is_integer(N), N >= 0, N =< 16#FFFFFFFFFFFFFFFF ->
  <<?MP_UINT64, N:64>>;

% integer within the range [-32, -1] in 1 bytes
pack_int(N) when is_integer(N), N < 0, N >= -16#20 ->
  <<?MP_NEG_FIXNUM,N:5>>;

% signed 8-bit integer in 2 bytes
pack_int(N) when is_integer(N), N < -16#20, N >= -16#FF ->
  <<?MP_INT8, N:8>>;

% signed 16-bit big-endian integer in 3 bytes
pack_int(N) when is_integer(N), N < -16#FF, N >= -16#FFFF ->
  <<?MP_INT16, N:16>>;

% signed 32-bit big-endian integer in 5 bytes
pack_int(N) when is_integer(N), N < -16#FFFF, N >= -16#FFFFFFFF ->
  <<?MP_INT32, N:32>>;  

% signed 64-bit big-endian integer in 9 bytes             
pack_int(N) when is_integer(N), N < -16#FFFFFFFF, N > -16#FFFFFFFFFFFFFF ->
  <<?MP_INT64, N:64>>.  



% ================
% = Float/Double =
% ================

% floats in erlang are always 64bit!

pack_float(F) when is_float(F) ->
  <<?MP_DOUBLE, F:64/big-float-unit:1 >>.



% =============
% = Raw Bytes =
% =============
pack_raw(Bin) when is_binary(Bin) ->
  MaxLen = round(math:pow(2, 16)),
  case byte_size(Bin) of
	  Len when Len < 6 -> <<?MP_FIXRAW:3, Len:5, Bin/binary >>;
	  Len when Len < MaxLen -> <<?MP_RAW16, Len:16, Bin/binary >>;
	  Len -> <<?MP_RAW32, Len:32, Bin/binary >>
  end.



% ==========
% = Arrays =
% ==========
pack_array(A) when is_list(A) ->
  case length(A) of
    Len when Len < 16 ->      <<?MP_FIXARRAY:4, Len:4,  (pack_array_(A))/binary>>;
    Len when Len =< 65535 ->  <<?MP_ARRAY16,    Len:16, (pack_array_(A))/binary>>;
    Len ->                    <<?MP_ARRAY32,    Len:32, (pack_array_(A))/binary>>
  end.

pack_array_([]) -> <<>>;
pack_array_([H|T]) -> <<(pack_object(H))/binary, (pack_array_(T))/binary >>.



% =====================
% = Dictionaries/Maps =
% =====================
pack_map(M) ->
  case dict:size(M) of
    Len when Len < 16 ->      <<?MP_FIXMAP:4, Len:4,  (pack_map_(dict:to_list(M)))/binary>>;
    Len when Len =< 65535 ->  <<?MP_MAP16,    Len:16, (pack_map_(dict:to_list(M)))/binary>>;
    Len ->                    <<?MP_MAP32,    Len:32, (pack_map_(dict:to_list(M)))/binary>>
  end.

pack_map_([]) -> <<>>;
pack_map_([{Key,Value}|T]) -> <<(pack_object(Key))/binary, (pack_object(Value))/binary, (pack_map_(T))/binary >>.
  


% ===============================
% = Pack Object with autodetect =
% ===============================
pack_object(N) when is_integer(N)->
    pack_int(N);
pack_object(F) when is_float(F)->
    pack_float(F);
pack_object(nil) ->
    pack_nil();
pack_object(Bool) when is_atom(Bool) ->
    pack_bool(Bool);
pack_object(Bin) when is_binary(Bin)->
    pack_raw(Bin);
pack_object(List) when is_list(List)->
    pack_array(List);
% pack_object({dict, Map})->
%     pack_map({dict, Map});
pack_object(_) ->
    undefined.









% =================
% =   Unpacking   =
% =================

% nil
unpack(<<?MP_NIL>>) ->
  {nil, <<>>};

% true
unpack(<<?MP_TRUE>>) ->
  {true, <<>>};

% false
unpack(<<?MP_FALSE>>) ->
  {false, <<>>};


% =============
% = Raw bytes =
% =============

% fix raw
unpack(<<?MP_FIXRAW, ByteLength:5, Data/binary>>) ->
  unpack_binary(ByteLength, Data);

% raw 16
unpack(<<?MP_RAW16, ByteLength:16, Data/binary>>) ->
  unpack_binary(ByteLength, Data);

% raw 32
unpack(<<?MP_RAW32, ByteLength:32, Data/binary>>) ->
  unpack_binary(ByteLength, Data);
  
 

% ============
% = Integers =
% ============
unpack(<<?MP_POS_FIXNUM, Data:7, Rest/binary>>) ->
  {Data, Rest};
  
unpack(<<?MP_NEG_FIXNUM, Data:5, Rest/binary>>) ->
% todo: this looks ugly!
  {Data-32, Rest};

% uint 8  
unpack(<<?MP_UINT8, Data:8, Rest/binary>>) ->
  {Data, Rest};
  
% uint 16
unpack(<<?MP_UINT16, Data:16, Rest/binary>>) ->
  {Data, Rest};

% uint 32
unpack(<<?MP_UINT32, Data:32, Rest/binary>>) ->
  {Data, Rest};
  
% uint 64
unpack(<<?MP_UINT64, Data:64, Rest/binary>>) ->
  {Data, Rest};

unpack(<<>>) ->
  {<<>>,<<>>};


% ==========
% = Floats =
% ==========

unpack(<<?MP_FLOAT:8, Data:32/float-unit:1, Rest/binary >>) ->
  {Data, Rest};

unpack(<<?MP_DOUBLE:8, Data:64/float-unit:1, Rest/binary >>) ->
  {Data, Rest};


% ==========
% = Arrays =
% ==========

% fix array
unpack(<<?MP_FIXARRAY, Length:4, Data/binary>>) ->
  unpack_array(Length, [], Data);

% array 16
unpack(<<?MP_ARRAY16, Length:16, Data/binary>>) ->
  unpack_array(Length, [], Data);

% array 32
unpack(<<?MP_ARRAY32, Length:32, Data/binary>>) ->
  unpack_array(Length, [], Data);


% ========
% = Maps =
% ========

% fix map
unpack(<<?MP_FIXMAP, Length:4, Data/binary>>) ->
  unpack_map(Length, [], Data);

% map 16
unpack(<<?MP_MAP16, Length:4, Data/binary>>) ->
  unpack_map(Length, [], Data);

% map 32
unpack(<<?MP_MAP32, Length:4, Data/binary>>) ->
  unpack_map(Length, [], Data).


% ==========
% = Helper =
% ==========
unpack_array(0, A, RestData) -> {lists:reverse(A), RestData};
unpack_array(Length, A, Data) when Length > 0 ->
  {UnpackedData, RestData} = unpack(Data),
  unpack_array(Length-1, [UnpackedData|A], RestData).


unpack_map(0, M, RestData) -> {M, RestData};
unpack_map(RestLength, M, Data) when is_binary(Data), is_integer(RestLength), RestLength > 0 ->
  {UnpackedKey, RestData} = unpack(Data),
  {UnpackedValue, RestData2} = unpack(RestData),
  unpack_map(RestLength-1, [{UnpackedKey, UnpackedValue}|M], RestData2).

  

unpack_binary(ByteLength, Data)->
  <<RawBytes:ByteLength/binary, Rest/binary>> = Data,
  {RawBytes, Rest}.
