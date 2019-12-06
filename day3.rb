require "rspec"

def closest_intersection(intersections)
  intersections.map(&:manhattan_distance).min
end

def closest_intersection2(intersections, wire_paths)
  intersections.map(&:steps).min
end

def intersections(wire_paths)
  wire_paths.map do |wire_path|
    wire_path.points.drop(1)
  end.reduce(:&)
end

class WirePath
  attr_reader :line_specs, :measured_points

  def initialize(line_specs)
    @line_specs = line_specs
    @measured_points = compute_measured_points
  end

  def points
    measured_points
  end

  private

  def compute_measured_points
    @line_specs.reduce(MeasuredPoints.new(Point.new(0, 0), 0)) do |measured_points, line_spec|
      points = Line.new(measured_points.last, line_spec).points
      steps = (0...points.length).map { |i| i + measured_points.length }
      measured_points.update(points, steps)
    end
  end
end

class MeasuredPoints
  def initialize(point, steps)
    @data = {point => steps}
  end

  def last
    data.keys.last
  end

  def length
    data.length
  end

  def update(points, steps)
    @data.merge!(points.zip(steps).to_h) { |_, old_val| old_val }
    self
  end

  def steps_for(key)
    data[key]
  end

  def drop(n)
    @data = data.drop(n).to_h
    self
  end

  def &(other)
    longer, shorter = (length >= other.length) ? [self, other] : [other, self]
    shorter.reduce([]) do |intersections, (point, steps)|
      if longer.include?(point)
        intersections << MeasuredPoint.new(point, steps + longer.steps_for(point))
      else
        intersections
      end
    end
  end

  def include?(point)
    points.include?(point)
  end

  def reduce(init, &block)
    data.reduce(init, &block)
  end

  private

  attr_reader :data

  def points
    data.keys
  end
end

class Line
  attr_reader :points

  def initialize(from, axis_and_length)
    @from, @axis_and_length = from, axis_and_length
    @points = compute_points
  end

  private

  attr_reader :from, :axis_and_length

  def compute_points
    axis, range = axis_and_range
    range.map do |i|
      if axis == :x
        Point.new(i, from.send(:y))
      else
        Point.new(from.send(:x), i)
      end
    end
  end

  def axis_and_range
    axis, length = axis_and_length
    start = from.send(axis)
    one = length.abs / length
    op = length > 0 ? :upto : :downto
    range = (start + one).send(op, start + length)
    [axis, range]
  end
end

MeasuredPoint = Struct.new(:point, :steps) do
  def manhattan_distance
    x.abs + y.abs
  end

  def x
    point.x
  end

  def y
    point.y
  end
end

Point = Struct.new(:x, :y) do
  def manhattan_distance
    x.abs + y.abs
  end

  def to_s
    "(#{x}, #{y})"
  end
end

class Parser
  attr_reader :path_spec

  def initialize(path_spec)
    @path_spec = path_spec
  end

  def parse
    path_spec.split(",").map { |line_spec| axis_and_length(line_spec) }
  end

  private

  LINE_SPEC_REGEX = /([RLUD])(\d+)/

  def axis_and_length(line_spec)
    axis, length = LINE_SPEC_REGEX.match(line_spec).captures
    length = length.to_i
    case axis
    when "R" then [:x, length]
    when "L" then [:x, -length]
    when "U" then [:y, length]
    when "D" then [:y, -length]
    end
  end
end

RSpec.describe "day 3" do
  describe "closest intersection distance" do
    let(:all_path_specs) {
      [
        %w(
          R8,U5,L5,D3
          U7,R6,D4,L4
        ),
        %w(
          R75,D30,R83,U83,L12,D49,R71,U7,L72
          U62,R66,U55,R34,D71,R55,D58,R83
        ),
        %w(
          R98,U47,R26,D63,R33,U87,L62,D20,R33,U53,R51
          U98,R91,D20,R16,D67,R40,U7,R15,U6,R7
        ),
      ]
    }
    let(:all_wire_paths) {
      all_path_specs.map do |path_specs|
        path_specs.map do |path_spec|
          WirePath.new(Parser.new(path_spec).parse)
        end
      end
    }
    let(:all_intersections) {
      all_wire_paths.map do |wire_paths|
        intersections(wire_paths)
      end
    }
    context "step 1" do
      let(:expected_distances) { [6, 159, 135] }
      it "facts" do
        all_intersections.zip(expected_distances).each do |intersections, expected_distance|
          expect(closest_intersection(intersections)).to eq expected_distance
        end
      end
    end
    context "step 2" do
      let(:expected_distances) { [30, 610, 410] }
      it "facts" do
        all_wire_paths
          .zip(all_intersections, expected_distances)
          .each do |wire_paths, intersections, expected_distance|
          expect(closest_intersection2(intersections, wire_paths)).to eq expected_distance
        end
      end
    end
  end
end

class WirePathPrinter
  attr_reader :points_to_chars

  def initialize(wire_paths)
    @points_to_chars = wire_paths
                         .map { |wire_path| points_to_chars_for(wire_path) }
                         .reduce { |acc, cur| acc.merge(cur) { "X" } }
    @points_to_chars[Point.new(0, 0)] = "o"
  end

  def pretty_print
    x_min, x_max, y_min, y_max = bounding_box
    width = x_max - x_min + 1
    height = y_max - y_min + 1
    grid = Array.new(height) { Array.new(width) { "." } }
    points_to_chars.each do |point, char|
      row = point.y - y_min
      col = point.x - x_min
      grid[row][col] = char
    end
    puts grid.reverse.map { |row| row.join("") }.join("\n")
  end

  private

  def points_to_chars_for(wire_path)
    index = 0
    wire_path.line_specs.reduce([[Point.new(0, 0), "o"]]) do |h, line_spec|
      char = /[LR]/ =~ line_spec[0] ? "-" : "|"
      points = Line.new(h.last[0], line_spec).points
      end_element =
        if index < wire_path.line_specs.length - 1
          [[points.pop, "+"]]
        else
          []
        end
      index += 1
      h + points.map { |p| [p, char] } + end_element
    end.to_h
  end

  def bounding_box
    xs = points.map(&:x)
    ys = points.map(&:y)
    [xs.min, xs.max, ys.min, ys.max]
  end

  def points
    points_to_chars.keys
  end
end

if __FILE__ == $0
  path_specs = File.readlines("day3_input.txt").map(&:chomp).map do |line|
    Parser.new(line).parse
  end
  wire_paths = path_specs.map { |p| WirePath.new(p) }
  intersections = intersections(wire_paths)
  answer1 = closest_intersection(intersections)
  puts answer1

  answer2 = closest_intersection2(intersections, wire_paths)
  puts answer2
end