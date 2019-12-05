require "set"
require "rspec"

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

Point = Struct.new(:x, :y) do
  def to_s
    "(#{x}, #{y})"
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

class WirePath
  attr_reader :line_specs, :points_to_steps

  def initialize(line_specs)
    @line_specs = line_specs
    @points_to_steps = compute_points_to_steps
  end

  def points
    points_to_steps.keys
  end

  private

  def compute_points_to_steps
    @line_specs.reduce({Point.new(0, 0) => 0}) do |points_to_steps, line_spec|
      points = Line.new(points_to_steps.keys.last, line_spec).points
      new_points_to_steps = points.zip(points_to_steps.length...points.length + points_to_steps.length).to_h
      points_to_steps.merge(new_points_to_steps) { |_, old_val| old_val }
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

def intersections(wire_paths)
  wire_paths.map do |wire_path|
    wire_path.points.drop(1)
  end.reduce(:&)
end

def closest_intersection(intersections)
  intersections.map do |intersection|
    intersection.x.abs + intersection.y.abs
  end.min
end

def closest_intersection2(intersections, wire_paths)
  intersections.map do |intersection|
    wire_paths.map do |wire_path|
      wire_path.points_to_steps[intersection]
    end.reduce(:+)
  end.min
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