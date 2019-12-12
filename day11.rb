require_relative "intcode_processor"

class PaintingRobot
  def initialize(program, start_color)
    @processor = IntcodeProcessor.new(program, [start_color])
    @visited_panels = [VisitedPanel.new(Point.new(0, 0), :up, nil)]
  end

  def painted_panels
    visited_panels[0...-1].map { |panel| [panel.location, panel.color] }.to_h
  end

  def run
    while processor.running?
      color = processor.process_to_output
      turn = processor.process_to_output
      visit_panel(color, turn)
      processor.add_input(current_color)
    end
  end

  private

  attr_reader :processor, :visited_panels

  def visit_panel(color, turn_direction)
    current_panel = visited_panels.last
    current_panel.color = color
    heading = turn(current_panel.heading, turn_direction)
    location = move(current_panel.location, heading)
    visited_panels << VisitedPanel.new(location, heading, nil)
  end

  def turn(heading, direction)
    direction = (direction == 0) ? :left : :right
    offset = (direction == :right) ? 1 : -1
    HEADINGS[(HEADINGS.find_index(heading) + offset) % HEADINGS.length]
  end

  HEADINGS = [:up, :right, :down, :left]

  def move(from, heading)
    delta = MOVE_DELTAS[heading]
    Point.new(from.x + delta[0], from.y + delta[1])
  end

  MOVE_DELTAS = {
    up: [0, 1],
    down: [0, -1],
    right: [1, 0],
    left: [-1, 0],
  }

  def current_color
    painted_panels.fetch(current_location, 0)
  end

  def current_location
    visited_panels.last.location
  end
end

class PaintingRobotImage
  def initialize(painted_panels)
    @pixels = compute_pixels(painted_panels)
  end

  def show
    puts to_s
  end

  def to_s
    pixels
      .map { |row| row.map { |pixel| pixel ? "█" : " " }.join("") }
      .join("\n")
  end

  private

  attr_reader :pixels

  def compute_pixels(painted_panels)
    xmin, xmax, ymin, ymax = bounding_box(painted_panels)
    pixels = Array.new(ymax - ymin + 1) { Array.new(xmax - xmin + 1, false) }
    painted_panels.each do |location, color|
      row = location.y - ymin
      col = location.x - xmin
      pixels[row][col] = (color == 1) ? true : false
    end
    pixels.reverse
  end

  def bounding_box(painted_panels)
    xs, ys = painted_panels.keys.map { |p| [p.x, p.y] }.transpose
    [xs.min, xs.max, ys.min, ys.max]
  end
end

VisitedPanel = Struct.new(:location, :heading, :color)

Point = Struct.new(:x, :y)

if __FILE__ == $0
  program = File.read("day11_input.txt").chomp.split(",").map(&:to_i)
  # robot = PaintingRobot.new(program, 0)
  # robot.run
  # answer1 = robot.painted_panels.length
  # puts answer1

  robot = PaintingRobot.new(program, 1)
  robot.run
  PaintingRobotImage.new(robot.painted_panels).show
end