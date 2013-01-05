class PegLite;end

#------------------------------------------------------------------------------
class PegLite::Compiler
  def initialize peglite_rule
    tokenize peglite_rule
  end

  def compile
    fail if @tokens.empty?
    if @tokens[0] == '('
      @tokens.shift
      got = compile
      fail if (@tokens.empty? or not @tokens.shift.match /^\)([\?\*\+]?)/)
      got.merge! compile_limits $1
    elsif @tokens.size > 1
      if @tokens[1] == '|'
        got = compile_any
      else
        got = compile_all
      end
    else
      fail @tokens.to_s
    end
    return got
  end

  def compile_all
    fail if @tokens.empty?
    all = []
    until @tokens.empty?
      if @tokens[0] == '('
        all.push compile
      elsif @tokens[0].match /^\)/
        break
      elsif @tokens[0].match /^\w/
        all.push compile_ref
      else
        fail
      end
    end
    return {
      'type' => 'all',
      'rule' => all,
      'min' => 1,
      'max' => 1,
    }
  end

  def compile_any
    fail if @tokens.empty?
    any = []
    until @tokens.empty?
      if @tokens[0] == '('
        any.push compile
      elsif @tokens[0].match /^\)/
        break
      elsif @tokens[0].match /^\w/
        any.push compile_ref
        if not @tokens.empty?
          if @tokens[0] == '|'
            @tokens.shift
          elsif not @tokens[0].match /^\)/
            fail
          end
        end
      else
        fail
      end
    end
    return {
      'type' => 'any',
      'rule' => any,
      'min' => 1,
      'max' => 1,
    }
  end

  def compile_ref
    fail if @tokens.empty?
    token = @tokens.shift
    token.match(/^(\w+)([\?\*\+]?)$/) or fail
    rule, quantifier = $1, $2
    ref = {
      'type' => 'ref',
      'rule' => rule,
    }
    return ref.merge! compile_limits(quantifier)
  end

  def compile_limits quantifier
    case quantifier
    when '?'; { 'min' => 0, 'max' => 1 }
    when '*'; { 'min' => 0, 'max' => 0 }
    when '+'; { 'min' => 1, 'max' => 0 }
    else; { 'min' => 1, 'max' => 1 }
    end
  end

  def tokenize text
    input = text.clone
    @tokens = []
    while (token = get_token input)
      @tokens.concat token
    end
  end

  PATTERNS = [
    /\A\s+/,
    /\A(\()/,
    /\A(\w+[\?\*\+]?)/,
    /\A(\|)/,
    /\A(\)[\?\*\+]?)/,
  ]
  def get_token input
    return if input.empty?
    PATTERNS.each do |r|
      if m = input.match(r)
        input.sub! r, ''
        return m.captures
      end
    end
    fail "Failed to find next token in '#{input}'"
  end
end
