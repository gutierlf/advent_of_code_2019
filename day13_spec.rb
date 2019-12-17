require "rspec"
require_relative "day13"

class TestableGame < GameWithoutQuarters
  attr_accessor :outputs
  def start
    parse_program_output
  end
end

RSpec.describe "day 13" do
  describe "step 1" do
    it "tiles" do
      outputs = [1,2,3,6,5,4]
      game = TestableGame.new([])
      game.outputs = outputs
      game.start
      expect(game.empties).to eq []
      expect(game.walls).to eq []
      expect(game.blocks).to eq []
      expect(game.paddles).to eq [Point.new(1, 2)]
      expect(game.balls).to eq [Point.new(6, 5)]
    end
  end
end