require "rspec"
require_relative "intcode_processor"

def maximize_thrust(phase_settings, &block)
  result = [0, phase_settings]
  phase_settings.permutation do |phases|
    thrust = block.call(phases)
    if thrust > result[0]
      result = [thrust, phases]
    end
  end
  result
end

def measure_thrust(program, phases)
  phases.reduce(0) do |input, phase|
    IntcodeProcessor.new(program, [input, phase]).process
  end
end

def measure_thrust_with_feedback(program, phases)
  processors = phases.map { |phase| IntcodeProcessor.new(program, [phase]) }
  thrust = i = 0
  while processors.any?(&:running?)
    processor = processors[i % phases.length]
    if processor.running?
      processor.add_input(thrust)
      thrust = processor.process
    end
    i += 1
  end
  thrust
end

RSpec.describe "day 7" do
  describe "step 1" do
    it "examples" do
      program = "3,15,3,16,1002,16,10,16,1,16,15,15,4,15,99,0,0".split(",").map(&:to_i)
      result = maximize_thrust((0..4).to_a) { |phases| measure_thrust(program, phases) }
      expect(result).to eq [43210, [4,3,2,1,0]]

      program = "3,23,3,24,1002,24,10,24,1002,23,-1,23,101,5,23,23,1,24,23,23,4,23,99,0,0".split(",").map(&:to_i)
      result = maximize_thrust((0..4).to_a) { |phases| measure_thrust(program, phases) }
      expect(result).to eq [54321, [0,1,2,3,4]]

      program = "3,31,3,32,1002,32,10,32,1001,31,-2,31,1007,31,0,33,1002,33,7,33,1,33,31,31,1,32,31,31,4,31,99,0,0,0".split(",").map(&:to_i)
      result = maximize_thrust((0..4).to_a) { |phases| measure_thrust(program, phases) }
      expect(result).to eq [65210, [1,0,4,3,2]]
    end
  end

  describe "step 2" do
    it "examples" do
      program = "3,26,1001,26,-4,26,3,27,1002,27,2,27,1,27,26,27,4,27,1001,28,-1,28,1005,28,6,99,0,0,5".split(",").map(&:to_i)
      result = maximize_thrust((5..9).to_a) { |phases| measure_thrust_with_feedback(program, phases)}
      expect(result).to eq [139629729, [9,8,7,6,5]]

      program = "3,52,1001,52,-5,52,3,53,1,52,56,54,1007,54,5,55,1005,55,26,1001,54,-5,54,1105,1,12,1,53,54,53,1008,54,0,55,1001,55,1,55,2,53,55,53,4,53,1001,56,-1,56,1005,56,6,99,0,0,0,0,10".split(",").map(&:to_i)
      result = maximize_thrust((5..9).to_a) { |phases| measure_thrust_with_feedback(program, phases)}
      expect(result).to eq [18216, [9,7,8,5,6]]
    end
  end
end

if __FILE__ == $0
  program = File.read("day7_input.txt").split(",").map(&:to_i)
  answer1, _ = maximize_thrust((0..4).to_a) { |phases| measure_thrust(program, phases) }
  puts answer1

  answer2, _ = maximize_thrust((5..9).to_a) { |phases| measure_thrust_with_feedback(program, phases)}
  puts answer2
end
