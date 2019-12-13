require "rspec"
require_relative "day12"

RSpec.describe "day 12" do
  describe "step 1" do
    it "example 1" do
      input = <<~INPUT
        <x=-1, y=0, z=2>
        <x=2, y=-10, z=-7>
        <x=4, y=-8, z=8>
        <x=3, y=5, z=-1>
      INPUT
      positions = parse_input(input)
      sim = JupiterMoonSimulation.new(positions)
      expected_string = <<~EXPECTED
        pos=<x=-1, y=  0, z= 2>, vel=<x= 0, y= 0, z= 0>
        pos=<x= 2, y=-10, z=-7>, vel=<x= 0, y= 0, z= 0>
        pos=<x= 4, y= -8, z= 8>, vel=<x= 0, y= 0, z= 0>
        pos=<x= 3, y=  5, z=-1>, vel=<x= 0, y= 0, z= 0>
      EXPECTED
      expect(sim.moons).to eq parse_expected(expected_string)

      sim.step
      expected_string = <<~EXPECTED
        pos=<x= 2, y=-1, z= 1>, vel=<x= 3, y=-1, z=-1>
        pos=<x= 3, y=-7, z=-4>, vel=<x= 1, y= 3, z= 3>
        pos=<x= 1, y=-7, z= 5>, vel=<x=-3, y= 1, z=-3>
        pos=<x= 2, y= 2, z= 0>, vel=<x=-1, y=-3, z= 1>
      EXPECTED
      expect(sim.moons).to eq parse_expected(expected_string)

      sim.step
      expected_string = <<~EXPECTED
        pos=<x= 5, y=-3, z=-1>, vel=<x= 3, y=-2, z=-2>
        pos=<x= 1, y=-2, z= 2>, vel=<x=-2, y= 5, z= 6>
        pos=<x= 1, y=-4, z=-1>, vel=<x= 0, y= 3, z=-6>
        pos=<x= 1, y=-4, z= 2>, vel=<x=-1, y=-6, z= 2>
      EXPECTED
      expect(sim.moons).to eq parse_expected(expected_string)

      8.times { sim.step }
      expected_string = <<~EXPECTED
        pos=<x= 2, y= 1, z=-3>, vel=<x=-3, y=-2, z= 1>
        pos=<x= 1, y=-8, z= 0>, vel=<x=-1, y= 1, z= 3>
        pos=<x= 3, y=-6, z= 1>, vel=<x= 3, y= 2, z=-3>
        pos=<x= 2, y= 0, z= 4>, vel=<x= 1, y=-1, z=-1>
      EXPECTED
      expect(sim.moons).to eq parse_expected(expected_string)

      expect(sim.total_energy).to eq 179
    end

    it "example 2" do
      input = <<~INPUT
        <x=-8, y=-10, z=0>
        <x=5, y=5, z=10>
        <x=2, y=-7, z=3>
        <x=9, y=-8, z=-3>
      INPUT
      positions = parse_input(input)
      sim = JupiterMoonSimulation.new(positions)
      100.times { sim.step }

      expected_string = <<~EXPECTED
        pos=<x=  8, y=-12, z= -9>, vel=<x= -7, y=  3, z=  0>
        pos=<x= 13, y= 16, z= -3>, vel=<x=  3, y=-11, z= -5>
        pos=<x=-29, y=-11, z= -1>, vel=<x= -3, y=  7, z=  4>
        pos=<x= 16, y=-13, z= 23>, vel=<x=  7, y=  1, z=  1>
      EXPECTED
      expect(sim.moons).to eq parse_expected(expected_string)

      expect(sim.total_energy).to eq 1940
    end
  end

  describe "step 2" do
    it "moon data equality" do
      m1 = MoonData.new(Point.new(0,1,2), Velocity.new(3,4,5))
      m2 = MoonData.new(Point.new(0,1,2), Velocity.new(3,4,5))
      expect(m1 == m2).to eq true
      set = Set.new([m1, m2])
      expect(set.length).to eq 1
    end

    it "example 1" do
      input = <<~INPUT
        <x=-1, y=0, z=2>
        <x=2, y=-10, z=-7>
        <x=4, y=-8, z=8>
        <x=3, y=5, z=-1>
      INPUT
      positions = parse_input(input)
      expect(period(positions)).to eq 2772
    end
  end
end

def parse_expected(str)
  parse_lines(str).with_index { |line, i| parse_expected_line(line, i) }
end

def parse_expected_line(line, index)
  regex = /pos=#{position_pattern}, vel=#{position_pattern}/
  px, py, pz, vx, vy, vz = regex.match(line).captures.map(&:to_i)
  MoonData.new(Point.new(px, py, pz), Velocity.new(vx, vy, vz))
end

