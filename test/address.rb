# This PegLite test shows an address grammar parsing an street address.
# We parse it 3 different ways, to get different desired results.


require 'test/unit'
require 'peglite'

# A sample street address
$address = <<'...'
John Doe
123 Main St
Los Angeles, CA 90009
...

# Expected result tree for default/plain parsing
$parse_plain = <<'...'
---
- John Doe
- 123 Main St
- - Los Angeles
  - CA
  - '90009'
...

# Expected result tree using the 'wrap' option
$parse_wrap = <<'...'
---
address:
- - name:
    - John Doe
  - street:
    - 123 Main St
  - place:
    - - city:
        - Los Angeles
      - state:
        - CA
      - zip:
        - '90009'
...

# Expected result tree from our Custom parser extension
$parse_custom = <<'...'
---
name: John Doe
street: 123 Main St
city: Los Angeles
state: CA
zipcode: '90008'
...

# Run 3 tests
class Test::Unit::TestCase
  # Parse address to an array of arrays
  def test_plain
    parser = AddressParser.new
    result = parser.parse $address
    assert_equal YAML.dump(result), $parse_plain, "Plain parse works"
  end
  # Turn on 'wrap' to add rule name to each result
  def test_wrap
    parser = AddressParser.new wrap: true
    result = parser.parse $address
    assert_equal YAML.dump(result), $parse_wrap, "Wrapping parse works"
  end
  # Return a custom AST
  def test_custom
    parser = AddressParserCustom.new
    result = parser.parse $address
    assert_equal YAML.dump(result), $parse_custom, "Custom parse works"
  end
end

# This class defines a complete address parser using PegLite
class AddressParser < PegLite
  rule address: "name street place"
  rule name: /(.*?)\n/
  rule street: /(.*?)\n/
  rule place: "city COMMA _ state __ zip NL"
  rule city: /(\w+(?: \w+)?)/
  rule state: /(WA|OR|CA)/ # Left Coast Rulez
  rule zip: /(\d{5})/
end

# Extend AddressParser
class AddressParserCustom < AddressParser
  def address
    name, street, place = match.first
    city, state, zip = place
    # Make the final AST from the parts collected.
    @got = {
      'name' => name,
      'street' => street,
      'city' => city,
      'state' => state,
      # Show as 'zipcode' instead of 'zip'
      'zipcode' => zip,
    }
  end

  # Subtract 1 from the zipcode for fun
  def zip
    (match.first.to_i - 1).to_s
  end
end
