require 'peglite'

class MyJson < PegLite
  rule json: "object | array"
  rule node: "object | array | value"
  rule object: "_ LCURLY _ ( pair ( _ COMMA _ pair )* )? _ RCURLY _"
  rule pair: "string _ COLON _ node"
  rule array: "_ LSQUARE _ ( node ( _ COMMA _ node)* )? _ RSQUARE _"
  rule value: "string | number | boolean | null"
  rule string: (/"((?:\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})|[^"\x00-\x1f])*)"/)
  rule number: (/(\-?(?:0|[1-9][0-9]*)(?:\.[0-9]*)?(?:[eE][\-\+]?[0-9]+)?)/)
  rule boolean: "true | false"
  rule true: /(true)/
  rule false: /(false)/
  rule null: /(null)/

  # TODO Parse findings are correct but need methods to reshape them
end

# Test from Parslet's json.rb
# https://github.com/kschiess/parslet/blob/master/example/json.rb
s = %{
  [ 1, 2, 3, null,
    "asdfasdf asdfds", { "a": -1.2 }, { "b": true, "c": false },
    0.1e24, true, false, [ 1 ] ]
}

out = XXX MyJson.new(debug: false).parse(s)

p out; puts

out == [
  1, 2, 3, nil,
  "asdfasdf asdfds", { "a" => -1.2 }, { "b" => true, "c" => false },
  0.1e24, true, false, [ 1 ]
] || raise("MyJson is a failure")
