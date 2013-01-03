require 'peglite'

class Mini < PegLite
  rule integer: (/(\d+)/)
end

p Mini.new.parse "132432"   # => "132432"

__END__
This is the PegLite version of the "simplest Parselet" example from here:

    http://kschiess.github.com/parslet/get-started.html

Here is the original:

    require 'parslet'

    class Mini < Parslet::Parser
      rule(:integer) { match('[0-9]').repeat(1) }
      root(:integer)
    end

    Mini.new.parse("132432")  # => "132432"@0
