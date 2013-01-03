require 'peglite'

class Mini < PegLite
  rule expression: "sum | integer"
  rule integer: /(\d+)/
  rule operator: /([+])/
  rule sum: "integer _ operator _ expression"
end

def parse str
  mini = Mini.new
  mini.parse str
rescue PegLite::PegexParseError => failure
  Mini.new(debug: true).parse str
end

p parse "1 + 2 + 3"     # => ["1", "+", ["2", "+", "3"]]
p parse "a + 2"         # => Print debug trace and error analysis

__END__
This is the PegLite version of the "Parselet expression parser" example from
here:

    http://kschiess.github.com/parslet/get-started.html

Here is the original:

  class Mini < Parslet::Parser
    rule(:integer)    { match('[0-9]').repeat(1) >> space? }

    rule(:space)      { match('\s').repeat(1) }
    rule(:space?)     { space.maybe }

    rule(:operator)   { match('[+]') >> space? }

    rule(:sum)        { integer >> operator >> expression }
    rule(:expression) { sum | integer }

    root :expression
  end

  def parse(str)
    mini = Mini.new

    mini.parse(str)
  rescue Parslet::ParseFailed => failure
    puts failure.cause.ascii_tree
  end

  parse "1 + 2 + 3"  # => "1 + 2 + 3"@0
  parse "a + 2"      # fails, see below
