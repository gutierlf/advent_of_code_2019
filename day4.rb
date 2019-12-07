require "rspec"

def valid?(password)
  two_adjacent_same?(password) && never_decreases?(password)
end

def valid2?(password)
  only_two_adjacent_same?(password) && never_decreases?(password)
end

def only_two_adjacent_same?(password)
  match = two_adjacent_same_match(password)
  return false if match.nil?
  if more_than_two_adjacent_same?(password, match[0][0])
    only_two_adjacent_same?(password.gsub(match[0], ""))
  else
    true
  end
end

def two_adjacent_same?(password)
  !!two_adjacent_same_match(password)
end

def two_adjacent_same_match(password)
  two_adjacent_same = /00|11|22|33|44|55|66|77|88|99/
  two_adjacent_same.match(password)
end

def more_than_two_adjacent_same?(password, digit)
  more_than_two_adjacent_same = /#{digit}{3,}/
  !!more_than_two_adjacent_same.match(password)
end

def never_decreases?(password)
  never_decrease = /0[0-9]|1[1-9]|2[2-9]|3[3-9]|4[4-9]|5[5-9]|6[6-9]|7[7-9]|8[8-9]|9[9-9]/
  result = true
  password.chars.each_cons(2) do |pair|
    result = false unless !!pair.join("").match(never_decrease)
  end
  result
end

RSpec.describe "day 4" do
  describe "step 1" do
    it "examples" do
      expect(valid?("111111")).to eq true
      expect(valid?("223450")).to eq false
      expect(valid?("123789")).to eq false
    end
  end
  describe "step 2" do
    it "examples" do
      expect(valid2?("112233")).to eq true
      expect(valid2?("123444")).to eq false
      expect(valid2?("111122")).to eq true
    end
  end
end

if __FILE__ == $0
  input = "382345-843167"
  from, to = /(\d{6})-(\d{6})/.match(input).captures
  answer1 = from.upto(to).to_a.select { |password| valid?(password) }.length
  puts answer1

  answer2 = from.upto(to).to_a.select { |password| valid2?(password) }.length
  puts answer2
end
