require 'peglite/compiler'

require 'yaml'; def XXX *args; args.each \
  {|a|puts YAML.dump a};puts caller.first; exit; end
require 'yaml'; def YYY *args; args.each \
  {|a|puts YAML.dump a};puts caller.first;return args[0]; end

#------------------------------------------------------------------------------
class PegLite
  VERSION = '0.0.2'

  $PegLiteRules = {}         # TODO get rid of global variable smell
  def self.rule args
    name, rule = args.first
    name = name.to_s
    $PegLiteTopRule ||= name
    if rule.kind_of? Regexp
      regex = Regexp.new(rule.to_s.sub(/:/, ':\\A'))
      $PegLiteRules[name] = {
        'type' => 'rgx',
        'rule' => regex,
        'min' => 1,
        'max' => 1,
      }
    elsif rule.kind_of? String
      $PegLiteRules[name] = PegLite::Compiler.new(rule).compile
    else
      fail "Don't know how to make rule '#{name}' from '#{rule}'"
    end
  end

  # TODO define all the Pegex Atoms here
  rule _: (/\s*/)
  rule __: (/\s+/)
  rule EQUAL: (/=/)
  rule COMMA: (/,/)
  rule PLUS: (/\+/)
  rule NL: (/\n/)
  rule EOL: (/\r?\n/)
  $PegLiteTopRule = nil

  attr_accessor :got
  attr_accessor :wrap
  attr_accessor :debug
  attr_accessor :input
  def initialize attrs={}
    @got = nil
    @wrap = false
    @debug = false
    @input = nil

    attrs.each { |k,v| self.send "#{k}=", v }

    @pos = 0
    @far = 0
    @rules = $PegLiteRules
    yield self if block_given?
  end

  def parse input=@input, top=($PegLiteTopRule || 'top')
    fail "PegLite parse() method requires an input string" \
      unless input.kind_of? String
    @input = input
    got = match_ref top
    failure if @pos < @input.length
    return @got || got[0]
  end

  def match rule=nil
    if not rule.kind_of? Hash
      rule ||= caller.first.scan(/(\w+)/).last.first
      rule_name = rule
      if rule.kind_of? String
        rule = @rules[rule]
      end
      fail "Can't find rule for '#{rule_name}'" \
        if not(rule and rule.kind_of? Hash)
    end

    pos, count, matched, type, child, min, max =
      @pos, 0, [], *(rule.values_at *%w(type rule min max))

    while (result = self.method("match_#{type}").call(child))
      pos = @pos
      count += 1
      if result.kind_of? Array
        matched.concat result
      else
        matched << result
      end
      break if max == 1
    end

    if count >= min and (max == 0 or count <= max)
      return matched
    else
      @pos = pos
      return
    end
  end

  def match_all all
    pos, set, count = @pos, [], 0
    all.each do |elem|
      if (m = match elem)
        set.concat m
        count += 1
      else
        if (@pos = pos) > @far
          @far = pos
        end
        return
      end
    end
    set = [ set ] if count > 1
    return set
  end

  def match_any any
    any.each do |elem|
      if (m = match elem)
        return m
      end
    end
    return
  end

  # TODO move trace/debug out of default match_ref method
  def match_ref ref
    trace "Try #{ref}" if @debug
    begin
      m = self.method(ref).call
    rescue NameError => e
      if @rules[ref]
        m = match @rules[ref]
      else
        fail "No rule defined for '#{ref}'"
      end
    end
    if m
      m = (@wrap and not m.empty?) ? [{ref => m}] : m
      trace "Got #{ref}" if @debug
    else
      trace "Not #{ref}" if @debug
    end
    return m
  end

  def match_rgx regex
    m = @input[@pos..-1].match(regex)
    return unless m
    @pos += m[0].length
    match = m.captures
    # XXX not sure about this:
    match = [ match ] if m.length > 2
    @far = @pos if @pos > @far
    return match
  end

  #----------------------------------------------------------------------------
  # Debugging and error reporting support methods
  #----------------------------------------------------------------------------
  def trace action
    indent = !!action.match(/^Try /)
    @indent ||= 0
    @indent -= 1 unless indent
    $stderr.print ' ' * @indent
    @indent += 1 if indent
    snippet = @input[@pos..-1]
    snippet = snippet[0..30] + '...' if snippet.length > 30;
    snippet.gsub! /\n/, "\\n"
    $stderr.printf "%-30s", action
    $stderr.print indent ? " >#{snippet}<\n" : "\n"
  end

  def failure
    msg = "Parse failed for some reason"
    raise PegexParseError, format_error(msg)
  end

  class PegexParseError < RuntimeError;end
  def format_error msg
    buffer = @input
    position = @far
    real_pos = @pos

    line = buffer[0, position].scan(/\n/).size + 1
    column = position - (buffer.rindex("\n", position) || -1)

    pretext = @input[
      position < 50 ? 0 : position - 50,
      position < 50 ? position : 50
    ]
    context = @input[position, 50]
    pretext.gsub! /.*\n/m, ''
    context.gsub! /\n/, "\\n"

    return <<"..."
Error parsing Pegex document:
  message:  #{msg}
  line:     #{line}
  column:   #{column}
  position: #{position}
  context:  #{pretext}#{context}
  #{' ' * (pretext.length + 10)}^
...
  end
end
