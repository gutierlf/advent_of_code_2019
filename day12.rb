class JupiterMoonSimulation
  attr_reader :moons

  def initialize(positions)
    @moons = positions.map.with_index { |p, i| init_moon(i, p) }
  end

  def step
    apply_gravity
    apply_velocity
  end

  def total_energy
    moons.map(&:total_energy).reduce(:+)
  end

  private

  def init_moon(index, position)
    MoonData.new(index, position, Velocity.new(0, 0, 0))
  end

  def apply_gravity
    moons.combination(2).to_a.each do |m1, m2|
      m1.apply_gravity_towards(m2)
      m2.apply_gravity_towards(m1)
    end
  end

  def apply_velocity
    positions.each.with_index { |p, i| p.apply_velocity(velocities[i]) }
  end

  def positions
    moons.map { |moon| moon.pos }
  end

  def velocities
    moons.map { |moon| moon.vel }
  end
end

MoonData = Struct.new(:id, :pos, :vel) do
  def apply_gravity_towards(other)
    vel.add(*pos.gravity_towards(other.pos))
  end

  def total_energy
    potential_energy * kinetic_energy
  end

  private

  def potential_energy
    sum_of_absolute_values(pos)
  end

  def kinetic_energy
    sum_of_absolute_values(vel)
  end

  def sum_of_absolute_values(element)
    axes = element.axes
    axes.map { |axis| element.send(axis).abs }.reduce(:+)
  end
end

Point = Struct.new(:x, :y, :z) do
  def self.axes
    [:x, :y, :z]
  end

  def axes
    self.class.axes
  end

  def gravity_towards(other)
    axes.map { |axis| gravity_by_axis(axis, other) }
  end

  def gravity_by_axis(axis, to)
    to.send(axis) <=> self.send(axis)
  end

  def apply_velocity(v)
    self.x += v.u
    self.y += v.v
    self.z += v.w
  end
end

Velocity = Struct.new(:u, :v, :w) do
  def self.axes
    [:u, :v, :w]
  end

  def axes
    self.class.axes
  end

  def add(du, dv, dw)
    self.u += du
    self.v += dv
    self.w += dw
  end
end

def parse_input(input)
  parse_lines(input) { |line| parse_input_position(line) }
end

def parse_lines(input, &block)
  input.split("\n").map(&block)
end

def parse_input_position(line)
  regex = /#{position_pattern}/
  xyz = regex.match(line).captures.map(&:to_i)
  Point.new(*xyz)
end

def position_pattern
  number = " *(-?\\d*)"
  "<x=#{number}, y=#{number}, z=#{number}>"
end

if __FILE__ == $0
  input = File.read("day12_input.txt").chomp
  positions = parse_input(input)
  sim = JupiterMoonSimulation.new(positions)
  1000.times { sim.step }
  answer1 = sim.total_energy
  puts answer1
end