require "rspec"
require_relative "day10"

RSpec.describe "day 10" do
  describe "step 1" do
    it "asteroids" do
      map = <<~MAP
        .#..#
        #....
      MAP
      expect(asteroids(map)).to eq [
        Point.new(1, 0),
        Point.new(4, 0),
        Point.new(0, 1),
      ]
    end

    it "direction" do
      expect(Vector.new(Point.new(0, 0), Point.new(2, 2)).normalized).to eq NormalizedVector.new(1, 1)
    end

    it "example 1" do
      map = <<-MAP
.#..#
.....
#####
....#
...##
      MAP
      expect(monitoring_station_location_for(map)[0]).to eq Point.new(3, 4)
    end

    it "example 2" do
      map = <<~MAP
......#.#.
#..#.#....
..#######.
.#.#.###..
.#..#.....
..#....#.#
#..#....#.
.##.#..###
##...#..#.
.#....####
      MAP
      expect(monitoring_station_location_for(map)[0]).to eq Point.new(5, 8)
    end

    it "example 3" do
      map = <<~MAP
#.#...#.#.
.###....#.
.#....#...
##.#.#.#.#
....#.#.#.
.##..###.#
..#...##..
..##....##
......#...
.####.###.
      MAP
      expect(monitoring_station_location_for(map)[0]).to eq Point.new(1, 2)
    end

    it "example 4" do
      map = <<~MAP
.#..#..###
####.###.#
....###.#.
..###.##.#
##.##.#.#.
....###..#
..#.#..#.#
#..#.#.###
.##...##.#
.....#.#..
      MAP
      expect(monitoring_station_location_for(map)[0]).to eq Point.new(6, 3)
    end

    it "example 5" do
      map = <<~MAP
.#..##.###...#######
##.############..##.
.#.######.########.#
.###.#######.####.#.
#####.##.#.##.###.##
..#####..#.#########
####################
#.####....###.#.#.##
##.#################
#####.##.###..####..
..######..##.#######
####.##.####...##..#
.#####..#.######.###
##...#.##########...
#.##########.#######
.####.#.###.###.#.##
....##.##.###..#####
.#.#.###########.###
#.#.#.#####.####.###
###.##.####.##.#..##
      MAP
      expect(monitoring_station_location_for(map)[0]).to eq Point.new(11, 13)
    end
  end
end