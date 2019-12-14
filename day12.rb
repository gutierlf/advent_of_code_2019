require "set"

def period(positions)
  # learned this from alexanderhaupt while watching
  # https://www.youtube.com/watch?v=vfPwct8QyhM&t=10297s
  #
  # code at https://pastebin.com/Jn4ctapx
  (0..2)
    .map { |dim| period_by_dimension(positions, dim) }
    .reduce { |acc, cur| lcm(acc, cur) }
end

def period_by_dimension(positions, dim)
  sim = JupiterMoonSimulation.new(positions)
  state = ->(moons) { moons_list_by_dimension(moons, dim) }
  history = Set.new
  loop do
    this_state = state[sim.moons]
    break if history.include?(this_state)
    history << this_state
    sim.step
  end
  history.length
end

def moons_list_by_dimension(moons, dim)
  moons.map { |moon| (dim...6).step(3).map { |i| moon.to_a[i] } }.flatten
end

def lcm(a, b)
  a * b / a.gcd(b)
end

class JupiterMoonSimulation
  attr_reader :moons

  def initialize(positions)
    @moons = positions.map { |p| init_moon(p.dup) }
  end

  def step
    @moons = apply_gravity
    @moons = apply_velocity
  end

  def total_energy
    moons.map(&:total_energy).reduce(:+)
  end

  private

  def init_moon(position)
    MoonData.new(position, Velocity.new(0, 0, 0))
  end

  def apply_gravity
    moons.map do |m1|
      (moons - [m1]).reduce(m1) { |new_m1, m2| new_m1.apply_gravity_towards(m2) }
    end
  end

  def apply_velocity
    moons.map { |moon| moon.apply_velocity }
  end
end

MoonData = Struct.new(:pos, :vel) do
  def apply_gravity_towards(other)
    new(pos, vel.add(*pos.gravity_towards(other.pos)))
  end

  def apply_velocity
    new(pos.apply_velocity(vel), vel)
  end

  def total_energy
    potential_energy * kinetic_energy
  end

  def to_a
    pos.to_a + vel.to_a
  end

  private

  def new(pos, vel)
    self.class.new(pos, vel)
  end

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

  def to_a
    axes.map { |axis| send(axis) }
  end

  def gravity_towards(other)
    axes.map { |axis| gravity_by_axis(axis, other) }
  end

  def gravity_by_axis(axis, to)
    to.send(axis) <=> self.send(axis)
  end

  def apply_velocity(v)
    new(x + v.u, y + v.v, z + v.w)
  end

  private

  def new(x, y, z)
    self.class.new(x, y, z)
  end
end

Velocity = Struct.new(:u, :v, :w) do
  def self.axes
    [:u, :v, :w]
  end

  def axes
    self.class.axes
  end

  def to_a
    axes.map { |axis| send(axis) }
  end

  def add(du, dv, dw)
    new(u + du, v + dv, w + dw)
  end

  private

  def new(u, v, w)
    self.class.new(u, v, w)
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

  answer2 = period(positions)
  puts answer2
end