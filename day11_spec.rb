require "rspec"
require_relative "day11"

class TestablePaintingRobot < PaintingRobot
  def initialize(outputs)
    @processor = TestableIntcodeProcessor.new(outputs)
    @visited_panels = [VisitedPanel.new(Point.new(0, 0), :up, nil)]
  end
end

class TestableIntcodeProcessor
  def initialize(outputs)
    @outputs = outputs
    @halted = false
  end

  def process_to_output
    output = outputs.shift
    if outputs.empty?
      @halted = true
    end
    output
  end

  def running?
    !halted?
  end

  def add_input(_)
    #no-op
  end

  private

  attr_reader :outputs, :halted
  alias :halted? :halted
end

RSpec.describe "day 11" do
  describe "step 1" do
    it "example" do
      colors = [1, 0, 1, 1, 0, 1, 1]
      turns = [0, 0, 0, 0, 1, 0, 0]
      outputs = colors.zip(turns).flatten
      robot = TestablePaintingRobot.new(outputs)
      robot.run
      expect(robot.painted_panels.length).to eq 6
    end
  end
end