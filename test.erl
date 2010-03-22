#!/usr/bin/env escript

main(_) ->
  compile:file(msgpack),
  compile:file(test_msgpack),
  eunit:test({inparallel, test_msgpack}).
