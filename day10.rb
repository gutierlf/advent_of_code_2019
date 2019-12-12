require "set"

def monitoring_station_location_for(map)
  asteroid_pairs = asteroids(map).permutation(2).to_a
  asteroid_to_directions = asteroid_pairs.reduce({}) do |acc, (from, to)|
    acc[from] = acc.fetch(from, Set.new) << Vector.new(from, to).normalized
    acc
  end
  asteroid_to_directions
    .map { |asteroid, directions| [asteroid, directions.length] }
    .max { |a, b| a[1] <=> b[1] }
end

def asteroids(map)
  result = []
  map.split("\n").each.with_index do |line, row|
    line.split("").each.with_index do |char, col|
      if char == "#"
        result << Point.new(col, row)
      end
    end
  end
  result
end

Point = Struct.new(:col, :row)

Vector = Struct.new(:from, :to) do
  def u
    to_minus_from(:col)
  end

  def v
    to_minus_from(:row)
  end

  def normalized
    NormalizedVector.for(self)
  end

  private

  def to_minus_from(component)
    [to, from].map(&component).reduce(:-)
  end
end

NormalizedVector = Struct.new(:i, :j) do
  def self.for(vec)
    mag_squared = vec.u**2 + vec.v**2
    u_gcd = vec.u.gcd(mag_squared)
    v_gcd = vec.v.gcd(mag_squared)
    denominator = u_gcd.gcd(v_gcd)
    new(vec.u / denominator, vec.v / denominator)
  end
end

if __FILE__ == $0
  map = File.read("day10_input.txt")
  answer1 = monitoring_station_location_for(map)
  puts answer1
end
