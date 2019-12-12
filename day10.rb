require "set"

def vaporized_asteroids(monitor, asteroids)
  asteroids_by_direction = asteroids
    .map { |asteroid| Vector.new(monitor, asteroid) }
    .group_by { |vector| vector.clockwise_angle }
    .to_a
    .sort { |a, b| a[0] <=> b[0] }
    .map { |angle, list| [angle, list.sort_by { |vector| vector.magnitude_squared }]}

  vaporized = []
  i = 0
  while asteroids_by_direction.flatten.any? { |el| el.is_a?(Vector) }
    _, list_in_direction = asteroids_by_direction[i % asteroids_by_direction.length]
    vaporized << list_in_direction.shift unless list_in_direction.empty?
    i += 1
  end
  vaporized.map { |vector| vector.to }
end

def monitoring_station_location_for(asteroids)
  asteroid_pairs = asteroids.permutation(2).to_a
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
  def magnitude_squared
    u**2 + v**2
  end

  def clockwise_angle
    Math.atan2(u, -v) % (2 * Math::PI)
  end

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
    mag_squared = vec.magnitude_squared
    u_gcd = vec.u.gcd(mag_squared)
    v_gcd = vec.v.gcd(mag_squared)
    denominator = u_gcd.gcd(v_gcd)
    new(vec.u / denominator, vec.v / denominator)
  end
end

if __FILE__ == $0
  map = File.read("day10_input.txt")
  asteroids = asteroids(map)
  monitor, answer1 = monitoring_station_location_for(asteroids)
  puts answer1

  vaporized = vaporized_asteroids(monitor, asteroids - [monitor])
  vaporized200 = vaporized[199]
  answer2 = vaporized200.col * 100 + vaporized200.row
  puts answer2
end
