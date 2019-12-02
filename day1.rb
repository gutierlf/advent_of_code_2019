require 'rspec'

# For a mass of 12, divide by 3 and round down to get 4, then subtract 2 to get 2.
# For a mass of 14, dividing by 3 and rounding down still yields 4, so the fuel required is also 2.
# For a mass of 1969, the fuel required is 654.
# For a mass of 100756, the fuel required is 33583.

def fuel_requirement(mass)
  # to find the fuel required for a module,
  # take its mass, divide by three, round down, and subtract 2
  [(mass / 3).round - 2, 0].max
end

RSpec.describe "day 1" do
  describe "fuel_requirement" do
    it "calculates" do
      expect(fuel_requirement(12)).to eq 2
      expect(fuel_requirement(14)).to eq 2
      expect(fuel_requirement(1969)).to eq 654
      expect(fuel_requirement(100756)).to eq 33583
    end
  end
end

answer1 = File.readlines('day1_input.txt').map do |mass|
  fuel_requirement(mass.to_i)
end.reduce(:+)
puts answer1 # => 3147032

# A module of mass 14 requires 2 fuel.
# This fuel requires no further fuel (2 divided by 3 and rounded down is 0,
# which would call for a negative fuel), so the total fuel required is still
# just 2.
# At first, a module of mass 1969 requires 654 fuel. Then, this fuel
# requires 216 more fuel (654 / 3 - 2). 216 then requires 70 more fuel,
# which requires 21 fuel, which requires 5 fuel, which requires no further
# fuel. So, the total fuel required for a module of mass 1969 is
# 654 + 216 + 70 + 21 + 5 = 966.
# The fuel required by a module of mass 100756 and its fuel is:
# 33583 + 11192 + 3728 + 1240 + 411 + 135 + 43 + 12 + 2 = 50346.

def fuel_requirement2(mass)
  # for each module mass, calculate its fuel and add it to the total.
  # Then, treat the fuel amount you just calculated as the input mass and repeat
  # the process, continuing until a fuel requirement is zero or negative
  total = fuel_mass = fuel_requirement(mass)
  while fuel_mass > 0
    fuel_mass = fuel_requirement(fuel_mass)
    total += fuel_mass
  end
  total
end

RSpec.describe "day 1" do
  describe "fuel_requirement2" do
    it "calculates" do
      expect(fuel_requirement2(14)).to eq 2
      expect(fuel_requirement2(1969)).to eq 966
      expect(fuel_requirement2(100756)).to eq 50346
    end
  end
end

answer2 = File.readlines('day1_input.txt').map do |mass|
  fuel_requirement2(mass.to_i.to_i)
end.reduce(:+)
puts answer2
