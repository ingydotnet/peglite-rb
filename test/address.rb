require 'test/unit'
require 'peglite'

$address1 = <<'...'
John Doe
123 Main St
Los Angeles, CA 90009
...

$parse_plain = <<'...'
---
- John Doe
- 123 Main St
- - Los Angeles
  - CA
  - '90009'
...

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

class Test::Unit::TestCase
  def test_plain
    parser = AddressParser.new
    result = parser.parse $address1
    assert_equal YAML.dump(result), $parse_plain, "Plain parse works"
  end
  def test_wrap
    parser = AddressParser.new wrap: true
    result = parser.parse $address1
    assert_equal YAML.dump(result), $parse_wrap, "Wrapping parse works"
  end
end

class AddressParser < PegLite
  rule address: "name street place"
  rule name: (/\A(.*?)\n/)
  rule street: (/\A(.*?)\n/)
  rule place: "city COMMA _ state __ zip NL"
  rule city: (/\A(\w+(?: \w+)?)/)
  rule state: (/\A(WA|OR|CA)/)  # Left Coast Rulez
  rule zip: (/\A(\d{5})/)
end
