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

    shared_examples "monitoring_station_location_for" do |expected|
      it "works" do
        asteroids = asteroids(map)
        expect(monitoring_station_location_for(asteroids)[0]).to eq expected
      end
    end

    context "example 1" do
      let(:map) do
        <<~MAP
          .#..#
          .....
          #####
          ....#
          ...##
        MAP
      end
      include_examples "monitoring_station_location_for", Point.new(3, 4)
    end

    context "example 2" do
      let(:map) do
        <<~MAP
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
      end
      include_examples "monitoring_station_location_for", Point.new(5, 8)
    end

    context "example 3" do
      let(:map) do
        <<~MAP
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
      end
      include_examples "monitoring_station_location_for", Point.new(1, 2)
    end

    context "example 4" do
      let(:map) do
        <<~MAP
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
      end
      include_examples "monitoring_station_location_for", Point.new(6, 3)
    end

    context "example 5" do
      let(:map) do
        <<~MAP
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
      end
      include_examples "monitoring_station_location_for", Point.new(11, 13)
    end
  end

  describe "step 2" do
    it "example" do
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
      asteroids = asteroids(map)
      monitor, _ = monitoring_station_location_for(asteroids)
      list = vaporized_asteroids(monitor, asteroids - [monitor])
      expect(list.length).to eq 299
      expect(list[0]).to eq Point.new(11, 12)
      expect(list[1]).to eq Point.new(12, 1)
      expect(list[2]).to eq Point.new(12, 2)
      expect(list[9]).to eq Point.new(12, 8)
      expect(list[19]).to eq Point.new(16, 0)
      expect(list[49]).to eq Point.new(16, 9)
      expect(list[99]).to eq Point.new(10, 16)
      expect(list[198]).to eq Point.new(9, 6)
      expect(list[199]).to eq Point.new(8, 2)
      expect(list[200]).to eq Point.new(10, 9)
      expect(list[298]).to eq Point.new(11, 1)
    end
  end
end